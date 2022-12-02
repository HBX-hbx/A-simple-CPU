module mtimer
(
    input wire clk,
    input wire rst,
    input wire mtime_we,
    input wire mtimecmp_we,
    input wire upper,
    input wire [31:0] wdata,
    output reg [63:0] mtime,
    output reg [63:0] mtimecmp,
    output reg interrupt
);

reg [9:0] state = 0; 

always_comb begin
    if (mtime >= mtimecmp) interrupt = 1'b1;
    else interrupt = 1'b0;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        mtime <= 64'b0;
        mtimecmp <= 64'hFFFFFFFFFFFFFFFF;
        state <= 6'b0;
    end else begin
        if (mtime_we) begin
            if (upper) mtime <= {wdata, mtime[31:0]};
            else mtime <= {mtime[63:32], wdata};
        end
        else begin
            if (state == 19) begin
                mtime <= mtime + 1;
                state <= 0;
            end else begin
                state <= state + 1;
            end
        end
        if (mtimecmp_we) begin
            if (upper) mtimecmp <= {wdata, mtimecmp[31:0]};
            else mtimecmp <= {mtimecmp[63:32], wdata};
        end
        else mtimecmp <= mtimecmp;
    end
end

endmodule