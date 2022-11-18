module rscomp(
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    input wire [31:0] inst_i,
    output logic [31:0] direct_out_o
);  
    reg [31:0] sext_imm;

    always_comb begin
        sext_imm = 0;
        // SLT instruction
        if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0110011) begin
            if ($signed(a_i) < $signed(b_i)) begin
                direct_out_o = 32'b1;
            end else begin
                direct_out_o = 32'b0;
            end
        // SLTU instruction
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b0110011) begin
            if (a_i < b_i) begin
                direct_out_o = 32'b1;
            end else begin
                direct_out_o = 32'b0;
            end
        // SLTI instruction
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0010011) begin
            sext_imm = (inst_i[31] == 0) ? {20'b00000000000000000000, inst_i[31:20]} : {20'b11111111111111111111, inst_i[31:20]};
            if ($signed(a_i) < $signed(sext_imm)) begin
                direct_out_o = 32'b1;
            end else begin
                direct_out_o = 32'b0;
            end
        // SLTIU instruction
        end else if (inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b0010011) begin
            sext_imm = (inst_i[31] == 0) ? {20'b00000000000000000000, inst_i[31:20]} : {20'b11111111111111111111, inst_i[31:20]};
            if (a_i < sext_imm) begin
                direct_out_o = 32'b1;
            end else begin
                direct_out_o = 32'b0;
            end
        end else begin
            direct_out_o = 32'b0;
        end
    end
endmodule