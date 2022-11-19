`timescale 1ns / 1ps
`include "./utils.vh"

module BTB_branch_decider(
    input wire [3:0] br_op_i,
    output wire is_branch_o
);

    assign is_branch_o = (br_op_i==4'b0010)?1'b0:1'b1; // 2 不跳转

endmodule