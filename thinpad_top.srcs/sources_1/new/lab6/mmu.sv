module mmu (
	// clk and reset
    input wire clk_i,
    input wire rst_i,

	input wire [1:0] priv_i, // current mode: '11' for M, '01' for S, '00' for U
	input wire [31:0] satp_i, // base addr for root page table satp[19:0]

	input wire tlb_flush_i,
	input wire is_requesting_i, // cyc / stb

	input wire master_type_i, // '0' for im, '1' for dm
	input wire [1:0] master_rw_type_i, // '01' for read, '10' for write

	input wire [31:0] pc_i, // if_pc or mem_pc

	// PTE: data read from master
	// PPN: [31:10] Reserved: [9:8] D A G U X W R V
	input wire [31:0] master_data_i, 
	input wire master_ack_i,
	input wire ctrl_ack_i,
	input wire [31:0] vir_addr_i, // virtual addr 1st: [31:22] 2nd: [21:12] offset: [11:0]

	// '00': without pg,     '01': Inst Page Fault
	// '10': Load Page Fault '11': Store Page Fault
	output reg [1:0] page_fault_code_o,
	output reg [31:0] page_fault_addr_o,

	output wire tlb_hit_o,
	output reg  is_mmu_on_o,
	output wire [1:0] mmu_state_o, // tell the master which state now
	output reg [31:0] phy_addr_o // translated pa
);

	reg [31:0] master_data_reg;

	reg [31:0] last_phy_addr = 0;
	reg [1:0]  page_fault_code = 0;
	reg [1:0]  last_page_fault_code = 0;
	reg [31:0] last_pc = 0;

	typedef enum logic [1:0] {
		INIT = 0,  // without va -> pa
        FIRST_PTE = 1,   // Load First Page Table Entry
        SECOND_PTE = 2,  // Load Second Page Table Entry
        DONE = 3         // Form PA
    } state_t;

	state_t state;

	assign mmu_state_o = state;

	// to tlb
	reg tlb_ppn_we; // tmp
	reg [19:0] tlb_vpn;
	reg [19:0] w_tlb_ppn; // write to tlb
	reg [4:0]  w_tlb_status; // write to tlb
	// from tlb
	reg tlb_hit; // hit longer
	reg [19:0] r_tlb_ppn; // read from tlb, only when tlb_hit = 1 
	reg [4:0]  r_tlb_status;

	assign tlb_vpn = vir_addr_i[31:12];
	assign tlb_hit = tlb_hit_o;

	TLB mmu_tlb (
      .clk_i (clk_i),
      .rst_i (rst_i),
	  // to tlb
	  .tlb_flush_i (tlb_flush_i),
	  .tlb_vpn_i (tlb_vpn),
	  .tlb_ppn_we_i (tlb_ppn_we),
	  .tlb_ppn_i (w_tlb_ppn),
	  .tlb_status_i (w_tlb_status),
      // from tlb
	  .tlb_ppn_o (r_tlb_ppn),
	  .tlb_status_o (r_tlb_status),
      .tlb_hit_o (tlb_hit_o)
	);

	// 1. Attempting to fetch an instruction from a page that does not have execute permissions raises a
	//    fetch page-fault exception. 
	// 2. Attempting to execute a load or load-reserved instruction whose effective
	//    address lies within a page without read permissions raises a load page-fault exception. 
	// 3. Attempting to execute a store without write permissions raises a store page-fault exception
	// 4. U-mode software may only access the page when U=1. ?
	// TODO:5. what about S mode program access a page whose U=1 ? (sstatus)

	assign is_mmu_on_o = (priv_i == 2'b01 || priv_i == 2'b00) & satp_i[31]; // for S mode and U mode
	assign page_fault_code_o = master_type_i ? (last_pc != pc_i ? 2'b00 : (page_fault_code | last_page_fault_code))
								: (page_fault_code | last_page_fault_code);

	always_comb begin
		page_fault_code = 2'b00;
		page_fault_addr_o = vir_addr_i;
		// U X W R V
		case (state)
			INIT: begin
				if (tlb_hit && is_mmu_on_o) begin
					if (master_type_i) begin // dm
						if (master_rw_type_i == 2'b10) begin // write
							if (~r_tlb_status[0] || (~r_tlb_status[1] && r_tlb_status[2])) begin
								// not valid
								page_fault_code = 2'b11; // Store Page Fault
								page_fault_addr_o = vir_addr_i;
							end else if (~r_tlb_status[2] || (priv_i == 2'b00 && ~r_tlb_status[4])) begin
								page_fault_code = 2'b11; // Store Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end else if (master_rw_type_i == 2'b01) begin // read
							if (~r_tlb_status[0] || (~r_tlb_status[1] && r_tlb_status[2])) begin
								// not valid
								page_fault_code = 2'b10; // Load Page Fault
								page_fault_addr_o = vir_addr_i;
							end else if (~r_tlb_status[1] || (priv_i == 2'b00 && ~r_tlb_status[4])) begin
								page_fault_code = 2'b10; // Load Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end
					end else begin // im
						if (~r_tlb_status[0] || (~r_tlb_status[1] && r_tlb_status[2])) begin
							// not valid
							page_fault_code = 2'b01; // Instr Page Fault
							page_fault_addr_o = vir_addr_i;
						end else if (~r_tlb_status[3] || (priv_i == 2'b00 && ~r_tlb_status[4]) || (priv_i == 2'b01 && r_tlb_status[4])) begin // without Execute permission
							page_fault_code = 2'b01; // Instr Page Fault
							page_fault_addr_o = vir_addr_i;
						end
					end
				end
			end
			FIRST_PTE: begin
				if (tlb_hit && is_mmu_on_o) begin
					if (master_type_i) begin // dm
						if (master_rw_type_i == 2'b10) begin // write
							if (~r_tlb_status[0] || (~r_tlb_status[1] && r_tlb_status[2])) begin
								// not valid
								page_fault_code = 2'b11; // Store Page Fault
								page_fault_addr_o = vir_addr_i;
							end else if (~r_tlb_status[2] || (priv_i == 2'b00 && ~r_tlb_status[4])) begin
								page_fault_code = 2'b11; // Store Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end else if (master_rw_type_i == 2'b01) begin // read
							if (~r_tlb_status[0] || (~r_tlb_status[1] && r_tlb_status[2])) begin
								// not valid
								page_fault_code = 2'b10; // Load Page Fault
								page_fault_addr_o = vir_addr_i;
							end else if (~r_tlb_status[1] || (priv_i == 2'b00 && ~r_tlb_status[4])) begin
								page_fault_code = 2'b10; // Load Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end
					end else begin // im
						if (~r_tlb_status[0] || (~r_tlb_status[1] && r_tlb_status[2])) begin
							// not valid
							page_fault_code = 2'b01; // Instr Page Fault
							page_fault_addr_o = vir_addr_i;
						end else if (~r_tlb_status[3] || (priv_i == 2'b00 && ~r_tlb_status[4]) || (priv_i == 2'b01 && r_tlb_status[4])) begin // without Execute permission
							page_fault_code = 2'b01; // Instr Page Fault
							page_fault_addr_o = vir_addr_i;
						end
					end
				end
			end
			SECOND_PTE: begin
				if (master_type_i) begin // dm
					if (master_rw_type_i == 2'b10) begin // write
						if (~master_data_reg[0] || (~master_data_reg[1] && master_data_reg[2])) begin
							// not valid
							page_fault_code = 2'b11; // Store Page Fault
							page_fault_addr_o = vir_addr_i;
						end else begin
							// valid
							if ((master_data_reg[3] | master_data_reg[1]) && (~master_data_reg[2] || (priv_i == 2'b00 && ~r_tlb_status[4]))) begin
								page_fault_code = 2'b11; // Store Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end
					end else if (master_rw_type_i == 2'b01) begin // read
						if (~master_data_reg[0] || (~master_data_reg[1] && master_data_reg[2])) begin
							// not valid
							page_fault_code = 2'b10; // Load Page Fault
							page_fault_addr_o = vir_addr_i;
						end else begin
							// valid
							if ((master_data_reg[3] | master_data_reg[1]) && (~master_data_reg[1] || (priv_i == 2'b00 && ~r_tlb_status[4]))) begin
								page_fault_code = 2'b10; // Load Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end
					end
				end else begin // im
					if (~master_data_reg[0] || (~master_data_reg[1] && master_data_reg[2])) begin
						// not valid
						page_fault_code = 2'b01; // Instr Page Fault
						page_fault_addr_o = vir_addr_i;
					end else begin
						// valid
						if ((master_data_reg[3] | master_data_reg[1]) && (~master_data_reg[3] || (priv_i == 2'b00 && ~r_tlb_status[4]) || (priv_i == 2'b01 && r_tlb_status[4]))) begin // without Execute permission
							page_fault_code = 2'b01; // Instr Page Fault
							page_fault_addr_o = vir_addr_i;
						end
					end
				end
			end
			DONE: begin
				if (master_type_i) begin // dm
					if (master_rw_type_i == 2'b10) begin // write
						if (~master_data_reg[0] || (~master_data_reg[1] && master_data_reg[2])) begin
							// not valid
							page_fault_code = 2'b11; // Store Page Fault
							page_fault_addr_o = vir_addr_i;
						end else begin
							// valid
							if ((master_data_reg[3] | master_data_reg[1]) && (~master_data_reg[2] || (priv_i == 2'b00 && ~r_tlb_status[4]))) begin
								page_fault_code = 2'b11; // Store Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end
					end else if (master_rw_type_i == 2'b01) begin // read
						if (~master_data_reg[0] || (~master_data_reg[1] && master_data_reg[2])) begin
							// not valid
							page_fault_code = 2'b10; // Load Page Fault
							page_fault_addr_o = vir_addr_i;
						end else begin
							// valid
							if ((master_data_reg[3] | master_data_reg[1]) && (~master_data_reg[1] || (priv_i == 2'b00 && ~r_tlb_status[4]))) begin
								page_fault_code = 2'b10; // Load Page Fault
								page_fault_addr_o = vir_addr_i;
							end
						end
					end
				end else begin // im
					if (~master_data_reg[0] || (~master_data_reg[1] && master_data_reg[2])) begin
						// not valid
						page_fault_code = 2'b01; // Instr Page Fault
						page_fault_addr_o = vir_addr_i;
					end else begin
						// valid
						if ((master_data_reg[3] | master_data_reg[1]) && (~master_data_reg[3] || (priv_i == 2'b00 && ~r_tlb_status[4]) || (priv_i == 2'b01 && r_tlb_status[4]))) begin // without Execute permission
							page_fault_code = 2'b01; // Instr Page Fault
							page_fault_addr_o = vir_addr_i;
						end
					end
				end
			end
			default: begin
				page_fault_code = 2'b00;
				page_fault_addr_o = vir_addr_i;
			end
		endcase
	end

	always_comb begin
		phy_addr_o = vir_addr_i;
		w_tlb_ppn = 0;
		w_tlb_status = 0;
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
				// if (ctrl_ack_i) begin
				// 	phy_addr_o = last_phy_addr;
				// end else begin
				if (tlb_hit || tlb_flush_i) begin
					phy_addr_o = is_mmu_on_o ? {r_tlb_ppn, vir_addr_i[11:0]} : vir_addr_i;
				end else begin
					phy_addr_o = is_mmu_on_o ? {satp_i[19:0], vir_addr_i[31:22], 2'b00} : vir_addr_i;
				end
				// end
			end
			SECOND_PTE: begin
				if (master_data_reg[3] | master_data_reg[2] | master_data_reg[1]) begin // leaf
					phy_addr_o = {master_data_reg[29:10], vir_addr_i[11:0]};
					w_tlb_ppn = master_data_reg[29:10];
					w_tlb_status = master_data_reg[4:0];
					tlb_ppn_we = 1'b1;
				end else begin // find the next PT
					phy_addr_o = {master_data_reg[29:10], vir_addr_i[21:12], 2'b00};
				end
			end
			DONE: begin
				phy_addr_o = {master_data_reg[29:10], vir_addr_i[11:0]};
				w_tlb_ppn = master_data_reg[29:10];
				w_tlb_status = master_data_reg[4:0];
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
			last_pc <= pc_i;
			last_phy_addr <= phy_addr_o;

			if (last_page_fault_code == 2'b00 && page_fault_code != 2'b00) begin
				last_page_fault_code <= page_fault_code;
			end else if (last_pc != pc_i) begin
				last_page_fault_code <= 2'b00;
			end

			case (state)
				INIT: begin
					if (is_mmu_on_o && page_fault_code == 2'b00) begin
						state <= FIRST_PTE;
					end
				end
				FIRST_PTE: begin
					if (~is_mmu_on_o || page_fault_code != 2'b00) begin // stop the va->pa
						state <= INIT;
					end else begin
						if (master_ack_i) begin
							master_data_reg <= master_data_i;
							if (tlb_hit || tlb_flush_i) begin
								state <= FIRST_PTE;
							end else begin
								state <= SECOND_PTE;
							end
						end
					end
				end
				SECOND_PTE: begin
					if (~is_mmu_on_o || page_fault_code != 2'b00) begin // stop the va->pa
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
					if (~is_mmu_on_o || page_fault_code != 2'b00) begin // stop the va->pa
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
				end
			endcase
		end
	end

endmodule