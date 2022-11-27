module bcomp(
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    input wire [3:0] br_op_i,
    output logic if_br_o
);
    always_comb begin
        case (br_op_i)
            3'd0: begin
                if_br_o = (a_i == b_i) ? 1 : 0;
            end
            3'd1: begin
                if_br_o = (a_i != b_i) ? 1 : 0;
            end
            3'd3: begin
                if_br_o = 1;
            end
            3'd4: begin
                if_br_o = ($signed(a_i) < $signed(b_i)) ? 1 : 0;
            end
            3'd5: begin
                if_br_o = ($signed(a_i) >= $signed(b_i)) ? 1 : 0;
            end
            3'd6: begin
                if_br_o = (a_i < b_i) ? 1 : 0;
            end
            3'd7: begin
                if_br_o = (a_i >= b_i) ? 1 : 0;
            end
            default: begin
                if_br_o = 0;
            end
        endcase
    end
    
    // assign if_br_o = (a_i == b_i) ? 1'd1 : 1'd0;
endmodule