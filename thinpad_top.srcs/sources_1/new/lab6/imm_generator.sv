module imm_generator(
    input wire [31:0] inst_i,
    input wire [2:0]  imm_sel_i,
    input wire [31:0] direct_out_i,
    output logic [31:0] imm_o
);
    always_comb begin
        case (imm_sel_i)
            3'd1: begin
                imm_o = {inst_i[31:12],12'd0};
            end
            3'd2: begin
                // 32-bit signed extension
                if (inst_i[31] == 1) begin
                    imm_o = {11'b11111111111, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
                end else begin
                    imm_o = {11'b00000000000, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
                end
            end
            3'd3: begin
                if (inst_i[31] == 1) begin
                    imm_o = {20'b11111111111111111111, inst_i[31:20]};
                end else begin
                    imm_o = {20'b00000000000000000000, inst_i[31:20]};
                end
            end
            3'd4: begin
                if (inst_i[31] == 1) begin
                    imm_o = {19'b1111111111111111111, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'd0};
                end else begin
                    imm_o = {19'b0000000000000000000, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'd0};
                end
            end
            3'd5: begin
                if (inst_i[31] == 1) begin
                    imm_o = {20'b11111111111111111111, inst_i[31:25], inst_i[11:7]};
                end else begin 
                    imm_o = {20'b00000000000000000000, inst_i[31:25], inst_i[11:7]};
                end
            end
            // especially for sltu currently
            3'd6: begin
                imm_o = direct_out_i;
            end
            default: begin
                imm_o = 32'd0;
            end
        endcase
    end
endmodule