module ALU_a_mux(
    input wire [31:0] pc_i,
    input wire [31:0] rs1_data_i,
    input wire alu_a_sel_i,
    output wire [31:0] alu_a_o
);
    assign alu_a_o = (alu_a_sel_i == 1) ? rs1_data_i : pc_i;
endmodule