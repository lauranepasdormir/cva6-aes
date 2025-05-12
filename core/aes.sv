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
logic start_round;
logic done_round;
logic busy;

logic [3:0] round_counter;
logic [127:0] current_state;

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
    .ciphertext_o(cipher_reg)
);

aes_round #(
    .CVA6Cfg    (CVA6Cfg),
    .fu_data_t  (fu_data_t)
) aes_round_i (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .start_i    (start_round),
    .is_first_round_i(round_counter == 0),
    .is_final_round_i(round_counter == 10),
    .key_i      (key_reg),
    .round_i(round_counter),
    .state_i(current_state),
    .done_o     (done_round),
    .state_o(cipher_reg)
);

always_ff @(posedge clk_i) begin
    if (start_enc || start_round) busy <= 1'b1;
    else if (done_enc || done_round) busy <= 1'b0;
end

assign start_enc = (fu_data_i.operation == AES_START_ENC);
assign start_round = (fu_data_i.operation == AES_ROUND);
assign aes_trans_id_o = fu_data_i.trans_id;
assign ready_o = ~busy;

// round counter & state control
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      round_counter <= 0;
      current_state <= 0;
    end else begin
      if (start_round) begin
        if (round_counter == 0) begin
          current_state <= data_reg;
        end
      end
      if (done_round) begin
        current_state <= cipher_reg;
        round_counter <= round_counter + 1;
      end
      if (round_counter == 11) begin
        round_counter <= 0;
      end
    end
  end

// -----------------------------
// Sequential logic
// -----------------------------
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        key_reg <= 128'b0;
        data_reg <= 128'b0;
        cipher_reg <= 128'b0;
    end else begin

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
            default: begin
                // Do nothing
            end
        endcase
    end
end

// result mux
always_comb begin
    result_o = '0;
    case (fu_data_i.operation)
        AES_READ_HIGH: result_o = cipher_reg[127:64];
        AES_READ_LOW:  result_o = cipher_reg[63:0];
        default:       result_o = '0;
    endcase
end


endmodule
