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

    // 连接寄存器堆模块的信号
    output wire [4:0]  rf_raddr_a,
    input  wire [15:0] rf_rdata_a,
    output wire [4:0]  rf_raddr_b,
    input  wire [15:0] rf_rdata_b,
    output wire [4:0]  rf_waddr,
    output wire [15:0] rf_wdata,
    output reg  rf_wen,

    // 连接 ALU 模块的信号
    output reg  [15:0] alu_a,
    output reg  [15:0] alu_b,
    output reg  [ 3:0] alu_op,
    input  wire [15:0] alu_y,

    // 控制信号
    input  wire        step,    // 用户按键状态脉冲
    input  wire [31:0] dip_sw,  // 32 位拨码开关状态
    output reg  [15:0] leds
);
  reg [15:0] out;
  logic [31:0] inst_reg;  // 指令寄存器

  // 组合逻辑，解析指令中的常用部分，依赖于有效的 inst_reg 值
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
  
  // 多用组合逻辑
  assign rf_raddr_a = is_rtype ? rs1 : rd;
  assign rf_raddr_b = rs2;
  assign rf_wdata = out;
  assign rf_waddr = rd;

  // 使用枚举定义状态列表，数据类型为 logic [3:0]
  typedef enum logic [3:0] {
      ST_INIT,
      ST_DECODE,
      ST_CALC,
      ST_READ_REG,
      ST_WRITE_REG
  } state_t;
  
  // 状态机当前状态寄存器
  state_t state;

  // 状态机逻辑
  always_ff @(posedge clk) begin
      if (reset) begin
          // TODO: 复位各个输出信号
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
                // 把寄存器地址交给寄存器堆，读取操作数
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
                // 未知指令，回到初始状态
                state <= ST_INIT;
            end
        end

        ST_CALC: begin
            // TODO: 将数据交给 ALU，并从 ALU 获取结果
            out <= alu_y;
            if (rd != 0) begin
                rf_wen <= 1'b1;
                state <= ST_WRITE_REG;
            end else begin
                state <= ST_INIT;
            end
        end

        ST_WRITE_REG: begin
            // TODO: 这个周期时会进行写入！
            rf_wen <= 1'b0;
            state <= ST_INIT;
        end

        ST_READ_REG: begin
            // TODO: 这个周期中会进行读取
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
