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
    // ���ӼĴ�����ģ����ź�?
    input wire  [4:0]  rf_raddr_a,
    output wire [31:0] rf_rdata_a,
    input wire  [4:0]  rf_raddr_b,
    output wire [31:0] rf_rdata_b,

    input wire  [4:0]  rf_waddr,
    input wire  [31:0] rf_wdata,

    input wire  rf_wen,

    output reg just_w,
    output reg [31:0] last_w_data,
    output reg [4:0] last_w_addr
);
    
    reg [31:0] allregs [31:0];
    
    // ������������߼�?
    assign rf_rdata_a = allregs[rf_raddr_a];
    assign rf_rdata_b = allregs[rf_raddr_b];
    
    // д����������߼�?
    always_ff @(posedge clk) begin
        if (reset) begin
            allregs[0] <= 32'd0;
//            just_w <= 0;
//            last_w_data <= 0;
//            last_w_addr <= 0;
        end else begin
            if (rf_wen && rf_waddr != 0) begin
                last_w_data <= rf_wdata;
                last_w_addr <= rf_waddr;
                allregs[rf_waddr] <= rf_wdata;
                if (rf_wdata != last_w_data || rf_waddr != last_w_addr) begin
                    just_w <= 1;
                end else begin
                    just_w <= 0;
                end
            end else begin
                just_w <= 0;
            end
        end
    end
endmodule
