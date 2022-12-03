module cachable_mux(
    input wire [31:0] addr,
    output reg cachable
);

    // four bytes align
    // only used in dm_cache
    // TODO
    always_comb begin
        if ((addr >= 32'h8000_0000) && (addr <= 32'h807F_FFFF)) begin
            cachable = 1;
        end else begin
            cachable = 0;
        end
    end

endmodule