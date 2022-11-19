`define NOP 32'b0000000_00000_00000_000_00000_0110_011

module im_cache(
    // clk and rst
    input wire clk_i,
    input wire rst_i,

    // pc_reg
    input wire req_i,
    output wire ack_o,
    input wire [31:0] pc_i,
    output reg [31:0] inst_o,

    // im_master
    output reg im_req_o,
    input wire im_ack_i,
    output reg [31:0] im_pc_o,
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
    reg data_ready = 0;
    reg state = 0;
    assign ack_o = data_ready && req_i != 1;

    always_ff @(posedge clk_i) begin
        if (rst_i || fence_i) begin // init with all cache fake
            j = 6'b0;
            repeat(64) begin
                valid_1[j] <= 1'b0;
                valid_2[j] <= 1'b0;
                j = j + 1;
            end
            // init ack and inst
            data_ready <= 0;
            inst_o <= `NOP;
        end else begin
            // update
            if ((req_i == 1 || data_ready == 1) && pc_tag_1[pc_i[7:2]] == pc_i[31:8] && valid_1[pc_i[7:2]]) begin
                inst_o <= data_1[pc_i[7:2]];
                data_ready <= 1;
            end else if ((req_i == 1 || data_ready == 1) && pc_tag_2[pc_i[7:2]] == pc_i[31:8] && valid_2[pc_i[7:2]]) begin
                inst_o <= data_2[pc_i[7:2]];
                data_ready <= 1;
            end else begin
                    if (im_ack_i && ~data_ready) begin
                        data_ready <= 1;
                        inst_o <= im_inst_i;
                        // fill the cache
                        if (valid_1[pc_i[7:2]] && pc_tag_1[pc_i[7:2]] == pc_i[31:8]) begin
                            // update
                            data_1[pc_i[7:2]] <= im_inst_i;
                        end else if (valid_2[pc_i[7:2]]  && pc_tag_2[pc_i[7:2]] == pc_i[31:8]) begin
                            data_2[pc_i[7:2]] <= im_inst_i;
                        end else begin
                            if (~valid_1[pc_i[7:2]]) begin
                                pc_tag_1[pc_i[7:2]] <= pc_i[31:8];
                                valid_1[pc_i[7:2]] <= 1'b1;
                                data_1[pc_i[7:2]] <= im_inst_i;
                            end else if (~valid_2[pc_i[7:2]]) begin
                                pc_tag_2[pc_i[7:2]] <= pc_i[31:8];
                                valid_2[pc_i[7:2]] <= 1'b1;
                                data_2[pc_i[7:2]] <= im_inst_i;
                            end else begin
                                pc_tag_1[pc_i[7:2]] <= pc_i[31:8];
                                valid_1[pc_i[7:2]] <= 1'b1;
                                data_1[pc_i[7:2]] <= im_inst_i;
                            end
                        end
                    end else begin
                        data_ready <= 0;
                    end
            end
        end
    end

    always_comb begin
        if (fence_i) begin
            im_req_o = 0;
            im_pc_o = pc_i;
        end else begin
            if ((req_i == 1 || data_ready == 1) && (pc_tag_1[pc_i[7:2]] == pc_i[31:8]) && valid_1[pc_i[7:2]]) begin
                // not to request wishbone
                im_req_o = 0;
                im_pc_o = pc_i;
            end else if ((req_i == 1 || data_ready == 1) && pc_tag_2[pc_i[7:2]] == pc_i[31:8] && valid_2[pc_i[7:2]]) begin
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