`timescale 1ns / 1ps
`include "./utils.vh"

module PC_sel_mux(
    input wire [3:0] csr_code_i,
    input wire [`ADDR_WIDTH-1:0] exe_inst_i,
    output logic [1:0] pc_sel_o // 给 btb 地址生成器用来选择用
);

always_comb begin
    if (csr_code_i != 0) begin
        pc_sel_o = 3;
    end else if (exe_inst_i[14:12] == 3'b000 && exe_inst_i[6:0] == 7'b1100111) begin
        pc_sel_o = 2;
    end else begin
        pc_sel_o = 0;
    end
end

endmodule