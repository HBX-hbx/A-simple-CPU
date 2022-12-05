module mem_wb_regs(
    input wire clk_i,
    input wire rst_i,
    input wire mem_wb_regs_hold_i,
    input wire mem_wb_regs_bubble_i,
    
    input wire [31:0] wb_data_i,
    output reg [31:0] wb_data_o,
    input wire [4:0] rd_addr_i,
    output reg [4:0] rd_addr_o,
    
    input wire rf_wen_i,
    output reg rf_wen_o
);
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            rd_addr_o <= 0;
            rf_wen_o <= 0;
            wb_data_o <= 0;
        end else begin
            if (mem_wb_regs_hold_i) begin
            
            end else if (mem_wb_regs_bubble_i) begin
                rd_addr_o <= 0;
                rf_wen_o <= 0;
                wb_data_o <= 0;
            end else begin
                rd_addr_o <= rd_addr_i;;
                rf_wen_o <= rf_wen_i;
                wb_data_o <= wb_data_i;
            end
        end
    end
endmodule