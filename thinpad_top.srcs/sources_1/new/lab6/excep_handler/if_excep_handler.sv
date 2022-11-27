module if_excep_handler (
    // input from csr regs
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

    // if page fault
    input wire [31:0] page_fault_addr_i,
    input wire [1:0] page_fault_code_i,
    input wire [31:0] if_pc_i,
    output logic sstatus_we_out,
    output logic mhartid_we_out,
    output logic sie_we_out,
    output logic sip_we_out
);

    always_comb begin
        mtvec_out = mtvec_in;
        mscratch_out = mscratch_in;
        mepc_out = mepc_in;
        mcause_out = mcause_in;
        mstatus_out = mstatus_in;
        mie_out = mie_in;
        mip_out = mip_in;
        priv_out = priv_in;

        satp_out = satp_in;
        mtval_out = mtval_in;
        mideleg_out = mideleg_in;
        medeleg_out = medeleg_in;
        sepc_out = sepc_in;
        scause_out = scause_in;
        stval_out = stval_in;
        stvec_out = stvec_in;
        sscratch_out = sscratch_in;

        sstatus_out = sstatus_in;
        mhartid_out = mhartid_in;
        sie_out = sie_in;
        sip_out = sip_in;
                
        mtvec_we_out = 0;
        mscratch_we_out = 0;
        mepc_we_out = 0;
        mcause_we_out = 0;
        mstatus_we_out = 0;
        mie_we_out = 0;
        mip_we_out = 0;
        priv_we_out = 0;

        satp_we_out = 0;
        mtval_we_out = 0;
        mideleg_we_out = 0;
        medeleg_we_out = 0;
        sepc_we_out = 0;
        scause_we_out = 0;
        stval_we_out = 0;
        stvec_we_out = 0;
        sscratch_we_out = 0;

        sstatus_we_out = 0;
        mhartid_we_out = 0;
        sie_we_out = 0;
        sip_we_out = 0;
        
        // TODO : Add signals to be passed on, deal with exceptions in IF

        case (page_fault_code_i) 
            2'b01: begin // Instr Page Fault
                priv_we_out = 1'b1;
                mstatus_we_out = 1'b1;
                if ((priv_in < 2) && medeleg_in[12]) begin // delegation
                    sepc_we_out = 1'b1;
                    scause_we_out = 1'b1;
                    stval_we_out = 1'b1;

                    priv_out = 2'b01;
                    mstatus_out = {mstatus_in[31:9], priv_in[0], mstatus_in[7:6], mstatus_in[1],mstatus_in[4:2],1'b0,mstatus_in[0]};
                    sepc_out = if_pc_i; // return back to here after handling the exception
                    scause_out = {1'b0, 27'b0, 4'd12};
                    stval_out = page_fault_addr_i; // the load/store addr
                end else begin
                    mepc_we_out = 1'b1;
                    mcause_we_out = 1'b1;
                    mtval_we_out = 1'b1;

                    priv_out = 2'b11;
                    mstatus_out = {mstatus_in[31:13], priv_in, mstatus_in[10:8], mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
                    mepc_out = if_pc_i; // return back to here after handling the exception
                    mcause_out = {1'b0, 27'b0, 4'd12};
                    mtval_out = page_fault_addr_i; // the load/store addr
                end
            end
            2'b10: begin // Load Page Fault
                priv_we_out = 1'b1;
                mstatus_we_out = 1'b1;
                if ((priv_in < 2) && medeleg_in[13]) begin // delegation
                    sepc_we_out = 1'b1;
                    scause_we_out = 1'b1;
                    stval_we_out = 1'b1;

                    priv_out = 2'b01;
                    mstatus_out = {mstatus_in[31:9], priv_in[0], mstatus_in[7:6], mstatus_in[1],mstatus_in[4:2],1'b0,mstatus_in[0]};
                    sepc_out = if_pc_i; // return back to here after handling the exception
                    scause_out = {1'b0, 27'b0, 4'd13};
                    stval_out = page_fault_addr_i; // the load/store addr
                end else begin
                    mepc_we_out = 1'b1;
                    mcause_we_out = 1'b1;
                    mtval_we_out = 1'b1;

                    priv_out = 2'b11;
                    mstatus_out = {mstatus_in[31:13], priv_in, mstatus_in[10:8], mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
                    mepc_out = if_pc_i; // return back to here after handling the exception
                    mcause_out = {1'b0, 27'b0, 4'd13};
                    mtval_out = page_fault_addr_i; // the load/store addr
                end
            end
            2'b11: begin // Store Page Fault
                priv_we_out = 1'b1;
                mstatus_we_out = 1'b1;
                if ((priv_in < 2) && medeleg_in[15]) begin // delegation
                    sepc_we_out = 1'b1;
                    scause_we_out = 1'b1;
                    stval_we_out = 1'b1;

                    priv_out = 2'b01;
                    mstatus_out = {mstatus_in[31:9], priv_in[0], mstatus_in[7:6], mstatus_in[1],mstatus_in[4:2],1'b0,mstatus_in[0]};
                    sepc_out = if_pc_i; // return back to here after handling the exception
                    scause_out = {1'b0, 27'b0, 4'd15};
                    stval_out = page_fault_addr_i; // the load/store addr
                end else begin
                    mepc_we_out = 1'b1;
                    mcause_we_out = 1'b1;
                    mtval_we_out = 1'b1;
                    
                    priv_out = 2'b11;
                    mstatus_out = {mstatus_in[31:13], priv_in, mstatus_in[10:8], mstatus_in[3],mstatus_in[6:4],1'b0,mstatus_in[2:0]};
                    mepc_out = if_pc_i; // return back to here after handling the exception
                    mcause_out = {1'b0, 27'b0, 4'd15};
                    mtval_out = page_fault_addr_i; // the load/store addr
                end
            end
            default: begin
                
            end
        endcase
    end

endmodule