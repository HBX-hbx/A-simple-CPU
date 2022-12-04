module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // TODO: 添加需要的控制信号，例如按键开关？
    input wire [DATA_WIDTH-1:0] dip_sw,
    
    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

    // TODO: 实现实验 5 的内存+串口 Master
    typedef enum logic [3:0] {
        READ_WAIT_ACTION = 0,
        READ_WAIT_CHECK = 1,
        READ_DATA_ACTION = 2,
        READ_DATA_DONE = 3,
        WRITE_SRAM_ACTION = 4,
        WRITE_SRAM_DONE = 5,
        WRITE_WAIT_ACTION = 6,
        WRITE_WAIT_CHECK = 7,
        WRITE_DATA_ACTION = 8,
        WRITE_DATA_DONE = 9  
    } state_t;
  
    state_t state;
    reg [31:0] addr; // 输入地址
    reg [7:0] cur_data; // 当前的一字节数据
    reg [3:0] count; // 辅助计次
    reg [1:0] substep;
    
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            wb_adr_o <= 0;
            wb_dat_o <= 0;
            wb_sel_o <= 0;
            wb_we_o <= 1'b0;
            cur_data <= 4'b0;
            count <= 0;
            substep <= 0;
            addr <= dip_sw;
            state <= READ_WAIT_ACTION;
        end
        else begin
            case (state)
                READ_WAIT_ACTION: begin
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    // 0 为读取
                    wb_we_o <= 1'b0;
                    // 读取 0x10000005
                    wb_adr_o <= 32'h10000005;
                    wb_sel_o <= 4'b0010;
                    state <= READ_WAIT_CHECK;
                end
                READ_WAIT_CHECK: begin
                    if (substep == 0) begin
                        if (wb_ack_i) begin
                            wb_stb_o <= 0;
                            substep <= 1;
                        end
                    end else if (substep == 1) begin
                        // 抽取 0x10000005 的第 [0] 位检查是否为 1
                        if ((wb_dat_i & 32'h00000100) == 32'h00000100) begin
                            wb_adr_o <= 32'h10000000;
                            wb_sel_o <= 4'b0001;
                            wb_stb_o <= 1;
                            substep <= 0;
                            state <= READ_DATA_ACTION;
                        end else begin
                            state <= READ_WAIT_ACTION;
                            substep <= 0;
                        end
                    end
                end
                READ_DATA_ACTION: begin
                    if (wb_ack_i) begin
                        cur_data <= wb_dat_i[7:0];
                        state <= READ_DATA_DONE;
                        wb_stb_o <= 0;
                    end
                end
                READ_DATA_DONE: begin
                    // 准备进行 sram 写入
                    // 1 为写入
                    wb_we_o <= 1'b1;
                    // 读取 0x10000005
                    wb_adr_o <= addr + 4 * count;
                    wb_dat_o <= cur_data;
                    wb_sel_o <= 4'b0001;
                    wb_stb_o <= 1;
                    state <= WRITE_SRAM_ACTION;
                end
                WRITE_SRAM_ACTION: begin
                    wb_stb_o <= 0;
                    if (wb_ack_i) begin
                        state <= WRITE_SRAM_DONE;
                    end
                end
                WRITE_SRAM_DONE: begin
                    // 读取 0x10000005
                    wb_adr_o <= 32'h10000005;
                    wb_sel_o <= 4'b0010;
                    wb_stb_o <= 1;
                    state <= WRITE_WAIT_CHECK;
                end
                WRITE_WAIT_CHECK: begin
                    if (substep == 0) begin
                        if (wb_ack_i) begin
                            wb_stb_o <= 0;
                            substep <= 1;
                        end
                    end else if (substep == 1) begin
                        // 抽取 0x10000005 的第 [5] 位检查是否为 1
                        if ((wb_dat_i & 32'h00002000) == 32'h00002000) begin
                            wb_adr_o <= 32'h10000000;
                            wb_dat_o[7:0] <= cur_data;
                            wb_sel_o <= 4'b0001;
                            wb_stb_o <= 1;
                            substep <= 0;
                            state <= WRITE_DATA_ACTION;
                        end else begin
                            state <= WRITE_SRAM_DONE;
                            substep <= 0;
                        end
                    end
                end
                WRITE_DATA_ACTION: begin
                    if (wb_ack_i) begin
                        state <= WRITE_DATA_DONE;
                        count <= count + 1;
                        wb_stb_o <= 0;
                    end
                end
                WRITE_DATA_DONE: begin
                    if (count < 10) begin
                        state <= READ_WAIT_ACTION;
                    end
                end
            endcase
        end
    end
    
endmodule
