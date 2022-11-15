module extra_inst_handler (
    input wire [31:0] inst_i,
    input wire [31:0] rs1_data_i,
    input wire [31:0] rs2_data_i,
    output logic [31:0] data_o
);
    
    always_comb begin
        // Current inst is CTZ
        if (inst_i[31:25] == 7'b0110000 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0010011) begin
            if (rs1_data_i == 32'b00000000000000000000000000000000) begin
                data_o = 32'd32;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000000000000) & 32'b00000000000000000000000000000001) == 32'b00000000000000000000000000000001) begin
                data_o = 32'd0;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000000000001) & 32'b00000000000000000000000000000011) == 32'b00000000000000000000000000000011) begin
                data_o = 32'd1;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000000000011) & 32'b00000000000000000000000000000111) == 32'b00000000000000000000000000000111) begin
                data_o = 32'd2;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000000000111) & 32'b00000000000000000000000000001111) == 32'b00000000000000000000000000001111) begin
                data_o = 32'd3;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000000001111) & 32'b00000000000000000000000000011111) == 32'b00000000000000000000000000011111) begin
                data_o = 32'd4;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000000011111) & 32'b00000000000000000000000000111111) == 32'b00000000000000000000000000111111) begin
                data_o = 32'd5;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000000111111) & 32'b00000000000000000000000001111111) == 32'b00000000000000000000000001111111) begin
                data_o = 32'd6;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000001111111) & 32'b00000000000000000000000011111111) == 32'b00000000000000000000000011111111) begin
                data_o = 32'd7;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000011111111) & 32'b00000000000000000000000111111111) == 32'b00000000000000000000000111111111) begin
                data_o = 32'd8;
            end else if (((rs1_data_i ^ 32'b00000000000000000000000111111111) & 32'b00000000000000000000001111111111) == 32'b00000000000000000000001111111111) begin
                data_o = 32'd9;
            end else if (((rs1_data_i ^ 32'b00000000000000000000001111111111) & 32'b00000000000000000000011111111111) == 32'b00000000000000000000011111111111) begin
                data_o = 32'd10;
            end else if (((rs1_data_i ^ 32'b00000000000000000000011111111111) & 32'b00000000000000000000111111111111) == 32'b00000000000000000000111111111111) begin
                data_o = 32'd11;
            end else if (((rs1_data_i ^ 32'b00000000000000000000111111111111) & 32'b00000000000000000001111111111111) == 32'b00000000000000000001111111111111) begin
                data_o = 32'd12;
            end else if (((rs1_data_i ^ 32'b00000000000000000001111111111111) & 32'b00000000000000000011111111111111) == 32'b00000000000000000011111111111111) begin
                data_o = 32'd13;
            end else if (((rs1_data_i ^ 32'b00000000000000000011111111111111) & 32'b00000000000000000111111111111111) == 32'b00000000000000000111111111111111) begin
                data_o = 32'd14;
            end else if (((rs1_data_i ^ 32'b00000000000000000111111111111111) & 32'b00000000000000001111111111111111) == 32'b00000000000000001111111111111111) begin
                data_o = 32'd15;
            end else if (((rs1_data_i ^ 32'b00000000000000001111111111111111) & 32'b00000000000000011111111111111111) == 32'b00000000000000011111111111111111) begin
                data_o = 32'd16;
            end else if (((rs1_data_i ^ 32'b00000000000000011111111111111111) & 32'b00000000000000111111111111111111) == 32'b00000000000000111111111111111111) begin
                data_o = 32'd17;
            end else if (((rs1_data_i ^ 32'b00000000000000111111111111111111) & 32'b00000000000001111111111111111111) == 32'b00000000000001111111111111111111) begin
                data_o = 32'd18;
            end else if (((rs1_data_i ^ 32'b00000000000001111111111111111111) & 32'b00000000000011111111111111111111) == 32'b00000000000011111111111111111111) begin
                data_o = 32'd19;
            end else if (((rs1_data_i ^ 32'b00000000000011111111111111111111) & 32'b00000000000111111111111111111111) == 32'b00000000000111111111111111111111) begin
                data_o = 32'd20;
            end else if (((rs1_data_i ^ 32'b00000000000111111111111111111111) & 32'b00000000001111111111111111111111) == 32'b00000000001111111111111111111111) begin
                data_o = 32'd21;
            end else if (((rs1_data_i ^ 32'b00000000001111111111111111111111) & 32'b00000000011111111111111111111111) == 32'b00000000011111111111111111111111) begin
                data_o = 32'd22;
            end else if (((rs1_data_i ^ 32'b00000000011111111111111111111111) & 32'b00000000111111111111111111111111) == 32'b00000000111111111111111111111111) begin
                data_o = 32'd23;
            end else if (((rs1_data_i ^ 32'b00000000111111111111111111111111) & 32'b00000001111111111111111111111111) == 32'b00000001111111111111111111111111) begin
                data_o = 32'd24;
            end else if (((rs1_data_i ^ 32'b00000001111111111111111111111111) & 32'b00000011111111111111111111111111) == 32'b00000011111111111111111111111111) begin
                data_o = 32'd25;
            end else if (((rs1_data_i ^ 32'b00000011111111111111111111111111) & 32'b00000111111111111111111111111111) == 32'b00000111111111111111111111111111) begin
                data_o = 32'd26;
            end else if (((rs1_data_i ^ 32'b00000111111111111111111111111111) & 32'b00001111111111111111111111111111) == 32'b00001111111111111111111111111111) begin
                data_o = 32'd27;
            end else if (((rs1_data_i ^ 32'b00001111111111111111111111111111) & 32'b00011111111111111111111111111111) == 32'b00011111111111111111111111111111) begin
                data_o = 32'd28;
            end else if (((rs1_data_i ^ 32'b00011111111111111111111111111111) & 32'b00111111111111111111111111111111) == 32'b00111111111111111111111111111111) begin
                data_o = 32'd29;
            end else if (((rs1_data_i ^ 32'b00111111111111111111111111111111) & 32'b01111111111111111111111111111111) == 32'b01111111111111111111111111111111) begin
                data_o = 32'd30;
            end else if (((rs1_data_i ^ 32'b01111111111111111111111111111111) & 32'b11111111111111111111111111111111) == 32'b11111111111111111111111111111111) begin
                data_o = 32'd31;
            // Should not exist
            end else begin
                data_o = 32'd0;
            end
        // Current inst is MINU
        end else if (inst_i[31:25] == 7'b0000101 && inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b0110011) begin
            data_o = rs1_data_i < rs2_data_i ? rs1_data_i : rs2_data_i;
        // Current inst is SBCLR
        end else if (inst_i[31:25] == 7'b0100100 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0110011) begin
            data_o = rs1_data_i & ~(1 << (rs2_data_i & 32'h0000001f));
        // Other that we won't use
        end else begin
            data_o = 32'd0;
        end
    end

endmodule