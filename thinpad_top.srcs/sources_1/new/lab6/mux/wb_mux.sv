module writeback_mux(
    input wire [31:0] pc_i,
    input wire [31:0] alu_y_i,
    input wire [31:0] dm_data_i,
    input wire [1:0]  wb_sel_i,
    output reg [31:0] wb_data_o
);
    always_comb begin
        case (wb_sel_i)
            2'd1: begin
                wb_data_o = alu_y_i;
            end
            2'd2: begin
                wb_data_o = dm_data_i;
            end
            2'd3: begin
                wb_data_o = pc_i + 4;
            end
            default: begin
                wb_data_o = 32'd0;
            end
        endcase
    end
    
endmodule