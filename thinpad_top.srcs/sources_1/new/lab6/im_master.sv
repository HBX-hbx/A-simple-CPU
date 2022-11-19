`define NOP 32'b0000000_00000_00000_000_00000_0110_011


module im_master(
    // clk and reset
    input wire clk_i,
    input wire rst_i,
    // mmu state
    // 0: FIRST_PTE
    // 1: SECOND_PTE
    // 2: DONE
    input wire [1:0] mmu_state_i,
    input wire is_mmu_on_i,
    // inst
    input wire req_i,
    output wire mmu_ack_o, // to mmu
    output reg ack_o, // to controller (only when the final PA is gotten, assign to '1')
    input wire [31:0] phy_addr_i, // physical address (1st, 2nd and final PA)
    output wire [31:0] mmu_data_o, // every requested data (PageTable Address)
    output wire [31:0] inst_o, // final PA -> inst
    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [31:0] wb_adr_o,
    output reg [31:0] wb_dat_o,
    input wire [31:0] wb_dat_i,
    output reg [3:0]  wb_sel_o,
    output reg wb_we_o
);  
    reg [1:0] state = 0;
    
    reg im_ready = 0;
    reg [31:0] out_data = 0;
    
    reg [31:0] last_pa = 0;
    
    // immediately return when final ack
    assign inst_o = ack_o ? (state == 1 ? wb_dat_i : out_data) : 0;
    always_comb begin
        ack_o = (im_ready || wb_ack_i) && req_i != 1;
        if (is_mmu_on_i) begin
            case (mmu_state_i)
                1: begin
                    ack_o = im_ready && req_i != 1;
                end
                2: begin
                    ack_o = 0;
                end
                3: begin
                    ack_o = mmu_ack_o;
                end
                default: begin
                    ack_o = (im_ready || wb_ack_i) && req_i != 1;
                end
            endcase
            // ack_o = mmu_ack_o && mmu_state_i == 3;
        end else begin
            ack_o = (im_ready || wb_ack_i) && req_i != 1;
        end
    end

    assign mmu_data_o = mmu_ack_o ? (state == 1 ? wb_dat_i : out_data) : 0;
    assign mmu_ack_o = (~im_ready && wb_ack_i) && req_i != 1;
    
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            wb_cyc_o <= 1'd0;
            wb_stb_o <= 1'd0;
            wb_adr_o <= 32'd0;
            wb_dat_o <= 32'd0;
            wb_sel_o <= 4'd0;
            wb_we_o <= 1'd0;
        end else begin
            last_pa <= phy_addr_i;
            if ((req_i == 1 || (mmu_state_i == 2 || mmu_state_i == 3)) && state == 0 && last_pa != phy_addr_i) begin
                wb_cyc_o <= 1;
                wb_stb_o <= 1;
                wb_adr_o <= phy_addr_i;
                wb_sel_o <= 4'b1111;
                wb_we_o <= 0;
                state <= 1;
                im_ready <= 0;
                out_data <= 0;
            end else if (wb_ack_i == 1 && state == 1) begin
                wb_cyc_o <= 0;
                wb_stb_o <= 0;
                state <= 0;
                im_ready <= 1;
                out_data <= wb_dat_i;
            end
        end
    end
endmodule