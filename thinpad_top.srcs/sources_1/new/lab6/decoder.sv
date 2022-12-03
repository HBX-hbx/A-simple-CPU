module decoder(
    input wire [31:0] inst_i,
    input wire time_int_i,
    input wire page_fault_i, // '1': pg, '0' normal
    
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

    output logic tlb_flush_o,

    output logic fence_o
);  
  
    typedef enum logic [6:0] {
      TIME_INT,
      LUI,
      AUIPC,
      SUB, //
      ADD,
      ADDI,
      _AND,
      ANDI,
      _OR,
      ORI,
      _XOR,
      XORI, //
      SLL, //
      SLLI,
      SRL, //
      SRLI,
      SRA, //
      SRAI, //
      SLTI, //
      SLTIU, //
      SLT, //
      SLTU,
      SB,
      SH,
      SW,
      LB,
      LH,
      LW,
      LBU,
      LHU,
      BEQ,
      BNE,
      BLT,
      BGE,
      BLTU,
      BGEU,
      JAL,
      JALR,
      ECALL,
      EBREAK,
      MRET,
      SRET,
      CSRRW,
      CSRRS,
      CSRRC,
      CSRRWI,
      CSRRSI,
      CSRRCI,
      SFENCE_VMA,
      PAGE_FAULT,
      FENCE_I,
      ERR
    } decode_ops;
    
    decode_ops d_op;
  
    always_comb begin
        // First deal with page fault and time interrupt
        if (page_fault_i) begin
            d_op = PAGE_FAULT;
        end else if (time_int_i) begin
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
        end else if (inst_i[14:12] == 3'b100 && inst_i[6:0] == 7'b0010011) begin
            d_op = XORI;
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0010011) begin
            d_op = SLTI;
        end else if (inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b0010011) begin
            d_op = SLTIU;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0010011) begin
            d_op = SLLI;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b0110011) begin
            d_op = SRL;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b0010011) begin
            d_op = SRLI;
        end else if (inst_i[31:25] == 7'b0100000 && inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b0110011) begin
            d_op = SRA;
        end else if (inst_i[31:25] == 7'b0100000 && inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b0010011) begin
            d_op = SRAI;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b011 && inst_i[6:0] == 7'b0110011) begin
            d_op = SLTU;
        end else if (inst_i[31:25] == 7'b0100000 && inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0110011) begin
            d_op = SUB;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0110011) begin
            d_op = SLL;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0110011) begin
            d_op = SLT;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0100011) begin
            d_op = SB;
        end else if (inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0100011) begin
            d_op = SH;
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0100011) begin
            d_op = SW;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0000011) begin
            d_op = LB;
        end else if (inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0000011) begin
            d_op = LH;
        end else if (inst_i[14:12] == 3'b010 && inst_i[6:0] == 7'b0000011) begin
            d_op = LW;
        end else if (inst_i[14:12] == 3'b100 && inst_i[6:0] == 7'b0000011) begin
            d_op = LBU;
        end else if (inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b0000011) begin
            d_op = LHU;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b1100011) begin
            d_op = BEQ;
        end else if (inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b1100011) begin
            d_op = BNE;
        end else if (inst_i[14:12] == 3'b100 && inst_i[6:0] == 7'b1100011) begin
            d_op = BLT;
        end else if (inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b1100011) begin
            d_op = BGE;
        end else if (inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b1100011) begin
            d_op = BLTU;
        end else if (inst_i[14:12] == 3'b111 && inst_i[6:0] == 7'b1100011) begin
            d_op = BGEU;
        end else if (inst_i[6:0] == 7'b1101111) begin
            d_op = JAL;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b1100111) begin
            d_op = JALR;
        end else if (inst_i[31:20] == 12'h000 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = ECALL;
        end else if (inst_i[31:20] == 12'h001 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = EBREAK;
        end else if (inst_i[31:20] == 12'h302 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = MRET;
        end else if (inst_i[31:25] == 7'b0001001 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = SFENCE_VMA;
        end else if (inst_i[31:20] == 12'h102 && inst_i[19:15] == 5'b00000 && inst_i[14:12] == 3'b000 && inst_i[11:7] == 5'b00000 && inst_i[6:0] == 7'b1110011) begin
            d_op = SRET;
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
        end else if (inst_i == 32'b0000_0000_0000_0000_0001_0000_0000_1111) begin
            d_op = FENCE_I;
        end else begin
            d_op = ERR;
        end
    end
    
    always_comb begin
        // for these, we just want it to branch
        if (d_op == TIME_INT || d_op == ECALL || d_op == EBREAK || d_op == MRET || d_op == SRET || d_op == PAGE_FAULT) begin
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
            tlb_flush_o = 0;
            fence_o = 0;
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
            tlb_flush_o = 0;
            fence_o = 0;
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
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == SUB) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = 1;
            alu_op_o = 2; // 2 is SUB
            imm_sel_o = 0;
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == ADD || d_op == ADDI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == ADD) ? inst_i[24:20] : 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = (d_op == ADD) ? 1 : 0; // 0 represents choose imm
            alu_op_o = 1; // 1 is ADD
            imm_sel_o = (d_op == ADD) ? 0 : 3; // 0 represent no imm, 3 represents want [11:0]
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == _AND || d_op == ANDI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == _AND) ? inst_i[24:20] : 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = (d_op == _AND) ? 1 : 0; // 0 represents choose imm
            alu_op_o = 3; // 3 is AND
            imm_sel_o = (d_op == _AND) ? 0 : 3; // 0 represent no imm, 3 represents want [11:0]
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == _OR || d_op == ORI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == _OR) ? inst_i[24:20] : 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = (d_op == _OR) ? 1 : 0; // 0 represents choose imm
            alu_op_o = 4; // 4 is OR
            imm_sel_o = (d_op == _OR) ? 0 : 3; // 0 represent no imm, 3 represents want [11:0]
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == _XOR || d_op == XORI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == _XOR) ? inst_i[24:20] : 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = (d_op == _XOR) ? 1 : 0; // 0 represents choose imm
            alu_op_o = 5; // 5 is XOR
            imm_sel_o = (d_op == _XOR) ? 0 : 3; // 0 represent no imm, 3 represents want [11:0]
            wb_sel_o = 1; // 1 represent wb data comes from ALU
            br_op_o = 2; // no branch op
            shamt_o = 0; // no shamt
            dm_sel_o = 0; // no dm sel
            dm_op_o = 0; // no dm op
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == SLL || d_op == SLLI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == SLL) ? inst_i[24:20] : 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = (d_op == SLL) ? 1 : 0; // 0 represents choose imm
            alu_op_o = 7; // 7 is SLL
            imm_sel_o = (d_op == SLL) ? 0 : 3; // 0 represent no imm, 3 represents want [11:0]
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = inst_i[24:20];
            dm_sel_o = 0;
            dm_op_o = 0;
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == SRL || d_op == SRLI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == SRL) ? inst_i[24:20] : 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = (d_op == SRL) ? 1 : 0; // 0 represents choose imm
            alu_op_o = 8; // 8 is SRL
            imm_sel_o = (d_op == SRL) ? 0 : 3; // 0 represent no imm, 3 represents want [11:0]
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = inst_i[24:20];
            dm_sel_o = 0;
            dm_op_o = 0;
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == SRA || d_op == SRAI) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == SRA) ? inst_i[24:20] : 0;
            rf_wen_o = 1;
            alu_a_sel_o = 1;
            alu_b_sel_o = (d_op == SRA) ? 1 : 0; // 0 represents choose imm
            alu_op_o = 9; // 9 is SRA
            imm_sel_o = (d_op == SRA) ? 0 : 3; // 0 represent no imm, 3 represents want [11:0]
            wb_sel_o = 1;
            br_op_o = 2;
            shamt_o = inst_i[24:20];
            dm_sel_o = 0;
            dm_op_o = 0;
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == SLT || d_op == SLTU || d_op == SLTI || d_op == SLTIU) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = (d_op == SLT || d_op == SLTU) ? inst_i[24:20] : 0;
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
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == SB || d_op == SH || d_op == SW) begin
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
            if (d_op == SB) dm_sel_o = 4'b0001; // save the lowest
            else if (d_op == SH) dm_sel_o = 4'b0011; // save half
            else dm_sel_o = 4'b1111; // save all
            dm_op_o = 2; // 2 represents save
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == LB || d_op == LH || d_op == LW || d_op == LBU || d_op == LHU) begin
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
            // We distinguish between signed and unsigned in wb_mux, default to unsigned
            if (d_op == LB || d_op == LBU) dm_sel_o = 4'b0001; // load the lowest
            else if (d_op == LH || d_op == LHU) dm_sel_o = 4'b0011; // load half
            else dm_sel_o = 4'b1111; // save all
            dm_op_o = 1; // 1 represents read
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == BEQ || d_op == BNE || d_op == BGE || d_op == BLT || d_op == BGEU || d_op == BLTU) begin
            rd_addr_o = 0;
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 0;
            alu_a_sel_o = 1;
            alu_b_sel_o = 0;
            alu_op_o = 11; // We just want the imm
            imm_sel_o = 4; // 4 represents [12|10:5] + [4:1|11]
            wb_sel_o = 0; // no write back
            br_op_o = {1'b0, inst_i[14:12]}; // Use the operation code
            shamt_o = 0;
            dm_sel_o = 0;
            dm_op_o = 0;
            tlb_flush_o = 0;
            fence_o = 0;
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
            tlb_flush_o = 0;
            fence_o = 0;
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
            tlb_flush_o = 0;
            fence_o = 0;
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
            tlb_flush_o = 0;
            fence_o = 0;
        end else if (d_op == SFENCE_VMA) begin
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
            tlb_flush_o = 1; // flush
            fence_o = 0;
        end else if (d_op == FENCE_I) begin
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
            tlb_flush_o = 0;
            fence_o = 1; // fence
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
            tlb_flush_o = 0;
            fence_o = 0;
        end
    end

endmodule
