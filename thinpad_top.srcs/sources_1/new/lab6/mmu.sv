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

	output wire is_mmu_on_o,
	output wire [31:0] mmu_state_o, // tell the master which state now
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

	assign is_mmu_on_o = (~priv_i[0]) & satp_i[31]; // TODO: only for U mode ?

	// TODO: add Page Fault
	// without execute permission

	always_comb begin
		phy_addr_o = vir_addr_i;
		case (state)
			INIT: begin
				// state = FIRST_PTE
				phy_addr_o = is_mmu_on_o ? {satp_i[19:0], vir_addr_i[31:22], 2'b00} : vir_addr_i;
			end
			FIRST_PTE: begin
				if (ctrl_ack_i) begin
					phy_addr_o = last_phy_addr;
				end else begin
					phy_addr_o = is_mmu_on_o ? {satp_i[19:0], vir_addr_i[31:22], 2'b00} : vir_addr_i;
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
					// if (~is_mmu_on_o) begin // stop the va->pa
					// 	state <= INIT;
					// end else begin
					// 	if (master_ack_i) begin
					// 		state <= FIRST_PTE;
					// 		// phy_addr_o <= {satp_i[19:0], vir_addr_i[31:22], 2'b00};
					// 	end
					// end
				end
				FIRST_PTE: begin
					// TODO: add TLB hit
					if (~is_mmu_on_o) begin // stop the va->pa
						state <= INIT;
					end else begin
						if (master_ack_i) begin
							master_data_reg <= master_data_i;
							state <= SECOND_PTE;
							// phy_addr_o <= {satp_i[19:0], vir_addr_i[31:22], 2'b00};
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
								// phy_addr_o <= {master_data_reg[29:10], vir_addr_i[11:0]};
							end else begin
								// phy_addr_o <= {master_data_reg[29:10], vir_addr_i[21:12], 2'b00};
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
							// TODO: when ack = 0 jump to FIRST?
							state <= FIRST_PTE;
							// phy_addr_o <= {master_data_reg[29:10], vir_addr_i[11:0]};
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