`define TLB_ENTRY_CNT = 128 // 128 entries
`define TLB_WAY_CNT = 8 // 8-way

`define TLB_SET_CNT = 16 // 16 * 8 = 128
`define TLBT_WIDTH = 16
`define TLBI_WIDTH = 4

module TLB (
	// clk and reset
    input wire clk_i,
    input wire rst_i,

	input wire tlb_flush_i, // flush the tlb
	// 20 bits: VPN [16: TLBT, 4: TLBI]
	input wire [19:0] tlb_vpn_i, 
	input wire tlb_ppn_we_i,
	input wire [19:0] tlb_ppn_i, // from mmu, after tlb miss
	input wire [4:0]  tlb_status_i, // from mmu, after tlb miss
	// 20 bits: PPN
	output reg [19:0] tlb_ppn_o,
	output reg [4:0]  tlb_status_o, // U X W R V
	output reg tlb_hit_o
);
	// TLB
	reg [15:0] tlb_tag    [15:0] [7:0]; // 16 * 8, each 16 bits
	reg [19:0] tlb_ppn    [15:0] [7:0]; // 16 * 8, each 20 bits
	reg        tlb_valid  [15:0] [7:0]; // 16 * 8, each 1  bit
	reg [4:0]  tlb_status [15:0] [7:0]; // 16 * 8, each 5 bits: U X W R V

	logic [15:0] tlb_tag_i;
	logic [3:0]  tlb_idx_i;
	logic [7:0]  not_valid;

	assign tlb_tag_i = tlb_vpn_i[19:4];
	assign tlb_idx_i = tlb_vpn_i[3:0];

	integer i, j; // for loop clear all valid regs
	reg last_tlb_ppn_we;

	assign not_valid[0] = ~tlb_valid[tlb_idx_i][0];

	assign not_valid[1] = tlb_valid[tlb_idx_i][0] & 
						 ~tlb_valid[tlb_idx_i][1];

	assign not_valid[2] = tlb_valid[tlb_idx_i][0] & 
						 tlb_valid[tlb_idx_i][1] & 
						 ~tlb_valid[tlb_idx_i][2];
	
	assign not_valid[3] = tlb_valid[tlb_idx_i][0] & 
						 tlb_valid[tlb_idx_i][1] & 
						 tlb_valid[tlb_idx_i][2] & 
						 ~tlb_valid[tlb_idx_i][3];
	
	assign not_valid[4] = tlb_valid[tlb_idx_i][0] & 
						 tlb_valid[tlb_idx_i][1] & 
						 tlb_valid[tlb_idx_i][2] & 
						 tlb_valid[tlb_idx_i][3] & 
						 ~tlb_valid[tlb_idx_i][4];
	
	assign not_valid[5] = tlb_valid[tlb_idx_i][0] & 
						 tlb_valid[tlb_idx_i][1] & 
						 tlb_valid[tlb_idx_i][2] & 
						 tlb_valid[tlb_idx_i][3] & 
						 tlb_valid[tlb_idx_i][4] & 
						 ~tlb_valid[tlb_idx_i][5];
	
	assign not_valid[6] = tlb_valid[tlb_idx_i][0] & 
						 tlb_valid[tlb_idx_i][1] & 
						 tlb_valid[tlb_idx_i][2] & 
						 tlb_valid[tlb_idx_i][3] & 
						 tlb_valid[tlb_idx_i][4] & 
						 tlb_valid[tlb_idx_i][5] & 
						 ~tlb_valid[tlb_idx_i][6];

	assign not_valid[7] = tlb_valid[tlb_idx_i][0] & 
						 tlb_valid[tlb_idx_i][1] & 
						 tlb_valid[tlb_idx_i][2] & 
						 tlb_valid[tlb_idx_i][3] & 
						 tlb_valid[tlb_idx_i][4] & 
						 tlb_valid[tlb_idx_i][5] & 
						 tlb_valid[tlb_idx_i][6] &
						 ~tlb_valid[tlb_idx_i][7];

	always_ff @ (posedge clk_i) begin
		if (tlb_flush_i || rst_i) begin
			last_tlb_ppn_we <= 1'b0;
			// clear all
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 8; j = j + 1) begin
					tlb_valid[i][j] <= 1'b0;
					tlb_tag[i][j] <= 16'd0;
					tlb_ppn[i][j] <= 20'd0;
					tlb_status[i][j] <= 5'd0;
				end
            end
		end else begin
			last_tlb_ppn_we <= tlb_ppn_we_i;
			if (tlb_ppn_we_i && ~last_tlb_ppn_we) begin
				// write the tlb_ppn_i & tlb_status_i to an entry of the set tlb_idx_i
				// look for an entry which is not valid, else substitude the first one
				case (not_valid) 
					8'b0000_0001: begin
						tlb_tag[tlb_idx_i][0]    <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][0]    <= tlb_ppn_i;
						tlb_status[tlb_idx_i][0] <= tlb_status_i;
						tlb_valid[tlb_idx_i][0]  <= 1'b1;
					end
					8'b0000_0010: begin
						tlb_tag[tlb_idx_i][1]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][1]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][1] <= tlb_status_i;
						tlb_valid[tlb_idx_i][1] <= 1'b1;
					end
					8'b0000_0100: begin
						tlb_tag[tlb_idx_i][2]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][2]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][2] <= tlb_status_i;
						tlb_valid[tlb_idx_i][2] <= 1'b1;
					end
					8'b0000_1000: begin
						tlb_tag[tlb_idx_i][3]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][3]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][3] <= tlb_status_i;
						tlb_valid[tlb_idx_i][3] <= 1'b1;
					end
					8'b0001_0000: begin
						tlb_tag[tlb_idx_i][4]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][4]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][4] <= tlb_status_i;
						tlb_valid[tlb_idx_i][4] <= 1'b1;
					end
					8'b0010_0000: begin
						tlb_tag[tlb_idx_i][5]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][5]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][5] <= tlb_status_i;
						tlb_valid[tlb_idx_i][5] <= 1'b1;
					end
					8'b0100_0000: begin
						tlb_tag[tlb_idx_i][6]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][6]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][6] <= tlb_status_i;
						tlb_valid[tlb_idx_i][6] <= 1'b1;
					end
					8'b1000_0000: begin
						tlb_tag[tlb_idx_i][7]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][7]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][7] <= tlb_status_i;
						tlb_valid[tlb_idx_i][7] <= 1'b1;
					end
					default: begin // all valid!
						tlb_tag[tlb_idx_i][0]   <= tlb_tag_i;
						tlb_ppn[tlb_idx_i][0]   <= tlb_ppn_i;
						tlb_status[tlb_idx_i][0] <= tlb_status_i;
						tlb_valid[tlb_idx_i][0] <= 1'b1;
					end
				endcase
			end
		end
	end

	always_comb begin
		if (tlb_ppn_we_i) begin
			tlb_ppn_o = tlb_ppn_i;
			tlb_status_o = tlb_status_i;
			tlb_hit_o = 1'b1;
		end else begin
			// compare the tlb_tag_i to all tlb_tag[tlb_idx_i][0 ~ 7]
			if (tlb_tag_i == tlb_tag[tlb_idx_i][0] && tlb_valid[tlb_idx_i][0]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][0];
				tlb_status_o = tlb_status[tlb_idx_i][0];
				tlb_hit_o = 1'b1;
			end else if (tlb_tag_i == tlb_tag[tlb_idx_i][1] && tlb_valid[tlb_idx_i][1]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][1];
				tlb_status_o = tlb_status[tlb_idx_i][1];
				tlb_hit_o = 1'b1;
			end else if (tlb_tag_i == tlb_tag[tlb_idx_i][2] && tlb_valid[tlb_idx_i][2]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][2];
				tlb_status_o = tlb_status[tlb_idx_i][2];
				tlb_hit_o = 1'b1;
			end else if (tlb_tag_i == tlb_tag[tlb_idx_i][3] && tlb_valid[tlb_idx_i][3]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][3];
				tlb_status_o = tlb_status[tlb_idx_i][3];
				tlb_hit_o = 1'b1;
			end else if (tlb_tag_i == tlb_tag[tlb_idx_i][4] && tlb_valid[tlb_idx_i][4]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][4];
				tlb_status_o = tlb_status[tlb_idx_i][4];
				tlb_hit_o = 1'b1;
			end else if (tlb_tag_i == tlb_tag[tlb_idx_i][5] && tlb_valid[tlb_idx_i][5]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][5];
				tlb_status_o = tlb_status[tlb_idx_i][5];
				tlb_hit_o = 1'b1;
			end else if (tlb_tag_i == tlb_tag[tlb_idx_i][6] && tlb_valid[tlb_idx_i][6]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][6];
				tlb_status_o = tlb_status[tlb_idx_i][6];
				tlb_hit_o = 1'b1;
			end else if (tlb_tag_i == tlb_tag[tlb_idx_i][7] && tlb_valid[tlb_idx_i][7]) begin
				tlb_ppn_o = tlb_ppn[tlb_idx_i][7];
				tlb_status_o = tlb_status[tlb_idx_i][7];
				tlb_hit_o = 1'b1;
			end else begin
				tlb_ppn_o = tlb_ppn_i;
				tlb_status_o = tlb_status_i;
				tlb_hit_o = 1'b0; // not hit, loading
			end
		end
	end

endmodule