module pc_reg (
    input wire clk_i,
    input wire rst_i,

    input wire [31:0] next_pc_i,
    output reg [31:0] cur_pc_o,

    input wire pc_hold_i,

    output reg if_req_o 
);
    // reg [3:0] space = 0;
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            cur_pc_o <= 32'h80000000;
            if_req_o <= 1'b1;
        end else begin
            if (pc_hold_i) begin
                if_req_o <= 1'b0;
            end else begin
                if_req_o <= 1'b1;
                cur_pc_o <= next_pc_i;
            end
        end
        
    end
endmodule
