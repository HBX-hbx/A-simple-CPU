`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/19 20:01:29
// Design Name: 
// Module Name: gettrigger
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


module gettrigger(
    input wire clk,
    input wire push_btn,
    output wire outtrigger
    );
    reg out;
    reg last_cond;
    always_ff @ (posedge clk) begin
            if (push_btn) begin
                if (last_cond == 1'd0) begin
                    last_cond <= 1'd1;
                    out <= 1'd1;
                end
                else begin
                    last_cond <= 1'd1;
                    out <= 1'd0;
                end 
            end
            else begin
                last_cond <= 1'd0;
                out <= 1'd0;
            end
    end
    assign outtrigger = out;
endmodule
