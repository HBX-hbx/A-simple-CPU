`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/20 13:59:07
// Design Name: 
// Module Name: regfile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module regfile(
    input wire clk,
    input wire reset,
    
    input wire  [4:0]  rf_raddr_a,
    output logic [31:0] rf_rdata_a,
    input wire  [4:0]  rf_raddr_b,
    output logic [31:0] rf_rdata_b,

    input wire  [4:0]  rf_waddr,
    input wire  [31:0] rf_wdata,

    input wire  rf_wen
);
    
    reg [31:0] allregs [31:0];
    
    always_comb begin
        if (rf_raddr_a == 0) rf_rdata_a = 0;
        else if (rf_raddr_a == rf_waddr && rf_wen) rf_rdata_a = rf_wdata;
        else rf_rdata_a = allregs[rf_raddr_a];
        
        if (rf_raddr_b == 0) rf_rdata_b = 0;
        else if (rf_raddr_b == rf_waddr && rf_wen) rf_rdata_b = rf_wdata;
        else rf_rdata_b = allregs[rf_raddr_b];
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            allregs[0] <= 32'h00000000;
            allregs[1] <= 32'h00000000;
            allregs[2] <= 32'h00000000;
            allregs[3] <= 32'h00000000;
            allregs[4] <= 32'h00000000;
            allregs[5] <= 32'h00000000;
            allregs[6] <= 32'h00000000;
            allregs[7] <= 32'h00000000;
            allregs[8] <= 32'h00000000;
            allregs[9] <= 32'h00000000;
            allregs[10] <= 32'h00000000;
            allregs[11] <= 32'h00000000;
            allregs[12] <= 32'h00000000;
            allregs[13] <= 32'h00000000;
            allregs[14] <= 32'h00000000;
            allregs[15] <= 32'h00000000;
            allregs[16] <= 32'h00000000;
            allregs[17] <= 32'h00000000;
            allregs[18] <= 32'h00000000;
            allregs[19] <= 32'h00000000;
            allregs[20] <= 32'h00000000;
            allregs[21] <= 32'h00000000;
            allregs[22] <= 32'h00000000;
            allregs[23] <= 32'h00000000;
            allregs[24] <= 32'h00000000;
            allregs[25] <= 32'h00000000;
            allregs[26] <= 32'h00000000;
            allregs[27] <= 32'h00000000;
            allregs[28] <= 32'h00000000;
            allregs[29] <= 32'h00000000;
            allregs[30] <= 32'h00000000;
            allregs[31] <= 32'h00000000;
        end else begin
            if (rf_wen && rf_waddr != 0) begin;
                allregs[rf_waddr] <= rf_wdata;
            end
        end
    end
endmodule
