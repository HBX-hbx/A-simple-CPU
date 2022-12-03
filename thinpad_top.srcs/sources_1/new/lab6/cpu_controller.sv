module cpu_controller(
    output logic [1:0] pc_sel_o,
    output logic pc_hold_o,
      
    input wire if_ack_i,
      
    output logic if_id_regs_hold_o,
    output logic if_id_regs_bubble_o,
      
    input wire [31:0] id_inst_i,
    input wire [4:0] id_rs1_i,
    input wire [4:0] id_rs2_i,
      
    output logic id_exe_regs_hold_o,
    output logic id_exe_regs_bubble_o,
    
    input wire [31:0] exe_inst_i,
    input wire [3:0] exe_br_op_i,
    input wire exe_if_br_i,
    input wire [4:0] exe_rd_i,
    input wire exe_rf_wen_i,
      
    output logic exe_mem_regs_hold_o,
    output logic exe_mem_regs_bubble_o,
      
    input wire [4:0] mem_rd_i,
    input wire mem_rf_wen_i,
    input wire mem_data_access_ack_i,
    input wire [1:0] mem_dm_op_i,
    input wire [1:0] mem_page_fault_code_i,
      
    output logic mem_wb_regs_hold_o,
    output logic mem_wb_regs_bubble_o,
      
    input wire [4:0] wb_rd_addr_i,
    input wire wb_rf_wen_i,

    input wire [3:0] csr_code_i,
    input wire predict_fault_i,

    output logic hold_all_o,

    input logic id_fence_i,
    input logic exe_fence_i,
    input logic mem_fence_i
);
    
    reg if_br;
    assign if_br = (exe_if_br_i === 1) && (exe_br_op_i !== 1'bX) && (exe_br_op_i !== 1'bZ) && (exe_br_op_i !== 2);
    
    reg hold_all;
    assign hold_all = (mem_data_access_ack_i !== 1) || (if_ack_i !== 1);
    assign hold_all_o = hold_all;
    
    always_comb begin
        if (hold_all) begin
            pc_sel_o = 1;
            pc_hold_o = 1;
            if_id_regs_hold_o = 1;
            id_exe_regs_hold_o = 1;
            exe_mem_regs_hold_o = 1;
            mem_wb_regs_hold_o = 1;
            if_id_regs_bubble_o = 0;
            id_exe_regs_bubble_o = 0;
            exe_mem_regs_bubble_o = 0;
            mem_wb_regs_bubble_o = 0;
        end else begin
            // if (if_br) begin
            if (mem_page_fault_code_i != 2'b00) begin // mem page fault first
                pc_hold_o = 0;
                pc_sel_o = 1;
                if_id_regs_hold_o = 0;
                id_exe_regs_hold_o = 0;
                exe_mem_regs_hold_o = 0;
                mem_wb_regs_hold_o = 0;
                if_id_regs_bubble_o = 0;
                id_exe_regs_bubble_o = 0;
                exe_mem_regs_bubble_o = 1;
                mem_wb_regs_bubble_o = 1;
            end else if (predict_fault_i) begin
                // page fault should bubble exe_mem
                if (csr_code_i == 14) begin
                    pc_hold_o = 0;
                    pc_sel_o = 3; // branch select direct branch addr from csr!
                    if_id_regs_hold_o = 0;
                    id_exe_regs_hold_o = 0;
                    exe_mem_regs_hold_o = 0;
                    mem_wb_regs_hold_o = 0;
                    if_id_regs_bubble_o = 1;
                    id_exe_regs_bubble_o = 1;
                    exe_mem_regs_bubble_o = 1;
                    mem_wb_regs_bubble_o = 0;
                end else if (csr_code_i != 0 && csr_code_i != 14) begin // if it is CSR
                    pc_hold_o = 0;
                    pc_sel_o = 3; // branch select direct branch addr from csr!
                    if_id_regs_hold_o = 0;
                    id_exe_regs_hold_o = 0;
                    exe_mem_regs_hold_o = 0;
                    mem_wb_regs_hold_o = 0;
                    if_id_regs_bubble_o = 1;
                    id_exe_regs_bubble_o = 1;
                    exe_mem_regs_bubble_o = 0;
                    mem_wb_regs_bubble_o = 0;
                // if it is JALR
                end else if (exe_inst_i[14:12] == 3'b000 && exe_inst_i[6:0] == 7'b1100111) begin
                    pc_hold_o = 0;
                    pc_sel_o = 2; // branch select only alu_y!
                    if_id_regs_hold_o = 0;
                    id_exe_regs_hold_o = 0;
                    exe_mem_regs_hold_o = 0;
                    mem_wb_regs_hold_o = 0;
                    if_id_regs_bubble_o = 1;
                    id_exe_regs_bubble_o = 1;
                    exe_mem_regs_bubble_o = 0;
                    mem_wb_regs_bubble_o = 0;
                end else begin
                    pc_hold_o = 0;
                    pc_sel_o = 0;
                    if_id_regs_hold_o = 0;
                    id_exe_regs_hold_o = 0;
                    exe_mem_regs_hold_o = 0;
                    mem_wb_regs_hold_o = 0;
                    if_id_regs_bubble_o = 1;
                    id_exe_regs_bubble_o = 1;
                    exe_mem_regs_bubble_o = 0;
                    mem_wb_regs_bubble_o = 0;
                end
            end else if (id_fence_i | exe_fence_i | mem_fence_i) begin
                pc_hold_o = 1;
                pc_sel_o = 0;
                if_id_regs_hold_o = 0;
                id_exe_regs_hold_o = 0;
                exe_mem_regs_hold_o = 0;
                mem_wb_regs_hold_o = 0;
                if_id_regs_bubble_o = 1;
                id_exe_regs_bubble_o = 0;
                exe_mem_regs_bubble_o = 0;
                mem_wb_regs_bubble_o = 0;
            end else begin
                pc_hold_o = 0;
                pc_sel_o = 1;
                if_id_regs_hold_o = 0;
                id_exe_regs_hold_o = 0;
                exe_mem_regs_hold_o = 0;
                mem_wb_regs_hold_o = 0;
                if_id_regs_bubble_o = 0;
                id_exe_regs_bubble_o = 0;
                exe_mem_regs_bubble_o = 0;
                mem_wb_regs_bubble_o = 0;
            end
        end
    end
    
endmodule