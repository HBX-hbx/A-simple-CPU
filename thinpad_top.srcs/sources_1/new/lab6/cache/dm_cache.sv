`include "./cache_struct.svh"

module dm_cache(
    // clk and rst
    input wire clk_i,
    input wire rst_i,

    // exe_mem_regs
    input wire [1:0] dm_op_i, // 01 for read, 10 for write
    input wire [3:0] sel_i,

    output reg data_access_ack_o,
    input wire [31:0] data_addr_i,
    input wire [31:0] data_i,
    output reg [31:0] data_o,

    // dm_master
    output reg [1:0] dm_op_o,
    output reg [3:0] sel_o, 

    input wire dm_data_access_ack_i,
    output reg [31:0] dm_data_addr_o,
    output reg [31:0] dm_data_o,
    input wire [31:0] dm_data_i,

    // fence
    input wire fence_i,

    // fault
    output wire align_fault_o,

    // shortcut to bram
    output logic [18:0] bram_addr,
    output logic [7:0] bram_data,
    output logic bram_we
);

    dm_cache_entry entry[63:0];

    reg [31:0] addr_4_align;
    reg [3:0] sel_4_align;
    reg [31:0] data_4_align;
    reg [31:0] cache_data;
    reg [31:0] wishbone_data;
    reg align_fault;
    reg cachable;
    reg cache_hit;
    reg wishbone_ok;
    reg writeback_dirty;
    reg fence_i_finish;
    integer j;

    // for fence
    reg [5:0] dirty_judge_idx;

    // shortcut judging if addr is vga (only sw)
    reg if_vga;
    assign if_vga = (data_addr_i[31:20] == 12'h600) && (dm_op_i == 2);

    assign data_4_align = cache_hit?(cache_data):wishbone_data;
    assign data_access_ack_o = if_vga | cache_hit | (~cachable & wishbone_ok & ~fence_i);
    assign wishbone_ok = dm_data_access_ack_i;
    assign wishbone_data = dm_data_i;

    `define ENTRY_VALID 1'b1;
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            // j = 6'b0;
            // repeat(64) begin
            //     entry[j].valid <= 1'b0;
            //     entry[j].dirty <= 1'b0;
            //     j = j + 1;
            // end
            for(j=0;j<64;j=j+1)begin
                entry[j].valid <= 1'b0;
                entry[j].dirty <= 1'b0;
            end
            fence_i_finish <= 0;
            dirty_judge_idx <= 6'b0;
        end else if (~if_vga) begin
            if (fence_i) begin // fence 
                if (wishbone_ok) begin
                    if(~fence_i_finish) begin
                        entry[dirty_judge_idx].dirty <= 1'b0;
                        dirty_judge_idx <= dirty_judge_idx + 1;
                        if (dirty_judge_idx == 6'b111111) begin
                            fence_i_finish <= 1'b1;
                        end
                    end
                end
            end else begin
                fence_i_finish <= 1'b0;
                dirty_judge_idx <= 6'b0;
                if (cache_hit && dm_op_i == 2'b10) begin // update the dirty cache
                    case (sel_4_align)
                    4'b1111 : begin
                        entry[addr_4_align[7:2]].data <= data_i;
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    4'b1100 : begin
                        entry[addr_4_align[7:2]].data[31:16] <= data_i[15:0];
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    4'b0110 : begin
                        entry[addr_4_align[7:2]].data[23:8] <= data_i[15:0];
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    4'b0011 : begin
                        entry[addr_4_align[7:2]].data[15:0] <= data_i[15:0];
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    4'b1000 : begin
                        entry[addr_4_align[7:2]].data[31:24] <= data_i[7:0];
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    4'b0100 : begin
                        entry[addr_4_align[7:2]].data[23:16] <= data_i[7:0];
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    4'b0010 : begin
                        entry[addr_4_align[7:2]].data[15:8] <= data_i[7:0];
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    4'b0001 : begin
                        entry[addr_4_align[7:2]].data[7:0] <= data_i[7:0];
                        entry[addr_4_align[7:2]].dirty <= 1;
                    end
                    default : begin
                        // do nothing
                    end
                    endcase
                end else if(wishbone_ok && (dm_op_o == 2'b10 || dm_op_o == 2'b01) ) begin // 这里的写入逻辑还是不对
                    if (writeback_dirty) begin
                        entry[addr_4_align[7:2]].dirty <= 1'b0;
                    end else begin // new record
                        if (cachable) begin
                            entry[addr_4_align[7:2]].tag <= addr_4_align[31:8];
                            entry[addr_4_align[7:2]].valid <= 1'b1; 
                            entry[addr_4_align[7:2]].dirty <= 1'b0;
                            entry[addr_4_align[7:2]].data <= wishbone_data;
                        end else begin
                            // not need to update
                        end
                    end
                end
            end
        end
    end

    // align fault
    align_fault_judger judger(
        .addr(data_addr_i),
        .sel(sel_i),
        .fault(align_fault)
    );
    assign align_fault_o = ~if_vga & align_fault & ((dm_op_i == 2'b01 ) | (dm_op_i == 2'b10));

    // get align addr and corresponding sel
    `define ADDR_MASK 32'hfffffffc;
    `define SEL_MASK 32'h00000003;
    always_comb begin
        addr_4_align = data_addr_i & `ADDR_MASK;
        sel_4_align =  sel_i << (data_addr_i & 32'h00000003);
    end

    // judge if cachable (such as uart is uncachable)
    cachable_mux cachable_mux(
        .addr(addr_4_align),
        .cachable(cachable)
    );

    // get cache hit (already consider if cachable)
    always_comb begin
        if(fence_i) begin
            if (fence_i_finish) begin
                cache_hit = 1'b1;
                cache_data = 32'b0;
            end else begin
                cache_hit = 1'b0;
                cache_data = 32'b0;
            end
        // Add VGA situation
        end else if (if_vga) begin
            cache_hit = 1'b0;
            cache_data = 32'b0;
        end else begin
            if (~align_fault_o) begin // no align fault
                if (dm_op_i == 2'b01 || dm_op_i == 2'b10) begin
                    cache_hit = (cachable) && (entry[addr_4_align[7:2]].tag == addr_4_align[31:8]) && (entry[addr_4_align[7:2]].valid); 
                    cache_data = entry[addr_4_align[7:2]].data;
                end else begin
                    cache_hit = 1'b1;
                    cache_data = 32'b0;
                end
            end else begin // align fault
                cache_hit = 1'b0;
                cache_data = 32'b0;
            end
        end
    end

    // req from the wishbone when cache miss
    // jugde for dirty and write back before update
    always_comb begin
        if (fence_i) begin
            if (entry[dirty_judge_idx].dirty && ~fence_i_finish) begin // need to wirte back
                dm_op_o = 2'b10;
                writeback_dirty = 1;
                dm_data_addr_o = {entry[dirty_judge_idx].tag,dirty_judge_idx,2'b00};
                dm_data_o = entry[dirty_judge_idx].data;
                sel_o = 4'b1111;
            end else begin // need to do nothing
                dm_op_o = 2'b00;
                writeback_dirty = 1;
                dm_data_addr_o = {entry[dirty_judge_idx].tag,dirty_judge_idx,2'b00};
                dm_data_o = entry[dirty_judge_idx].data;
                sel_o = 4'b1111;
            end
        // Add VGA situation
        end else if (if_vga) begin
            dm_op_o = 2'b00;
            dm_data_addr_o = 32'b0;
            dm_data_o = 32'b0;
            writeback_dirty = 0;
            sel_o = 4'b1111;
        end else begin
            if (~cache_hit && ~align_fault_o) begin // need to update cache
                if (cachable) begin
                    if (entry[addr_4_align[7:2]].dirty) begin // wireback the dirty data
                        dm_data_addr_o = {entry[addr_4_align[7:2]].tag,addr_4_align[7:2],2'b00};
                        dm_data_o = entry[addr_4_align[7:2]].data;
                        dm_op_o = 2'b10;
                        writeback_dirty = 1;
                        sel_o = 4'b1111;
                    end else begin // load the right data from wishbone to cache
                        writeback_dirty = 0;
                        dm_data_addr_o = addr_4_align;
                        dm_data_o = data_i;
                        dm_op_o = 2'b01;
                        sel_o = 4'b1111;
                    end
                end else begin // uncachable addr
                    dm_data_addr_o = data_addr_i;
                    dm_data_o = data_i;
                    dm_op_o = dm_op_i;
                    writeback_dirty = 0;
                    sel_o = sel_i;
                end
            end else begin // need to do nothing with wishbone
                dm_op_o = 2'b00;
                dm_data_addr_o = addr_4_align;
                dm_data_o = data_i;
                writeback_dirty = 0;
                sel_o = 4'b1111;
            end
        end
    end

    // get real data
    always_comb begin
        // Add VGA situation
        if (if_vga) begin
            data_o = 0;
        end else if (cachable) begin
            case(sel_4_align)
            4'b1111 : begin
                data_o = data_4_align;
            end
            4'b1100 : begin
                data_o = {data_4_align[31:16],data_4_align[31:16]};
            end
            4'b0110 : begin
                data_o = {data_4_align[23:8],data_4_align[23:8]};
            end
            4'b0011 : begin
                data_o = {data_4_align[15:0],data_4_align[15:0]};
            end
            4'b0001 : begin
                data_o = {{24{1'b0}},data_4_align[7:0]};
            end
            4'b0010 : begin
                data_o = {{24{1'b0}},data_4_align[15:8]};
            end
            4'b0100 : begin
                data_o = {{24{1'b0}},data_4_align[23:16]};
            end
            4'b1000 : begin
                data_o = {{24{1'b0}},data_4_align[31:24]};
            end
            default : data_o = {{24{1'b0}},data_4_align[7:0]};
            endcase
        end else begin
            data_o = data_4_align;
        end
    end

    // handle VGA situation
    always_comb begin
        bram_addr = 0;
        bram_data = 0;
        bram_we = 0;
        if (if_vga) begin
            bram_addr = data_addr_i[18:0];
            bram_data = data_i[7:0];
            bram_we = 1;
        end
    end
endmodule