`timescale 1ns / 1ps
`include "./utils.vh"

module BTB(
    input wire clk_i,
    input wire rst_i,
    input wire [`ADDR_WIDTH-1:0] curr_pc_i, // 这个 pc 必须�? 4 对齐�?
    input wire [1:0] addr_sel_i,

    input wire stall,

    input wire exe_is_branch_i, // exe 阶段是不�? branch
    input wire branch_taken_i, // branch 是否发生了跳�?
    input wire [`ADDR_WIDTH-1:0] branch_addr_i, // 跳转到的地址，即 ALU 算出来的那个
    input wire [`ADDR_WIDTH-1:0] id_addr_i, // id 阶段正在跑的地址
    input wire [`ADDR_WIDTH-1:0] exe_addr_i, // exe 阶段正在跑的地址

    output logic [`ADDR_WIDTH-1:0] next_pc_o, // 下一条指令地�?
    output logic predict_fault_o // 预测是否失败，为 1 表示失败，需要插气泡
);

    reg [23:0] pc_tag [63:0]; // 24 6 2
    reg taken [63:0];
    reg [`ADDR_WIDTH-1:0] next_pc [63:0];
    // reg [5:0] j;
    integer j;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            // j = 6'b0;
            // repeat(64) begin
            //     taken[j] <= 1'b0;
            //     j = j + 1;
            // end
            for(j=0;j<64;j=j+1) begin
                taken[j] <= 1'b0;
            end
        end else begin
            // 更新 taken tag 以及寄存�?
            if (addr_sel_i != 2'b11) begin
                if (~stall && (exe_is_branch_i === 1'b1) && (branch_taken_i === 1'b1) && (branch_addr_i !== id_addr_i)) begin // 该跳跳错了或者没�?
                    pc_tag[exe_addr_i[7:2]] <= exe_addr_i[31:8]; // 23+1
                    taken[exe_addr_i[7:2]] <= 1'b1;
                    next_pc[exe_addr_i[7:2]] <= branch_addr_i;
                end else if (~stall && (exe_is_branch_i === 1'b1) && ~branch_taken_i && ( (exe_addr_i + 4) != id_addr_i)) begin // 不该跳跳�?
                    pc_tag[exe_addr_i[7:2]] <= exe_addr_i[31:8];
                    taken[exe_addr_i[7:2]] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        if ((exe_is_branch_i === 1'b1) && (branch_taken_i === 1'b1) && (branch_addr_i !== id_addr_i)) begin // 该跳跳错了或者没�?
            predict_fault_o = 1;
            next_pc_o = branch_addr_i;
        end else if (exe_is_branch_i && ~branch_taken_i && ( (exe_addr_i + 4) != id_addr_i)) begin // 不该跳跳�?
            predict_fault_o = 1;
            next_pc_o = exe_addr_i + 4;
        end else begin // 其他情况（还没发现跳错了�?
            predict_fault_o = 0;
            next_pc_o = ((pc_tag[curr_pc_i[7:2]] == curr_pc_i[31:8]) && taken[curr_pc_i[7:2]])?next_pc[curr_pc_i[7:2]]:curr_pc_i+4;
        end
    end

endmodule