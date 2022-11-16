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
    output reg wb_we_o,

    input wire [63:0] mtime,
    input wire [63:0] mtimecmp,
    output logic mtime_we,
    output logic mtimecmp_we,
    output logic upper,
    output logic [31:0] timer_wdata
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
    reg [63:0] last_valid_mtime = 0;
    reg [63:0] last_valid_mtimecmp = 0;

    // Judge if the address is related to timer
    reg [1:0] time_op = 0; // 0 means normal(not time), 1 means mtime, 2 means mtimecmp
    reg if_up = 0; // 0 not upper, 1 is upper
    
    logic if_same;
    logic [3:0] sel;
    logic [31:0] data_sft;
    logic [31:0] normal_time_data_buf;
    
    assign if_same = (last_data_addr == data_addr_i) && (last_data == data_i) && (last_sel == sel_i) && (last_dm_op == dm_op_i);

    logic isread;
    assign isread = (dm_op_i == 1) && (state == 0) && (~if_same);
    logic iswrite;
    assign iswrite = (dm_op_i == 2) && (state == 0) && (~if_same);
    
    assign data_sft = (data_access_ack_o && wb_we_o == 0) ? (state == 1 ? normal_time_data_buf : data_out): 0;
    assign data_access_ack_o = (dm_ready || wb_ack_i) && (isread !== 1) && (iswrite !== 1);

    // one cycle is enough to write back to update timer
    assign mtime_we = wb_ack_i && state == 1 && (time_op == 1);
    assign mtimecmp_we = wb_ack_i && state == 1 && (time_op == 2);
    assign upper = wb_ack_i && state == 1 && if_up;
    assign timer_wdata = (mtime_we || mtimecmp_we) ? wb_dat_i : 0;
    
    // dealing with digit shift problems
    always_comb begin
        // if load or save byte
        if (sel_i == 4'b0001 || (last_valid_sel == 4'b0001 && ~isread && ~ iswrite)) begin
            sel = (sel_i == 4'b0001) ? (sel_i << (data_addr_i % 4)) : (last_valid_sel << (last_valid_addr % 4));
            data_o = (data_sft & ((32'h000000FF) << ((last_valid_addr % 4) * 8))) >> ((last_valid_addr % 4) * 8);
        // if load or save half
        end else if (sel_i == 4'b0011 || (last_valid_sel == 4'b0011 && ~isread && ~ iswrite)) begin
            sel = (sel_i == 4'b0011) ? (sel_i << (data_addr_i % 4)) : (last_valid_sel << (last_valid_addr % 4));
            data_o = (data_sft & ((32'h0000FFFF) << ((last_valid_addr % 4) * 8))) >> ((last_valid_addr % 4) * 8);
        // load or save word
        end else begin
            sel = sel_i;
            data_o = data_sft;
        end
    end

    // choosing between normal wb_dat_i as output or the timer as output
    always_comb begin
        if (time_op == 0) begin
            normal_time_data_buf = wb_dat_i;
        end else begin
            if (time_op == 1) begin
                if (if_up) normal_time_data_buf = last_valid_mtime[63:32];
                else normal_time_data_buf = last_valid_mtime[31:0];
            end else if (time_op == 2) begin
                if (if_up) normal_time_data_buf = last_valid_mtimecmp[63:32];
                else normal_time_data_buf = last_valid_mtimecmp[31:0];
            end
        end
    end
    
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            wb_cyc_o <= 1'd0;
            wb_stb_o <= 1'd0;
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
            // Related to timer
            if (isread || iswrite) begin
                if (data_addr_i == 32'h0200bff8) begin
                    time_op <= 1;
                    if_up <= 0;
                    last_valid_mtime <= mtime;
                end else if (data_addr_i == 32'h0200bffc) begin
                    time_op <= 1;
                    if_up <= 1;
                    last_valid_mtime <= mtime;
                end else if (data_addr_i == 32'h02004000) begin
                    time_op <= 2;
                    if_up <= 1;
                    last_valid_mtimecmp <= mtimecmp;
                end else if (data_addr_i == 32'h02004004) begin
                    time_op <= 2;
                    if_up <= 1;
                    last_valid_mtimecmp <= mtimecmp;
                end else begin
                    time_op <= 0;
                    if_up <= 0;
                end
            end
            if (wb_ack_i == 1 && state == 1) begin
                wb_cyc_o <= 0;
                wb_stb_o <= 0;
                state <= 0;
                dm_ready <= 1;
                // To make the data last longer, we get from data buf
                data_out <= normal_time_data_buf;
                // let time op last for one cycle is enough, 
                // as we use data out(which is update to time related output) to make data_o last longer
                time_op <= 0;
            end
        end
    end
endmodule