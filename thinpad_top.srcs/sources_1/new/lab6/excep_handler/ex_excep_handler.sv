module ex_excep_handler (
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

    input wire [3:0] csr_code_in,
    output logic [31:0] data_out,

    input wire [31:0] exe_rs1_data,
    input wire [31:0] exe_inst,
    input wire [31:0] exe_pc
);

    // if csr_code_in = 10/11/12, indicates csr instr with zimm
    reg [31:0] regs1_in;
    assign regs1_in = (csr_code_in == 10 || csr_code_in == 11 || csr_code_in == 12) ? {27'b0, exe_inst[19:15]} : exe_rs1_data;

    always_comb begin
        // Default set to directly pass the signals
        mtvec_we_out = mtvec_we_in;
        mscratch_we_out = mscratch_we_in;
        mepc_we_out = mepc_we_in;
        mcause_we_out = mcause_we_in;
        mstatus_we_out = mstatus_we_in;
        mie_we_out = mie_we_in;
        mip_we_out = mip_we_in;
        satp_we_out = satp_we_in;
        priv_we_out = priv_we_in;
        mtval_we_out = mtval_we_in;
        mideleg_we_out = mideleg_we_in;
        medeleg_we_out = medeleg_we_in;
        sepc_we_out = sepc_we_in;
        scause_we_out = scause_we_in;
        stval_we_out = stval_we_in;
        stvec_we_out = stvec_we_in;
        sscratch_we_out = sscratch_we_in;

        mtvec_out = mtvec_in;
        mscratch_out = mscratch_in;
        mepc_out = mepc_in;
        mcause_out = mcause_in;
        mstatus_out = mstatus_in;
        mie_out = mie_in;
        mip_out = mip_in;
        satp_out = satp_in;
        priv_out = priv_in;
        mtval_out = mtval_in;
        mideleg_out = mideleg_in;
        medeleg_out = medeleg_in;
        sepc_out = sepc_in;
        scause_out = scause_in;
        stval_out = stval_in;
        stvec_out = stvec_in;
        sscratch_out = sscratch_in;

        data_out = 32'b0;

        // MTIME_INT
        if (csr_code_in == 1) begin
            priv_out = 2'b11;
            mstatus_out = {mstatus_in[31:13],priv_in,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
            mepc_out = exe_pc;
            mcause_out = {1'b1, 27'b0, 4'b0111};
        // STIME_INT
        end else if (csr_code_in == 2) begin
            priv_out = 2'b01;
            mstatus_out = {mstatus_in[31:9],priv_in[0],mstatus_in[7:6],mstatus_in[1],mstatus_in[4:2],1'b0,mstatus_in[0]};
            sepc_out = exe_pc;
            scause_out = {1'b1, 27'b0, 4'b0111};
        // ECALL
        end else if (csr_code_in == 3) begin
            if ((priv_in < 2) && medeleg_in[priv_in+8]) begin // delegation
                priv_out = 2'b01;
                mstatus_out = {mstatus_in[31:9],priv_in[0],mstatus_in[7:6],mstatus_in[1],mstatus_in[4:2],1'b0,mstatus_in[0]};
                sepc_out = exe_pc;
                scause_out = {1'b0, 27'b0, 2'b10, priv_in};
            end else begin
                priv_out = 2'b11;
                mstatus_out = {mstatus_in[31:13],priv_in,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
                mepc_out = exe_pc;
                mcause_out = {1'b0, 27'b0, 2'b10, priv_in};
            end
        // EBREAK
        end else if (csr_code_in == 4) begin
            if ((priv_in < 2) && medeleg_in[3]) begin // delegation
                priv_out = 2'b01;
                mstatus_out = {mstatus_in[31:9],priv_in[0],mstatus_in[7:6],mstatus_in[1],mstatus_in[4:2],1'b0,mstatus_in[0]};
                sepc_out = exe_pc;
                scause_out = {1'b0, 27'b0, 4'b0011};
            end else begin
                priv_out = 2'b11;
                mstatus_out = {mstatus_in[31:13],priv_in,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
                mepc_out = exe_pc;
                mcause_out = {1'b0, 27'b0, 4'b0011}; //breakpoint exception
            end
        // MRET
        end else if (csr_code_in == 5) begin
            // only available in M mode
            priv_out = mstatus_in[12:11];
            mstatus_out = {mstatus_in[31:13],2'b11,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],mstatus_in[7],mstatus_in[2:0]};
        // SRET
        end else if (csr_code_in == 6) begin
            // only available in S mode
            priv_out = {1'b0,mstatus_in[8]};
            mstatus_out = {mstatus_in[31:9],1'b1,mstatus_in[7:6],mstatus_in[1],mstatus_in[4:2],mstatus_in[5],mstatus_in[0]};
        // CSR INstructions
        // CSRRC(I)
        end else if (csr_code_in == 7 || csr_code_in == 10) begin
            case (exe_inst[31:20])
                12'h305: begin
                    data_out = mtvec_in;
                    mtvec_out = mtvec_in & ~regs1_in;
                end
                12'h340: begin
                    data_out = mscratch_in;
                    mscratch_out = mscratch_in & ~regs1_in;
                end
                12'h341: begin
                    data_out = mepc_in;
                    mepc_out = mepc_in & ~regs1_in;
                end
                12'h342: begin
                    data_out = mcause_in;
                    mcause_out = mcause_in & ~regs1_in;
                end
                12'h300: begin
                    data_out = mstatus_in;
                    mstatus_out = mstatus_in & ~regs1_in;
                end
                12'h302: begin
                    data_out = medeleg_in;
                    medeleg_out = medeleg_in & ~regs1_in;
                end
                12'h303: begin
                    data_out = mideleg_in;
                    mideleg_out = mideleg_in & ~regs1_in;
                end
                12'h304: begin
                    data_out = mie_in;
                    mie_out = mie_in & ~regs1_in;
                end
                12'h343: begin
                    data_out = mtval_in;
                    mtval_out = mtval_in & ~regs1_in;
                end
                12'h344: begin
                    data_out = mip_in;
                    mip_out = mip_in & ~regs1_in;
                end
                12'h180: begin
                    data_out = satp_in;
                    satp_out = satp_in & ~regs1_in;
                end
                12'h105: begin
                    data_out = stvec_in;
                    stvec_out = stvec_in & ~regs1_in;
                end
                12'h140: begin
                    data_out = sscratch_in;
                    sscratch_out = sscratch_in & ~regs1_in;
                end
                12'h141: begin
                    data_out = sepc_in;
                    sepc_out = sepc_in & ~regs1_in;
                end
                12'h142: begin
                    data_out = scause_in;
                    scause_out = scause_in & ~regs1_in;
                end
                12'h143: begin
                    data_out = stval_in;
                    stval_out = stval_in & ~regs1_in;
                end
                default: begin
                end
            endcase
        // CSRRS(I)
        end else if (csr_code_in == 8 || csr_code_in == 11) begin
            case (exe_inst[31:20])
                12'h305: begin
                    data_out = mtvec_in;
                    mtvec_out = mtvec_in | regs1_in;
                end
                12'h340: begin
                    data_out = mscratch_in;
                    mscratch_out = mscratch_in | regs1_in;
                end
                12'h341: begin
                    data_out = mepc_in;
                    mepc_out = mepc_in | regs1_in;
                end
                12'h342: begin
                    data_out = mcause_in;
                    mcause_out = mcause_in | regs1_in;
                end
                12'h300: begin
                    data_out = mstatus_in;
                    mstatus_out = mstatus_in | regs1_in;
                end
                12'h302: begin
                    data_out = medeleg_in;
                    medeleg_out = medeleg_in | regs1_in;
                end
                12'h303: begin
                    data_out = mideleg_in;
                    mideleg_out = mideleg_in | regs1_in;
                end
                12'h304: begin
                    data_out = mie_in;
                    mie_out = mie_in | regs1_in;
                end
                12'h343: begin
                    data_out = mtval_in;
                    mtval_out = mtval_in | regs1_in;
                end
                12'h344: begin
                    data_out = mip_in;
                    mip_out = mip_in | regs1_in;
                end
                12'h180: begin
                    data_out = satp_in;
                    satp_out = satp_in | regs1_in;
                end
                12'h105: begin
                    data_out = stvec_in;
                    stvec_out = stvec_in | regs1_in;
                end
                12'h140: begin
                    data_out = sscratch_in;
                    sscratch_out = sscratch_in | regs1_in;
                end
                12'h141: begin
                    data_out = sepc_in;
                    sepc_out = sepc_in | regs1_in;
                end
                12'h142: begin
                    data_out = scause_in;
                    scause_out = scause_in | regs1_in;
                end
                12'h143: begin
                    data_out = stval_in;
                    stval_out = stval_in | regs1_in;
                end
                default: begin
                end
            endcase
        // CSRRW(I)
        end else if (csr_code_in == 9 || csr_code_in == 12) begin
            case (exe_inst[31:20])
                12'h305: begin
                    data_out = mtvec_in;
                    mtvec_out = regs1_in;
                end
                12'h340: begin
                    data_out = mscratch_in;
                    mscratch_out = regs1_in;
                end
                12'h341: begin
                    data_out = mepc_in;
                    mepc_out = regs1_in;
                end
                12'h342: begin
                    data_out = mcause_in;
                    mcause_out = regs1_in;
                end
                12'h300: begin
                    data_out = mstatus_in;
                    mstatus_out = regs1_in;
                end
                12'h302: begin
                    data_out = medeleg_in;
                    medeleg_out = regs1_in;
                end
                12'h303: begin
                    data_out = mideleg_in;
                    mideleg_out = regs1_in;
                end
                12'h304: begin
                    data_out = mie_in;
                    mie_out = regs1_in;
                end
                12'h343: begin
                    data_out = mtval_in;
                    mtval_out = regs1_in;
                end
                12'h344: begin
                    data_out = mip_in;
                    mip_out = regs1_in;
                end
                12'h180: begin
                    data_out = satp_in;
                    satp_out = regs1_in;
                end
                12'h105: begin
                    data_out = stvec_in;
                    stvec_out = regs1_in;
                end
                12'h140: begin
                    data_out = sscratch_in;
                    sscratch_out = regs1_in;
                end
                12'h141: begin
                    data_out = sepc_in;
                    sepc_out = regs1_in;
                end
                12'h142: begin
                    data_out = scause_in;
                    scause_out = regs1_in;
                end
                12'h143: begin
                    data_out = stval_in;
                    stval_out = regs1_in;
                end
                default: begin
                end
            endcase
        // The default situation
        end else begin
        end
    end

endmodule