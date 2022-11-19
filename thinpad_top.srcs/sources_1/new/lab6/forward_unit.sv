module forward_unit(
    input wire [4:0] exe_rs1_addr,
    input wire [4:0] exe_rs2_addr,
    input wire [4:0] mem_rd_addr,
    input wire [4:0] wb_rd_addr,

    input wire mem_rf_wen,
    input wire wb_rf_wen,

    output logic [1:0] rs1_data_sel,
    output logic [1:0] rs2_data_sel
);  
    always_comb begin
        // we need to check mem first
        if ((mem_rd_addr == exe_rs1_addr) && mem_rf_wen && mem_rd_addr != 0) begin
            rs1_data_sel = 1;
        end else if ((wb_rd_addr == exe_rs1_addr) && wb_rf_wen && wb_rd_addr != 0) begin
            rs1_data_sel = 2;
        end else begin
            rs1_data_sel = 0;
        end
        if ((mem_rd_addr == exe_rs2_addr) && mem_rf_wen && mem_rd_addr != 0) begin
            rs2_data_sel = 1;
        end else if ((wb_rd_addr == exe_rs2_addr) && wb_rf_wen && wb_rd_addr != 0) begin
            rs2_data_sel = 2;
        end else begin
            rs2_data_sel = 0;
        end
    end
endmodule