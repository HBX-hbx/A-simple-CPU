`timescale 1ns / 1ps

module ALU(
    input wire  [31:0] alu_a,
    input wire  [31:0] alu_b,
    input wire  [ 3:0] alu_op,
    output reg  [31:0] alu_y
    );

    always_comb begin
        if (alu_op == 4'd1) begin
          alu_y = (alu_a + alu_b);
        end else if (alu_op == 4'd2) begin
          alu_y = (alu_a - alu_b);
        end else if (alu_op == 4'd3) begin
          alu_y = (alu_a & alu_b);
        end else if (alu_op == 4'd4) begin
          alu_y = (alu_a | alu_b);
        end else if (alu_op == 4'd5) begin
          alu_y = (alu_a ^ alu_b);
        end else if (alu_op == 4'd6) begin
          alu_y = (~ alu_a);
        end else if (alu_op == 4'd7) begin
          alu_y = alu_a << (alu_b & 32'h1F);
        end else if (alu_op == 4'd8) begin
          alu_y = alu_a >> (alu_b & 32'h1F);
        end else if (alu_op == 4'd9) begin
          if ((32'h80000000 & alu_a) == 32'h80000000)
            alu_y = (alu_a >> (alu_b & 32'h1F)) | (36'h100000000 - (36'h100000000 >> (alu_b & 32'h1F)));
          else
            alu_y = (alu_a >> (alu_b & 32'h1F));
        end else if (alu_op == 4'd10) begin
          alu_y = (alu_a << (alu_b & 32'hF)) | (alu_a >> (32 - (alu_b & 32'hF)));
        end else if (alu_op == 4'd11) begin
          alu_y = alu_b;
        // ALU especially for JALR
        end else if (alu_op == 4'd12) begin
          alu_y = (alu_a + alu_b) & 32'hFFFFFFFE;
        end else begin
          alu_y = 0;
        end
    end
    
endmodule
