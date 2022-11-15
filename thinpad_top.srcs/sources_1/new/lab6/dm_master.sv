module dm_master(
    // clk and reset
    input wire clk_i,
    input wire rst_i,
     
    input wire [1:0] dm_op_i,
    input wire [3:0] sel_i,
    
    output reg data_access_ack_o,
    input wire [31:0] data_addr_i,
    input wire [31:0] data_i,
    output reg [31:0] data_o,
     
    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [31:0] wb_adr_o,
    output reg [31:0] wb_dat_o,
    input wire [31:0] wb_dat_i,
    output reg [3:0]  wb_sel_o,
    output reg wb_we_o
);
    reg [1:0] state;
    reg dm_ready = 0;
    reg [31:0] data_out = 0;
    
    reg [31:0] last_data_addr = 0;
    reg [31:0] last_data = 0;
    reg [3:0] last_sel = 0;
    reg [1:0] last_dm_op = 0;
    reg [31:0] last_valid_addr = 0;
    reg [3:0] last_valid_sel = 0;
    
    logic if_same;
    logic [3:0] sel;
    logic [31:0] data_sft;
    
    assign if_same = (last_data_addr == data_addr_i) && (last_data == data_i) && (last_sel == sel_i) && (last_dm_op == dm_op_i);

    logic isread;
    assign isread = (dm_op_i == 1) && (state == 0) && (~if_same);
    logic iswrite;
    assign iswrite = (dm_op_i == 2) && (state == 0) && (~if_same);
    
    assign data_sft = (data_access_ack_o && wb_we_o == 0) ? (state == 1 ? wb_dat_i : data_out): 0;
    assign data_access_ack_o = (dm_ready || wb_ack_i) && (isread !== 1) && (iswrite !== 1);
    
    always_comb begin
        // if load or save byte
        if (sel_i == 4'b0001 || (last_valid_sel == 4'b0001 && ~isread && ~ iswrite)) begin
            sel = (sel_i == 4'b0001) ? (sel_i << (data_addr_i % 4)) : (last_valid_sel << (last_valid_addr % 4));
            data_o = (data_sft & ((32'h000000FF) << ((last_valid_addr % 4) * 8))) >> ((last_valid_addr % 4) * 8);
        end else begin
            sel = sel_i;
            data_o = data_sft;
        end
    end
    
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            // ack_o <= 1'd0;
            wb_cyc_o <= 1'd0;
            wb_stb_o <= 1'd0;
            // inst_o <= `NOP;
            wb_adr_o <= 32'd0;
            wb_dat_o <= 32'd0;
            wb_sel_o <= 4'd0;
            wb_we_o <= 1'd0;
            state <= 0;
            dm_ready <= 1;
        end else begin
            last_data_addr <= data_addr_i;
            last_data <= data_i;
            last_sel <= sel;
            last_dm_op <= dm_op_i;
            // dm_op = 1 represents read
            if (isread) begin
                wb_cyc_o <= 1;
                wb_stb_o <= 1;
                wb_adr_o <= data_addr_i;
                wb_dat_o <= 0;
                wb_sel_o <= sel;
                wb_we_o <= 0;
                state <= 1;
                dm_ready <= 0;
                data_out <= 0;
                last_valid_addr <= data_addr_i;
                last_valid_sel <= sel_i;              
            // dm_op = 2 represents write
            end else if (iswrite) begin
                wb_cyc_o <= 1;
                wb_stb_o <= 1;
                wb_adr_o <= data_addr_i;
                wb_dat_o <= data_i;
                wb_sel_o <= sel;
                wb_we_o <= 1;
                state <= 1;
                dm_ready <= 0;
                data_out <= 0;
                last_valid_addr <= data_addr_i;
                last_valid_sel <= sel_i;
            end
            if (wb_ack_i == 1 && state == 1) begin
                wb_cyc_o <= 0;
                wb_stb_o <= 0;
                state <= 0;
                dm_ready <= 1;
                data_out <= wb_dat_i;
            end
        end
    end
endmodule