module id_excep_handler (
    // Input signals from ID stage
    input wire [31:0] inst_i,
    output wire time_int_o,

    // Data in from CSR
    input wire [31:0] csr_mtvec_in,
    input wire [31:0] csr_mscratch_in,
    input wire [31:0] csr_mepc_in,
    input wire [31:0] csr_mcause_in,
    input wire [31:0] csr_mstatus_in,
    input wire [31:0] csr_mie_in,
    input wire [31:0] csr_mip_in,
    input wire [1:0] csr_priv_in,

    input wire [31:0] csr_satp_in,
    input wire [31:0] csr_mtval_in,
    input wire [31:0] csr_mideleg_in,
    input wire [31:0] csr_medeleg_in,
    input wire [31:0] csr_sepc_in,
    input wire [31:0] csr_scause_in,
    input wire [31:0] csr_stval_in,
    input wire [31:0] csr_stvec_in,
    input wire [31:0] csr_sscratch_in,

    input wire [31:0] csr_sstatus_in,
    input wire [31:0] csr_mhartid_in,
    input wire [31:0] csr_sie_in,
    input wire [31:0] csr_sip_in,

    // Data in from EXE
    input wire [31:0] exe_mtvec_in,
    input wire [31:0] exe_mscratch_in,
    input wire [31:0] exe_mepc_in,
    input wire [31:0] exe_mcause_in,
    input wire [31:0] exe_mstatus_in,
    input wire [31:0] exe_mie_in,
    input wire [31:0] exe_mip_in,
    input wire [1:0] exe_priv_in,

    input wire [31:0] exe_satp_in,
    input wire [31:0] exe_mtval_in,
    input wire [31:0] exe_mideleg_in,
    input wire [31:0] exe_medeleg_in,
    input wire [31:0] exe_sepc_in,
    input wire [31:0] exe_scause_in,
    input wire [31:0] exe_stval_in,
    input wire [31:0] exe_stvec_in,
    input wire [31:0] exe_sscratch_in,

    input wire [31:0] exe_sstatus_in,
    input wire [31:0] exe_mhartid_in,
    input wire [31:0] exe_sie_in,
    input wire [31:0] exe_sip_in,

    // WE in from EXE
    input wire exe_mtvec_we_in,
    input wire exe_mscratch_we_in,
    input wire exe_mepc_we_in,
    input wire exe_mcause_we_in,
    input wire exe_mstatus_we_in,
    input wire exe_mie_we_in,
    input wire exe_mip_we_in,
    input wire exe_priv_we_in,

    input wire exe_satp_we_in,
    input wire exe_mtval_we_in,
    input wire exe_mideleg_we_in,
    input wire exe_medeleg_we_in,
    input wire exe_sepc_we_in,
    input wire exe_scause_we_in,
    input wire exe_stval_we_in,
    input wire exe_stvec_we_in,
    input wire exe_sscratch_we_in,

    input wire exe_sstatus_we_in,
    input wire exe_mhartid_we_in,
    input wire exe_sie_we_in,
    input wire exe_sip_we_in,

    // All belows are from IF
    // Data in signals
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

    input wire [31:0] sstatus_in,
    input wire [31:0] mhartid_in,
    input wire [31:0] sie_in,
    input wire [31:0] sip_in,
      
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

    output logic [31:0] sstatus_out,
    output logic [31:0] mhartid_out,
    output logic [31:0] sie_out,
    output logic [31:0] sip_out,

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

    input wire sstatus_we_in,
    input wire mhartid_we_in,
    input wire sie_we_in,
    input wire sip_we_in,
     
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

    output logic sstatus_we_out,
    output logic mhartid_we_out,
    output logic sie_we_out,
    output logic sip_we_out,

    // Other signals
    input wire [1:0] if_page_fault_code_i, // 从 if_id_reg 而来
    input wire [1:0] mem_page_fault_code_i,
    output logic [31:0] direct_branch_addr,
    output logic [3:0] csr_code
);  

    // Deal with how the output data
    always_comb begin
        // Default set to data from CSR
        mtvec_out = csr_mtvec_in;
        mscratch_out = csr_mscratch_in;
        mepc_out = csr_mepc_in;
        mcause_out = csr_mcause_in;
        mstatus_out = csr_mstatus_in;
        mie_out = csr_mie_in;
        mip_out = csr_mip_in;
        priv_out = csr_priv_in;
        satp_out = csr_satp_in;
        mtval_out = csr_mtval_in;
        mideleg_out = csr_mideleg_in;
        medeleg_out = csr_medeleg_in;
        sepc_out = csr_sepc_in;
        scause_out = csr_scause_in;
        stval_out = csr_stval_in;
        stvec_out = csr_stvec_in;
        sscratch_out = csr_sscratch_in;

        sstatus_out = csr_sstatus_in;
        mhartid_out = csr_mhartid_in;
        sie_out = csr_sie_in;
        sip_out = csr_sip_in;

        // Set to data from EXE if EXE is writing
        if (exe_mtvec_we_in) begin
            mtvec_out = exe_mtvec_in;
        end else if (mtvec_we_in) begin
            mtvec_out = mtvec_in;
        end
        if (exe_mscratch_we_in) begin
            mscratch_out = exe_mscratch_in;
        end else if (mscratch_we_in) begin
            mscratch_out = mscratch_in;
        end
        if (exe_mepc_we_in) begin
            mepc_out = exe_mepc_in;
        end else if (mepc_we_in) begin
            mepc_out = mepc_in;
        end
        if (exe_mcause_we_in) begin
            mcause_out = exe_mcause_in;
        end else if (mcause_we_in) begin
            mcause_out = mcause_in;
        end
        if (exe_mstatus_we_in) begin
            mstatus_out = exe_mstatus_in;
        end else if (mstatus_we_in) begin
            mstatus_out = mstatus_in;
        end
        if (exe_mie_we_in) begin
            mie_out = exe_mie_in;
        end else if (mie_we_in) begin
            mie_out = mie_in;
        end
        if (exe_mip_we_in) begin
            mip_out = exe_mip_in;
        end else if (mip_we_in) begin
            mip_out = mip_in;
        end
        if (exe_priv_we_in) begin
            priv_out = exe_priv_in;
        end else if (priv_we_in) begin
            priv_out = priv_in;
        end
        if (exe_satp_we_in) begin
            satp_out = exe_satp_in;
        end else if (satp_we_in) begin
            satp_out = satp_in;
        end
        if (exe_mtval_we_in) begin
            mtval_out = exe_mtval_in;
        end else if (mtval_we_in) begin
            mtval_out = mtval_in;
        end
        if (exe_mideleg_we_in) begin
            mideleg_out = exe_mideleg_in;
        end else if (mideleg_we_in) begin
            mideleg_out = mideleg_in;
        end
        if (exe_medeleg_we_in) begin
            medeleg_out = exe_medeleg_in;
        end else if (medeleg_we_in) begin
            medeleg_out = medeleg_in;
        end
        if (exe_sepc_we_in) begin
            sepc_out = exe_sepc_in;
        end else if (sepc_we_in) begin
            sepc_out = sepc_in;
        end
        if (exe_scause_we_in) begin
            scause_out = exe_scause_in;
        end else if (scause_we_in) begin
            scause_out = scause_in;
        end
        if (exe_stval_we_in) begin
            stval_out = exe_stval_in;
        end else if (stval_we_in) begin
            stval_out = stval_in;
        end
        if (exe_stvec_we_in) begin
            stvec_out = exe_stvec_in;
        end else if (stvec_we_in) begin
            stvec_out = stvec_in;
        end
        if (exe_sscratch_we_in) begin
            sscratch_out = exe_sscratch_in;
        end else if (sscratch_we_in) begin
            sscratch_out = sscratch_in;
        end

        if (exe_sstatus_we_in) begin
            sstatus_out = exe_sstatus_in;
        end else if (sstatus_we_in) begin
            sstatus_out = sstatus_in;
        end
        if (exe_mhartid_we_in) begin
            mhartid_out = exe_mhartid_in;
        end else if (mhartid_we_in) begin
            mhartid_out = mhartid_in;
        end
        if (exe_sie_we_in) begin
            sie_out = exe_sie_in;
        end else if (sie_we_in) begin
            sie_out = sie_in;
        end
        if (exe_sip_we_in) begin
            sip_out = exe_sip_in;
        end else if (sip_we_in) begin
            sip_out = sip_in;
        end
    end

    // All instructions are CSR related
    typedef enum logic [3:0] {
      NORMAL, // 0
      MTIME_INT,
      STIME_INT,
      ECALL,
      EBREAK,
      MRET,
      SRET,
      CSRRC,
      CSRRS,
      CSRRW,
      CSRRCI,
      CSRRSI,
      CSRRWI,
      SFENCE_VMA,
      IM_PAGE_FAULT, // 14
      DM_PAGE_FAULT
    } decode_ops;
    
    decode_ops d_op;

    always_comb begin
        // we all use mie/mip to judge
        if (mip_out[5] && mie_out[5] && (((priv_out==2'b01) && mstatus_out[1]) || (priv_out==2'b00))) begin
            d_op = STIME_INT;
        end else if (mip_out[7] && mie_out[7] && (mstatus_out[3] || priv_out == 2'b00 || priv_out == 2'b01)) begin
            d_op = MTIME_INT;
        end else if (inst_i[31:20] == 12'h000 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = ECALL;
        end else if (inst_i[31:20] == 12'h001 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = EBREAK;
        end else if (inst_i[31:20] == 12'h302 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = MRET;
        end else if (inst_i[31:20] == 12'h102 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = SRET;
        // end else if (inst_i[31:25] == 7'b0001001 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
        //     d_op = SFENCE_VMA;
        end else if (inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRW;
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRS;
        end else if (inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRC;
        end else if (inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRWI;
        end else if (inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRSI;
        end else if (inst_i[14:12] == 3'b111 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRCI;
        end else if (mem_page_fault_code_i != 2'b00) begin
            d_op = DM_PAGE_FAULT;
        end else if (if_page_fault_code_i != 2'b00 ) begin
            d_op = IM_PAGE_FAULT;
        end else begin
            d_op = NORMAL;
        end
    end

    // Send the time interrupt signal to decoder
    assign time_int_o = (d_op == MTIME_INT || d_op == STIME_INT) ? 1 : 0;
    // CSR code keep the same order as d_op
    assign csr_code = d_op;

    // The writing of CSR enable signals, and the decision of branch
    always_comb begin
        // We take the IF WE signal as our default priority
        mtvec_we_out = mtvec_we_in && (mem_page_fault_code_i == 2'b00);
        mscratch_we_out = mscratch_we_in && (mem_page_fault_code_i == 2'b00);
        mepc_we_out = mepc_we_in && (mem_page_fault_code_i == 2'b00);
        mcause_we_out = mcause_we_in && (mem_page_fault_code_i == 2'b00);
        mstatus_we_out = mstatus_we_in && (mem_page_fault_code_i == 2'b00);
        mie_we_out = mie_we_in && (mem_page_fault_code_i == 2'b00);
        mip_we_out = mip_we_in && (mem_page_fault_code_i == 2'b00);
        priv_we_out = priv_we_in && (mem_page_fault_code_i == 2'b00);

        satp_we_out = satp_we_in && (mem_page_fault_code_i == 2'b00);
        mtval_we_out = mtval_we_in && (mem_page_fault_code_i == 2'b00);
        mideleg_we_out = mideleg_we_in && (mem_page_fault_code_i == 2'b00);
        medeleg_we_out = medeleg_we_in && (mem_page_fault_code_i == 2'b00);
        sepc_we_out = sepc_we_in && (mem_page_fault_code_i == 2'b00);
        scause_we_out = scause_we_in && (mem_page_fault_code_i == 2'b00);
        stval_we_out = stval_we_in && (mem_page_fault_code_i == 2'b00);
        stvec_we_out = stvec_we_in && (mem_page_fault_code_i == 2'b00);
        sscratch_we_out = sscratch_we_in && (mem_page_fault_code_i == 2'b00);

        sstatus_we_out = sstatus_we_in && (mem_page_fault_code_i == 2'b00);
        mhartid_we_out = mhartid_we_in && (mem_page_fault_code_i == 2'b00);
        sie_we_out = sie_we_in && (mem_page_fault_code_i == 2'b00);
        sip_we_out = sip_we_in && (mem_page_fault_code_i == 2'b00);

        direct_branch_addr = 32'b0;

        case (mem_page_fault_code_i) 
            2'b01: begin // Instr Page Fault
                if ((priv_in < 2) && medeleg_in[12]) begin // delegation
                    direct_branch_addr = csr_stvec_in;
                end else begin
                    direct_branch_addr = csr_mtvec_in;
                end
            end
            2'b10: begin // Load Page Fault
                if ((priv_in < 2) && medeleg_in[13]) begin // delegation
                    direct_branch_addr = csr_stvec_in;
                end else begin
                    direct_branch_addr = csr_mtvec_in;
                end
            end
            2'b11: begin // Store Page Fault
                if ((priv_in < 2) && medeleg_in[15]) begin // delegation
                    direct_branch_addr = csr_stvec_in;
                end else begin
                    direct_branch_addr = csr_mtvec_in;
                end
            end
            default: begin
                // normal, without mem page fault
                if (d_op == MTIME_INT) begin
                    priv_we_out = 1'b1;
                    mstatus_we_out = 1'b1;
                    mepc_we_out = 1'b1;
                    mcause_we_out = 1'b1;
                    direct_branch_addr = mtvec_out;
                end else if (d_op == STIME_INT) begin
                    priv_we_out = 1'b1;
                    mstatus_we_out = 1'b1;
                    // if mideleg.SITP = 1, transfer to S mode to process
                    if (mideleg_out[5]) begin
                        sepc_we_out = 1'b1;
                        scause_we_out = 1'b1;
                        direct_branch_addr = stvec_out;
                    end else begin
                        mepc_we_out = 1'b1;
                        mcause_we_out = 1'b1;
                        direct_branch_addr = mtvec_out;
                    end
                end else if (d_op == ECALL) begin
                    priv_we_out = 1'b1;
                    mstatus_we_out = 1'b1;
                    mie_we_out = 1'b1;
                    if ((priv_out < 2) && medeleg_out[priv_out+8]) begin // delegation
                        sepc_we_out = 1'b1;
                        scause_we_out = 1'b1;
                        direct_branch_addr = stvec_out;
                    end else begin
                        mepc_we_out = 1'b1;
                        mcause_we_out = 1'b1;
                        direct_branch_addr = mtvec_out;
                    end
                end else if (d_op == EBREAK) begin
                    priv_we_out = 1'b1;
                    mstatus_we_out = 1'b1;
                    mie_we_out = 1'b1;
                    if ((priv_out < 2) && medeleg_out[3]) begin // delegation
                        sepc_we_out = 1'b1;
                        scause_we_out = 1'b1;
                        direct_branch_addr = stvec_out;
                    end else begin
                        mepc_we_out = 1'b1;
                        mcause_we_out = 1'b1;
                        direct_branch_addr = mtvec_out;
                    end
                end else if (d_op == MRET) begin
                    priv_we_out = 1'b1;
                    mstatus_we_out = 1'b1;
                    direct_branch_addr = mepc_out;
                end else if (d_op == SRET) begin
                    priv_we_out = 1'b1;
                    mstatus_we_out = 1'b1;
                    direct_branch_addr = sepc_out;
                end else if (d_op == CSRRC || d_op == CSRRCI || d_op == CSRRS || d_op == CSRRSI || d_op == CSRRW || d_op == CSRRWI) begin
                    case(inst_i[31:20])
                        12'h305: mtvec_we_out = 1'b1;
                        12'h340: mscratch_we_out = 1'b1;
                        12'h341: mepc_we_out = 1'b1;
                        12'h342: mcause_we_out = 1'b1;
                        12'h300: mstatus_we_out = 1'b1;
                        12'h304: mie_we_out = 1'b1;
                        12'h344: mip_we_out = 1'b1;
                        12'h180: satp_we_out = 1'b1;
                        12'h343: mtval_we_out = 1'b1;
                        12'h303: mideleg_we_out = 1'b1;
                        12'h302: medeleg_we_out = 1'b1;
                        12'h141: sepc_we_out = 1'b1;
                        12'h142: scause_we_out = 1'b1;
                        12'h143: stval_we_out = 1'b1;
                        12'h105: stvec_we_out = 1'b1;
                        12'h140: sscratch_we_out = 1'b1;
                        12'h100: mstatus_we_out = 1'b1;
                        12'h104: mie_we_out = 1'b1;
                        12'h144: mip_we_out = 1'b1;
                        12'hF14: mhartid_we_out = 1'b1;
                        default: mtvec_we_out = 1'b0; // shouldn't be used
                    endcase
                end else begin // for the NORMAL situations, we don't write anything
                    // default situation is just that we let IF signals be priority
                    // let's talk about if page fault
                    case (if_page_fault_code_i) 
                        2'b01: begin // Instr Page Fault
                            if ((priv_in < 2) && medeleg_in[12]) begin // delegation
                                direct_branch_addr = stvec_in;
                            end else begin
                                direct_branch_addr = mtvec_in;
                            end
                        end
                        2'b10: begin // Load Page Fault
                            if ((priv_in < 2) && medeleg_in[13]) begin // delegation
                                direct_branch_addr = stvec_in;
                            end else begin
                                direct_branch_addr = mtvec_in;
                            end
                        end
                        2'b11: begin // Store Page Fault
                            if ((priv_in < 2) && medeleg_in[15]) begin // delegation
                                direct_branch_addr = stvec_in;
                            end else begin
                                direct_branch_addr = mtvec_in;
                            end
                        end
                        default: begin
                        end
                    endcase
                end
            end
        endcase

    end

endmodule