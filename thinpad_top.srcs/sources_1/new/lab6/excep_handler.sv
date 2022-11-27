module excep_handler (
    input wire [31:0] satp_in,
    input wire [31:0] mtvec_in,
    input wire [31:0] mscratch_in,
    input wire [31:0] mepc_in,
    input wire [31:0] mcause_in,
    input wire [31:0] mstatus_in,
    input wire [31:0] mie_in,
    input wire [31:0] mip_in,
    input wire [1:0] priv_in,

    output logic [31:0] satp_out,
    output logic [31:0] mtvec_out,
    output logic [31:0] mscratch_out,
    output logic [31:0] mepc_out,
    output logic [31:0] mcause_out,
    output logic [31:0] mstatus_out,
    output logic [31:0] mie_out,
    output logic [31:0] mip_out,
    output logic [1:0] priv_out,

    input wire satp_we_in,
    input wire mtvec_we_in,
    input wire mscratch_we_in,
    input wire mepc_we_in,
    input wire mcause_we_in,
    input wire mstatus_we_in,
    input wire mie_we_in,
    input wire mip_we_in,
    input wire priv_we_in,

    output logic satp_we_out,
    output logic mtvec_we_out,
    output logic mscratch_we_out,
    output logic mepc_we_out,
    output logic mcause_we_out,
    output logic mstatus_we_out,
    output logic mie_we_out,
    output logic mip_we_out,
    output logic priv_we_out,

    input wire [3:0] csr_code_in,
    output logic [31:0] data_out,

    input wire [31:0] exe_rs1_data,
    input wire [31:0] exe_inst,
    input wire [31:0] exe_pc
);

    // if csr_code_in = 3/5/7, indicates csr instr with zimm
    reg [31:0] regs1_in;
    assign regs1_in = (csr_code_in == 3 || csr_code_in == 5 || csr_code_in == 7) ? {27'b0, exe_inst[19:15]} : exe_rs1_data;

    always_comb begin
        satp_we_out = satp_we_in;
        mtvec_we_out = mtvec_we_in;
        mscratch_we_out = mscratch_we_in;
        mepc_we_out = mepc_we_in;
        mcause_we_out = mcause_we_in;
        mstatus_we_out = mstatus_we_in;
        mie_we_out = mie_we_in;
        mip_we_out = mip_we_in;
        priv_we_out = priv_we_in;

        satp_out = satp_in;
        mtvec_out = mtvec_in;
        mscratch_out = mscratch_in;
        mepc_out = mepc_in;
        mcause_out = mcause_in;
        mstatus_out = mstatus_in;
        mie_out = mie_in;
        mip_out = mip_in;
        priv_out = priv_in;

        data_out = 0;

        // TIME_INT
        if (csr_code_in == 1) begin
            priv_out = 2'b11;
            mstatus_out = {mstatus_in[31:13],priv_in,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
            mepc_out = exe_pc;
            mcause_out = {1'b1, 27'b0, 4'b0111};
        // ECALL
        end else if (csr_code_in == 8) begin
            priv_out = 2'b11;
            mstatus_out = {mstatus_in[31:13],priv_in,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
            mepc_out = exe_pc;
            mcause_out = {1'b0, 27'b0, 4'b1000}; // Call from U mode?
        // EBREAK
        end else if (csr_code_in == 9) begin
            priv_out = 2'b11;
            mstatus_out = {mstatus_in[31:13],priv_in,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
            mepc_out = exe_pc;
            mcause_out = {1'b0, 27'b0, 4'b0011}; //breakpoint exception
        // MRET
        end else if (csr_code_in == 10) begin
            // only available in M mode
            priv_out = mstatus_in[12:11];
            mstatus_out = {mstatus_in[31:13],2'b11,mstatus_in[10:8],mstatus_in[3],mstatus_in[6:4],mstatus_in[7],mstatus_in[2:0]};
        // CSR INstructions
        // CSRRC(I)
        end else if (csr_code_in == 2 || csr_code_in == 3) begin
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
                12'h304: begin
                    data_out = mie_in;
                    mie_out = mie_in & ~regs1_in;
                end
                12'h344: begin
                    data_out = mip_in;
                    mip_out = mip_in & ~regs1_in;
                end
                12'h180: begin
                    data_out = satp_in;
                    satp_out = satp_in & ~regs1_in;
                end
                default: begin
                end
            endcase
        // CSRRS(I)
        end else if (csr_code_in == 4 || csr_code_in == 5) begin
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
                12'h304: begin
                    data_out = mie_in;
                    mie_out = mie_in | regs1_in;
                end
                12'h344: begin
                    data_out = mip_in;
                    mip_out = mip_in | regs1_in;
                end
                12'h180: begin
                    data_out = satp_in;
                    satp_out = satp_in | regs1_in;
                end
                default: begin
                end
            endcase
        // CSRRW(I)
        end else if (csr_code_in == 6 || csr_code_in == 7) begin
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
                12'h304: begin
                    data_out = mie_in;
                    mie_out = regs1_in;
                end
                12'h344: begin
                    data_out = mip_in;
                    mip_out = regs1_in;
                end
                12'h180: begin
                    data_out = satp_in;
                    satp_out = regs1_in;
                end
                default: begin
                end
            endcase
        // The default situation
        end else begin
        end
    end

endmodule