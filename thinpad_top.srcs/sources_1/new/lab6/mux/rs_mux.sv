module rs_mux(
    input wire [1:0] rs_sel,
    input wire [31:0] exe_rs_data,
    input wire [31:0] mem_rs_data,
    input wire [31:0] wb_rs_data,
    output reg [31:0] exe_data_o
);
    always_comb begin
        case (rs_sel)
            2'd0: begin
                exe_data_o = exe_rs_data;
            end
            2'd1: begin
                exe_data_o = mem_rs_data;
            end
            2'd2: begin
                exe_data_o = wb_rs_data;
            end
            default: begin
                exe_data_o = exe_rs_data;
            end
        endcase
    end
    
endmodule