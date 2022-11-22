module align_fault_judger(
    input wire [31:0] addr,
    input wire [3:0] sel,
    output reg fault // 1 for fault, 0 for safe
);

 reg [1:0] align_pos;
 `define SEL_MASK 32'h00000003;
 
 always_comb begin
    align_pos = (addr[1:0] & 2'b11);
    if (sel == 4'b1111) begin
        if (align_pos == 2'b00) begin
            fault = 1'b0;
        end else begin
            fault = 1'b1;
        end
    end else if (sel == 4'b0011) begin
        if (align_pos == 2'b11) begin
            fault = 1'b1;
        end else begin
            fault = 1'b0;
        end
    end else begin
        fault = 1'b0;
    end
 end

endmodule