`define NOP 32'b0000000_00000_00000_000_00000_0110_011
module exe_mem_regs(
    input wire clk,
    input wire reset,
    input wire exe_mem_regs_hold_i,
    input wire exe_mem_regs_bubble_i,
      
    input wire [31:0] pc_i,
    output reg [31:0] pc_o,
    input wire [31:0] inst_i,
    output reg [31:0] inst_o,
      
    input wire [31:0] alu_y_i,
    output reg [31:0] alu_y_o,
      
    input wire [31:0] rs2_data_i,
    output reg [31:0] rs2_data_o,
    input wire [4:0] rd_addr_i,
    output reg [4:0] rd_addr_o,
      
    input wire [3:0] dm_sel_i,
    output reg [3:0] dm_sel_o,
    input wire [1:0] dm_op_i,
    output reg [1:0] dm_op_o,
      
    input wire rf_wen_i,
    output reg rf_wen_o,
      
    input wire [1:0] wb_sel_i,
    output reg [1:0] wb_sel_o
);
    always_ff @ (posedge clk) begin
        if (reset) begin

        end else begin
            if (exe_mem_regs_hold_i) begin
            
            end else if (exe_mem_regs_bubble_i) begin
                pc_o <= 0;
                inst_o <= `NOP;
                rd_addr_o <= 0;
                rs2_data_o <= 0;
                alu_y_o <= 0;
                rf_wen_o <= 0;
                wb_sel_o <= 0;
                dm_sel_o <= 0;
                dm_op_o <= 0;
            end else begin
                pc_o <= pc_i;
                inst_o <= inst_i;
                rd_addr_o <= rd_addr_i;
                rs2_data_o <= rs2_data_i;
                alu_y_o <= alu_y_i;
                rf_wen_o <= rf_wen_i;
                wb_sel_o <= wb_sel_i;
                dm_sel_o <= dm_sel_i;
                dm_op_o <= dm_op_i;
            end
        end
    end
endmodule