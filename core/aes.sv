module aes
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type fu_data_t = logic
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  fu_data_t fu_data_i,        
    input logic aes_valid_i,
    output logic [CVA6Cfg.XLEN-1:0] result_o,
    output logic ready_o,                    
    output logic [CVA6Cfg.TRANS_ID_BITS-1:0] aes_trans_id_o,
    output logic aes_valid_o
);


logic [127:0] key_reg;
logic [127:0] data_reg;
logic [127:0] cipher_reg;
logic start_enc;
logic done_enc;

logic read_high;
logic read_low;

logic [CVA6Cfg.XLEN-1:0] result_buffer;

logic [127:0] ciphertext;
aes_enc #(
    .CVA6Cfg    (CVA6Cfg),
    .fu_data_t  (fu_data_t)
) aes_enc_i (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .start_i    (start_enc),
    .key_i      (key_reg),
    .plaintext_i(data_reg),
    .done_o     (done_enc),
    .ciphertext_o(ciphertext)
);

assign start_enc = (fu_data_i.operation == AES_START_ENC);
assign aes_trans_id_o = fu_data_i.trans_id;

logic busy;
always_ff @(posedge clk_i) begin
    if (start_enc) busy <= 1'b1;
    else if (done_enc) busy <= 1'b0;
end

assign ready_o = ~busy;
assign result_o = result_buffer;

// -----------------------------
// Sequential logic
// -----------------------------
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        key_reg <= 128'b0;
        data_reg <= 128'b0;
        cipher_reg <= 128'b0;
        read_high <= 1'b0;
        read_low <= 1'b0;
    end else begin
        if (done_enc) begin
            cipher_reg <= ciphertext;
        end 

        if (aes_valid_i && (fu_data_i.operation inside { AES_READ_HIGH, AES_READ_LOW})) begin
            aes_valid_o <= aes_valid_i;
        end
       
        unique case (fu_data_i.operation)
            AES_LOAD_KEY: begin
                key_reg[127:64] <= fu_data_i.operand_a; 
                key_reg[63:0] <= fu_data_i.operand_b; 
            end
            AES_LOAD_DATA: begin
                data_reg[127:64] <= fu_data_i.operand_a; 
                data_reg[63:0] <= fu_data_i.operand_b; 
            end
            AES_READ_HIGH: begin
                read_high <= 1'b1;
                // result_o <= cipher_reg[127:64];
            end
            AES_READ_LOW: begin
                read_low <= 1'b1;
                // result_o <= cipher_reg[63:0];
            end
            default: begin
                // Do nothing
            end
        endcase
    end
end

// result mux
always_comb begin
    case (fu_data_i.operation)
        AES_READ_HIGH: result_buffer = cipher_reg[127:64];
        AES_READ_LOW:  result_buffer = cipher_reg[63:0];
        default:       result_buffer = '0;
    endcase
end

endmodule