module ALU_b_mux(
    input wire [31:0] imm_i,
    input wire [31:0] rs2_data_i,
    input wire alu_b_sel_i,
    output wire [31:0] alu_b_o
);
    assign alu_b_o = (alu_b_sel_i == 1) ? rs2_data_i : imm_i;
endmodule