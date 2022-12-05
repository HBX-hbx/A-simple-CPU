`define NOP 32'b0000000_00000_00000_000_00000_0110_011

module if_id_regs(
    input wire clk_i,
    input wire rst_i,
      
    input wire if_id_regs_hold_i,
    input wire if_id_regs_bubble_i,
      
    input wire [31:0] pc_i,
    output reg [31:0] pc_o,
      
    input wire [31:0] inst_i,
    output reg [31:0] inst_o
);
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin

        end else begin
            if (if_id_regs_hold_i) begin
            
            end else if (if_id_regs_bubble_i) begin
                pc_o <= 0;
                inst_o <= `NOP;
            end else begin
                pc_o <= pc_i;
                inst_o <= inst_i;
            end
        end
    end
endmodule