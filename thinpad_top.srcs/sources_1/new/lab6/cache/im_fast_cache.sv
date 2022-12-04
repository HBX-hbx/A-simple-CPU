`define NOP 32'b0000000_00000_00000_000_00000_0110_011

module im_fast_cache(
    // clk and rst
    input wire clk_i,
    input wire rst_i,

    // pc_reg
    input wire req_i,
    output logic ack_o,
    input wire [31:0] pc_i,
    output logic [31:0] inst_o,

    // im_master
    output logic im_req_o,
    input wire im_ack_i,
    output logic [31:0] im_pc_o,
    input wire [31:0] im_inst_i,

    // fence
    input wire fence_i
);

    reg [23:0] pc_tag_1 [63:0];
    reg valid_1 [63:0];
    reg [31:0] data_1 [63:0];

    reg [23:0] pc_tag_2 [63:0];
    reg valid_2 [63:0];
    reg [31:0] data_2 [63:0];

    reg [5:0] j;
    reg [5:0] k;
    
    reg cache_hit = 0;
    reg hit_longer = 0;

    reg [31:0] last_w_pc = 32'b0;
    reg [31:0] last_im_inst = 32'b0;
    reg if_same;
    reg fence_start_and_finish;
    reg fence_requested;

    assign if_same = (last_w_pc == pc_i) && (last_im_inst == im_inst_i);

    always_ff @(posedge clk_i) begin
        if (rst_i) begin // init with all cache fake
            j = 6'b0;
            k = 6'b0;
            repeat(64) begin
                valid_1[j] <= 1'b0;
                j = j + 1;
            end
            repeat(64) begin
                valid_2[k] <= 1'b0;
                k = k + 1;
            end
            fence_start_and_finish <= 0;
            fence_requested <= 0;
        end else if (fence_i) begin
            if (fence_start_and_finish && im_ack_i) begin
                // fence_start_and_finish <= 0;
            end else if(fence_start_and_finish) begin
                // Do nothing and wait
                fence_requested <= 1;
            end begin
                j = 6'b0;
                k = 6'b0;
                repeat(64) begin
                    valid_1[j] <= 1'b0;
                    j = j + 1;
                end
                repeat(64) begin
                    valid_2[k] <= 1'b0;
                    k = k + 1;
                end
                fence_start_and_finish <= 1;
            end

        end else begin
            fence_start_and_finish <= 0;
            fence_requested <= 0;
            if (im_ack_i && ~if_same && ~cache_hit) begin
                last_w_pc <= pc_i;
                last_im_inst <= im_inst_i;
                // fill the cache
                if (valid_1[pc_i[7:2]] && pc_tag_1[pc_i[7:2]] == pc_i[31:8]) begin
                    // update
                    data_1[pc_i[7:2]] <= im_inst_i;
                end else if (valid_2[pc_i[7:2]] && pc_tag_2[pc_i[7:2]] == pc_i[31:8]) begin
                    data_2[pc_i[7:2]] <= im_inst_i;
                end else begin
                    if (~valid_1[pc_i[7:2]] || (valid_1[pc_i[7:2]] && valid_2[pc_i[7:2]])) begin
                        pc_tag_1[pc_i[7:2]] <= pc_i[31:8];
                        valid_1[pc_i[7:2]] <= 1'b1;
                        data_1[pc_i[7:2]] <= im_inst_i;
                    end else begin // if (~valid_2[pc_i[7:2]]) begin
                        pc_tag_2[pc_i[7:2]] <= pc_i[31:8];
                        valid_2[pc_i[7:2]] <= 1'b1;
                        data_2[pc_i[7:2]] <= im_inst_i;
                    end
                end
            end
            // To make the hit last longer
            if (cache_hit) begin
                hit_longer <= 1;
            end else begin
                hit_longer <= 0;
            end
        end
    end

    always_comb begin
        if ((req_i == 1 || hit_longer) && pc_tag_1[pc_i[7:2]] == pc_i[31:8] && valid_1[pc_i[7:2]]) begin
            inst_o = data_1[pc_i[7:2]];
            ack_o = 1;
            cache_hit = 1;
        end else if ((req_i == 1 || hit_longer) && pc_tag_2[pc_i[7:2]] == pc_i[31:8] && valid_2[pc_i[7:2]]) begin
            inst_o = data_2[pc_i[7:2]];
            ack_o = 1;
            cache_hit = 1;
        end else if (fence_i) begin
            if (fence_start_and_finish && im_ack_i) begin
                inst_o = im_inst_i;
                ack_o = 1;
                cache_hit = 0;
            end else begin
                inst_o = im_inst_i;
                cache_hit = 0;
                ack_o = 0;
            end
        end else begin
            inst_o = im_inst_i;
            cache_hit = 0;
            if (im_ack_i) ack_o = 1;
            else ack_o = 0;
        end
    end

    always_comb begin
        if (fence_i) begin
            if (fence_start_and_finish) begin
                im_req_o = 0;
                im_pc_o = pc_i;
            end else begin
                im_req_o = 1;
                im_pc_o = pc_i;
            end
        end else begin
            if ((req_i == 1 || hit_longer) && (pc_tag_1[pc_i[7:2]] == pc_i[31:8]) && valid_1[pc_i[7:2]]) begin
                // not to request wishbone
                im_req_o = 0;
                im_pc_o = pc_i;
            end else if ((req_i == 1 || hit_longer) && pc_tag_2[pc_i[7:2]] == pc_i[31:8] && valid_2[pc_i[7:2]]) begin
                // not to request wishbone
                im_req_o = 0;
                im_pc_o = pc_i;
            end else begin
                im_req_o = req_i;
                im_pc_o = pc_i;
            end
        end
    end


endmodule