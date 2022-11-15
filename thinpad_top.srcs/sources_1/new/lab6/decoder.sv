module decoder(
    input wire [31:0] inst_i,
    
    output logic rf_wen_o,
    output logic [4:0] rd_addr_o,
    output logic [4:0] rs1_addr_o,
    output logic [4:0] rs2_addr_o,
    
    output logic alu_a_sel_o, // pc(0) or rs1(1)?
    output logic alu_b_sel_o, // imm(0) or rs2(1)?
    output logic [3:0] alu_op_o,
    
    output logic [2:0] imm_sel_o, // 5 imm generation patterns
    output logic [1:0] wb_sel_o, // 3 write back patterns
    output logic [3:0] br_op_o,
    output logic [4:0] shamt_o,
    
    output logic [3:0] dm_sel_o, // where to write in DM
    output logic [1:0] dm_op_o
);  

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
      SB,
      SW,
      LB,
      LW,
      BEQ,
      BNE,
      JAL,
      JALR,
      CTZ,
      MINU,
      SBCLR,
      ERR
    } decode_ops;
    
    decode_ops d_op;
  
    always_comb begin
        if (inst_i[6:0] == 7'b0110111) begin
            d_op = LUI;
        end else if (inst_i[6:0] == 7'b0010111) begin
            d_op = AUIPC;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0110011) begin
            d_op = ADD;
        end else if (inst_i[14:12] == 3'b000 && inst_i[6:0] == 7'b0010011) begin
            d_op = ADDI;
        end else if (inst_i[14:12] == 3'b111 && inst_i[6:0] == 7'b0110011) begin
            d_op = _AND;
        end else if (inst_i[14:12] == 3'b111 && inst_i[6:0] == 7'b0010011) begin
            d_op = ANDI;
        end else if (inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b0110011) begin
            d_op = _OR;
        end else if (inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b0010011) begin
            d_op = ORI;
        end else if (inst_i[14:12] == 3'b100 && inst_i[6:0] == 7'b0110011) begin
            d_op = _XOR;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0010011) begin
            d_op = SLLI;
        end else if (inst_i[31:25] == 7'b0000000 && inst_i[14:12] == 3'b101 && inst_i[6:0] == 7'b0010011) begin
            d_op = SRLI;
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
        end else if (inst_i[31:25] == 7'b0110000 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0010011) begin
            d_op = CTZ;
        end else if (inst_i[31:25] == 7'b0000101 && inst_i[14:12] == 3'b110 && inst_i[6:0] == 7'b0110011) begin
            d_op = MINU;
        end else if (inst_i[31:25] == 7'b0100100 && inst_i[14:12] == 3'b001 && inst_i[6:0] == 7'b0110011) begin
            d_op = SBCLR;
        end else begin
            d_op = ERR;
        end
    end
    
    always_comb begin
        if (d_op == LUI) begin
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
        // All these inst go through extra inst handler, where data_o is passed to imm_g and then ALU
        end else if (d_op == CTZ || d_op == MINU || d_op == SBCLR) begin
            rd_addr_o = inst_i[11:7];
            rs1_addr_o = inst_i[19:15];
            rs2_addr_o = inst_i[24:20];
            rf_wen_o = 1;
            alu_a_sel_o = 1; 
            alu_b_sel_o = 0; // Want IMM out
            alu_op_o = 11; // IMM Directly out
            imm_sel_o = 6; // we want directly out from IMM Generator
            wb_sel_o = 1; // write back from ALU
            br_op_o = 2; // no branch op
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
endmodule
