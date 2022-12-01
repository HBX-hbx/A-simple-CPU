module dm_master(
    // clk and reset
    input wire clk_i,
    input wire rst_i,
    // mmu state
    // 0: FIRST_PTE
    // 1: SECOND_PTE
    // 2: DONE
    input wire [1:0] mmu_state_i,
    input wire is_mmu_on_i,
     
    input wire [1:0] dm_op_i,
    input wire [3:0] sel_i,

    input wire tlb_hit_i,
    input wire [1:0] page_fault_code_i,
    
    output wire mmu_ack_o, // to mmu
    output reg data_access_ack_o, // to controller (only when the final PA is gotten, assign to '1')
    input wire [31:0] data_addr_i, // physical address (1st, 2nd and final PA)
    output reg [31:0] mmu_data_o, // every requested data (PageTable Address)
    input wire [31:0] data_i,
    output reg [31:0] data_o, // final PA -> data
     
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
<<<<<<< HEAD
=======
    reg [31:0] last_valid_data = 0;
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
    reg [63:0] last_valid_time = 0;

    // Judge if the address is related to timer
    reg [1:0] time_op = 0; // 0 means normal(not time), 1 means mtime, 2 means mtimecmp
    
    logic if_same;
    logic if_time;
    logic isread;
    logic iswrite;
<<<<<<< HEAD
    assign if_same = (last_data_addr == data_addr_i) && (last_data == data_i) && (last_sel == sel_i) && (last_dm_op == dm_op_i);
    assign if_time = (data_addr_i == 32'h0200bff8) || (data_addr_i == 32'h0200bffc) || (data_addr_i == 32'h02004000) || (data_addr_i == 32'h02004004);
    assign isread = (dm_op_i == 1) && (state == 0) && (~if_same);
    assign iswrite = (dm_op_i == 2) && (state == 0) && (~if_same);

    logic [3:0] sel;
    logic [31:0] data_sft;
    logic [31:0] normal_time_data_buf;
    assign data_sft = (data_access_ack_o && wb_we_o == 0) ? (state == 1 ? normal_time_data_buf : data_out): 0;
    // For mtime, we only need one cycle to read the data / load the data
    assign data_access_ack_o = (dm_ready || (wb_ack_i || time_op != 0)) && (isread !== 1) && (iswrite !== 1);
    
=======
    logic isread_without_mmu;
    logic iswrite_without_mmu;
    assign if_same = (last_data_addr == data_addr_i) && (last_data == data_i) && (last_sel == sel_i) && (last_dm_op == dm_op_i);
    assign if_time = (data_addr_i == 32'h0200bff8) || (data_addr_i == 32'h0200bffc) || (data_addr_i == 32'h02004000) || (data_addr_i == 32'h02004004);
    
    // TODO: when state = 1 && tlb_hit, maybe if the ack not arrive, should not req
    assign isread = (dm_op_i == 1 || (dm_op_i == 2 && ((mmu_state_i == 1 && ~tlb_hit_i) || mmu_state_i == 2))) && (state == 0) && (~if_same);
    // only when mmu off or va->pa done can write ram
    assign iswrite = (dm_op_i == 2 && (mmu_state_i == 0 || (mmu_state_i == 1 && tlb_hit_i) || mmu_state_i == 3)) && (state == 0) && (~if_same);

    assign isread_without_mmu = (dm_op_i == 1) && (state == 0) && (~if_same);
    assign iswrite_without_mmu = (dm_op_i == 2) && (state == 0) && (~if_same);

    logic [3:0] sel;
    logic [31:0] data_sft;
    logic [31:0] data;
    logic [31:0] normal_time_data_buf;

    // immediately return when final ack
    assign data_sft = (data_access_ack_o && wb_we_o == 0) ? (state == 1 ? normal_time_data_buf : data_out): 0;
    // TODO: when to give data_access_ack_o, when im not give, it should keep high
    always_comb begin
        data_access_ack_o = (dm_ready || (wb_ack_i || time_op != 0)) && (isread_without_mmu !== 1) && (iswrite_without_mmu !== 1);
        // For mtime, we only need one cycle to read the data / load the data
        if (is_mmu_on_i) begin
            // if (dm_op_i == 1 || dm_op_i == 2) begin
            //     data_access_ack_o = mmu_ack_o && (mmu_state_i == 3 || mmu_state_i == 1 && tlb_hit_i);
            // end
            case (mmu_state_i)
                1: begin
                    data_access_ack_o = dm_ready && (isread_without_mmu !== 1) && (iswrite_without_mmu !== 1);
                end
                2: begin
                    data_access_ack_o = 0;
                end
                3: begin
                    data_access_ack_o = mmu_ack_o;
                end
                default: begin
                    data_access_ack_o = (dm_ready || (wb_ack_i || time_op != 0)) && (isread_without_mmu !== 1) && (iswrite_without_mmu !== 1);
                end
            endcase
        end
    end

    assign mmu_data_o = (mmu_ack_o && wb_we_o == 0) ? (state == 1 ? normal_time_data_buf : data_out): 0;
    assign mmu_ack_o = (~dm_ready && (wb_ack_i || time_op != 0)) && (isread_without_mmu !== 1) && (iswrite_without_mmu !== 1);
    
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
    // dealing with digit shift problems
    always_comb begin
        // if load or save byte
        if (sel_i == 4'b0001 || (last_valid_sel == 4'b0001 && ~isread && ~ iswrite)) begin
            sel = (sel_i == 4'b0001) ? (sel_i << (data_addr_i % 4)) : (last_valid_sel << (last_valid_addr % 4));
            data = (sel_i == 4'b0001) ? (data_i << ((data_addr_i % 4) * 8)) : (last_valid_data << ((last_valid_addr % 4) * 8));
            data_o = (data_sft & ((32'h000000FF) << ((last_valid_addr % 4) * 8))) >> ((last_valid_addr % 4) * 8);
        // if load or save half
        end else if (sel_i == 4'b0011 || (last_valid_sel == 4'b0011 && ~isread && ~ iswrite)) begin
            sel = (sel_i == 4'b0011) ? (sel_i << (data_addr_i % 4)) : (last_valid_sel << (last_valid_addr % 4));
<<<<<<< HEAD
=======
            data = (sel_i == 4'b0011) ? (data_i << ((data_addr_i % 4) * 8)) : (last_valid_data << ((last_valid_addr % 4) * 8));
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
            data_o = (data_sft & ((32'h0000FFFF) << ((last_valid_addr % 4) * 8))) >> ((last_valid_addr % 4) * 8);
        // load or save word
        end else begin
            sel = sel_i;
            data = data_i;
            data_o = data_sft;
        end
    end

    // choosing between normal wb_dat_i as output or the timer as output
    always_comb begin
        if (time_op == 0) begin
            normal_time_data_buf = wb_dat_i;
        end else begin
            normal_time_data_buf = last_valid_time;
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
            last_sel <= sel_i;
            last_dm_op <= dm_op_i;
            // dm_op = 1 represents read
            if (isread) begin
<<<<<<< HEAD
                if (~if_time) begin
=======
                if (~if_time && page_fault_code_i == 2'b00) begin // only the page fault not happen
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
                    wb_cyc_o <= 1;
                    wb_stb_o <= 1;
                    wb_adr_o <= data_addr_i;
                    wb_dat_o <= 0;
<<<<<<< HEAD
                    wb_sel_o <= sel;
=======
                    wb_sel_o <= (mmu_state_i == 1 || mmu_state_i == 2) ? 4'b1111 : sel; // shifted!
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
                    wb_we_o <= 0;
                    state <= 1;
                    dm_ready <= 0;
                    data_out <= 0;
                    last_valid_addr <= data_addr_i;
                    last_valid_sel <= sel_i;
                end else begin
                    wb_we_o <= 0;
                    if (data_addr_i == 32'h0200bff8) begin
                        time_op <= 1;
                        last_valid_time <= mtime[31:0];
                    end else if (data_addr_i == 32'h0200bffc) begin
                        time_op <= 1;
                        last_valid_time <= mtime[63:32];
                    end else if (data_addr_i == 32'h02004000) begin
                        time_op <= 2;
                        last_valid_time <= mtimecmp[31:0];
                    end else begin // if (data_addr_i == 32'h02004004) begin
                        time_op <= 2;
                        last_valid_time <= mtimecmp[63:32];
                    end
                    state <= 1;
                    dm_ready <= 0;
                    data_out <= 0;
                    last_valid_addr <= data_addr_i;
                    last_valid_sel <= sel_i;
                end
            // dm_op = 2 represents write
            end else if (iswrite) begin
<<<<<<< HEAD
                if (~if_time) begin
                    wb_cyc_o <= 1;
                    wb_stb_o <= 1;
                    wb_adr_o <= data_addr_i;
                    wb_dat_o <= data_i;
                    wb_sel_o <= sel;
=======
                if (~if_time && page_fault_code_i == 2'b00) begin // only the page fault not happen
                    wb_cyc_o <= 1;
                    wb_stb_o <= 1;
                    wb_adr_o <= data_addr_i;
                    wb_dat_o <= data; // shifted!
                    wb_sel_o <= sel; // shifted!
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
                    wb_we_o <= 1;
                    state <= 1;
                    dm_ready <= 0;
                    data_out <= 0;
<<<<<<< HEAD
=======
                    last_valid_data <= data_i;
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
                    last_valid_addr <= data_addr_i;
                    last_valid_sel <= sel_i;
                end else begin
                    timer_wdata <= data_i;
                    if (data_addr_i == 32'h0200bff8) begin
                        time_op <= 1;
                        last_valid_time <= 0;
                        upper <= 0;
                        mtime_we <= 1;
                    end else if (data_addr_i == 32'h0200bffc) begin
                        time_op <= 1;
                        last_valid_time <= 0;
                        upper <= 1;
                        mtime_we <= 1;
                    end else if (data_addr_i == 32'h02004000) begin
                        time_op <= 2;
                        last_valid_time <= 0;
                        upper <= 0;
                        mtimecmp_we <= 1;
                    end else begin // if (data_addr_i == 32'h02004004) begin
                        time_op <= 2;
                        last_valid_time <= 0;
                        upper <= 1;
                        mtimecmp_we <= 1;
                    end
                    state <= 1;
                    dm_ready <= 0;
                    data_out <= 0;
<<<<<<< HEAD
=======
                    last_valid_data <= data_i;
>>>>>>> 70f5705f5ef1230723b2a0742f443b93e0ec6fd5
                    last_valid_addr <= data_addr_i;
                    last_valid_sel <= sel_i;
                end
            end

            if ((wb_ack_i == 1 || time_op != 0) && state == 1) begin
                wb_cyc_o <= 0;
                wb_stb_o <= 0;
                state <= 0;
                dm_ready <= 1;
                // To make the data last longer, we get from data buf
                data_out <= normal_time_data_buf;
                // let time op last for one cycle is enough, 
                // as we use data out(which is update to time related output) to make data_o last longer
                time_op <= 0;
                upper <= 0;
                timer_wdata <= 0;
                mtimecmp_we <= 0;
                mtime_we <= 0;
            end

        end
    end
endmodule