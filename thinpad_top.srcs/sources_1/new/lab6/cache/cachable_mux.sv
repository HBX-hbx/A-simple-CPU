module cachable_mux(
    input wire [31:0] addr,
    output reg cachable
);
    // four bytes align
    // only used in dm_cache
    // TODO
    always_comb begin
        if ((addr >= 32'h8010_0000) && (addr <= 32'h8010_0FFF)) begin
            cachable = 1;
            // cachable = 0;
        end else if ((addr >= 32'h0000_0000) && (addr <= 32'h002F_FFFF)) begin
            cachable = 1;
        end else if ((addr >= 32'h7FC1_0000) && (addr <= 32'h7FFF_FFFF)) begin
            cachable = 1;
        end else if ((addr >= 32'h8000_0000) && (addr <= 32'h8000_0FFF)) begin
            cachable = 1;
        end else if ((addr >= 32'h8000_1000) && (addr <= 32'h8000_1FFF)) begin
            cachable = 1;
        end else begin
            cachable = 0;
        end
    end

endmodule