module rscomp(
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    input wire [31:0] inst_i,
    output logic [31:0] direct_out_o
);  
    always_comb begin
        // SLTU instruction
        if (inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b0110011) begin
            if (a_i < b_i) begin
                direct_out_o = 32'b1;
            end else begin
                direct_out_o = 32'b0;
            end
        end else begin
            direct_out_o = 32'b0;
        end
    end
endmodule