`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/20 10:08:17
// Design Name: 
// Module Name: controller
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


module controller (
    input wire clk,
    input wire reset,

    // ���ӼĴ�����ģ����ź�
    output wire [4:0]  rf_raddr_a,
    input  wire [15:0] rf_rdata_a,
    output wire [4:0]  rf_raddr_b,
    input  wire [15:0] rf_rdata_b,
    output wire [4:0]  rf_waddr,
    output wire [15:0] rf_wdata,
    output reg  rf_wen,

    // ���� ALU ģ����ź�
    output reg  [15:0] alu_a,
    output reg  [15:0] alu_b,
    output reg  [ 3:0] alu_op,
    input  wire [15:0] alu_y,

    // �����ź�
    input  wire        step,    // �û�����״̬����
    input  wire [31:0] dip_sw,  // 32 λ���뿪��״̬
    output reg  [15:0] leds
);
  reg [15:0] out;
  logic [31:0] inst_reg;  // ָ��Ĵ���

  // ����߼�������ָ���еĳ��ò��֣���������Ч�� inst_reg ֵ
  logic is_rtype, is_itype, is_peek, is_poke;
  logic [15:0] imm;
  logic [4:0] rd, rs1, rs2;
  logic [3:0] opcode;
  
  always_comb begin
      is_rtype = (inst_reg[2:0] == 3'b001);
      is_itype = (inst_reg[2:0] == 3'b010);
      is_peek = is_itype && (inst_reg[6:3] == 4'b0010);
      is_poke = is_itype && (inst_reg[6:3] == 4'b0001);

      imm = inst_reg[31:16];
      rd = inst_reg[11:7];
      rs1 = inst_reg[19:15];
      rs2 = inst_reg[24:20];
      opcode = inst_reg[6:3];    
  end
  
  // ��������߼�
  assign rf_raddr_a = is_rtype ? rs1 : rd;
  assign rf_raddr_b = rs2;
  assign rf_wdata = out;
  assign rf_waddr = rd;

  // ʹ��ö�ٶ���״̬�б���������Ϊ logic [3:0]
  typedef enum logic [3:0] {
      ST_INIT,
      ST_DECODE,
      ST_CALC,
      ST_READ_REG,
      ST_WRITE_REG
  } state_t;
  
  // ״̬����ǰ״̬�Ĵ���
  state_t state;

  // ״̬���߼�
  always_ff @(posedge clk) begin
      if (reset) begin
          // TODO: ��λ��������ź�
          state <= ST_INIT;
          rf_wen <= 1'd0;
          alu_a <= 16'd0;
          alu_b <= 16'd0;
          alu_op <= 4'd0;
          leds <= 16'd0;
          out <= 16'd0;
      end else begin
      case (state)
        ST_INIT: begin
            rf_wen <= 1'b0;
            if (step) begin
                inst_reg <= dip_sw;
                state <= ST_DECODE;
            end
        end

        ST_DECODE: begin
            if (is_rtype) begin
                // �ѼĴ�����ַ�����Ĵ����ѣ���ȡ������
                alu_a <= rf_rdata_a;
                alu_b <= rf_rdata_b;
                alu_op <= opcode;
                state <= ST_CALC;
            end else if (is_peek) begin
                state <= ST_READ_REG;
            end else if (is_poke) begin
                if (rd != 0) begin
                    out <= imm;
                    rf_wen <= 1'b1;
                    state <= ST_WRITE_REG;
                end else begin
                    state <= ST_INIT;
                end
            end else begin
                // δָ֪��ص���ʼ״̬
                state <= ST_INIT;
            end
        end

        ST_CALC: begin
            // TODO: �����ݽ��� ALU������ ALU ��ȡ���
            out <= alu_y;
            if (rd != 0) begin
                rf_wen <= 1'b1;
                state <= ST_WRITE_REG;
            end else begin
                state <= ST_INIT;
            end
        end

        ST_WRITE_REG: begin
            // TODO: �������ʱ�����д�룡
            rf_wen <= 1'b0;
            state <= ST_INIT;
        end

        ST_READ_REG: begin
            // TODO: ��������л���ж�ȡ
            leds <= rf_rdata_a;
            state <= ST_INIT;
        end

        default: begin
            state <= ST_INIT;
        end
      endcase
    end
  end
endmodule
