`default_nettype none

module lab6_top (
    input wire clk_50M,     // 50MHz
    input wire clk_11M0592, // 11.0592MHz

    input wire push_btn,  // BTN
    input wire reset_btn, // BTN6

    input  wire [ 3:0] touch_btn,  //
    input  wire [31:0] dip_sw,     //
    output wire [15:0] leds,       //
    output wire [ 7:0] dpy0,       //
    output wire [ 7:0] dpy1,       //

    // CPLD
    output wire uart_rdn,        //
    output wire uart_wrn,        //
    input  wire uart_dataready,  //
    input  wire uart_tbre,       //
    input  wire uart_tsre,       // 

    // BaseRAM
    inout wire [31:0] base_ram_data,  // BaseRAM 
    output wire [19:0] base_ram_addr,  // BaseRAM
    output wire [3:0] base_ram_be_n,  // BaseRAM
    output wire base_ram_ce_n,  // BaseRAM
    output wire base_ram_oe_n,  // BaseRAM
    output wire base_ram_we_n,  // BaseRAM

    // ExtRAM
    inout wire [31:0] ext_ram_data,  // ExtRAM
    output wire [19:0] ext_ram_addr,  // ExtRAM
    output wire [3:0] ext_ram_be_n,  // ExtRAM
    output wire ext_ram_ce_n,  // ExtRAM
    output wire ext_ram_oe_n,  // ExtRAM
    output wire ext_ram_we_n,  // ExtRAM

    // 
    output wire txd,  //
    input  wire rxd,  //

    output wire [22:0] flash_a,  //
    inout wire [15:0] flash_d,  //
    output wire flash_rp_n,  //
    output wire flash_vpen,
    output wire flash_ce_n,  //
    output wire flash_oe_n,  //
    output wire flash_we_n,  // 
    output wire flash_byte_n, //

    output wire sl811_a0,
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    output wire [2:0] video_red,    //
    output wire [2:0] video_green,  //
    output wire [1:0] video_blue,   // 
    output wire       video_hsync,  //
    output wire       video_vsync,  //
    output wire       video_clk,    //
    output wire       video_de      //
);

  /* =========== Demo code begin =========== */

  // PLL 
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  //
      // Clock out ports
      .clk_out1(clk_10M),  //
      .clk_out2(clk_20M),  //
      // Status and control signals
      .reset(reset_btn),  // PLL
      .locked(locked)  // PLL
                       //
  );

  logic reset_of_clk10M;
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_10M;
  assign sys_rst = reset_of_clk10M;
  
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  /* =========== Lab6 begin =========== */
  
  // for pc_reg
  logic [31:0] next_pc; // 
  logic [31:0] cur_pc;  //
  logic [1:0]  pc_sel;  //
  logic        pc_hold;
  logic        if_req;
  logic        if_ack;
  logic [31:0] if_inst; //

  // for BTB
  logic [31:0] btb_branch_addr;
  logic predict_fault;

  // for cache 
  logic cache_im_req;
  logic cache_im_ack;
  logic [31:0] cache_im_pc;
  logic [31:0] cache_im_inst;

  //Timer
  logic mtime_we;
  logic mtimecmp_we;
  logic timer_upper;
  logic [31:0] timer_wdata;
  logic [63:0] mtime;
  logic [63:0] mtimecmp;
  logic interrupt;

  mtimer u_mtimer (
      .clk (sys_clk),
      .rst (sys_rst),
      .mtime_we (mtime_we),
      .mtimecmp_we (mtimecmp_we),
      .upper (timer_upper),
      .wdata (timer_wdata),
      .mtime (mtime),
      .mtimecmp (mtimecmp),
      .interrupt (interrupt)
  );

  //CSR File
  //input
  logic mtvec_we;
  logic mscratch_we;
  logic mepc_we;
  logic mcause_we;
  logic mstatus_we;
  logic mie_we;
  logic mip_we;
  logic privilege_we;

  logic satp_we;
  logic mtval_we;
  logic mideleg_we;
  logic medeleg_we;
  logic sepc_we;
  logic scause_we;
  logic stval_we;
  logic stvec_we;
  logic sscratch_we;

  logic sstatus_we;
  logic mhartid_we;
  logic sie_we;
  logic sip_we;

  //input
  logic [31:0] mtvec_wdata;
  logic [31:0] mscratch_wdata;
  logic [31:0] mepc_wdata;
  logic [31:0] mcause_wdata;
  logic [31:0] mstatus_wdata;
  logic [31:0] mie_wdata;
  logic [31:0] mip_wdata;
  logic [1:0] privilege_wdata;
  
  logic [31:0] satp_wdata;
  logic [31:0] mtval_wdata;
  logic [31:0] mideleg_wdata;
  logic [31:0] medeleg_wdata;
  logic [31:0] sepc_wdata;
  logic [31:0] scause_wdata;
  logic [31:0] stval_wdata;
  logic [31:0] stvec_wdata;
  logic [31:0] sscratch_wdata;

  logic [31:0] sstatus_wdata;
  logic [31:0] mhartid_wdata;
  logic [31:0] sie_wdata;
  logic [31:0] sip_wdata;

  //output
  logic [31:0] mtvec_o;
  logic [31:0] mscratch_o;
  logic [31:0] mepc_o;
  logic [31:0] mcause_o;
  logic [31:0] mstatus_o;
  logic [31:0] mie_o;
  logic [31:0] mip_o;
  logic [1:0] privilege_o;
  
  logic [31:0] satp_o;
  logic [31:0] mtval_o;
  logic [31:0] mideleg_o;
  logic [31:0] medeleg_o;
  logic [31:0] sepc_o;
  logic [31:0] scause_o;
  logic [31:0] stval_o;
  logic [31:0] stvec_o;
  logic [31:0] sscratch_o;

  logic [31:0] sstatus_o;
  logic [31:0] mhartid_o;
  logic [31:0] sie_o;
  logic [31:0] sip_o;

  csr u_csr (
      .clk(sys_clk),
      .rst(sys_rst),
      .int_time(interrupt),

      // input
      .mtvec_we(mtvec_we),
      .mscratch_we(mscratch_we),
      .mepc_we(mepc_we),
      .mcause_we(mcause_we),
      .mstatus_we(mstatus_we),
      .mie_we(mie_we),
      .mip_we(mip_we),
      .privilege_we(privilege_we),

      .satp_we(satp_we),
      .mtval_we(mtval_we),
      .mideleg_we(mideleg_we),
      .medeleg_we(medeleg_we),
      .sepc_we(sepc_we),
      .scause_we(scause_we),
      .stval_we(stval_we),
      .stvec_we(stvec_we),
      .sscratch_we(sscratch_we),

      .sstatus_we(sstatus_we),
      .mhartid_we(mhartid_we),
      .sie_we(sie_we),
      .sip_we(sip_we),

      //input
      .mtvec_wdata(mtvec_wdata),
      .mscratch_wdata(mscratch_wdata),
      .mepc_wdata(mepc_wdata),
      .mcause_wdata(mcause_wdata),
      .mstatus_wdata(mstatus_wdata),
      .mie_wdata(mie_wdata),
      .mip_wdata(mip_wdata),
      .privilege_wdata(privilege_wdata),

      .satp_wdata(satp_wdata),
      .mtval_wdata(mtval_wdata),
      .mideleg_wdata(mideleg_wdata),
      .medeleg_wdata(medeleg_wdata),
      .sepc_wdata(sepc_wdata),
      .scause_wdata(scause_wdata),
      .stval_wdata(stval_wdata),
      .stvec_wdata(stvec_wdata),
      .sscratch_wdata(sscratch_wdata),

      .sstatus_wdata(sstatus_wdata),
      .mhartid_wdata(mhartid_wdata),
      .sie_wdata(sie_wdata),
      .sip_wdata(sip_wdata),

      //output
      .mtvec_o(mtvec_o),
      .mscratch_o(mscratch_o),
      .mepc_o(mepc_o),
      .mcause_o(mcause_o),
      .mstatus_o(mstatus_o),
      .mie_o(mie_o),
      .mip_o(mip_o),
      .privilege_o(privilege_o),

      .satp_o(satp_o),
      .mtval_o(mtval_o),
      .mideleg_o(mideleg_o),
      .medeleg_o(medeleg_o),
      .sepc_o(sepc_o),
      .scause_o(scause_o),
      .stval_o(stval_o),
      .stvec_o(stvec_o),
      .sscratch_o(sscratch_o),

      .sstatus_o(sstatus_o),
      .mhartid_o(mhartid_o),
      .sie_o(sie_o),
      .sip_o(sip_o)
  );

  logic if_mtvec_we_o;
  logic if_mscratch_we_o;
  logic if_mepc_we_o;
  logic if_mcause_we_o;
  logic if_mstatus_we_o;
  logic if_mie_we_o;
  logic if_mip_we_o;
  logic if_privilege_we_o;

  logic if_satp_we_o;
  logic if_mtval_we_o;
  logic if_mideleg_we_o;
  logic if_medeleg_we_o;
  logic if_sepc_we_o;
  logic if_scause_we_o;
  logic if_stval_we_o;
  logic if_stvec_we_o;
  logic if_sscratch_we_o;

  logic if_sstatus_we_o;
  logic if_mhartid_we_o;
  logic if_sie_we_o;
  logic if_sip_we_o;

  logic [31:0] if_mtvec_data_o;
  logic [31:0] if_mscratch_data_o;
  logic [31:0] if_mepc_data_o;
  logic [31:0] if_mcause_data_o;
  logic [31:0] if_mstatus_data_o;
  logic [31:0] if_mie_data_o;
  logic [31:0] if_mip_data_o;
  logic [1:0] if_privilege_data_o;
  
  logic [31:0] if_satp_data_o;
  logic [31:0] if_mtval_data_o;
  logic [31:0] if_mideleg_data_o;
  logic [31:0] if_medeleg_data_o;
  logic [31:0] if_sepc_data_o;
  logic [31:0] if_scause_data_o;
  logic [31:0] if_stval_data_o;
  logic [31:0] if_stvec_data_o;
  logic [31:0] if_sscratch_data_o;

  logic [31:0] if_sstatus_data_o;
  logic [31:0] if_mhartid_data_o;
  logic [31:0] if_sie_data_o;
  logic [31:0] if_sip_data_o;

  logic hold_all;
  
  /* =========== IF Stage begin =========== */
  pc_reg u_pc_reg (
      .clk_i     (sys_clk),
      .rst_i     (sys_rst),
      
      .next_pc_i (next_pc),
      .cur_pc_o  (cur_pc),
      
      .pc_hold_i (pc_hold),
      .if_req_o  (if_req)
  );
  
  // PC_sel_generator
  PC_sel_mux pc_sel_mux(
    .csr_code_i(ex_csr_code),
    .exe_inst_i(exe_inst),
    .pc_sel_o(pc_sel)
  );

  // BTB_Addr_MUX
  BTB_Addr_MUX btb_mux(
    .addr_sel(pc_sel),
    .exe_pc_i(exe_pc),
    .alu_pc_i(exe_alu_y),
    .direct_br_addr(ex_direct_branch_addr),
    .branch_addr_o(btb_branch_addr)
  );

  // BTB
  BTB btb(
    .clk_i(sys_clk),
    .rst_i(sys_rst),
    .curr_pc_i(cur_pc),
    .addr_sel_i(pc_sel),

    .stall(hold_all),

    .exe_is_branch_i(exe_is_branch),
    .branch_taken_i(exe_br_eq),
    .branch_addr_i(btb_branch_addr),
    .id_addr_i(id_pc),
    .exe_addr_i(exe_pc),

    .next_pc_o(next_pc),
    .predict_fault_o(predict_fault)
  );

  // for mmu
  logic [31:0] if_master_data_mmu;
  logic        if_master_ack_mmu;
  logic [1:0]  if_mmu_state;
  logic        if_mmu_on;
  logic        if_tlb_hit;
  logic [31:0] if_master_phy_addr;
  logic [1:0]  if_page_fault_code;
  logic [31:0] if_page_fault_addr;
  
  im_fast_cache im_cache(
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    // inst
    .req_i(if_req),
    .ack_o(if_ack),
    .pc_i(cur_pc),
    .inst_o(if_inst),

    // im master
    .im_req_o(cache_im_req),
    .im_ack_i(cache_im_ack),
    .im_pc_o(cache_im_pc),
    .im_inst_i(cache_im_inst),

    .fence_i(id_fence)
  );

  im_master u_im_master (
      .clk_i (sys_clk),
      .rst_i (sys_rst),
      // inst
      .req_i  (cache_im_req),
      .ack_o  (cache_im_ack),
      .inst_o (cache_im_inst),
      // from mmu
      .phy_addr_i (if_master_phy_addr),
      .mmu_state_i (if_mmu_state),
      .is_mmu_on_i (if_mmu_on),
      .tlb_hit_i (if_tlb_hit),
      // to mmu
      .mmu_ack_o (if_master_ack_mmu),
      .mmu_data_o (if_master_data_mmu),
      // Im => If Master
      .wb_cyc_o (if_cyc_o),
      .wb_stb_o (if_stb_o),
      .wb_ack_i (if_ack_i),
      .wb_adr_o (if_adr_o),
      .wb_dat_o (if_dat_o),
      .wb_dat_i (if_dat_i),
      .wb_sel_o (if_sel_o),
      .wb_we_o  (if_we_o)
  );

  mmu u_im_mmu (
      .clk_i (sys_clk),
      .rst_i (sys_rst),
      .pc_i  (cache_im_pc),
      // from csr
      .priv_i (privilege_o),
      .satp_i (satp_o),
      // from decoder
      // TODO: maybe flush too late ? if id->sfence, should flush immediately
      // TODO: maybe when page fault should stall?  whether write to csr in mem is too late?
    //   .tlb_flush_i (1'b0),
      .tlb_flush_i (ex_tlb_flush),
      // from im_master
      .master_type_i (1'b0), // im
      .master_rw_type_i (2'b00), // default
      .is_requesting_i (if_cyc_o),
      .master_data_i (if_master_data_mmu),
      .master_ack_i (if_master_ack_mmu),
      .ctrl_ack_i (if_ack),
      // from pc_reg
      .vir_addr_i (cache_im_pc),
      // page fault code
      .page_fault_code_o (if_page_fault_code),
      .page_fault_addr_o (if_page_fault_addr),
      // to im_master
      .tlb_hit_o (if_tlb_hit),
      .is_mmu_on_o (if_mmu_on),
      .mmu_state_o (if_mmu_state),
      .phy_addr_o (if_master_phy_addr)
  );

  if_excep_handler u_if_excep_handler(
      // Connect in the signals output by CSR
      .mtvec_in(mtvec_o),
      .mscratch_in(mscratch_o),
      .mepc_in(mepc_o),
      .mcause_in(mcause_o),
      .mstatus_in(mstatus_o),
      .mie_in(mie_o),
      .mip_in(mip_o),
      .priv_in(privilege_o),

      .satp_in(satp_o),
      .mtval_in(mtval_o),
      .mideleg_in(mideleg_o),
      .medeleg_in(medeleg_o),
      .sepc_in(sepc_o),
      .scause_in(scause_o),
      .stval_in(stval_o),
      .stvec_in(stvec_o),
      .sscratch_in(sscratch_o),

      .sstatus_in(sstatus_o),
      .mhartid_in(mhartid_o),
      .sie_in(sie_o),
      .sip_in(sip_o),
      
      // Data out signals
      .mtvec_out(if_mtvec_data_o),
      .mscratch_out(if_mscratch_data_o),
      .mepc_out(if_mepc_data_o),
      .mcause_out(if_mcause_data_o),
      .mstatus_out(if_mstatus_data_o),
      .mie_out(if_mie_data_o),
      .mip_out(if_mip_data_o),
      .priv_out(if_privilege_data_o),

      .satp_out(if_satp_data_o),
      .mtval_out(if_mtval_data_o),
      .mideleg_out(if_mideleg_data_o),
      .medeleg_out(if_medeleg_data_o),
      .sepc_out(if_sepc_data_o),
      .scause_out(if_scause_data_o),
      .stval_out(if_stval_data_o),
      .stvec_out(if_stvec_data_o),
      .sscratch_out(if_sscratch_data_o),

      .sstatus_out(if_sstatus_data_o),
      .mhartid_out(if_mhartid_data_o),
      .sie_out(if_sie_data_o),
      .sip_out(if_sip_data_o),
      
      // WE output signals
      .mtvec_we_out(if_mtvec_we_o),
      .mscratch_we_out(if_mscratch_we_o),
      .mepc_we_out(if_mepc_we_o),
      .mcause_we_out(if_mcause_we_o),
      .mstatus_we_out(if_mstatus_we_o),
      .mie_we_out(if_mie_we_o),
      .mip_we_out(if_mip_we_o),
      .priv_we_out(if_privilege_we_o),

      .satp_we_out(if_satp_we_o),
      .mtval_we_out(if_mtval_we_o),
      .mideleg_we_out(if_mideleg_we_o),
      .medeleg_we_out(if_medeleg_we_o),
      .sepc_we_out(if_sepc_we_o),
      .scause_we_out(if_scause_we_o),
      .stval_we_out(if_stval_we_o),
      .stvec_we_out(if_stvec_we_o),
      .sscratch_we_out(if_sscratch_we_o),

      .page_fault_addr_i (if_page_fault_addr),
      .page_fault_code_i (if_page_fault_code),
      .if_pc_i (cur_pc),
      .sstatus_we_out(if_sstatus_we_o),
      .mhartid_we_out(if_mhartid_we_o),
      .sie_we_out(if_sie_we_o),
      .sip_we_out(if_sip_we_o)
  );
  

  // for if_id_regs
  logic        if_id_regs_hold;
  logic        if_id_regs_bubble;
  
  /* =========== IF Stage end =========== */
  
  if_id_regs u_if_id_regs(
      .clk_i(sys_clk),
      .rst_i(sys_rst),
      
      .if_id_regs_hold_i(if_id_regs_hold),
      .if_id_regs_bubble_i(if_id_regs_bubble),
      
      .pc_i(cur_pc),
      .pc_o(id_pc),
      
      .inst_i(if_inst),
      .inst_o(id_inst),
      
      // CSR passing signals
      // Data in signals
      .mtvec_in(if_mtvec_data_o),
      .mscratch_in(if_mscratch_data_o),
      .mepc_in(if_mepc_data_o),
      .mcause_in(if_mcause_data_o),
      .mstatus_in(if_mstatus_data_o),
      .mie_in(if_mie_data_o),
      .mip_in(if_mip_data_o),
      .priv_in(if_privilege_data_o),

      .satp_in(if_satp_data_o),
      .mtval_in(if_mtval_data_o),
      .mideleg_in(if_mideleg_data_o),
      .medeleg_in(if_medeleg_data_o),
      .sepc_in(if_sepc_data_o),
      .scause_in(if_scause_data_o),
      .stval_in(if_stval_data_o),
      .stvec_in(if_stvec_data_o),
      .sscratch_in(if_sscratch_data_o),

      .sstatus_in(if_sstatus_data_o),
      .mhartid_in(if_mhartid_data_o),
      .sie_in(if_sie_data_o),
      .sip_in(if_sip_data_o),

      // WE in signals
      .mtvec_we_in(if_mtvec_we_o),
      .mscratch_we_in(if_mscratch_we_o),
      .mepc_we_in(if_mepc_we_o),
      .mcause_we_in(if_mcause_we_o),
      .mstatus_we_in(if_mstatus_we_o),
      .mie_we_in(if_mie_we_o),
      .mip_we_in(if_mip_we_o),
      .priv_we_in(if_privilege_we_o),

      .satp_we_in(if_satp_we_o),
      .mtval_we_in(if_mtval_we_o),
      .mideleg_we_in(if_mideleg_we_o),
      .medeleg_we_in(if_medeleg_we_o),
      .sepc_we_in(if_sepc_we_o),
      .scause_we_in(if_scause_we_o),
      .stval_we_in(if_stval_we_o),
      .stvec_we_in(if_stvec_we_o),
      .sscratch_we_in(if_sscratch_we_o),

      .sstatus_we_in(if_sstatus_we_o),
      .mhartid_we_in(if_mhartid_we_o),
      .sie_we_in(if_sie_we_o),
      .sip_we_in(if_sip_we_o),
      
      // Data out signals
      .mtvec_out(id_mtvec_data_i),
      .mscratch_out(id_mscratch_data_i),
      .mepc_out(id_mepc_data_i),
      .mcause_out(id_mcause_data_i),
      .mstatus_out(id_mstatus_data_i),
      .mie_out(id_mie_data_i),
      .mip_out(id_mip_data_i),
      .priv_out(id_privilege_data_i),

      .satp_out(id_satp_data_i),
      .mtval_out(id_mtval_data_i),
      .mideleg_out(id_mideleg_data_i),
      .medeleg_out(id_medeleg_data_i),
      .sepc_out(id_sepc_data_i),
      .scause_out(id_scause_data_i),
      .stval_out(id_stval_data_i),
      .stvec_out(id_stvec_data_i),
      .sscratch_out(id_sscratch_data_i),

      .sstatus_out(id_sstatus_data_i),
      .mhartid_out(id_mhartid_data_i),
      .sie_out(id_sie_data_i),
      .sip_out(id_sip_data_i),
      
      // WE output signals
      .mtvec_we_out(id_mtvec_we_i),
      .mscratch_we_out(id_mscratch_we_i),
      .mepc_we_out(id_mepc_we_i),
      .mcause_we_out(id_mcause_we_i),
      .mstatus_we_out(id_mstatus_we_i),
      .mie_we_out(id_mie_we_i),
      .mip_we_out(id_mip_we_i),
      .priv_we_out(id_privilege_we_i),

      .satp_we_out(id_satp_we_i),
      .mtval_we_out(id_mtval_we_i),
      .mideleg_we_out(id_mideleg_we_i),
      .medeleg_we_out(id_medeleg_we_i),
      .sepc_we_out(id_sepc_we_i),
      .scause_we_out(id_scause_we_i),
      .stval_we_out(id_stval_we_i),
      .stvec_we_out(id_stvec_we_i),
      .sscratch_we_out(id_sscratch_we_i),

      .sstatus_we_out(id_sstatus_we_i),
      .mhartid_we_out(id_mhartid_we_i),
      .sie_we_out(id_sie_we_i),
      .sip_we_out(id_sip_we_i)
  );

  logic id_mtvec_we_i;
  logic id_mscratch_we_i;
  logic id_mepc_we_i;
  logic id_mcause_we_i;
  logic id_mstatus_we_i;
  logic id_mie_we_i;
  logic id_mip_we_i;
  logic id_privilege_we_i;

  logic id_satp_we_i;
  logic id_mtval_we_i;
  logic id_mideleg_we_i;
  logic id_medeleg_we_i;
  logic id_sepc_we_i;
  logic id_scause_we_i;
  logic id_stval_we_i;
  logic id_stvec_we_i;
  logic id_sscratch_we_i;

  logic id_sstatus_we_i;
  logic id_mhartid_we_i;
  logic id_sie_we_i;
  logic id_sip_we_i;

  logic [31:0] id_mtvec_data_i;
  logic [31:0] id_mscratch_data_i;
  logic [31:0] id_mepc_data_i;
  logic [31:0] id_mcause_data_i;
  logic [31:0] id_mstatus_data_i;
  logic [31:0] id_mie_data_i;
  logic [31:0] id_mip_data_i;
  logic [1:0] id_privilege_data_i;
  
  logic [31:0] id_satp_data_i;
  logic [31:0] id_mtval_data_i;
  logic [31:0] id_mideleg_data_i;
  logic [31:0] id_medeleg_data_i;
  logic [31:0] id_sepc_data_i;
  logic [31:0] id_scause_data_i;
  logic [31:0] id_stval_data_i;
  logic [31:0] id_stvec_data_i;
  logic [31:0] id_sscratch_data_i;

  logic [31:0] id_sstatus_data_i;
  logic [31:0] id_mhartid_data_i;
  logic [31:0] id_sie_data_i;
  logic [31:0] id_sip_data_i;

  logic id_mtvec_we_o;
  logic id_mscratch_we_o;
  logic id_mepc_we_o;
  logic id_mcause_we_o;
  logic id_mstatus_we_o;
  logic id_mie_we_o;
  logic id_mip_we_o;
  logic id_privilege_we_o;

  logic id_satp_we_o;
  logic id_mtval_we_o;
  logic id_mideleg_we_o;
  logic id_medeleg_we_o;
  logic id_sepc_we_o;
  logic id_scause_we_o;
  logic id_stval_we_o;
  logic id_stvec_we_o;
  logic id_sscratch_we_o;

  logic id_sstatus_we_o;
  logic id_mhartid_we_o;
  logic id_sie_we_o;
  logic id_sip_we_o;

  logic [31:0] id_mtvec_data_o;
  logic [31:0] id_mscratch_data_o;
  logic [31:0] id_mepc_data_o;
  logic [31:0] id_mcause_data_o;
  logic [31:0] id_mstatus_data_o;
  logic [31:0] id_mie_data_o;
  logic [31:0] id_mip_data_o;
  logic [1:0] id_privilege_data_o;
  
  logic [31:0] id_satp_data_o;
  logic [31:0] id_mtval_data_o;
  logic [31:0] id_mideleg_data_o;
  logic [31:0] id_medeleg_data_o;
  logic [31:0] id_sepc_data_o;
  logic [31:0] id_scause_data_o;
  logic [31:0] id_stval_data_o;
  logic [31:0] id_stvec_data_o;
  logic [31:0] id_sscratch_data_o;

  logic [31:0] id_sstatus_data_o;
  logic [31:0] id_mhartid_data_o;
  logic [31:0] id_sie_data_o;
  logic [31:0] id_sip_data_o;
  
  /* =========== ID Stage start =========== */
  
  // for decoder
  logic [31:0] id_pc;
  logic [31:0] id_inst;
  logic id_time_int;
  
  logic        id_rf_wen;
  logic [4:0]  id_rd_addr;
  logic [4:0]  id_rs1_addr;
  logic [4:0]  id_rs2_addr;
  logic [31:0] id_rs1_data;
  logic [31:0] id_rs2_data;
  
  logic        id_alu_a_sel;
  logic        id_alu_b_sel;
  logic [3:0]  id_alu_op;
  
  logic [2:0]  id_imm_sel;
  logic [3:0]  id_br_op;
  logic [2:0]  id_wb_sel;
  logic [4:0]  id_shamt;
  
  logic [3:0]  id_dm_sel;
  logic [1:0]  id_dm_op;

  logic id_tlb_flush;

  logic [31:0] id_direct_branch_addr;
  logic [3:0] id_csr_code;

  logic id_fence;
  
  decoder u_decoder (
      .inst_i     (id_inst),
      .time_int_i (id_time_int),
      .page_fault_i ((if_page_fault_code != 2'b00) || (mem_page_fault_code != 2'b00)),
      
      .rd_addr_o  (id_rd_addr),
      .rf_wen_o   (id_rf_wen),
      .rs1_addr_o (id_rs1_addr),
      .rs2_addr_o (id_rs2_addr),
      
      .alu_a_sel_o (id_alu_a_sel),
      .alu_b_sel_o (id_alu_b_sel),
      .alu_op_o    (id_alu_op),
      
      .imm_sel_o (id_imm_sel),
      .wb_sel_o  (id_wb_sel),
      .br_op_o   (id_br_op),
      .shamt_o   (id_shamt),
      
      .dm_sel_o  (id_dm_sel),
      .dm_op_o   (id_dm_op),

      .tlb_flush_o (id_tlb_flush),
      .fence_o(id_fence)
  );
  
  // RF
  regfile u_regfile (
      .clk (sys_clk),
      .reset (sys_rst),
      
      .rf_rdata_a (id_rs1_data),
      .rf_rdata_b (id_rs2_data),
      .rf_raddr_a (id_rs1_addr),
      .rf_raddr_b (id_rs2_addr),
      
      .rf_waddr (wb_rd_addr),
      .rf_wdata (wb_wb_data),
      .rf_wen (wb_rf_wen)
  );

  id_excep_handler u_id_excep_handler(
      .inst_i(id_inst),
      .time_int_o(id_time_int),

      // Input from CSR
      .csr_mtvec_in(mtvec_o),
      .csr_mscratch_in(mscratch_o),
      .csr_mepc_in(mepc_o),
      .csr_mcause_in(mcause_o),
      .csr_mstatus_in(mstatus_o),
      .csr_mie_in(mie_o),
      .csr_mip_in(mip_o),
      .csr_priv_in(privilege_o),

      .csr_satp_in(satp_o),
      .csr_mtval_in(mtval_o),
      .csr_mideleg_in(mideleg_o),
      .csr_medeleg_in(medeleg_o),
      .csr_sepc_in(sepc_o),
      .csr_scause_in(scause_o),
      .csr_stval_in(stval_o),
      .csr_stvec_in(stvec_o),
      .csr_sscratch_in(sscratch_o),

      .csr_sstatus_in(sstatus_o),
      .csr_mhartid_in(mhartid_o),
      .csr_sie_in(sie_o),
      .csr_sip_in(sip_o),

      // Input from EXE
      .exe_mtvec_in(exe_mtvec_data_o),
      .exe_mscratch_in(exe_mscratch_data_o),
      .exe_mepc_in(exe_mepc_data_o),
      .exe_mcause_in(exe_mcause_data_o),
      .exe_mstatus_in(exe_mstatus_data_o),
      .exe_mie_in(exe_mie_data_o),
      .exe_mip_in(exe_mip_data_o),
      .exe_priv_in(exe_privilege_data_o),

      .exe_satp_in(exe_satp_data_o),
      .exe_mtval_in(exe_mtval_data_o),
      .exe_mideleg_in(exe_mideleg_data_o),
      .exe_medeleg_in(exe_medeleg_data_o),
      .exe_sepc_in(exe_sepc_data_o),
      .exe_scause_in(exe_scause_data_o),
      .exe_stval_in(exe_stval_data_o),
      .exe_stvec_in(exe_stvec_data_o),
      .exe_sscratch_in(exe_sscratch_data_o),

      .exe_sstatus_in(exe_sstatus_data_o),
      .exe_mhartid_in(exe_mhartid_data_o),
      .exe_sie_in(exe_sie_data_o),
      .exe_sip_in(exe_sip_data_o),
      
      .exe_mtvec_we_in(exe_mtvec_we_o),
      .exe_mscratch_we_in(exe_mscratch_we_o),
      .exe_mepc_we_in(exe_mepc_we_o),
      .exe_mcause_we_in(exe_mcause_we_o),
      .exe_mstatus_we_in(exe_mstatus_we_o),
      .exe_mie_we_in(exe_mie_we_o),
      .exe_mip_we_in(exe_mip_we_o),
      .exe_priv_we_in(exe_privilege_we_o),

      .exe_satp_we_in(exe_satp_we_o),
      .exe_mtval_we_in(exe_mtval_we_o),
      .exe_mideleg_we_in(exe_mideleg_we_o),
      .exe_medeleg_we_in(exe_medeleg_we_o),
      .exe_sepc_we_in(exe_sepc_we_o),
      .exe_scause_we_in(exe_scause_we_o),
      .exe_stval_we_in(exe_stval_we_o),
      .exe_stvec_we_in(exe_stvec_we_o),
      .exe_sscratch_we_in(exe_sscratch_we_o),

      .exe_sstatus_we_in(exe_sstatus_we_o),
      .exe_mhartid_we_in(exe_mhartid_we_o),
      .exe_sie_we_in(exe_sie_we_o),
      .exe_sip_we_in(exe_sip_we_o),

      // Normal In-out Signals
      // Data in signals
      .mtvec_in(id_mtvec_data_i),
      .mscratch_in(id_mscratch_data_i),
      .mepc_in(id_mepc_data_i),
      .mcause_in(id_mcause_data_i),
      .mstatus_in(id_mstatus_data_i),
      .mie_in(id_mie_data_i),
      .mip_in(id_mip_data_i),
      .priv_in(id_privilege_data_i),

      .satp_in(id_satp_data_i),
      .mtval_in(id_mtval_data_i),
      .mideleg_in(id_mideleg_data_i),
      .medeleg_in(id_medeleg_data_i),
      .sepc_in(id_sepc_data_i),
      .scause_in(id_scause_data_i),
      .stval_in(id_stval_data_i),
      .stvec_in(id_stvec_data_i),
      .sscratch_in(id_sscratch_data_i),

      .sstatus_in(id_sstatus_data_i),
      .mhartid_in(id_mhartid_data_i),
      .sie_in(id_sie_data_i),
      .sip_in(id_sip_data_i),
      
      // Data out signals
      .mtvec_out(id_mtvec_data_o),
      .mscratch_out(id_mscratch_data_o),
      .mepc_out(id_mepc_data_o),
      .mcause_out(id_mcause_data_o),
      .mstatus_out(id_mstatus_data_o),
      .mie_out(id_mie_data_o),
      .mip_out(id_mip_data_o),
      .priv_out(id_privilege_data_o),

      .satp_out(id_satp_data_o),
      .mtval_out(id_mtval_data_o),
      .mideleg_out(id_mideleg_data_o),
      .medeleg_out(id_medeleg_data_o),
      .sepc_out(id_sepc_data_o),
      .scause_out(id_scause_data_o),
      .stval_out(id_stval_data_o),
      .stvec_out(id_stvec_data_o),
      .sscratch_out(id_sscratch_data_o),

      .sstatus_out(id_sstatus_data_o),
      .mhartid_out(id_mhartid_data_o),
      .sie_out(id_sie_data_o),
      .sip_out(id_sip_data_o),

      // WE in signals
      .mtvec_we_in(id_mtvec_we_i),
      .mscratch_we_in(id_mscratch_we_i),
      .mepc_we_in(id_mepc_we_i),
      .mcause_we_in(id_mcause_we_i),
      .mstatus_we_in(id_mstatus_we_i),
      .mie_we_in(id_mie_we_i),
      .mip_we_in(id_mip_we_i),
      .priv_we_in(id_privilege_we_i),

      .satp_we_in(id_satp_we_i),
      .mtval_we_in(id_mtval_we_i),
      .mideleg_we_in(id_mideleg_we_i),
      .medeleg_we_in(id_medeleg_we_i),
      .sepc_we_in(id_sepc_we_i),
      .scause_we_in(id_scause_we_i),
      .stval_we_in(id_stval_we_i),
      .stvec_we_in(id_stvec_we_i),
      .sscratch_we_in(id_sscratch_we_i),

      .sstatus_we_in(id_sstatus_we_i),
      .mhartid_we_in(id_mhartid_we_i),
      .sie_we_in(id_sie_we_i),
      .sip_we_in(id_sip_we_i),
      
      // WE out signals
      .mtvec_we_out(id_mtvec_we_o),
      .mscratch_we_out(id_mscratch_we_o),
      .mepc_we_out(id_mepc_we_o),
      .mcause_we_out(id_mcause_we_o),
      .mstatus_we_out(id_mstatus_we_o),
      .mie_we_out(id_mie_we_o),
      .mip_we_out(id_mip_we_o),
      .priv_we_out(id_privilege_we_o),

      .satp_we_out(id_satp_we_o),
      .mtval_we_out(id_mtval_we_o),
      .mideleg_we_out(id_mideleg_we_o),
      .medeleg_we_out(id_medeleg_we_o),
      .sepc_we_out(id_sepc_we_o),
      .scause_we_out(id_scause_we_o),
      .stval_we_out(id_stval_we_o),
      .stvec_we_out(id_stvec_we_o),
      .sscratch_we_out(id_sscratch_we_o),

      .sstatus_we_out(id_sstatus_we_o),
      .mhartid_we_out(id_mhartid_we_o),
      .sie_we_out(id_sie_we_o),
      .sip_we_out(id_sip_we_o),
      
      // Other signals
      .if_page_fault_code_i (if_page_fault_code),
      .mem_page_fault_code_i (mem_page_fault_code),
      .direct_branch_addr(id_direct_branch_addr),
      .csr_code(id_csr_code)
  );

  /* =========== ID Stage end =========== */
  
  // for id_exe_regs
  logic id_exe_regs_hold;
  logic id_exe_regs_bubble;
  
  id_exe_regs u_id_exe_regs (
      .clk (sys_clk),
      .reset (sys_rst),
      .id_exe_regs_hold_i (id_exe_regs_hold),
      .id_exe_regs_bubble_i (id_exe_regs_bubble),
      
      .pc_i (id_pc),
      .pc_o (exe_pc),
      .inst_i (id_inst),
      .inst_o (exe_inst),
      
      .rd_addr_i (id_rd_addr),
      .rd_addr_o (exe_rd_addr),
      .rs1_addr_i (id_rs1_addr),
      .rs1_addr_o (exe_rs1_addr),
      .rs2_addr_i (id_rs2_addr),
      .rs2_addr_o (exe_rs2_addr),
      
      .rs1_data_i (id_rs1_data),
      .rs1_data_o (ori_rs1_data),
      .rs2_data_i (id_rs2_data),
      .rs2_data_o (ori_rs2_data),
      
      .imm_sel_i (id_imm_sel),
      .imm_sel_o (exe_imm_sel),
      .alu_a_sel_i (id_alu_a_sel),
      .alu_a_sel_o (exe_alu_a_sel),
      .alu_b_sel_i (id_alu_b_sel),
      .alu_b_sel_o (exe_alu_b_sel),
      .alu_op_i (id_alu_op),
      .alu_op_o (exe_alu_op),
      
      .shamt_i (id_shamt),
      .shamt_o (exe_shamt),
      
      .br_op_i (id_br_op),
      .br_op_o (exe_br_op),
      
      .rf_wen_i (id_rf_wen),
      .rf_wen_o (exe_rf_wen),
      
      .wb_sel_i (id_wb_sel),
      .wb_sel_o (exe_wb_sel),
      
      .dm_sel_i (id_dm_sel),
      .dm_sel_o (exe_dm_sel),
      .dm_op_i (id_dm_op),
      .dm_op_o (exe_dm_op),

      // CSR passing signals
      // Data in signals
      .mtvec_in(id_mtvec_data_o),
      .mscratch_in(id_mscratch_data_o),
      .mepc_in(id_mepc_data_o),
      .mcause_in(id_mcause_data_o),
      .mstatus_in(id_mstatus_data_o),
      .mie_in(id_mie_data_o),
      .mip_in(id_mip_data_o),
      .priv_in(id_privilege_data_o),

      .satp_in(id_satp_data_o),
      .mtval_in(id_mtval_data_o),
      .mideleg_in(id_mideleg_data_o),
      .medeleg_in(id_medeleg_data_o),
      .sepc_in(id_sepc_data_o),
      .scause_in(id_scause_data_o),
      .stval_in(id_stval_data_o),
      .stvec_in(id_stvec_data_o),
      .sscratch_in(id_sscratch_data_o),

      .sstatus_in(id_sstatus_data_o),
      .mhartid_in(id_mhartid_data_o),
      .sie_in(id_sie_data_o),
      .sip_in(id_sip_data_o),

      // WE in signals
      .mtvec_we_in(id_mtvec_we_o),
      .mscratch_we_in(id_mscratch_we_o),
      .mepc_we_in(id_mepc_we_o),
      .mcause_we_in(id_mcause_we_o),
      .mstatus_we_in(id_mstatus_we_o),
      .mie_we_in(id_mie_we_o),
      .mip_we_in(id_mip_we_o),
      .priv_we_in(id_privilege_we_o),

      .satp_we_in(id_satp_we_o),
      .mtval_we_in(id_mtval_we_o),
      .mideleg_we_in(id_mideleg_we_o),
      .medeleg_we_in(id_medeleg_we_o),
      .sepc_we_in(id_sepc_we_o),
      .scause_we_in(id_scause_we_o),
      .stval_we_in(id_stval_we_o),
      .stvec_we_in(id_stvec_we_o),
      .sscratch_we_in(id_sscratch_we_o),

      .sstatus_we_in(id_sstatus_we_o),
      .mhartid_we_in(id_mhartid_we_o),
      .sie_we_in(id_sie_we_o),
      .sip_we_in(id_sip_we_o),
      
      // Data out signals
      .mtvec_out(exe_mtvec_data_i),
      .mscratch_out(exe_mscratch_data_i),
      .mepc_out(exe_mepc_data_i),
      .mcause_out(exe_mcause_data_i),
      .mstatus_out(exe_mstatus_data_i),
      .mie_out(exe_mie_data_i),
      .mip_out(exe_mip_data_i),
      .priv_out(exe_privilege_data_i),

      .satp_out(exe_satp_data_i),
      .mtval_out(exe_mtval_data_i),
      .mideleg_out(exe_mideleg_data_i),
      .medeleg_out(exe_medeleg_data_i),
      .sepc_out(exe_sepc_data_i),
      .scause_out(exe_scause_data_i),
      .stval_out(exe_stval_data_i),
      .stvec_out(exe_stvec_data_i),
      .sscratch_out(exe_sscratch_data_i),

      .sstatus_out(exe_sstatus_data_i),
      .mhartid_out(exe_mhartid_data_i),
      .sie_out(exe_sie_data_i),
      .sip_out(exe_sip_data_i),
      
      // WE output signals
      .mtvec_we_out(exe_mtvec_we_i),
      .mscratch_we_out(exe_mscratch_we_i),
      .mepc_we_out(exe_mepc_we_i),
      .mcause_we_out(exe_mcause_we_i),
      .mstatus_we_out(exe_mstatus_we_i),
      .mie_we_out(exe_mie_we_i),
      .mip_we_out(exe_mip_we_i),
      .priv_we_out(exe_privilege_we_i),

      .satp_we_out(exe_satp_we_i),
      .mtval_we_out(exe_mtval_we_i),
      .mideleg_we_out(exe_mideleg_we_i),
      .medeleg_we_out(exe_medeleg_we_i),
      .sepc_we_out(exe_sepc_we_i),
      .scause_we_out(exe_scause_we_i),
      .stval_we_out(exe_stval_we_i),
      .stvec_we_out(exe_stvec_we_i),
      .sscratch_we_out(exe_sscratch_we_i),

      .sstatus_we_out(exe_sstatus_we_i),
      .mhartid_we_out(exe_mhartid_we_i),
      .sie_we_out(exe_sie_we_i),
      .sip_we_out(exe_sip_we_i),
      
      // Other signals
      .id_csr_code(id_csr_code),
      .ex_csr_code(ex_csr_code),
      .id_tlb_flush(id_tlb_flush),
      .ex_tlb_flush(ex_tlb_flush),
      .id_direct_branch_addr(id_direct_branch_addr),
      .ex_direct_branch_addr(ex_direct_branch_addr),
      .id_fence(id_fence),
      .exe_fence(exe_fence)
  );
  
  logic exe_mtvec_we_i;
  logic exe_mscratch_we_i;
  logic exe_mepc_we_i;
  logic exe_mcause_we_i;
  logic exe_mstatus_we_i;
  logic exe_mie_we_i;
  logic exe_mip_we_i;
  logic exe_privilege_we_i;

  logic exe_satp_we_i;
  logic exe_mtval_we_i;
  logic exe_mideleg_we_i;
  logic exe_medeleg_we_i;
  logic exe_sepc_we_i;
  logic exe_scause_we_i;
  logic exe_stval_we_i;
  logic exe_stvec_we_i;
  logic exe_sscratch_we_i;

  logic exe_sstatus_we_i;
  logic exe_mhartid_we_i;
  logic exe_sie_we_i;
  logic exe_sip_we_i;

  logic [31:0] exe_mtvec_data_i;
  logic [31:0] exe_mscratch_data_i;
  logic [31:0] exe_mepc_data_i;
  logic [31:0] exe_mcause_data_i;
  logic [31:0] exe_mstatus_data_i;
  logic [31:0] exe_mie_data_i;
  logic [31:0] exe_mip_data_i;
  logic [1:0] exe_privilege_data_i;
  
  logic [31:0] exe_satp_data_i;
  logic [31:0] exe_mtval_data_i;
  logic [31:0] exe_mideleg_data_i;
  logic [31:0] exe_medeleg_data_i;
  logic [31:0] exe_sepc_data_i;
  logic [31:0] exe_scause_data_i;
  logic [31:0] exe_stval_data_i;
  logic [31:0] exe_stvec_data_i;
  logic [31:0] exe_sscratch_data_i;

  logic [31:0] exe_sstatus_data_i;
  logic [31:0] exe_mhartid_data_i;
  logic [31:0] exe_sie_data_i;
  logic [31:0] exe_sip_data_i;

  logic exe_mtvec_we_o;
  logic exe_mscratch_we_o;
  logic exe_mepc_we_o;
  logic exe_mcause_we_o;
  logic exe_mstatus_we_o;
  logic exe_mie_we_o;
  logic exe_mip_we_o;
  logic exe_privilege_we_o;

  logic exe_satp_we_o;
  logic exe_mtval_we_o;
  logic exe_mideleg_we_o;
  logic exe_medeleg_we_o;
  logic exe_sepc_we_o;
  logic exe_scause_we_o;
  logic exe_stval_we_o;
  logic exe_stvec_we_o;
  logic exe_sscratch_we_o;

  logic exe_sstatus_we_o;
  logic exe_mhartid_we_o;
  logic exe_sie_we_o;
  logic exe_sip_we_o;

  logic [31:0] exe_mtvec_data_o;
  logic [31:0] exe_mscratch_data_o;
  logic [31:0] exe_mepc_data_o;
  logic [31:0] exe_mcause_data_o;
  logic [31:0] exe_mstatus_data_o;
  logic [31:0] exe_mie_data_o;
  logic [31:0] exe_mip_data_o;
  logic [1:0] exe_privilege_data_o;
  
  logic [31:0] exe_satp_data_o;
  logic [31:0] exe_mtval_data_o;
  logic [31:0] exe_mideleg_data_o;
  logic [31:0] exe_medeleg_data_o;
  logic [31:0] exe_sepc_data_o;
  logic [31:0] exe_scause_data_o;
  logic [31:0] exe_stval_data_o;
  logic [31:0] exe_stvec_data_o;
  logic [31:0] exe_sscratch_data_o;

  logic [31:0] exe_sstatus_data_o;
  logic [31:0] exe_mhartid_data_o;
  logic [31:0] exe_sie_data_o;
  logic [31:0] exe_sip_data_o;

  logic exe_fence;

  /* =========== Exe Stage start =========== */
  
  // for exe
  logic [31:0] exe_pc;   
  logic [31:0] exe_inst;
  
  logic        exe_rf_wen;
  logic [4:0]  exe_rd_addr;
  logic [4:0]  exe_rs1_addr;
  logic [4:0]  exe_rs2_addr;
  logic [31:0] exe_rs1_data;
  logic [31:0] exe_rs2_data;
 
  logic [2:0]  exe_imm_sel;
  logic [31:0] exe_imm;
  
  logic        exe_br_eq;
  logic [3:0]  exe_br_op;
  logic        exe_is_branch;
  
  logic [2:0]  exe_wb_sel;
  logic [4:0]  exe_shamt;
  
  logic [1:0]  exe_dm_op;
  logic [3:0]  exe_dm_sel;
  
  logic        exe_alu_a_sel;
  logic        exe_alu_b_sel;
  logic [3:0]  exe_alu_op;
  logic [31:0] exe_alu_a;
  logic [31:0] exe_alu_b;
  logic [31:0] exe_alu_y;
  
  logic [1:0] rs1_sel;
  logic [1:0] rs2_sel;
  logic [31:0] ori_rs1_data;
  logic [31:0] ori_rs2_data;

  logic [31:0] exe_direct_out; // used in rs1 / rs2 comparation

  logic [31:0] ex_direct_branch_addr;
  logic [3:0] ex_csr_code;
  logic        ex_tlb_flush;

  logic [31:0] exe_csr_data;

  ex_excep_handler u_ex_excep_handler(
      // Data in signals
      .mtvec_in(exe_mtvec_data_i),
      .mscratch_in(exe_mscratch_data_i),
      .mepc_in(exe_mepc_data_i),
      .mcause_in(exe_mcause_data_i),
      .mstatus_in(exe_mstatus_data_i),
      .mie_in(exe_mie_data_i),
      .mip_in(exe_mip_data_i),
      .priv_in(exe_privilege_data_i),

      .satp_in(exe_satp_data_i),
      .mtval_in(exe_mtval_data_i),
      .mideleg_in(exe_mideleg_data_i),
      .medeleg_in(exe_medeleg_data_i),
      .sepc_in(exe_sepc_data_i),
      .scause_in(exe_scause_data_i),
      .stval_in(exe_stval_data_i),
      .stvec_in(exe_stvec_data_i),
      .sscratch_in(exe_sscratch_data_i),

      .sstatus_in(exe_sstatus_data_i),
      .mhartid_in(exe_mhartid_data_i),
      .sie_in(exe_sie_data_i),
      .sip_in(exe_sip_data_i),
      
      // Data out signals
      .mtvec_out(exe_mtvec_data_o),
      .mscratch_out(exe_mscratch_data_o),
      .mepc_out(exe_mepc_data_o),
      .mcause_out(exe_mcause_data_o),
      .mstatus_out(exe_mstatus_data_o),
      .mie_out(exe_mie_data_o),
      .mip_out(exe_mip_data_o),
      .priv_out(exe_privilege_data_o),

      .satp_out(exe_satp_data_o),
      .mtval_out(exe_mtval_data_o),
      .mideleg_out(exe_mideleg_data_o),
      .medeleg_out(exe_medeleg_data_o),
      .sepc_out(exe_sepc_data_o),
      .scause_out(exe_scause_data_o),
      .stval_out(exe_stval_data_o),
      .stvec_out(exe_stvec_data_o),
      .sscratch_out(exe_sscratch_data_o),

      .sstatus_out(exe_sstatus_data_o),
      .mhartid_out(exe_mhartid_data_o),
      .sie_out(exe_sie_data_o),
      .sip_out(exe_sip_data_o),

      // WE in signals
      .mtvec_we_in(exe_mtvec_we_i),
      .mscratch_we_in(exe_mscratch_we_i),
      .mepc_we_in(exe_mepc_we_i),
      .mcause_we_in(exe_mcause_we_i),
      .mstatus_we_in(exe_mstatus_we_i),
      .mie_we_in(exe_mie_we_i),
      .mip_we_in(exe_mip_we_i),
      .priv_we_in(exe_privilege_we_i),

      .satp_we_in(exe_satp_we_i),
      .mtval_we_in(exe_mtval_we_i),
      .mideleg_we_in(exe_mideleg_we_i),
      .medeleg_we_in(exe_medeleg_we_i),
      .sepc_we_in(exe_sepc_we_i),
      .scause_we_in(exe_scause_we_i),
      .stval_we_in(exe_stval_we_i),
      .stvec_we_in(exe_stvec_we_i),
      .sscratch_we_in(exe_sscratch_we_i),

      .sstatus_we_in(exe_sstatus_we_i),
      .mhartid_we_in(exe_mhartid_we_i),
      .sie_we_in(exe_sie_we_i),
      .sip_we_in(exe_sip_we_i),
      
      // WE out signals
      .mtvec_we_out(exe_mtvec_we_o),
      .mscratch_we_out(exe_mscratch_we_o),
      .mepc_we_out(exe_mepc_we_o),
      .mcause_we_out(exe_mcause_we_o),
      .mstatus_we_out(exe_mstatus_we_o),
      .mie_we_out(exe_mie_we_o),
      .mip_we_out(exe_mip_we_o),
      .priv_we_out(exe_privilege_we_o),

      .satp_we_out(exe_satp_we_o),
      .mtval_we_out(exe_mtval_we_o),
      .mideleg_we_out(exe_mideleg_we_o),
      .medeleg_we_out(exe_medeleg_we_o),
      .sepc_we_out(exe_sepc_we_o),
      .scause_we_out(exe_scause_we_o),
      .stval_we_out(exe_stval_we_o),
      .stvec_we_out(exe_stvec_we_o),
      .sscratch_we_out(exe_sscratch_we_o),

      .sstatus_we_out(exe_sstatus_we_o),
      .mhartid_we_out(exe_mhartid_we_o),
      .sie_we_out(exe_sie_we_o),
      .sip_we_out(exe_sip_we_o),
      
      // Other signals
      .csr_code_in(ex_csr_code),
      .data_out(exe_csr_data),

      .exe_rs1_data(exe_rs1_data),
      .exe_inst(exe_inst),
      .exe_pc(exe_pc),

      .time_in(mtime)
  );

  rs_mux u_rs1_mux(
      .rs_sel(rs1_sel),
      .exe_rs_data(ori_rs1_data),
      .mem_rs_data(mem_wb_data),
      .wb_rs_data(wb_wb_data),
      .exe_data_o(exe_rs1_data)
  );

  rs_mux u_rs2_mux(
      .rs_sel(rs2_sel),
      .exe_rs_data(ori_rs2_data),
      .mem_rs_data(mem_wb_data),
      .wb_rs_data(wb_wb_data),
      .exe_data_o(exe_rs2_data)
  );

  forward_unit u_forward_unit(
      .exe_rs1_addr(exe_rs1_addr),
      .exe_rs2_addr(exe_rs2_addr),
      .mem_rd_addr(mem_rd_addr),
      .wb_rd_addr(wb_rd_addr),

      .mem_rf_wen(mem_rf_wen),
      .wb_rf_wen(wb_rf_wen),

      .rs1_data_sel(rs1_sel),
      .rs2_data_sel(rs2_sel)
  );
  
  imm_generator u_imm_generator(
      .inst_i (exe_inst),
      .imm_sel_i (exe_imm_sel),
      .direct_out_i (exe_direct_out),
      .imm_o (exe_imm)
  );
  
  rscomp u_rscomp (
      .a_i (exe_rs1_data),
      .b_i (exe_rs2_data),
      .inst_i (exe_inst),
      .direct_out_o (exe_direct_out)
  );

  bcomp u_bcomp (
      .a_i (exe_rs1_data),
      .b_i (exe_rs2_data),
      .br_op_i (exe_br_op),
      .if_br_o (exe_br_eq)
  );
  
  // BTB_branch_decider
  BTB_branch_decider btb_branch_decider(
    .br_op_i(exe_br_op),
    .is_branch_o(exe_is_branch)
  );

  // ALU related modules
  ALU_a_mux u_alu_a_mux (
      .pc_i (exe_pc),
      .rs1_data_i (exe_rs1_data),
      .alu_a_sel_i (exe_alu_a_sel),
      .alu_a_o (exe_alu_a)
  );
  
  ALU_b_mux u_alu_b_mux (
      .imm_i (exe_imm),
      .rs2_data_i (exe_rs2_data),
      .alu_b_sel_i (exe_alu_b_sel),
      .alu_b_o (exe_alu_b)
  );
  
  ALU u_alu(
      .alu_a (exe_alu_a),
      .alu_b (exe_alu_b),
      .alu_y (exe_alu_y),
      .alu_op (exe_alu_op)
  );

  /* =========== Exe Stage end =========== */
  
  logic  exe_mem_regs_hold;
  logic  exe_mem_regs_bubble;

  exe_mem_regs u_exe_mem_regs(
      .clk (sys_clk),
      .reset (sys_rst),
      .exe_mem_regs_hold_i (exe_mem_regs_hold),
      .exe_mem_regs_bubble_i (exe_mem_regs_bubble),
      
      .pc_i (exe_pc),
      .pc_o (mem_pc),
      .inst_i (exe_inst),
      .inst_o (mem_inst),
      
      .alu_y_i (exe_alu_y),
      .alu_y_o (mem_alu_y),
      
      .rs2_data_i (exe_rs2_data),
      .rs2_data_o (mem_rs2_data),
      .rd_addr_i (exe_rd_addr),
      .rd_addr_o (mem_rd_addr),
      
      .dm_op_i (exe_dm_op),
      .dm_op_o (mem_dm_op),
      .dm_sel_i (exe_dm_sel),
      .dm_sel_o (mem_dm_sel),
      
      .rf_wen_i (exe_rf_wen),
      .rf_wen_o (mem_rf_wen),
      
      .wb_sel_i (exe_wb_sel),
      .wb_sel_o (mem_wb_sel),

      // CSR passing signals
      // Data in signals
      .mtvec_in(exe_mtvec_data_o),
      .mscratch_in(exe_mscratch_data_o),
      .mepc_in(exe_mepc_data_o),
      .mcause_in(exe_mcause_data_o),
      .mstatus_in(exe_mstatus_data_o),
      .mie_in(exe_mie_data_o),
      .mip_in(exe_mip_data_o),
      .priv_in(exe_privilege_data_o),

      .satp_in(exe_satp_data_o),
      .mtval_in(exe_mtval_data_o),
      .mideleg_in(exe_mideleg_data_o),
      .medeleg_in(exe_medeleg_data_o),
      .sepc_in(exe_sepc_data_o),
      .scause_in(exe_scause_data_o),
      .stval_in(exe_stval_data_o),
      .stvec_in(exe_stvec_data_o),
      .sscratch_in(exe_sscratch_data_o),

      .sstatus_in(exe_sstatus_data_o),
      .mhartid_in(exe_mhartid_data_o),
      .sie_in(exe_sie_data_o),
      .sip_in(exe_sip_data_o),

      // WE in signals
      .mtvec_we_in(exe_mtvec_we_o),
      .mscratch_we_in(exe_mscratch_we_o),
      .mepc_we_in(exe_mepc_we_o),
      .mcause_we_in(exe_mcause_we_o),
      .mstatus_we_in(exe_mstatus_we_o),
      .mie_we_in(exe_mie_we_o),
      .mip_we_in(exe_mip_we_o),
      .priv_we_in(exe_privilege_we_o),

      .satp_we_in(exe_satp_we_o),
      .mtval_we_in(exe_mtval_we_o),
      .mideleg_we_in(exe_mideleg_we_o),
      .medeleg_we_in(exe_medeleg_we_o),
      .sepc_we_in(exe_sepc_we_o),
      .scause_we_in(exe_scause_we_o),
      .stval_we_in(exe_stval_we_o),
      .stvec_we_in(exe_stvec_we_o),
      .sscratch_we_in(exe_sscratch_we_o),

      .sstatus_we_in(exe_sstatus_we_o),
      .mhartid_we_in(exe_mhartid_we_o),
      .sie_we_in(exe_sie_we_o),
      .sip_we_in(exe_sip_we_o),
      
      // Data out signals
      .mtvec_out(mem_mtvec_data_i),
      .mscratch_out(mem_mscratch_data_i),
      .mepc_out(mem_mepc_data_i),
      .mcause_out(mem_mcause_data_i),
      .mstatus_out(mem_mstatus_data_i),
      .mie_out(mem_mie_data_i),
      .mip_out(mem_mip_data_i),
      .priv_out(mem_privilege_data_i),

      .satp_out(mem_satp_data_i),
      .mtval_out(mem_mtval_data_i),
      .mideleg_out(mem_mideleg_data_i),
      .medeleg_out(mem_medeleg_data_i),
      .sepc_out(mem_sepc_data_i),
      .scause_out(mem_scause_data_i),
      .stval_out(mem_stval_data_i),
      .stvec_out(mem_stvec_data_i),
      .sscratch_out(mem_sscratch_data_i),

      .sstatus_out(mem_sstatus_data_i),
      .mhartid_out(mem_mhartid_data_i),
      .sie_out(mem_sie_data_i),
      .sip_out(mem_sip_data_i),
      
      // WE output signals
      .mtvec_we_out(mem_mtvec_we_i),
      .mscratch_we_out(mem_mscratch_we_i),
      .mepc_we_out(mem_mepc_we_i),
      .mcause_we_out(mem_mcause_we_i),
      .mstatus_we_out(mem_mstatus_we_i),
      .mie_we_out(mem_mie_we_i),
      .mip_we_out(mem_mip_we_i),
      .priv_we_out(mem_privilege_we_i),

      .satp_we_out(mem_satp_we_i),
      .mtval_we_out(mem_mtval_we_i),
      .mideleg_we_out(mem_mideleg_we_i),
      .medeleg_we_out(mem_medeleg_we_i),
      .sepc_we_out(mem_sepc_we_i),
      .scause_we_out(mem_scause_we_i),
      .stval_we_out(mem_stval_we_i),
      .stvec_we_out(mem_stvec_we_i),
      .sscratch_we_out(mem_sscratch_we_i),

      .sstatus_we_out(mem_sstatus_we_i),
      .mhartid_we_out(mem_mhartid_we_i),
      .sie_we_out(mem_sie_we_i),
      .sip_we_out(mem_sip_we_i),
      
      // Other signals
      .csr_data_i (exe_csr_data),
      .csr_data_o (mem_csr_data),

      .exe_fence_i(exe_fence),
      .mem_fence_o(mem_fence)
  );
  
  logic mem_mtvec_we_i;
  logic mem_mscratch_we_i;
  logic mem_mepc_we_i;
  logic mem_mcause_we_i;
  logic mem_mstatus_we_i;
  logic mem_mie_we_i;
  logic mem_mip_we_i;
  logic mem_privilege_we_i;

  logic mem_satp_we_i;
  logic mem_mtval_we_i;
  logic mem_mideleg_we_i;
  logic mem_medeleg_we_i;
  logic mem_sepc_we_i;
  logic mem_scause_we_i;
  logic mem_stval_we_i;
  logic mem_stvec_we_i;
  logic mem_sscratch_we_i;

  logic mem_sstatus_we_i;
  logic mem_mhartid_we_i;
  logic mem_sie_we_i;
  logic mem_sip_we_i;

  logic [31:0] mem_mtvec_data_i;
  logic [31:0] mem_mscratch_data_i;
  logic [31:0] mem_mepc_data_i;
  logic [31:0] mem_mcause_data_i;
  logic [31:0] mem_mstatus_data_i;
  logic [31:0] mem_mie_data_i;
  logic [31:0] mem_mip_data_i;
  logic [1:0] mem_privilege_data_i;
  
  logic [31:0] mem_satp_data_i;
  logic [31:0] mem_mtval_data_i;
  logic [31:0] mem_mideleg_data_i;
  logic [31:0] mem_medeleg_data_i;
  logic [31:0] mem_sepc_data_i;
  logic [31:0] mem_scause_data_i;
  logic [31:0] mem_stval_data_i;
  logic [31:0] mem_stvec_data_i;
  logic [31:0] mem_sscratch_data_i;

  logic [31:0] mem_sstatus_data_i;
  logic [31:0] mem_mhartid_data_i;
  logic [31:0] mem_sie_data_i;
  logic [31:0] mem_sip_data_i;

  logic mem_fence;

  /* =========== Mem Stage start =========== */
  
  logic [31:0] mem_pc;
  logic [31:0] mem_inst;
  
  logic [31:0] mem_alu_y;
  
  logic [31:0] mem_rs2_data;
  logic [4:0]  mem_rd_addr;
  
  logic [1:0]  mem_dm_op;
  logic [3:0]  mem_dm_sel;
  
  logic        mem_rf_wen;
  logic [2:0]  mem_wb_sel;
  
  logic        mem_data_access_ack;
  logic [31:0] mem_data_read;

  logic [31:0] mem_csr_data;

  // for mmu
  logic [31:0] mem_master_data_mmu;
  logic        mem_master_ack_mmu;
  logic [1:0]  mem_mmu_state;
  logic        mem_mmu_on;
  logic        mem_tlb_hit;
  logic [31:0] mem_master_phy_addr;
  logic [1:0]  mem_page_fault_code;
  logic [31:0] mem_page_fault_addr;

  // for dm cache
  logic [1:0] cache_dm_op;
  logic [3:0] cache_dm_sel;
  logic cache_dm_data_access_ack;
  logic [31:0] cache_dm_data_addr;
  logic [31:0] cache_dm_to_dm_data;
  logic [31:0] cache_dm_to_cache_data;
  
  dm_cache dm_cache(
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    // for mem
    .dm_op_i(mem_dm_op),
    .data_access_ack_o(mem_data_access_ack),
    .data_addr_i(mem_alu_y),
    .data_i(mem_rs2_data),
    .data_o(mem_data_read),
    .sel_i(mem_dm_sel),

    // for master
    .dm_op_o(cache_dm_op),
    .sel_o(cache_dm_sel),
    .dm_data_access_ack_i(cache_dm_data_access_ack),
    .dm_data_addr_o(cache_dm_data_addr),
    .dm_data_o(cache_dm_to_dm_data),
    .dm_data_i(cache_dm_to_cache_data),
    
    .fence_i(mem_fence),
    .align_fault_o()
  );

  dm_master u_dm_master(
      .clk_i (sys_clk),
      .rst_i (sys_rst),
      // from mmu
      .data_addr_i (mem_master_phy_addr),
      .mmu_state_i (mem_mmu_state),
      .is_mmu_on_i (mem_mmu_on),
      .tlb_hit_i   (mem_tlb_hit),
      .page_fault_code_i (mem_page_fault_code),
      // to mmu
      .mmu_ack_o (mem_master_ack_mmu),
      .mmu_data_o (mem_master_data_mmu),

      // to cache
    //   .dm_op_i (mem_dm_op),
    //   .data_access_ack_o (mem_data_access_ack),
    //   .data_i (mem_rs2_data),
    //   .data_o (mem_data_read),
    //   .sel_i (mem_dm_sel),
      .dm_op_i (cache_dm_op),
      .data_access_ack_o (cache_dm_data_access_ack),
      .data_i (cache_dm_to_dm_data),
      .data_o (cache_dm_to_cache_data),
      .sel_i (cache_dm_sel),
     
      // DM => Mem Master
      .wb_cyc_o(mem_cyc_o),
      .wb_stb_o(mem_stb_o),
      .wb_ack_i(mem_ack_i),
      .wb_adr_o(mem_adr_o),
      .wb_dat_o(mem_dat_o),
      .wb_dat_i(mem_dat_i),
      .wb_sel_o(mem_sel_o),
      .wb_we_o (mem_we_o),

      .mtime (mtime),
      .mtimecmp (mtimecmp),
      .mtime_we (mtime_we),
      .mtimecmp_we (mtimecmp_we),
      .upper (timer_upper),
      .timer_wdata (timer_wdata)
  );

    mmu u_dm_mmu (
      .clk_i (sys_clk),
      .rst_i (sys_rst),
      .pc_i  (mem_pc),

      // from decoder
      .tlb_flush_i (ex_tlb_flush),

      // from csr
      .priv_i (mem_privilege_data_i),
      .satp_i (mem_satp_data_i), 

      // from dm_master
      .master_type_i (1'b1), // dm
    //   .master_rw_type_i (mem_dm_op),
      .master_rw_type_i (cache_dm_op),
      .is_requesting_i (mem_cyc_o),
      .master_data_i (mem_master_data_mmu),
      .master_ack_i (mem_master_ack_mmu),
      .ctrl_ack_i (mem_data_access_ack),

      // load / store virtual addr
    //   .vir_addr_i (mem_alu_y),
      .vir_addr_i (cache_dm_data_addr),
      
      // page fault code
      .page_fault_addr_o (mem_page_fault_addr),
      .page_fault_code_o (mem_page_fault_code),

      // to dm_master
      .tlb_hit_o (mem_tlb_hit),
      .is_mmu_on_o (mem_mmu_on),
      .mmu_state_o (mem_mmu_state),
      .phy_addr_o (mem_master_phy_addr)
  );
  
  logic [31:0] mem_wb_data;
  
  writeback_mux u_writeback_mux(
      .pc_i (mem_pc),
      .inst_i (mem_inst),
      .alu_y_i (mem_alu_y),
      .dm_data_i (mem_data_read),
      .csr_data_i (mem_csr_data),
      .wb_sel_i (mem_wb_sel),
      .wb_data_o (mem_wb_data)
  );

  mem_excep_handler u_mem_excep_handler(
      // Data in signals
      .mtvec_in(mem_mtvec_data_i),
      .mscratch_in(mem_mscratch_data_i),
      .mepc_in(mem_mepc_data_i),
      .mcause_in(mem_mcause_data_i),
      .mstatus_in(mem_mstatus_data_i),
      .mie_in(mem_mie_data_i),
      .mip_in(mem_mip_data_i),
      .priv_in(mem_privilege_data_i),

      .satp_in(mem_satp_data_i),
      .mtval_in(mem_mtval_data_i),
      .mideleg_in(mem_mideleg_data_i),
      .medeleg_in(mem_medeleg_data_i),
      .sepc_in(mem_sepc_data_i),
      .scause_in(mem_scause_data_i),
      .stval_in(mem_stval_data_i),
      .stvec_in(mem_stvec_data_i),
      .sscratch_in(mem_sscratch_data_i),
      
      .sstatus_in(mem_sstatus_data_i),
      .mhartid_in(mem_mhartid_data_i),
      .sie_in(mem_sie_data_i),
      .sip_in(mem_sip_data_i),
      
      // Data out signals, writeback to CSR finally
      .mtvec_out(mtvec_wdata),
      .mscratch_out(mscratch_wdata),
      .mepc_out(mepc_wdata),
      .mcause_out(mcause_wdata),
      .mstatus_out(mstatus_wdata),
      .mie_out(mie_wdata),
      .mip_out(mip_wdata),
      .priv_out(privilege_wdata),

      .satp_out(satp_wdata),
      .mtval_out(mtval_wdata),
      .mideleg_out(mideleg_wdata),
      .medeleg_out(medeleg_wdata),
      .sepc_out(sepc_wdata),
      .scause_out(scause_wdata),
      .stval_out(stval_wdata),
      .stvec_out(stvec_wdata),
      .sscratch_out(sscratch_wdata),

      .sstatus_out(sstatus_wdata),
      .mhartid_out(mhartid_wdata),
      .sie_out(sie_wdata),
      .sip_out(sip_wdata),

      // WE in signals
      .mtvec_we_in(mem_mtvec_we_i),
      .mscratch_we_in(mem_mscratch_we_i),
      .mepc_we_in(mem_mepc_we_i),
      .mcause_we_in(mem_mcause_we_i),
      .mstatus_we_in(mem_mstatus_we_i),
      .mie_we_in(mem_mie_we_i),
      .mip_we_in(mem_mip_we_i),
      .priv_we_in(mem_privilege_we_i),

      .satp_we_in(mem_satp_we_i),
      .mtval_we_in(mem_mtval_we_i),
      .mideleg_we_in(mem_mideleg_we_i),
      .medeleg_we_in(mem_medeleg_we_i),
      .sepc_we_in(mem_sepc_we_i),
      .scause_we_in(mem_scause_we_i),
      .stval_we_in(mem_stval_we_i),
      .stvec_we_in(mem_stvec_we_i),
      .sscratch_we_in(mem_sscratch_we_i),

      .sstatus_we_in(mem_sstatus_we_i),
      .mhartid_we_in(mem_mhartid_we_i),
      .sie_we_in(mem_sie_we_i),
      .sip_we_in(mem_sip_we_i),
      
      // WE out signals, write back to CSR finally
      .mtvec_we_out(mtvec_we),
      .mscratch_we_out(mscratch_we),
      .mepc_we_out(mepc_we),
      .mcause_we_out(mcause_we),
      .mstatus_we_out(mstatus_we),
      .mie_we_out(mie_we),
      .mip_we_out(mip_we),
      .priv_we_out(privilege_we),

      .satp_we_out(satp_we),
      .mtval_we_out(mtval_we),
      .mideleg_we_out(mideleg_we),
      .medeleg_we_out(medeleg_we),
      .sepc_we_out(sepc_we),
      .scause_we_out(scause_we),
      .stval_we_out(stval_we),
      .stvec_we_out(stvec_we),
      .sscratch_we_out(sscratch_we),

      .page_fault_addr_i (mem_page_fault_addr),
      .page_fault_code_i (mem_page_fault_code),
      .mem_pc_i (mem_pc),
      .sstatus_we_out(sstatus_we),
      .mhartid_we_out(mhartid_we),
      .sie_we_out(sie_we),
      .sip_we_out(sip_we)
  );

  
  /* =========== Mem Stage end =========== */
  
  logic  mem_wb_regs_hold;
  logic  mem_wb_regs_bubble;
  
  mem_wb_regs u_mem_wb_regs(
      .clk_i (sys_clk),
      .rst_i (sys_rst),
      
      .mem_wb_regs_hold_i (mem_wb_regs_hold),
      .mem_wb_regs_bubble_i (mem_wb_regs_bubble),
      
      .wb_data_i (mem_wb_data),
      .wb_data_o (wb_wb_data),
      .rd_addr_i (mem_rd_addr),
      .rd_addr_o (wb_rd_addr),
      
      .rf_wen_i (mem_rf_wen),
      .rf_wen_o (wb_rf_wen)
  );
  
  /* =========== Wb Stage start =========== */
  
  // Connect to the reg file
  logic [31:0] wb_wb_data;
  logic [4:0]  wb_rd_addr;
  logic        wb_rf_wen;
  
  /* =========== Wb Stage end =========== */
  
  cpu_controller u_cpu_controller(
      .pc_sel_o (),
      .pc_hold_o (pc_hold),
      
      .if_ack_i (if_ack),
      
      .if_id_regs_hold_o (if_id_regs_hold),
      .if_id_regs_bubble_o (if_id_regs_bubble),
      
      .id_inst_i (id_inst),
      .id_rs1_i (id_rs1_addr),
      .id_rs2_i (id_rs2_addr),
      
      .id_exe_regs_hold_o (id_exe_regs_hold),
      .id_exe_regs_bubble_o (id_exe_regs_bubble),
      
      .exe_inst_i (exe_inst),
      .exe_br_op_i (exe_br_op),
      .exe_if_br_i (exe_br_eq),
      .exe_rd_i (exe_rd_addr),
      .exe_rf_wen_i (exe_rf_wen),
      
      .exe_mem_regs_hold_o (exe_mem_regs_hold),
      .exe_mem_regs_bubble_o (exe_mem_regs_bubble),
      
      .mem_rd_i (mem_rd_addr),
      .mem_rf_wen_i (mem_rf_wen),
      .mem_data_access_ack_i (mem_data_access_ack),
      .mem_dm_op_i (mem_dm_op),
      .mem_page_fault_code_i (mem_page_fault_code),
      
      .mem_wb_regs_hold_o (mem_wb_regs_hold),
      .mem_wb_regs_bubble_o (mem_wb_regs_bubble),
      
      .wb_rd_addr_i (wb_rd_addr),
      .wb_rf_wen_i (wb_rf_wen),

      .csr_code_i(ex_csr_code),
      .predict_fault_i(predict_fault),

      .hold_all_o(hold_all),
      
      .id_fence_i(id_fence),
      .exe_fence_i(exe_fence),
      .mem_fence_i(mem_fence)
  );
  
  /* =========== Wishbone Master 2-1-1-3 begin =========== */
  // If Master => Arbiter
  logic        if_cyc_o;
  logic        if_stb_o;
  logic        if_ack_i;
  logic [31:0] if_adr_o;
  logic [31:0] if_dat_o;
  logic [31:0] if_dat_i;
  logic [ 3:0] if_sel_o;
  logic        if_we_o;
  
  // Mem Master => Arbiter
  logic        mem_cyc_o;
  logic        mem_stb_o;
  logic        mem_ack_i;
  logic [31:0] mem_adr_o;
  logic [31:0] mem_dat_o;
  logic [31:0] mem_dat_i;
  logic [ 3:0] mem_sel_o;
  logic        mem_we_o;
  
  // Lab6 Arbiter => Wishbone MUX (Slave)
  logic        wbm_cyc_o;
  logic        wbm_stb_o;
  logic        wbm_ack_i;
  logic [31:0] wbm_adr_o;
  logic [31:0] wbm_dat_o;
  logic [31:0] wbm_dat_i;
  logic [ 3:0] wbm_sel_o;
  logic        wbm_we_o;
  
  wb_arbiter_2 wb_arbiter(
      .clk(sys_clk),
      .rst(sys_rst),
    /*
     * Wishbone master 0 input
     */
      .wbm0_adr_i(if_adr_o),    // ADR_I() address input
      .wbm0_dat_i(if_dat_o),    // DAT_I() data in
      .wbm0_dat_o(if_dat_i),    // DAT_O() data out
      .wbm0_we_i(if_we_o),     // WE_I write enable input
      .wbm0_sel_i(if_sel_o),    // SEL_I() select input
      .wbm0_stb_i(if_stb_o),    // STB_I strobe input
      .wbm0_ack_o(if_ack_i),    // ACK_O acknowledge output
      .wbm0_err_o(),    // ERR_O error output
      .wbm0_rty_o(),    // RTY_O retry output
      .wbm0_cyc_i(if_cyc_o),    // CYC_I cycle input

    /*
     * Wishbone master 1 input
     */
      .wbm1_adr_i(mem_adr_o),    // ADR_I() address input
      .wbm1_dat_i(mem_dat_o),    // DAT_I() data in
      .wbm1_dat_o(mem_dat_i),    // DAT_O() data out
      .wbm1_we_i(mem_we_o),     // WE_I write enable input
      .wbm1_sel_i(mem_sel_o),    // SEL_I() select input
      .wbm1_stb_i(mem_stb_o),    // STB_I strobe input
      .wbm1_ack_o(mem_ack_i),    // ACK_O acknowledge output
      .wbm1_err_o(),    // ERR_O error output
      .wbm1_rty_o(),    // RTY_O retry output
      .wbm1_cyc_i(mem_cyc_o),    // CYC_I cycle input
    /*
     * Wishbone slave output
     */
      .wbs_adr_o(wbm_adr_o),     // ADR_O() address output
      .wbs_dat_i(wbm_dat_i),     // DAT_I() data in
      .wbs_dat_o(wbm_dat_o),     // DAT_O() data out
      .wbs_we_o(wbm_we_o),      // WE_O write enable output
      .wbs_sel_o(wbm_sel_o),     // SEL_O() select output
      .wbs_stb_o(wbm_stb_o),     // STB_O strobe output
      .wbs_ack_i(wbm_ack_i),     // ACK_I acknowledge input
      .wbs_err_i(),     // ERR_I error input
      .wbs_rty_i(),     // RTY_I retry input
      .wbs_cyc_o(wbm_cyc_o)      // CYC_O cycle output
  );
  
  /* =========== Lab6 MUX begin =========== */
  // Wishbone MUX (Masters) => bus slaves
  logic wbs0_cyc_o;
  logic wbs0_stb_o;
  logic wbs0_ack_i;
  logic [31:0] wbs0_adr_o;
  logic [31:0] wbs0_dat_o;
  logic [31:0] wbs0_dat_i;
  logic [3:0] wbs0_sel_o;
  logic wbs0_we_o;

  logic wbs1_cyc_o;
  logic wbs1_stb_o;
  logic wbs1_ack_i;
  logic [31:0] wbs1_adr_o;
  logic [31:0] wbs1_dat_o;
  logic [31:0] wbs1_dat_i;
  logic [3:0] wbs1_sel_o;
  logic wbs1_we_o;

  logic wbs2_cyc_o;
  logic wbs2_stb_o;
  logic wbs2_ack_i;
  logic [31:0] wbs2_adr_o;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel_o;
  logic wbs2_we_o;

  wb_mux_3 wb_mux (
      .clk(sys_clk),
      .rst(sys_rst),

      // Master interface (to Lab6 master)
      .wbm_adr_i(wbm_adr_o),
      .wbm_dat_i(wbm_dat_o),
      .wbm_dat_o(wbm_dat_i),
      .wbm_we_i (wbm_we_o),
      .wbm_sel_i(wbm_sel_o),
      .wbm_stb_i(wbm_stb_o),
      .wbm_ack_o(wbm_ack_i),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(wbm_cyc_o),

      // Slave interface 0 (to BaseRAM controller)
      // Address range: 0x8000_0000 ~ 0x803F_FFFF
      .wbs0_addr    (32'h8000_0000),
      .wbs0_addr_msk(32'hFFC0_0000),

      .wbs0_adr_o(wbs0_adr_o),
      .wbs0_dat_i(wbs0_dat_i),
      .wbs0_dat_o(wbs0_dat_o),
      .wbs0_we_o (wbs0_we_o),
      .wbs0_sel_o(wbs0_sel_o),
      .wbs0_stb_o(wbs0_stb_o),
      .wbs0_ack_i(wbs0_ack_i),
      .wbs0_err_i('0),
      .wbs0_rty_i('0),
      .wbs0_cyc_o(wbs0_cyc_o),

      // Slave interface 1 (to ExtRAM controller)
      // Address range: 0x8040_0000 ~ 0x807F_FFFF
      .wbs1_addr    (32'h8040_0000),
      .wbs1_addr_msk(32'hFFC0_0000),

      .wbs1_adr_o(wbs1_adr_o),
      .wbs1_dat_i(wbs1_dat_i),
      .wbs1_dat_o(wbs1_dat_o),
      .wbs1_we_o (wbs1_we_o),
      .wbs1_sel_o(wbs1_sel_o),
      .wbs1_stb_o(wbs1_stb_o),
      .wbs1_ack_i(wbs1_ack_i),
      .wbs1_err_i('0),
      .wbs1_rty_i('0),
      .wbs1_cyc_o(wbs1_cyc_o),
      
      // Slave interface 2 (to UART controller)
      // Address range: 0x1000_0000 ~ 0x1000_FFFF
      .wbs2_addr    (32'h1000_0000),
      .wbs2_addr_msk(32'hFFFF_0000),

      .wbs2_adr_o(wbs2_adr_o),
      .wbs2_dat_i(wbs2_dat_i),
      .wbs2_dat_o(wbs2_dat_o),
      .wbs2_we_o (wbs2_we_o),
      .wbs2_sel_o(wbs2_sel_o),
      .wbs2_stb_o(wbs2_stb_o),
      .wbs2_ack_i(wbs2_ack_i),
      .wbs2_err_i('0),
      .wbs2_rty_i('0),
      .wbs2_cyc_o(wbs2_cyc_o)
  );

  /* =========== Lab6 MUX end =========== */

  /* =========== Lab6 Slaves begin =========== */
  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_base (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs0_cyc_o),
      .wb_stb_i(wbs0_stb_o),
      .wb_ack_o(wbs0_ack_i),
      .wb_adr_i(wbs0_adr_o),
      .wb_dat_i(wbs0_dat_o),
      .wb_dat_o(wbs0_dat_i),
      .wb_sel_i(wbs0_sel_o),
      .wb_we_i (wbs0_we_o),

      // To SRAM chip
      .sram_addr(base_ram_addr),
      .sram_data(base_ram_data),
      .sram_ce_n(base_ram_ce_n),
      .sram_oe_n(base_ram_oe_n),
      .sram_we_n(base_ram_we_n),
      .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_ext (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs1_cyc_o),
      .wb_stb_i(wbs1_stb_o),
      .wb_ack_o(wbs1_ack_i),
      .wb_adr_i(wbs1_adr_o),
      .wb_dat_i(wbs1_dat_o),
      .wb_dat_o(wbs1_dat_i),
      .wb_sel_i(wbs1_sel_o),
      .wb_we_i (wbs1_we_o),

      // To SRAM chip
      .sram_addr(ext_ram_addr),
      .sram_data(ext_ram_data),
      .sram_ce_n(ext_ram_ce_n),
      .sram_oe_n(ext_ram_oe_n),
      .sram_we_n(ext_ram_we_n),
      .sram_be_n(ext_ram_be_n)
  );

  uart_controller #(
      .CLK_FREQ(10_000_000),
      .BAUD    (115200)
  ) uart_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs2_cyc_o),
      .wb_stb_i(wbs2_stb_o),
      .wb_ack_o(wbs2_ack_i),
      .wb_adr_i(wbs2_adr_o),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel_o),
      .wb_we_i (wbs2_we_o),

      // to UART pins
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

  /* =========== Lab6 Slaves end =========== */
  
endmodule