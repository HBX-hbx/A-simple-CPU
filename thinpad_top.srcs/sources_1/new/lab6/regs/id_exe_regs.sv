`define NOP 32'b0000000_00000_00000_000_00000_0110_011
module id_exe_regs(
    input wire clk,
    input wire reset,
    input wire id_exe_regs_hold_i,
    input wire id_exe_regs_bubble_i,
      
    input wire [31:0] pc_i,
    output reg [31:0] pc_o,
    input wire [31:0] inst_i,
    output reg [31:0] inst_o,
      
    input wire [4:0] rd_addr_i,
    output reg [4:0] rd_addr_o,
    input wire [4:0] rs1_addr_i,
    output reg [4:0] rs1_addr_o,
    input wire [4:0] rs2_addr_i,
    output reg [4:0] rs2_addr_o,
      
    input wire [31:0] rs1_data_i,
    output reg [31:0] rs1_data_o,
    input wire [31:0] rs2_data_i,
    output reg [31:0] rs2_data_o,
      
    input wire [2:0] imm_sel_i,
    output reg [2:0] imm_sel_o,
    input wire alu_a_sel_i,
    output reg alu_a_sel_o,
    input wire alu_b_sel_i,
    output reg alu_b_sel_o,
    input wire [3:0] alu_op_i,
    output reg [3:0] alu_op_o,
      
    input wire [4:0] shamt_i,
    output reg [4:0] shamt_o,
      
    input wire [3:0] br_op_i,
    output reg [3:0] br_op_o,
      
    input wire rf_wen_i,
    output reg rf_wen_o,
      
    input wire [1:0] wb_sel_i,
    output reg [1:0] wb_sel_o,
      
    input wire [3:0] dm_sel_i,
    output reg [3:0] dm_sel_o,
    input wire [1:0] dm_op_i,
    output reg [1:0] dm_op_o
);
    always_ff @ (posedge clk) begin
        if (reset) begin

        end else begin
            if (id_exe_regs_hold_i) begin
            
            end else if (id_exe_regs_bubble_i) begin
                pc_o <= 0;
                inst_o <= `NOP;
                rd_addr_o <= 0;
                rs1_addr_o <= 0;
                rs2_addr_o <= 0;
                rs1_data_o <= 0;
                rs2_data_o <= 0;
                imm_sel_o <= 0;
                alu_a_sel_o <= 1;
                alu_b_sel_o <= 1;
                alu_op_o <= 1; // ADD0 and 0 in NOP
                shamt_o <= 0;
                br_op_o <= 2; // 2 means doing nothing
                rf_wen_o <= 0; // don't really need to write
                wb_sel_o <= 0;
                dm_sel_o <= 0;
                dm_op_o <= 0;
            end else begin
                pc_o <= pc_i;
                inst_o <= inst_i;
                rd_addr_o <= rd_addr_i;
                rs1_addr_o <= rs1_addr_i;
                rs2_addr_o <= rs2_addr_i;
                rs1_data_o <= rs1_data_i;
                rs2_data_o <= rs2_data_i;
                imm_sel_o <= imm_sel_i;
                alu_a_sel_o <= alu_a_sel_i;
                alu_b_sel_o <= alu_b_sel_i;
                alu_op_o <= alu_op_i;
                shamt_o <= shamt_i;
                br_op_o <= br_op_i;
                rf_wen_o <= rf_wen_i;
                wb_sel_o <= wb_sel_i;
                dm_sel_o <= dm_sel_i;
                dm_op_o <= dm_op_i;
            end
        end
    end
endmodule