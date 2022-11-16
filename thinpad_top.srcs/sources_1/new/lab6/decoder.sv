module decoder(
    input wire [31:0] inst_i,
    
    output logic rf_wen_o,
    output logic [4:0] rd_addr_o,
    output logic [4:0] rs1_addr_o,
    output logic [4:0] rs2_addr_o,
    
    output logic alu_a_sel_o, // pc(0) or rs1(1)?
    output logic alu_b_sel_o, // imm(0) or rs2(1)?
    output logic [3:0] alu_op_o,
    
    output logic [2:0] imm_sel_o, // 5 imm generation patterns and 1 direct out pattern
    output logic [2:0] wb_sel_o, // 4 write back patterns (including csr)
    output logic [3:0] br_op_o,
    output logic [4:0] shamt_o,
    
    output logic [3:0] dm_sel_o, // where to write in DM
    output logic [1:0] dm_op_o,

    //get CSR value from CSR file
    input wire [31:0] mtvec_data_in,
    input wire [31:0] mscratch_data_in,
    input wire [31:0] mepc_data_in,
    input wire [31:0] mcause_data_in,
    input wire [31:0] mstatus_data_in,
    input wire [31:0] mie_data_in,
    input wire [31:0] mip_data_in,
    input wire [1:0] privilege_data_in,

    //output whether CSR is written to
    output logic mtvec_we,
    output logic mscratch_we,
    output logic mepc_we,
    output logic mcause_we,
    output logic mstatus_we,
    output logic mie_we,
    output logic mip_we,
    output logic privilege_we,

    //pass on CSR value to next stage
    output logic [31:0] mtvec_data_out,
    output logic [31:0] mscratch_data_out,
    output logic [31:0] mepc_data_out,
    output logic [31:0] mcause_data_out,
    output logic [31:0] mstatus_data_out,
    output logic [31:0] mie_data_out,
    output logic [31:0] mip_data_out,
    output logic [2:0] privilege_data_out,

    output logic [31:0] direct_branch_addr, // the direct branching addr
    output logic [3:0] csr_code // to handle csr calculation in the next step in an easier way
);  

    // Forwarding the CSR value to handle in exe stage
    assign mtvec_data_out = mtvec_data_in;
    assign mscratch_data_out = mscratch_data_in;
    assign mepc_data_out = mepc_data_in;
    assign mcause_data_out = mcause_data_in;
    assign mstatus_data_out = mstatus_data_in;
    assign mie_data_out = mie_data_in;
    assign mip_data_out = mip_data_in;
    assign privilege_data_out = privilege_data_in;

    logic is_rtype, is_itype, is_btype, is_utype, is_jtype, is_stype;
    
    always_comb begin
        is_rtype = (inst_i[6:0] == 7'b0110011);
        is_itype = (inst_i[6:0] == 7'b0000011 || inst_i[6:0] == 7'b0010011 || inst_i[6:0] == 7'b1100111);
        is_btype = (inst_i[6:0] == 7'b1100011);
        is_utype = (inst_i[6:0] == 7'b0110111 || inst_i[6:0] == 7'b0010111);
        is_jtype = (inst_i[6:0] == 7'b1101111);
        is_stype = (inst_i[6:0] == 7'b0100011);
    end
    
    typedef enum logic [5:0] {
      TIME_INT,
      LUI,
      AUIPC,
      ADD,
      ADDI,
      _AND,
      ANDI,
      _OR,
      ORI,
      _XOR,
      SLLI,
      SRLI,
      SLTU,
      SB,
      SW,
      LB,
      LW,
      BEQ,
      BNE,
      JAL,
      JALR,
      ECALL,
      EBREAK,
      MRET,
      CSRRW,
      CSRRS,
      CSRRC,
      CSRRWI,
      CSRRSI,
      CSRRCI,
      ERR
    } decode_ops;
    
    decode_ops d_op;
  
    always_comb begin
        // First deal with time interrupt
        if (mip_data_in[7] & mie_data_in[7] & (mstatus_data_in[3] | ~privilege_data_in[0])) begin
            d_op = TIME_INT;
        end else if (inst_i[6:0] == 7'b0110111) begin
            d_op = LUI;
        end else if (inst_i[6:0] == 7'b0010111) begin
            d_op = AUIPC;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0110011) begin
            d_op = ADD;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0010011) begin
            d_op = ADDI;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b111 && inst_i[6:0] == 7'b0110011) begin
            d_op = _AND;
        end else if (inst_i[14:12] == 3'b111 && inst_i[6:0] == 7'b0010011) begin
            d_op = ANDI;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b0110011) begin
            d_op = _OR;
        end else if (inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b0010011) begin
            d_op = ORI;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b100 && inst_i[6:0] == 7'b0110011) begin
            d_op = _XOR;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0010011) begin
            d_op = SLLI;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b0010011) begin
            d_op = SRLI;
        end else if (inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b0110011) begin
            d_op = SLTU;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0100011) begin
            d_op = SB;
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0100011) begin
            d_op = SW;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0000011) begin
            d_op = LB;
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0000011) begin
            d_op = LW;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b1100011) begin
            d_op = BEQ;
        end else if (inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b1100011) begin
            d_op = BNE;
        end else if (inst_i[6:0] == 7'b1101111) begin
            d_op = JAL;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b1100111) begin
            d_op = JALR;
        end else if (inst_i[31:20] == 12'h000 && inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b1110011) begin
            d_op = ECALL;
        end else if (inst_i[31:20] == 12'h001 && inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b1110011) begin
            d_op = EBREAK;
        end else if (inst_i[31:20] == 12'h302 && inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b1110011) begin
            d_op = MRET;
        end else if (inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRW;
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRS;
        end else if (inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRC;
        end else if (inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRWI;
        end else if (inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRSI;
        end else if (inst_i[14:12] == 3'b111 && inst_i[6:0] == 7'b1110011) begin
            d_op = CSRRCI;
        end else begin
            d_op = ERR;
        end
    end
    
    always_comb begin
        // for these, we just want it to branch
        if (d_op == TIME_INT || d_op == ECALL || d_op == EBREAK || d_op == MRET) begin
            rd_addr_o = 0;
            rs1_addr_o = 0;
            rs2_addr_o = 0;
            rf_wen_o = 0;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 0;
            imm_sel_o = 0;
            wb_sel_o = 0;
            br_op_o = 3; // we just want to branch directly
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == LUI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = 0;
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 11; // We just want the imm
            imm_sel_o = 1; // 1 represents [31:12]
            wb_sel_o = 1; // write back from ALU output
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == AUIPC) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = 0;
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 0;
            alu_b_sel_o = 0;
            alu_op_o = 1; // We just want the imm
            imm_sel_o = 1; // 1 represents [31:12]
            wb_sel_o = 1; // write back from ALU output
            br_op_o = 2; 
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == ADD) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 1; // 1 is ADD
            imm_sel_o = 0; // 0 represent no imm
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
        end else if (d_op == ADDI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0; // 0 represents choose imm
            alu_op_o = 1; // 1 is ADD
            imm_sel_o = 3; // 3 represents want [11:0]
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == _AND) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 3; // 1 is AND
            imm_sel_o = 0; // 0 represent no imm
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
        end else if (d_op == ANDI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 3; // 3 is AND
            imm_sel_o = 3;
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == _OR) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 4; // 4 is OR
            imm_sel_o = 0; // 0 represent no imm
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
        end else if (d_op == ORI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0; // 0 represents choose imm
            alu_op_o = 4; // 4 is OR
            imm_sel_o = 3; // 3 represents want [11:0]
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == _XOR) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 5; // 4 is XOR
            imm_sel_o = 0; // 0 represent no imm
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
        end else if (d_op == SLLI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0; // 0 represents choose imm
            alu_op_o = 7; // 7 is SLL
            imm_sel_o = 3; // 3 represents want [11:0], but in ALU we select only last 5 bits
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = inst_i[24:20];
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == SRLI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0; // 0 represents choose imm
            alu_op_o = 8; // 8 is SRL
            imm_sel_o = 3; // 3 represents want [11:0], but in ALU we select only last 5 bits
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = inst_i[24:20];
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == SLTU) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0; // 0 represents choose imm
            alu_op_o = 11; // imm directly as output
            imm_sel_o = 6; // we get the imm direct out from rscomp
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == SB) begin
            rd_addr_o = 0;
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 0;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 1; // We always ADD the offfset
            imm_sel_o = 5; // 5 represents [11:5] + [4:0]
            wb_sel_o = 0; // 0 represents do nothing
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 4'b0001; // save the lowest
            dm_op_o = 2; // 2 represents save
        end else if (d_op == SW) begin
            rd_addr_o = 0;
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 0;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 1; // We always ADD the offset
            imm_sel_o = 5; // 5 represents [11:5] + [4:0]
            wb_sel_o = 0; // 0 represents do nothing
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 4'b1111; // save all
            dm_op_o = 2; // 2 represents save
        end else if (d_op == LB) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 1; // We always ADD the offset
            imm_sel_o = 3; // 3 represents [11:0]
            wb_sel_o = 2; // 2 represents do writeback from DM
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 4'b0001; // save the lowest
            dm_op_o = 1; // 1 represents read
        end else if (d_op == LW) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 1; // We always ADD the offset
            imm_sel_o = 3; // 3 represents [11:0]
            wb_sel_o = 2; // 2 represents do writeback from DM
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 4'b1111; // save all
            dm_op_o = 1; // 1 represents read
        end else if (d_op == BEQ) begin
            rd_addr_o = 0;
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 0;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 11; // We just want the imm
            imm_sel_o = 4; // 4 represents [12|10:5] + [4:1|11]
            wb_sel_o = 0; // no write back
            br_op_o = 0; // 0 represents BEQ
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == BNE) begin
            rd_addr_o = 0;
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 0;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 11; // We just want the imm
            imm_sel_o = 4; // 4 represents [12|10:5] + [4:1|11]
            wb_sel_o = 0; // no write back
            br_op_o = 1; // 0 represents BEQ
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == JAL) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = 0;
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 11; // We just want the imm
            imm_sel_o = 2; // 2  represents the unique jal
            wb_sel_o = 3; // write back pc + 4
            br_op_o = 3; // direct branch success
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else if (d_op == JALR) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 12; // We ADD the offset and set last bit to 0
            imm_sel_o = 3;
            wb_sel_o = 3; // write back pc + 4
            br_op_o = 3; // direct branch success
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        // begin to deal with csr
        end else if (d_op == CSRRC || d_op == CSRRCI || d_op == CSRRS || d_op == CSRRSI || d_op == CSRRW || d_op == CSRRWI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 0;
            imm_sel_o = 0;
            wb_sel_o = 4; // write back from csr! choose 4!
            br_op_o = 2; // we do not branch here
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end else begin
            // all default situations
            rd_addr_o = 0;
            rs1_addr_o = 0;
            rs2_addr_o = 0;
            rf_wen_o = 0;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 0;
            imm_sel_o = 0;
            wb_sel_o = 0;
            br_op_o = 2;
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
        end
    end

    // The writing of CSR enable signals
    always_comb begin
        if (d_op == TIME_INT || d_op == ECALL || d_op == EBREAK) begin
            {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00111001;
        end else if (d_op == MRET) begin
            {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00001001;
        end else if (d_op == CSRRC || d_op == CSRRCI || d_op == CSRRS || d_op == CSRRSI || d_op == CSRRW || d_op == CSRRWI) begin
            case(inst_i[31:20])
                12'h305: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b10000000;
                12'h340: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b01000000;
                12'h341: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00100000;
                12'h342: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00010000;
                12'h300: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00001000;
                12'h304: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00000100;
                12'h344: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00000010;
                default: {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00000000;
            endcase
        end else begin
            {mtvec_we, mscratch_we, mepc_we, mcause_we, mstatus_we, mie_we, mip_we, privilege_we} = 8'b00000000;
        end
    end

    // Deal with two specific csr signals
    always_comb begin
        if (d_op == TIME_INT) begin
            direct_branch_addr = {mtvec_data_in[31:2], 2'b00};
            csr_code = 1;
        end else if (d_op == CSRRC) begin
            direct_branch_addr = 0;
            csr_code = 2;
        end else if (d_op == CSRRCI) begin
            direct_branch_addr = 0;
            csr_code = 3;
        end else if (d_op == CSRRS) begin
            direct_branch_addr = 0;
            csr_code = 4;
        end else if (d_op == CSRRSI) begin
            direct_branch_addr = 0;
            csr_code = 5;
        end else if (d_op == CSRRW) begin
            direct_branch_addr = 0;
            csr_code = 6;
        end else if (d_op == CSRRWI) begin
            direct_branch_addr = 0;
            csr_code = 7;
        end else if (d_op == ECALL) begin
            direct_branch_addr = {mtvec_data_in[31:2], 2'b00};
            csr_code = 8;
        end else if (d_op == EBREAK) begin
            direct_branch_addr = {mtvec_data_in[31:2], 2'b00};
            csr_code = 9;
        end else if (d_op == MRET) begin
            direct_branch_addr = mepc_data_in;
            csr_code = 10;
        end else begin
            direct_branch_addr = 0;
            csr_code = 0;
        end
    end
endmodule
