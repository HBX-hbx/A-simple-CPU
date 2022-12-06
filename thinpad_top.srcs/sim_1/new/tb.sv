`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/02 21:47:43
// Design Name: 
// Module Name: lab6_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module lab6_tb;
  wire clk_50M, clk_11M0592;

  reg push_btn;   // BTN5 ��ť���أ���������·������ʱΪ 1
  reg reset_btn;  // BTN6 ��λ��ť����������·������ʱΪ 1

  reg [3:0] touch_btn; // BTN1~BTN4����ť���أ�����ʱΪ 1
  reg [31:0] dip_sw;   // 32 λ���뿪�أ�����"ON"ʱΪ 1

  wire [15:0] leds;  // 16 λ LED������? 1 ����
  wire [7:0] dpy0;   // ����ܵ�λ�źţ�����С���㣬��� 1 ����
  wire [7:0] dpy1;   // ����ܸ�λ�źţ�����С���㣬��� 1 ����

  wire [31:0] base_ram_data;  // BaseRAM ���ݣ��� 8 λ�� CPLD ���ڿ���������
  wire [19:0] base_ram_addr;  // BaseRAM ��ַ
  wire[3:0] base_ram_be_n;    // BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���? 0
  wire base_ram_ce_n;  // BaseRAM Ƭѡ������Ч
  wire base_ram_oe_n;  // BaseRAM ��ʹ�ܣ�����Ч
  wire base_ram_we_n;  // BaseRAM дʹ�ܣ�����Ч

  wire [31:0] ext_ram_data;  // ExtRAM ����
  wire [19:0] ext_ram_addr;  // ExtRAM ��ַ
  wire[3:0] ext_ram_be_n;    // ExtRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���? 0
  wire ext_ram_ce_n;  // ExtRAM Ƭѡ������Ч
  wire ext_ram_oe_n;  // ExtRAM ��ʹ�ܣ�����Ч
  wire ext_ram_we_n;  // ExtRAM дʹ�ܣ�����Ч

  wire txd;  // ֱ�����ڷ��Ͷ�
  wire rxd;  // ֱ�����ڽ��ն�

  // CPLD ����
  wire uart_rdn;  // �������źţ�����Ч
  wire uart_wrn;  // д�����źţ�����Ч
  wire uart_dataready;  // ��������׼����
  wire uart_tbre;  // �������ݱ�־
  wire uart_tsre;  // ���ݷ�����ϱ��?

// Windows ��Ҫע��·���ָ�����ת�壬���� "D:\\foo\\bar.bin"
//  parameter BASE_RAM_INIT_FILE = "D:\\THUstudy\\study\\2022-2023autumn\\ComputerComposition\\rv-2022\\ucore_os_lab\\labcodes_answer\\lab8_evil\\bin\\rbl.img"; // BaseRAM ��ʼ���ļ������޸�Ϊʵ�ʵľ���·��
//  parameter EXT_RAM_INIT_FILE = "D:\\THUstudy\\study\\2022-2023autumn\\ComputerComposition\\rv-2022\\ucore_os_lab\\labcodes_answer\\lab8_evil\\bin\\ucore.img";  // ExtRAM ��ʼ���ļ������޸�Ϊʵ�ʵľ���·��

  parameter BASE_RAM_INIT_FILE = "D:\\rv-2022\\asmcode\\badapple_single.bin"; // BaseRAM ��ʼ���ļ������޸�Ϊʵ�ʵľ���·��
  parameter EXT_RAM_INIT_FILE = "";  // ExtRAM ��ʼ���ļ������޸�Ϊʵ�ʵľ���·��
  
  initial begin
    #100;
    reset_btn = 1;
    #100;
    reset_btn = 0;
    #4000000; // wait until the supervisor falls into infinite loop
    $finish;
  end
  
  // �������û����?
  lab6_top dut (
      .clk_50M(clk_50M),
      .clk_11M0592(clk_11M0592),
      .push_btn(push_btn),
      .reset_btn(reset_btn),
      .touch_btn(touch_btn),
      .dip_sw(dip_sw),
      .leds(leds),
      .dpy1(dpy1),
      .dpy0(dpy0),
      .txd(txd),
      .rxd(rxd),
      .uart_rdn(uart_rdn),
      .uart_wrn(uart_wrn),
      .uart_dataready(uart_dataready),
      .uart_tbre(uart_tbre),
      .uart_tsre(uart_tsre),
      .base_ram_data(base_ram_data),
      .base_ram_addr(base_ram_addr),
      .base_ram_ce_n(base_ram_ce_n),
      .base_ram_oe_n(base_ram_oe_n),
      .base_ram_we_n(base_ram_we_n),
      .base_ram_be_n(base_ram_be_n),
      .ext_ram_data(ext_ram_data),
      .ext_ram_addr(ext_ram_addr),
      .ext_ram_ce_n(ext_ram_ce_n),
      .ext_ram_oe_n(ext_ram_oe_n),
      .ext_ram_we_n(ext_ram_we_n),
      .ext_ram_be_n(ext_ram_be_n),
      .flash_d(),
      .flash_a(),
      .flash_rp_n(),
      .flash_vpen(),
      .flash_oe_n(),
      .flash_ce_n(),
      .flash_byte_n(),
      .flash_we_n()
  );

  // ʱ��Դ
  clock osc (
      .clk_11M0592(clk_11M0592),
      .clk_50M    (clk_50M)
  );

  // CPLD ���ڷ���ģ��
  cpld_model cpld (
      .clk_uart(clk_11M0592),
      .uart_rdn(uart_rdn),
      .uart_wrn(uart_wrn),
      .uart_dataready(uart_dataready),
      .uart_tbre(uart_tbre),
      .uart_tsre(uart_tsre),
      .data(base_ram_data[7:0])
  );
  // ֱ�����ڷ���ģ��
  uart_model uart (
    .rxd (txd),
    .txd (rxd)
  );
  // BaseRAM ����ģ��
  sram_model base1 (
      .DataIO(base_ram_data[15:0]),
      .Address(base_ram_addr[19:0]),
      .OE_n(base_ram_oe_n),
      .CE_n(base_ram_ce_n),
      .WE_n(base_ram_we_n),
      .LB_n(base_ram_be_n[0]),
      .UB_n(base_ram_be_n[1])
  );
  sram_model base2 (
      .DataIO(base_ram_data[31:16]),
      .Address(base_ram_addr[19:0]),
      .OE_n(base_ram_oe_n),
      .CE_n(base_ram_ce_n),
      .WE_n(base_ram_we_n),
      .LB_n(base_ram_be_n[2]),
      .UB_n(base_ram_be_n[3])
  );
  // ExtRAM ����ģ��
  sram_model ext1 (
      .DataIO(ext_ram_data[15:0]),
      .Address(ext_ram_addr[19:0]),
      .OE_n(ext_ram_oe_n),
      .CE_n(ext_ram_ce_n),
      .WE_n(ext_ram_we_n),
      .LB_n(ext_ram_be_n[0]),
      .UB_n(ext_ram_be_n[1])
  );
  sram_model ext2 (
      .DataIO(ext_ram_data[31:16]),
      .Address(ext_ram_addr[19:0]),
      .OE_n(ext_ram_oe_n),
      .CE_n(ext_ram_ce_n),
      .WE_n(ext_ram_we_n),
      .LB_n(ext_ram_be_n[2]),
      .UB_n(ext_ram_be_n[3])
  );

  // ���ļ����� BaseRAM
  initial begin
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
    if (!n_File_ID) begin
      n_Init_Size = 0;
      $display("Failed to open BaseRAM init file");
    end else begin
      n_Init_Size = $fread(tmp_array, n_File_ID);
      n_Init_Size /= 4;
      $fclose(n_File_ID);
    end
    $display("BaseRAM Init Size(words): %d", n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
      base1.mem_array0[i] = tmp_array[i][24+:8];
      base1.mem_array1[i] = tmp_array[i][16+:8];
      base2.mem_array0[i] = tmp_array[i][8+:8];
      base2.mem_array1[i] = tmp_array[i][0+:8];
    end
  end

  // ���ļ����� ExtRAM
  initial begin
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
    if (!n_File_ID) begin
      n_Init_Size = 0;
      $display("Failed to open ExtRAM init file");
    end else begin
      n_Init_Size = $fread(tmp_array, n_File_ID);
      n_Init_Size /= 4;
      $fclose(n_File_ID);
    end
    $display("ExtRAM Init Size(words): %d", n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
      ext1.mem_array0[i] = tmp_array[i][24+:8];
      ext1.mem_array1[i] = tmp_array[i][16+:8];
      ext2.mem_array0[i] = tmp_array[i][8+:8];
      ext2.mem_array1[i] = tmp_array[i][0+:8];
    end
  end
endmodule