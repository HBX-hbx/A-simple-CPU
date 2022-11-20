module mmu (
	// clk and reset
    input wire clk_i,
    input wire rst_i,

	input wire [1:0] priv_i, // current mode: '11' for M, '01' for S, '00' for U
	input wire [31:0] satp_i, // base addr for root page table satp[19:0]

	// PTE: data read from master
	// PPN: [31:10] Reserved: [9:8] D A G U X W R V
	input wire [31:0] master_data_i, 
	input wire master_ack_i,
	input wire ctrl_ack_i,
	input wire [31:0] vir_addr_i, // virtual addr 1st: [31:22] 2nd: [21:12] offset: [11:0]

	output wire tlb_hit_o,
	output wire is_mmu_on_o,
	output wire [1:0] mmu_state_o, // tell the master which state now
	output reg [31:0] phy_addr_o // translated pa
);

	reg [31:0] master_data_reg;

	reg [31:0] last_phy_addr = 0;

	typedef enum logic [1:0] {
		INIT = 0,  // without va -> pa
        FIRST_PTE = 1,   // Load First Page Table Entry
        SECOND_PTE = 2,  // Load Second Page Table Entry
        DONE = 3         // Form PA
    } state_t;

	state_t state;

	assign mmu_state_o = state;

	assign tlb_hit_o = tlb_hit;

	assign is_mmu_on_o = (~priv_i[0]) & satp_i[31]; // TODO: only for U mode ?

	// TODO: add Page Fault
	// without execute permission

	// to tlb
	reg tlb_ppn_we; // tmp
	reg [19:0] tlb_vpn;
	reg [19:0] w_tlb_ppn; // write to tlb
	// TODO: add flush
	// from tlb
	reg tlb_hit;
	reg [19:0] r_tlb_ppn; // read from tlb, only when tlb_hit = 1 

	assign tlb_vpn = vir_addr_i[31:12];

	TLB mmu_tlb (
      .clk_i (clk_i),
      .rst_i (rst_i),
	  // to tlb
	  .tlb_flush_i (1'b0), // TODO: add sfence.vma to flush
	  .tlb_vpn_i (tlb_vpn),
	  .tlb_ppn_we_i (tlb_ppn_we),
	  .tlb_ppn_i (w_tlb_ppn),
      // from tlb
	  .tlb_ppn_o (r_tlb_ppn),
      .tlb_hit_o (tlb_hit)
	);

	always_comb begin
		phy_addr_o = vir_addr_i;
		w_tlb_ppn = 0;
		tlb_ppn_we = 1'b0;
		case (state)
			INIT: begin
				// state = FIRST_PTE
				if (tlb_hit) begin
					phy_addr_o = is_mmu_on_o ? {r_tlb_ppn, vir_addr_i[11:0]} : vir_addr_i;
				end else begin
					phy_addr_o = is_mmu_on_o ? {satp_i[19:0], vir_addr_i[31:22], 2'b00} : vir_addr_i;
				end
			end
			FIRST_PTE: begin
				if (ctrl_ack_i) begin
					phy_addr_o = last_phy_addr;
				end else begin
					if (tlb_hit) begin
						phy_addr_o = is_mmu_on_o ? {r_tlb_ppn, vir_addr_i[11:0]} : vir_addr_i;
					end else begin
						phy_addr_o = is_mmu_on_o ? {satp_i[19:0], vir_addr_i[31:22], 2'b00} : vir_addr_i;
					end
				end
			end
			SECOND_PTE: begin
				if (master_data_reg[3] | master_data_reg[2] | master_data_reg[1]) begin // leaf
					phy_addr_o = {master_data_reg[29:10], vir_addr_i[11:0]};
				end else begin // find the next PT
					phy_addr_o = {master_data_reg[29:10], vir_addr_i[21:12], 2'b00};
				end
			end
			DONE: begin
				phy_addr_o = {master_data_reg[29:10], vir_addr_i[11:0]};
				w_tlb_ppn = master_data_reg[29:10];
				tlb_ppn_we = 1'b1;
			end
			default: begin
				phy_addr_o = vir_addr_i;
			end
		endcase
	end

	always_ff @ (posedge clk_i) begin
		if (rst_i) begin
			state <= INIT;
			master_data_reg <= 32'h0000_0000;
			// phy_addr_o <= vir_addr_i;
		end else begin
			last_phy_addr <= phy_addr_o;
			case (state)
				INIT: begin
					if (is_mmu_on_o) begin
						state <= FIRST_PTE;
					end
				end
				FIRST_PTE: begin
					// TODO: add TLB hit
					if (~is_mmu_on_o) begin // stop the va->pa
						state <= INIT;
					end else begin
						if (master_ack_i) begin
							master_data_reg <= master_data_i;
							if (tlb_hit) begin
								state <= FIRST_PTE;
							end else begin
								state <= SECOND_PTE;
							end
						end
					end
				end
				SECOND_PTE: begin
					// TODO: add TLB hit
					if (~is_mmu_on_o) begin // stop the va->pa
						state <= INIT;
					end else begin
						if (master_ack_i) begin
							master_data_reg <= master_data_i;
							if (master_data_reg[3] | master_data_reg[2] | master_data_reg[1]) begin
								state <= FIRST_PTE;
							end else begin
								state <= DONE;
							end
						end
					end
				end
				DONE: begin
					// TODO: add TLB hit
					if (~is_mmu_on_o) begin // stop the va->pa
						state <= INIT;
					end else begin
						if (master_ack_i) begin
							master_data_reg <= master_data_i;
							state <= FIRST_PTE;
						end
					end
				end
				default: begin
					state <= INIT;
					// phy_addr_o <= vir_addr_i;
				end
			endcase
		end
	end

endmodule