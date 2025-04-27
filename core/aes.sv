module aes
  import ariane_pkg::*;
  import config_pkg::*;
#(
    parameter cva6_cfg_t CVA6Cfg = cva6_cfg_empty,
    parameter type fu_data_t = logic
) (
    // Global signals
    input  logic                     clk_i,
    input  logic                     rst_ni,

    // FU Interface
    input  fu_data_t                 fu_data_i,  // Instruction data from decoder
    output logic [CVA6Cfg.XLEN-1:0]  result_o,   // result output
    output logic                     ready_o     // unit ready signal
);

// -------------------------
// AES internal state
// -------------------------
typedef enum logic [2:0] {
    IDLE,
    LOAD_KEY,
    LOAD_DATA,
    KEY_EXPAND,
    ENCRYPT_ROUND,
    FINAL_ROUND,
    READY
} aes_state_t;

aes_state_t curr_state, next_state;

// data registers
logic [127:0] key_reg;       // key register
logic [127:0] data_reg;      // plaintext

logic [127:0] cipher_reg, cipher_reg_next;
logic [1407:0] round_keys;

logic [3:0] round_cnt, round_cnt_next;

// -------------------------
// control signals
// -------------------------
logic load_key_high, load_key_low;
logic load_data_high, load_data_low;
logic start_encrypt;
logic read_high, read_low;

assign load_key_high = (fu_data_i.operation == AES_LOAD_KEYH);
assign load_key_low  = (fu_data_i.operation == AES_LOAD_KEYL);
assign load_data_high= (fu_data_i.operation == AES_LOAD_DATAH);
assign load_data_low = (fu_data_i.operation == AES_LOAD_DATAL);
assign start_encrypt = (fu_data_i.operation == AES_START_ENC);
assign read_high     = (fu_data_i.operation == AES_READ_HIGH);
assign read_low      = (fu_data_i.operation == AES_READ_LOW);

// -------------------------
// AES core
// -------------------------
function automatic logic [7:0] sbox(input [7:0] in);
    logic [7:0] sbox_table [0:255] = '{
        8'h63, 8'h7c, 8'h77, 8'h7b, 8'hf2, 8'h6b, 8'h6f, 8'hc5, 8'h30, 8'h01, 8'h67, 8'h2b, 8'hfe, 8'hd7, 8'hab, 8'h76,
        8'hca, 8'h82, 8'hc9, 8'h7d, 8'hfa, 8'h59, 8'h47, 8'hf0, 8'had, 8'hd4, 8'ha2, 8'haf, 8'h9c, 8'ha4, 8'h72, 8'hc0,
        8'hb7, 8'hfd, 8'h93, 8'h26, 8'h36, 8'h3f, 8'hf7, 8'hcc, 8'h34, 8'ha5, 8'he5, 8'hf1, 8'h71, 8'hd8, 8'h31, 8'h15,
        8'h04, 8'hc7, 8'h23, 8'hc3, 8'h18, 8'h96, 8'h05, 8'h9a, 8'h07, 8'h12, 8'h80, 8'he2, 8'heb, 8'h27, 8'hb2, 8'h75,
        8'h09, 8'h83, 8'h2c, 8'h1a, 8'h1b, 8'h6e, 8'h5a, 8'ha0, 8'h52, 8'h3b, 8'hd6, 8'hb3, 8'h29, 8'he3, 8'h2f, 8'h84,
        8'h53, 8'hd1, 8'h00, 8'hed, 8'h20, 8'hfc, 8'hb1, 8'h5b, 8'h6a, 8'hcb, 8'hbe, 8'h39, 8'h4a, 8'h4c, 8'h58, 8'hcf,
        8'hd0, 8'hef, 8'haa, 8'hfb, 8'h43, 8'h4d, 8'h33, 8'h85, 8'h45, 8'hf9, 8'h02, 8'h7f, 8'h50, 8'h3c, 8'h9f, 8'ha8,
        8'h51, 8'ha3, 8'h40, 8'h8f, 8'h92, 8'h9d, 8'h38, 8'hf5, 8'hbc, 8'hb6, 8'hda, 8'h21, 8'h10, 8'hff, 8'hf3, 8'hd2,
        8'hcd, 8'h0c, 8'h13, 8'hec, 8'h5f, 8'h97, 8'h44, 8'h17, 8'hc4, 8'ha7, 8'h7e, 8'h3d, 8'h64, 8'h5d, 8'h19, 8'h73,
        8'h60, 8'h81, 8'h4f, 8'hdc, 8'h22, 8'h2a, 8'h90, 8'h88, 8'h46, 8'hee, 8'hb8, 8'h14, 8'hde, 8'h5e, 8'h0b, 8'hdb,
        8'he0, 8'h32, 8'h3a, 8'h0a, 8'h49, 8'h06, 8'h24, 8'h5c, 8'hc2, 8'hd3, 8'hac, 8'h62, 8'h91, 8'h95, 8'he4, 8'h79,
        8'he7, 8'hc8, 8'h37, 8'h6d, 8'h8d, 8'hd5, 8'h4e, 8'ha9, 8'h6c, 8'h56, 8'hf4, 8'hea, 8'h65, 8'h7a, 8'hae, 8'h08,
        8'hba, 8'h78, 8'h25, 8'h2e, 8'h1c, 8'ha6, 8'hb4, 8'hc6, 8'he8, 8'hdd, 8'h74, 8'h1f, 8'h4b, 8'hbd, 8'h8b, 8'h8a,
        8'h70, 8'h3e, 8'hb5, 8'h66, 8'h48, 8'h03, 8'hf6, 8'h0e, 8'h61, 8'h35, 8'h57, 8'hb9, 8'h86, 8'hc1, 8'h1d, 8'h9e,
        8'he1, 8'hf8, 8'h98, 8'h11, 8'h69, 8'hd9, 8'h8e, 8'h94, 8'h9b, 8'h1e, 8'h87, 8'he9, 8'hce, 8'h55, 8'h28, 8'hdf,
        8'h8c, 8'ha1, 8'h89, 8'h0d, 8'hbf, 8'he6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2d, 8'h0f, 8'hb0, 8'h54, 8'hbb, 8'h16
    };
    return sbox_table[in];
endfunction

function automatic logic [127:0] key_expansion_core(input [127:0] key, input [3:0] round);
    logic [31:0] temp = {key[23:0], key[31:24]};
    temp = {sbox(temp[31:24]), sbox(temp[23:16]), sbox(temp[15:8]), sbox(temp[7:0])};
    temp = temp ^ {rcon(round), 24'h0};
    return {key[127:96] ^ temp, key[95:64] ^ key[127:96] ^ temp, 
            key[63:32] ^ key[95:64] ^ key[127:96] ^ temp, 
            key[31:0] ^ key[63:32] ^ key[95:64] ^ key[127:96] ^ temp};
endfunction

function automatic logic [7:0] rcon(input [3:0] round);
    case(round)
        4'h1: return 8'h01;
        4'h2: return 8'h02;
        4'h3: return 8'h04;
        4'h4: return 8'h08;
        4'h5: return 8'h10;
        4'h6: return 8'h20;
        4'h7: return 8'h40;
        4'h8: return 8'h80;
        4'h9: return 8'h1b;
        4'ha: return 8'h36;
        default: return 8'h00;
    endcase
endfunction

function automatic logic [31:0] mix_columns(input [31:0] col);
    logic [7:0] b0 = col[31:24], b1 = col[23:16], b2 = col[15:8], b3 = col[7:0];
    return {
        (b0<<1)^(b1>>7)*8'h1b ^ b1 ^ b2 ^ (b3<<1)^(b3>>7)*8'h1b,
        (b0<<1)^(b0>>7)*8'h1b ^ (b1<<1)^(b1>>7)*8'h1b ^ b2 ^ b3,
        b0 ^ (b1<<1)^(b1>>7)*8'h1b ^ (b2<<1)^(b2>>7)*8'h1b ^ b3,
        (b0<<1)^(b0>>7)*8'h1b ^ b1 ^ (b2<<1)^(b2>>7)*8'h1b ^ (b3<<1)^(b3>>7)*8'h1b
    };
endfunction

// -------------------------
// FSM
// -------------------------
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        curr_state <= IDLE;
        key_reg <= '0;
        data_reg <= '0;
        cipher_reg <= '0;
        round_keys <= '0;
        round_cnt <= '0;
    end else begin
        curr_state <= next_state;
        cipher_reg <= cipher_reg_next;
        round_cnt <= round_cnt_next;

        case(curr_state)
            IDLE: begin
                if (load_key_high) key_reg[127:64] <= fu_data_i.operand_a;
                if (load_key_low)  key_reg[63:0]   <= fu_data_i.operand_b;
                if (load_data_high) data_reg[127:64] <= fu_data_i.operand_a;
                if (load_data_low) data_reg[63:0]   <= fu_data_i.operand_b;
            end

            KEY_EXPAND: begin
                round_keys[127:0] <= key_expansion_core(key_reg, round_cnt);
            end

            ENCRYPT_ROUND: begin
                for (int i=0; i<16; i++)
                    cipher_reg[i*8 +:8] <= sbox(cipher_reg[i*8 +:8]);
                cipher_reg <= {
                    cipher_reg[127:120], cipher_reg[87:80], cipher_reg[47:40], cipher_reg[7:0],
                    cipher_reg[95:88],   cipher_reg[55:48], cipher_reg[15:8],  cipher_reg[103:96],
                    cipher_reg[63:56],   cipher_reg[23:16], cipher_reg[111:104], cipher_reg[71:64],
                    cipher_reg[31:24],   cipher_reg[119:112], cipher_reg[79:72], cipher_reg[39:32]
                };
                if (round_cnt < 10) begin
                    cipher_reg[127:96] <= mix_columns(cipher_reg[127:96]);
                    cipher_reg[95:64]  <= mix_columns(cipher_reg[95:64]);
                    cipher_reg[63:32]  <= mix_columns(cipher_reg[63:32]);
                    cipher_reg[31:0]   <= mix_columns(cipher_reg[31:0]);
                end
            end
        endcase
    end
end

always_comb begin
    next_state = curr_state;
    ready_o = 1'b0;
    cipher_reg_next = cipher_reg;
    round_cnt_next = round_cnt;

    unique case (curr_state)
        IDLE: begin
            ready_o = 1'b1;
            if (start_encrypt) begin
                cipher_reg_next = data_reg ^ round_keys[127:0];
                round_cnt_next = 4'd1;
                next_state = KEY_EXPAND;
            end
        end

        KEY_EXPAND: begin
            next_state = ENCRYPT_ROUND;
        end

        ENCRYPT_ROUND: begin
            if (round_cnt == 10)
                next_state = FINAL_ROUND;
            else begin
                cipher_reg_next = cipher_reg ^ round_keys[round_cnt*128 +:128];
                round_cnt_next = round_cnt + 1;
                next_state = KEY_EXPAND;
            end
        end

        FINAL_ROUND: begin
            next_state = READY;
        end

        READY: begin
            ready_o = 1'b1;
            next_state = IDLE;
        end
    endcase
end

always_comb begin
    result_o = '0;
    if (read_high)
        result_o = cipher_reg[127:64];
    else if (read_low)
        result_o = cipher_reg[63:0];
end

endmodule
