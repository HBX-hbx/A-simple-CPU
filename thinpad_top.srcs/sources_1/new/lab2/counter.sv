`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/19 19:48:53
// Design Name: 
// Module Name: counter
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


module counter(
    input wire clk,
    input wire reset,
    input wire trigger,
    output wire[3:0] count
    );
    reg [3:0] count_reg;
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            count_reg <= 4'd0;
        end else begin
            if (trigger) begin
                if (count_reg < 4'd15)
                    count_reg <= count_reg + 4'd1;
            end
        end
    end
    assign count = count_reg;
endmodule
