module pc_mux(
    input wire [31:0] cur_pc_i,
    input wire [31:0] alu_pc_i,
    input wire [31:0] exe_pc_i,
    input wire [31:0] direct_br_addr,
    input wire [1:0] pc_sel_i,
    output logic [31:0] next_pc_o
);  
    always_comb begin
        case (pc_sel_i)
            3'd0: begin
                next_pc_o = exe_pc_i + alu_pc_i;
            end
            3'd1: begin
                next_pc_o = cur_pc_i + 32'd4;
            end
            3'd2: begin
                next_pc_o = alu_pc_i;
            end
            3'd3: begin
                next_pc_o = direct_br_addr;
            end
            default: begin
                next_pc_o = cur_pc_i + 32'd4;
            end
        endcase
    end
endmodule