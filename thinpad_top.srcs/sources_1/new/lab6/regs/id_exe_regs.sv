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
      
    input wire [2:0] wb_sel_i,
    output reg [2:0] wb_sel_o,
      
    input wire [3:0] dm_sel_i,
    output reg [3:0] dm_sel_o,
    input wire [1:0] dm_op_i,
    output reg [1:0] dm_op_o,

    // exception signals
    input wire id_mtvec_we,
    input wire id_mscratch_we,
    input wire id_mepc_we,
    input wire id_mcause_we,
    input wire id_mstatus_we,
    input wire id_mie_we,
    input wire id_mip_we,
    input wire id_priv_we,

    output reg ex_mtvec_we,
    output reg ex_mscratch_we,
    output reg ex_mepc_we,
    output reg ex_mcause_we,
    output reg ex_mstatus_we,
    output reg ex_mie_we,
    output reg ex_mip_we,
    output reg ex_priv_we,

    input wire [31:0] id_mtvec_data,
    input wire [31:0] id_mscratch_data,
    input wire [31:0] id_mepc_data,
    input wire [31:0] id_mcause_data,
    input wire [31:0] id_mstatus_data,
    input wire [31:0] id_mie_data,
    input wire [31:0] id_mip_data,
    input wire [1:0] id_priv_data,

    output reg [31:0] ex_mtvec_data,
    output reg [31:0] ex_mscratch_data,
    output reg [31:0] ex_mepc_data,
    output reg [31:0] ex_mcause_data,
    output reg [31:0] ex_mstatus_data,
    output reg [31:0] ex_mie_data,
    output reg [31:0] ex_mip_data,
    output reg [1:0] ex_priv_data,

    input wire [31:0] id_direct_branch_addr,
    input wire [3:0] id_csr_code,
    output reg [31:0] ex_direct_branch_addr,
    output reg [3:0] ex_csr_code
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

                ex_mtvec_we <= 0;
                ex_mscratch_we <= 0;
                ex_mepc_we <= 0;
                ex_mcause_we <= 0;
                ex_mstatus_we <= 0;
                ex_mie_we <= 0;
                ex_mip_we <= 0;
                ex_priv_we <= 0;

                ex_mtvec_data <= 0;
                ex_mscratch_data <= 0;
                ex_mepc_data <= 0;
                ex_mcause_data <= 0;
                ex_mstatus_data <= 0;
                ex_mie_data <= 0;
                ex_mip_data <= 0;
                ex_priv_data <= 0;

                ex_csr_code <= 0;
                ex_direct_branch_addr <= 0;

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

                ex_mtvec_data <= id_mtvec_data;
                ex_mscratch_data <= id_mscratch_data;
                ex_mepc_data <= id_mepc_data;
                ex_mcause_data <= id_mcause_data;
                ex_mstatus_data <= id_mstatus_data;
                ex_mie_data <= id_mie_data;
                ex_mip_data <= id_mip_data;
                ex_priv_data <= id_priv_data;

                ex_mtvec_we <= id_mtvec_we;
                ex_mscratch_we <= id_mscratch_we;
                ex_mepc_we <= id_mepc_we;
                ex_mcause_we <= id_mcause_we;
                ex_mstatus_we <= id_mstatus_we;
                ex_mie_we <= id_mie_we;
                ex_mip_we <= id_mip_we;
                ex_priv_we <= id_priv_we;

                ex_csr_code <= id_csr_code;
                ex_direct_branch_addr <= id_direct_branch_addr;

            end
        end
    end
endmodule