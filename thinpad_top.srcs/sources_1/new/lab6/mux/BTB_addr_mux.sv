`timescale 1ns / 1ps
`include "./utils.vh"

module BTB_Addr_MUX(
    input wire [`ADDR_WIDTH-1:0] exe_pc_i,
    input wire [`ADDR_WIDTH-1:0] alu_pc_i,
    input wire [`ADDR_WIDTH-1:0] direct_br_addr,
    output logic [`ADDR_WIDTH-1:0] branch_addr_o,
    input wire [1:0] addr_sel
);

    always_comb begin
        case(addr_sel)
            2'b00: begin
                branch_addr_o = exe_pc_i + alu_pc_i;
            end
            2'b10: begin
                branch_addr_o = alu_pc_i;
            end
            2'b11: begin
                branch_addr_o = direct_br_addr;
            end
            default: begin
                branch_addr_o = exe_pc_i + alu_pc_i;
            end
        endcase
    end
endmodule