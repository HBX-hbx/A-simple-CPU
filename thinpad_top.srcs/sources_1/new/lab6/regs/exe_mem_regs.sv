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
      
    input wire [2:0] wb_sel_i,
    output reg [2:0] wb_sel_o,

    // Data In
    input wire [31:0] mtvec_in,
    input wire [31:0] mscratch_in,
    input wire [31:0] mepc_in,
    input wire [31:0] mcause_in,
    input wire [31:0] mstatus_in,
    input wire [31:0] mie_in,
    input wire [31:0] mip_in,
    input wire [1:0] priv_in,

    input wire [31:0] satp_in,
    input wire [31:0] mtval_in,
    input wire [31:0] mideleg_in,
    input wire [31:0] medeleg_in,
    input wire [31:0] sepc_in,
    input wire [31:0] scause_in,
    input wire [31:0] stval_in,
    input wire [31:0] stvec_in,
    input wire [31:0] sscratch_in,

    // WE in signals
    input wire mtvec_we_in,
    input wire mscratch_we_in,
    input wire mepc_we_in,
    input wire mcause_we_in,
    input wire mstatus_we_in,
    input wire mie_we_in,
    input wire mip_we_in,
    input wire priv_we_in,

    input wire satp_we_in,
    input wire mtval_we_in,
    input wire mideleg_we_in,
    input wire medeleg_we_in,
    input wire sepc_we_in,
    input wire scause_we_in,
    input wire stval_we_in,
    input wire stvec_we_in,
    input wire sscratch_we_in,
      
    // Data out signals
    output logic [31:0] mtvec_out,
    output logic [31:0] mscratch_out,
    output logic [31:0] mepc_out,
    output logic [31:0] mcause_out,
    output logic [31:0] mstatus_out,
    output logic [31:0] mie_out,
    output logic [31:0] mip_out,
    output logic [1:0] priv_out,

    output logic [31:0] satp_out,
    output logic [31:0] mtval_out,
    output logic [31:0] mideleg_out,
    output logic [31:0] medeleg_out,
    output logic [31:0] sepc_out,
    output logic [31:0] scause_out,
    output logic [31:0] stval_out,
    output logic [31:0] stvec_out,
    output logic [31:0] sscratch_out,
      
    // WE output signals
    output logic mtvec_we_out,
    output logic mscratch_we_out,
    output logic mepc_we_out,
    output logic mcause_we_out,
    output logic mstatus_we_out,
    output logic mie_we_out,
    output logic mip_we_out,
    output logic priv_we_out,

    output logic satp_we_out,
    output logic mtval_we_out,
    output logic mideleg_we_out,
    output logic medeleg_we_out,
    output logic sepc_we_out,
    output logic scause_we_out,
    output logic stval_we_out,
    output logic stvec_we_out,
    output logic sscratch_we_out,

    // Other Signals
    input wire [31:0] csr_data_i,
    output reg [31:0] csr_data_o
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

                mtvec_out <= 0;
                mscratch_out <= 0;
                mepc_out <= 0;
                mcause_out <= 0;
                mstatus_out <= 0;
                mie_out <= 0;
                mip_out <= 0;
                priv_out <= 0;

                satp_out <= 0;
                mtval_out <= 0;
                mideleg_out <= 0;
                medeleg_out <= 0;
                sepc_out <= 0;
                scause_out <= 0;
                stval_out <= 0;
                stvec_out <= 0;
                sscratch_out <= 0;
                
                mtvec_we_out <= 0;
                mscratch_we_out <= 0;
                mepc_we_out <= 0;
                mcause_we_out <= 0;
                mstatus_we_out <= 0;
                mie_we_out <= 0;
                mip_we_out <= 0;
                priv_we_out <= 0;

                satp_we_out <= 0;
                mtval_we_out <= 0;
                mideleg_we_out <= 0;
                medeleg_we_out <= 0;
                sepc_we_out <= 0;
                scause_we_out <= 0;
                stval_we_out <= 0;
                stvec_we_out <= 0;
                sscratch_we_out <= 0;
                
                csr_data_o <= 0;
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

                mtvec_out <= mtvec_in;
                mscratch_out <= mscratch_in;
                mepc_out <= mepc_in;
                mcause_out <= mcause_in;
                mstatus_out <= mstatus_in;
                mie_out <= mie_in;
                mip_out <= mip_in;
                priv_out <= priv_in;

                satp_out <= satp_in;
                mtval_out <= mtval_in;
                mideleg_out <= mideleg_in;
                medeleg_out <= medeleg_in;
                sepc_out <= sepc_in;
                scause_out <= scause_in;
                stval_out <= stval_in;
                stvec_out <= stvec_in;
                sscratch_out <= sscratch_in;
                
                mtvec_we_out <= mtvec_we_in;
                mscratch_we_out <= mscratch_we_in;
                mepc_we_out <= mepc_we_in;
                mcause_we_out <= mcause_we_in;
                mstatus_we_out <= mstatus_we_in;
                mie_we_out <= mie_we_in;
                mip_we_out <= mip_we_in;
                priv_we_out <= priv_we_in;

                satp_we_out <= satp_we_in;
                mtval_we_out <= mtval_we_in;
                mideleg_we_out <= mideleg_we_in;
                medeleg_we_out <= medeleg_we_in;
                sepc_we_out <= sepc_we_in;
                scause_we_out <= scause_we_in;
                stval_we_out <= stval_we_in;
                stvec_we_out <= stvec_we_in;
                sscratch_we_out <= sscratch_we_in;

                csr_data_o <= csr_data_i;
            end
        end
    end
endmodule