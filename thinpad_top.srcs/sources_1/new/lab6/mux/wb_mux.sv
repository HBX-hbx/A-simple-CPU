module writeback_mux(
    input wire [31:0] pc_i,
    input wire [31:0] inst_i,
    input wire [31:0] alu_y_i,
    input wire [31:0] dm_data_i,
    input wire [31:0] csr_data_i,
    input wire [2:0]  wb_sel_i,
    output reg [31:0] wb_data_o
);  
    reg [31:0] sext_dm_data = 0;

    always_comb begin
        if (wb_sel_i == 2) begin
            // LB
            if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0000011) begin
                // Signed Extension
                if (dm_data_i[7] == 1'b1) begin
                    sext_dm_data = {24'hFFFFFF, dm_data_i[7:0]};
                end else begin
                    sext_dm_data = {24'h000000, dm_data_i[7:0]};
                end
            // LH
            end else if (inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0000011) begin
                // Signed Extension
                if (dm_data_i[15] == 1'b1) begin
                    sext_dm_data = {16'hFFFF, dm_data_i[15:0]};
                end else begin
                    sext_dm_data = {16'h0000, dm_data_i[15:0]};
                end
            end else begin
                sext_dm_data = dm_data_i;
            end        
        end else begin
            sext_dm_data = dm_data_i;
        end
    end
    
    always_comb begin
        case (wb_sel_i)
            3'd1: begin
                wb_data_o = alu_y_i;
            end
            3'd2: begin
                wb_data_o = sext_dm_data;
            end
            3'd3: begin
                wb_data_o = pc_i + 4;
            end
            3'd4: begin
                wb_data_o = csr_data_i;
            end
            default: begin
                wb_data_o = 32'd0;
            end
        endcase
    end
    
endmodule