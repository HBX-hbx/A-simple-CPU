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
            alu_y = (alu_a >> (alu_b & 32'hF)) | (36'h100000000 - (36'h100000000 >> (alu_b & 32'h1F)));
          else
            alu_y = (alu_a >> (alu_b & 32'hF));
        // ʵ��ѭ�����ƣ�start_loop��mode��������
        end else if (alu_op == 4'd10) begin
          alu_y = (alu_a << (alu_b & 32'hF)) | (alu_a >> (32 - (alu_b & 32'hF)));
        // ����ֱ����� imm
        end else if (alu_op == 4'd11) begin
          alu_y = alu_b;
        // ALU especially for JALR
        end else if (alu_op == 4'd12) begin
          alu_y = (alu_a + alu_b) & 32'hFFFFFFFE;
        // XPERM8
        end else if (alu_op == 4'd13) begin
          case (alu_b[31:24])
            8'd0: begin
              alu_y[31:24] = alu_a[7:0];
            end
            8'd1: begin
              alu_y[31:24] = alu_a[15:8];
            end
            8'd2: begin
              alu_y[31:24] = alu_a[23:16];
            end
            8'd3: begin
              alu_y[31:24] = alu_a[31:24];
            end
            default: begin
              alu_y[31:24] = 8'd0;
            end
          endcase

          case (alu_b[23:16])
            8'd0: begin
              alu_y[23:16] = alu_a[7:0];
            end
            8'd1: begin
              alu_y[23:16] = alu_a[15:8];
            end
            8'd2: begin
              alu_y[23:16] = alu_a[23:16];
            end
            8'd3: begin
              alu_y[23:16] = alu_a[31:24];
            end
            default: begin
              alu_y[23:16] = 8'd0;
            end
          endcase

          case (alu_b[15:8])
            8'd0: begin
              alu_y[15:8] = alu_a[7:0];
            end
            8'd1: begin
              alu_y[15:8] = alu_a[15:8];
            end
            8'd2: begin
              alu_y[15:8] = alu_a[23:16];
            end
            8'd3: begin
              alu_y[15:8] = alu_a[31:24];
            end
            default: begin
              alu_y[15:8] = 8'd0;
            end
          endcase

          case (alu_b[7:0])
            8'd0: begin
              alu_y[7:0] = alu_a[7:0];
            end
            8'd1: begin
              alu_y[7:0] = alu_a[15:8];
            end
            8'd2: begin
              alu_y[7:0] = alu_a[23:16];
            end
            8'd3: begin
              alu_y[7:0] = alu_a[31:24];
            end
            default: begin
              alu_y[7:0] = 8'd0;
            end
          endcase
        end else begin
          alu_y = 0;
        end
    end
    
endmodule
