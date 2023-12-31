module cachable_mux(
    input wire [31:0] addr,
    output reg cachable
);
    // four bytes align
    // only used in dm_cache
    // TODO
    `define CACHE_ON 1'b1;
    
    always_comb begin
        if ((addr >= 32'h8010_0000) && (addr <= 32'h8010_0FFF)) begin
            cachable = `CACHE_ON;
            // cachable = 0;
        end else if ((addr >= 32'h0000_0000) && (addr <= 32'h002F_FFFF)) begin
            cachable = `CACHE_ON;
        end else if ((addr >= 32'h7FC1_0000) && (addr <= 32'h7FFF_FFFF)) begin
            cachable = `CACHE_ON;
        end else if ((addr >= 32'h8000_0000) && (addr <= 32'h8000_0FFF)) begin
            cachable = `CACHE_ON;
        end else if ((addr >= 32'h8000_1000) && (addr <= 32'h8000_1FFF)) begin
            cachable = `CACHE_ON;
        // end else if ((addr >= 32'h8000_0000) && (addr <= 32'h800F_FFFF)) begin
        //     cachable = `CACHE_ON;
        // end else if ((addr >= 32'h807F_0000) && (addr <= 32'h807F_FFFF)) begin
        //     cachable = `CACHE_ON;
        end else begin
            cachable = 0;
        end
    end

endmodule