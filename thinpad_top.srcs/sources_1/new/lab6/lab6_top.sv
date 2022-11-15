`default_nettype none

module lab6_top (
    input wire clk_50M,     // 50MHz ʱ����
    input wire clk_11M0592, // 11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire push_btn,  // BTN5 ��ť���أ���������·������ʱΪ 1
    input wire reset_btn, // BTN6 ��λ��ť����������·������ʱΪ 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4����ť���أ�����ʱΪ 1
    input  wire [31:0] dip_sw,     // 32 λ���뿪�أ�����"ON"ʱΪ 1
    output wire [15:0] leds,       // 16 λ LED������? 1 ����
    output wire [ 7:0] dpy0,       // ����ܵ�λ�źţ�����С���㣬��� 1 ����
    output wire [ 7:0] dpy1,       // ����ܸ�λ�źţ�����С���㣬��� 1 ����

    // CPLD ���ڿ������ź�
    output wire uart_rdn,        // �������źţ�����Ч
    output wire uart_wrn,        // д�����źţ�����Ч
    input  wire uart_dataready,  // ��������׼����
    input  wire uart_tbre,       // �������ݱ�־
    input  wire uart_tsre,       // ���ݷ�����ϱ��?

    // BaseRAM �ź�
    inout wire [31:0] base_ram_data,  // BaseRAM ���ݣ��� 8 λ�� CPLD ���ڿ���������
    output wire [19:0] base_ram_addr,  // BaseRAM ��ַ
    output wire [3:0] base_ram_be_n,  // BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���? 0
    output wire base_ram_ce_n,  // BaseRAM Ƭѡ������Ч
    output wire base_ram_oe_n,  // BaseRAM ��ʹ�ܣ�����Ч
    output wire base_ram_we_n,  // BaseRAM дʹ�ܣ�����Ч

    // ExtRAM �ź�
    inout wire [31:0] ext_ram_data,  // ExtRAM ����
    output wire [19:0] ext_ram_addr,  // ExtRAM ��ַ
    output wire [3:0] ext_ram_be_n,  // ExtRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���? 0
    output wire ext_ram_ce_n,  // ExtRAM Ƭѡ������Ч
    output wire ext_ram_oe_n,  // ExtRAM ��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,  // ExtRAM дʹ�ܣ�����Ч

    // ֱ�������ź�
    output wire txd,  // ֱ�����ڷ��Ͷ�
    input  wire rxd,  // ֱ�����ڽ��ն�

    // Flash �洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0] flash_a,  // Flash ��ַ��a0 ���� 8bit ģʽ��Ч��16bit ģʽ������
    inout wire [15:0] flash_d,  // Flash ����
    output wire flash_rp_n,  // Flash ��λ�źţ�����Ч
    output wire flash_vpen,  // Flash д�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,  // Flash Ƭѡ�źţ�����Ч
    output wire flash_oe_n,  // Flash ��ʹ���źţ�����Ч
    output wire flash_we_n,  // Flash дʹ���źţ�����Ч
    output wire flash_byte_n, // Flash 8bit ģʽѡ�񣬵���Ч����ʹ�� flash �� 16 λģʽʱ����Ϊ 1

    // USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB �������������������? dm9k_sd[7:0] ����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // ����������źţ��ο�? DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // ͼ������ź�?
    output wire [2:0] video_red,    // ��ɫ���أ�3 λ
    output wire [2:0] video_green,  // ��ɫ���أ�3 λ
    output wire [1:0] video_blue,   // ��ɫ���أ�2 λ
    output wire       video_hsync,  // ��ͬ����ˮƽͬ�����ź�
    output wire       video_vsync,  // ��ͬ������ֱͬ�����ź�
    output wire       video_clk,    // ����ʱ�����?
    output wire       video_de      // ��������Ч�źţ���������������
);

  /* =========== Demo code begin =========== */

  // PLL ��Ƶʾ��
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // �ⲿʱ������
      // Clock out ports
      .clk_out1(clk_10M),  // ʱ�����? 1��Ƶ���� IP ���ý���������
      .clk_out2(clk_20M),  // ʱ�����? 2��Ƶ���� IP ���ý���������
      // Status and control signals
      .reset(reset_btn),  // PLL ��λ����
      .locked(locked)  // PLL ����ָʾ�����?"1"��ʾʱ���ȶ���
                       // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
  );

  logic reset_of_clk10M;
  // �첽��λ��ͬ���ͷţ��� locked �ź�תΪ�󼶵�·�ĸ�λ reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_10M;
  assign sys_rst = reset_of_clk10M;

  // ��ʵ�鲻ʹ�� CPLD ���ڣ����÷�ֹ���߳�ͻ
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  /* =========== Lab6 begin =========== */
  
  // for pc_reg
  logic [31:0] next_pc; // ��������µ�? pc
  logic [31:0] cur_pc;  // ��ǰ pc
  logic [1:0]  pc_sel;  // pc ѡ���ź�
  logic        pc_hold;
  logic        if_req;
  logic        if_ack;
  logic [31:0] if_inst; // IM ��ȡ��ָ��
  
  /* =========== IF Stage begin =========== */
  pc_reg u_pc_reg (
      .clk_i     (sys_clk),
      .rst_i     (sys_rst),
      
      .next_pc_i (next_pc),
      .cur_pc_o  (cur_pc),
      
      .pc_hold_i (pc_hold),
      .if_req_o  (if_req)
  );
  
  // pc_mux
  pc_mux u_pc_mux (
      .cur_pc_i  (cur_pc),
      .alu_pc_i  (exe_alu_y),
      .exe_pc_i (exe_pc),
      .pc_sel_i  (pc_sel),
      .next_pc_o (next_pc)
  );
  
  im_master u_im_master (
      .clk_i (sys_clk),
      .rst_i (sys_rst),
      
      // inst
      .req_i  (if_req),
      .ack_o  (if_ack),
      .pc_i   (cur_pc),
      .inst_o (if_inst),
      
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
      .inst_o(id_inst)
  );
  
  /* =========== ID Stage start =========== */
  
  // for decoder
  logic [31:0] id_pc;
  logic [31:0] id_inst;
  
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
  logic [1:0]  id_wb_sel;
  logic [4:0]  id_shamt;
  
  logic [3:0]  id_dm_sel;
  logic [1:0]  id_dm_op;
  
  logic reg_just_w;
  logic [4:0] reg_last_w_addr;
  logic [31:0] reg_last_w_data;
  
  decoder u_decoder (
      .inst_i     (id_inst),
      
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
      .dm_op_o   (id_dm_op)
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
      .rf_wen (wb_rf_wen),
      
      .just_w (reg_just_w),
      .last_w_data (reg_last_w_data),
      .last_w_addr (reg_last_w_addr)
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
      .dm_op_o (exe_dm_op)
  );
  
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
  
  logic [1:0]  exe_wb_sel;
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

  logic [31:0] exe_handler_data;

  extra_inst_handler u_extra_inst_handler(
      .inst_i (exe_inst),
      .rs1_data_i (exe_rs1_data),
      .rs2_data_i (exe_rs2_data),
      .data_o (exe_handler_data)
  );

  rs_mux u_rs1_mux(
      .rs_sel(rs1_sel),
      .exe_rs_data(ori_rs1_data),
      .mem_rs_data(mem_wb_data),
      .wb_rs_data(wb_wb_data),
      .reg_rs_data(reg_last_w_data),
      .exe_data_o(exe_rs1_data)
  );

  rs_mux u_rs2_mux(
      .rs_sel(rs2_sel),
      .exe_rs_data(ori_rs2_data),
      .mem_rs_data(mem_wb_data),
      .wb_rs_data(wb_wb_data),
      .reg_rs_data(reg_last_w_data),
      .exe_data_o(exe_rs2_data)
  );

  forward_unit u_forward_unit(
      .exe_rs1_addr(exe_rs1_addr),
      .exe_rs2_addr(exe_rs2_addr),
      .mem_rd_addr(mem_rd_addr),
      .wb_rd_addr(wb_rd_addr),
      .reg_rd_addr(reg_last_w_addr),

      .mem_rf_wen(mem_rf_wen),
      .wb_rf_wen(wb_rf_wen),
      .reg_just_w(reg_just_w),

      .rs1_data_sel(rs1_sel),
      .rs2_data_sel(rs2_sel)
  );
  
  imm_generator u_imm_generator(
      .inst_i (exe_inst),
      .imm_sel_i (exe_imm_sel),
      .handler_data_i (exe_handler_data),
      .imm_o (exe_imm)
  );
  
  bcomp u_bcomp (
      .a_i (exe_rs1_data),
      .b_i (exe_rs2_data),
      .br_op_i (exe_br_op),
      .if_br_o (exe_br_eq)
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
      .wb_sel_o (mem_wb_sel)
  );
  
  /* =========== Mem Stage start =========== */
  
  logic [31:0] mem_pc;
  logic [31:0] mem_inst;
  
  logic [31:0] mem_alu_y;
  
  logic [31:0] mem_rs2_data;
  logic [4:0]  mem_rd_addr;
  
  logic [1:0]  mem_dm_op;
  logic [3:0]  mem_dm_sel;
  
  logic        mem_rf_wen;
  logic [1:0]  mem_wb_sel;
  
  logic        mem_data_access_ack;
  logic [31:0] mem_data_read;
  
  dm_master u_dm_master(
      .clk_i (sys_clk),
      .rst_i (sys_rst),
     
      .dm_op_i (mem_dm_op),
      .data_access_ack_o (mem_data_access_ack),
      .data_addr_i (mem_alu_y),
      .data_i (mem_rs2_data),
      .data_o (mem_data_read),
      .sel_i (mem_dm_sel),
     
      // DM => Mem Master
      .wb_cyc_o(mem_cyc_o),
      .wb_stb_o(mem_stb_o),
      .wb_ack_i(mem_ack_i),
      .wb_adr_o(mem_adr_o),
      .wb_dat_o(mem_dat_o),
      .wb_dat_i(mem_dat_i),
      .wb_sel_o(mem_sel_o),
      .wb_we_o (mem_we_o)
  );
  
  logic [31:0] mem_wb_data;
  
  writeback_mux u_writeback_mux(
      .pc_i (mem_pc),
      .alu_y_i (mem_alu_y),
      .dm_data_i (mem_data_read),
      .wb_sel_i (mem_wb_sel),
      .wb_data_o (mem_wb_data)
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
      .pc_sel_o (pc_sel),
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
      
      .mem_wb_regs_hold_o (mem_wb_regs_hold),
      .mem_wb_regs_bubble_o (mem_wb_regs_bubble),
      
      .wb_rd_addr_i (wb_rd_addr),
      .wb_rf_wen_i (wb_rf_wen),
      
      .reg_just_w_i (reg_just_w),
      .reg_last_w_data_i (reg_last_w_data),
      .reg_last_w_addr_i (reg_last_w_addr)
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

  // ���ڿ�����ģ��
  // NOTE: ����޸�ϵͳʱ��Ƶ�ʣ�Ҳ��Ҫ�޸Ĵ˴���ʱ��Ƶ�ʲ���?
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