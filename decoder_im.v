module decoder_im (
    input  wire [31:0] inst,
    
    // ex stage
    output wire [ 1:0] sel_src1,
    output wire        sel_src2,
    // output wire [4:0] rs1, rs2,
    output wire [31:0] imm,

    // alu part
    output wire [ 9:0] alu_op,

    // bru part
    output wire [ 7:0] bru_op,

    // lsu part
    output wire [ 5:0] lsu_op,

    // mul part
    output wire [ 3:0] mul_op,

    // div part
    output wire [ 2:0] div_op,

    // csr part
    output wire [ 3:0] csr_op,
    output wire [11:0] csr_addr,
    output wire        csr_wdata_sel,
    output wire [31:0] csr_vec_l,

    output wire [ 3:0] sel_rf_res,

    // wb stage 
    output wire        rf_we,
    output wire [ 4:0] rf_waddr
);
    wire [ 6:0] opcode  , funct7;
    wire [15:0] opcode_l, funct7_l;
    wire [ 7:0] opcode_h, funct7_h;
    wire [ 4:0] rs1, rs2;
    wire [ 4:0] rd, shamt;
    wire [ 2:0] funct3;
    wire [ 7:0] funct3_d;
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j, zimm;

    // define inst
    wire inst_sll, inst_slli, inst_srl, inst_srli, inst_sra, inst_srai;
    wire inst_add, inst_addi, inst_sub, inst_lui, inst_auipc;
    wire inst_xor, inst_xori, inst_or, inst_ori, inst_and, inst_andi;
    wire inst_slt, inst_slti, inst_sltu, inst_sltiu;
    wire inst_beq, inst_bne, inst_blt, inst_bge, inst_bltu, inst_bgeu;
    wire inst_jal, inst_jalr, inst_fence, inst_fence_i, inst_ecall, inst_ebreak, inst_mret;
    wire inst_csrrw, inst_csrrs, inst_csrrc, inst_csrrwi, inst_csrrsi, inst_csrrci;
    wire inst_lb, inst_lh, inst_lbu, inst_lhu, inst_lw;
    wire inst_sb, inst_sh, inst_sw;
    wire inst_mul, inst_mulh, inst_mulhsu, inst_mulhu;
    wire inst_div, inst_divu, inst_rem, inst_remu;

    // define alu op
    wire op_add,  op_sub, op_sll, op_slt;
    wire op_sltu, op_xor, op_srl, op_sra;
    wire op_or,   op_and;

    // define div op
    wire div, rem;
    wire signed_div;

    // define csr op
    wire csr_we;
    wire op_csrrw;
    wire op_csrrs;
    wire op_csrrc;

    assign opcode   = inst[ 6: 0];
    assign rd       = inst[11: 7];
    assign funct3   = inst[14:12];
    assign rs1      = inst[19:15];
    assign rs2      = inst[24:20];
    assign shamt    = inst[24:20];
    assign funct7   = inst[31:25]; 

    // sext(imm)
    assign imm_i = {{20{funct7[6]}}, funct7, rs2};
    assign imm_s = {{20{funct7[6]}}, funct7, rd};
    assign imm_b = {{20{funct7[6]}}, rd[0], funct7[5:0], rd[4:1], 1'b0};
    assign imm_u = {inst[31:12], 12'b0};
    assign imm_j = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    // zext(imm)
    assign zimm  = {27'b0,inst[19:15]};

    decoder_4_16 u0_decoder(
    	.in  (opcode[3:0]  ),
        .out (opcode_l )
    );

    decoder_3_8 u1_decoder(
    	.in  (opcode[6:4]  ),
        .out (opcode_h )
    );
    
    decoder_3_8 u2_decoder(
    	.in  (funct3  ),
        .out (funct3_d)
    );
    
    decoder_4_16 u3_decoder(
    	.in  (funct7[3:0]  ),
        .out (funct7_l )
    );
    
    decoder_3_8 u4_decoder(
    	.in  (funct7[6:4]  ),
        .out (funct7_h )
    );
    

    // decode inst
    assign inst_lui     = opcode_h[3'b011] & opcode_l[4'b0111];
    assign inst_auipc   = opcode_h[3'b001] & opcode_l[4'b0111];
    assign inst_jal     = opcode_h[3'b110] & opcode_l[4'b1111];
    assign inst_jalr    = opcode_h[3'b110] & opcode_l[4'b0111];

    assign inst_beq     = opcode_h[3'b110] & opcode_l[4'b0011] & funct3_d[3'b000];
    assign inst_bne     = opcode_h[3'b110] & opcode_l[4'b0011] & funct3_d[3'b001];
    assign inst_blt     = opcode_h[3'b110] & opcode_l[4'b0011] & funct3_d[3'b100];
    assign inst_bge     = opcode_h[3'b110] & opcode_l[4'b0011] & funct3_d[3'b101];
    assign inst_bltu    = opcode_h[3'b110] & opcode_l[4'b0011] & funct3_d[3'b110];
    assign inst_bgeu    = opcode_h[3'b110] & opcode_l[4'b0011] & funct3_d[3'b111];

    assign inst_lb      = opcode_h[3'b000] & opcode_l[4'b0011] & funct3_d[3'b000];
    assign inst_lh      = opcode_h[3'b000] & opcode_l[4'b0011] & funct3_d[3'b001];
    assign inst_lw      = opcode_h[3'b000] & opcode_l[4'b0011] & funct3_d[3'b010];
    assign inst_lbu     = opcode_h[3'b000] & opcode_l[4'b0011] & funct3_d[3'b100];
    assign inst_lhu     = opcode_h[3'b000] & opcode_l[4'b0011] & funct3_d[3'b101];

    assign inst_sb      = opcode_h[3'b010] & opcode_l[4'b0011] & funct3_d[3'b000];
    assign inst_sh      = opcode_h[3'b010] & opcode_l[4'b0011] & funct3_d[3'b001];
    assign inst_sw      = opcode_h[3'b010] & opcode_l[4'b0011] & funct3_d[3'b010];

    assign inst_addi    = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b000];
    assign inst_slti    = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b010];
    assign inst_sltiu   = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b011];
    assign inst_xori    = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b100];
    assign inst_ori     = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b110];
    assign inst_andi    = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b111];

    assign inst_slli    = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b001] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_srli    = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b101] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_srai    = opcode_h[3'b001] & opcode_l[4'b0011] & funct3_d[3'b101] & funct7_h[3'b010] & funct7_l[4'b0000];

    assign inst_add     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b000] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_sub     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b000] & funct7_h[3'b010] & funct7_l[4'b0000];
    assign inst_sll     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b001] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_slt     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b010] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_sltu    = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b011] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_xor     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b100] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_srl     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b101] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_sra     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b101] & funct7_h[3'b010] & funct7_l[4'b0000];
    assign inst_or      = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b110] & funct7_h[3'b000] & funct7_l[4'b0000];
    assign inst_and     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b111] & funct7_h[3'b000] & funct7_l[4'b0000];

    assign inst_ecall   = opcode_h[3'b111] & opcode_l[4'b0011] & ~(|inst[31:7]);
    assign inst_ebreak  = opcode_h[3'b111] & opcode_l[4'b0011] & ~(|inst[31:21]) & inst[20] & ~(|inst[19:7]);

    assign inst_mul     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b000] & funct7_h[3'b000] & funct7_l[4'b0001];
    assign inst_mulh    = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b001] & funct7_h[3'b000] & funct7_l[4'b0001];
    assign inst_mulhsu  = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b010] & funct7_h[3'b000] & funct7_l[4'b0001];
    assign inst_mulhu   = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b011] & funct7_h[3'b000] & funct7_l[4'b0001];
    
    assign inst_div     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b100] & funct7_h[3'b000] & funct7_l[4'b0001];
    assign inst_divu    = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b101] & funct7_h[3'b000] & funct7_l[4'b0001];
    
    assign inst_rem     = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b110] & funct7_h[3'b000] & funct7_l[4'b0001];
    assign inst_remu    = opcode_h[3'b011] & opcode_l[4'b0011] & funct3_d[3'b111] & funct7_h[3'b000] & funct7_l[4'b0001];
    
    assign inst_csrrw   = opcode_h[3'b111] & opcode_l[4'b0011] & funct3_d[3'b001];
    assign inst_csrrs   = opcode_h[3'b111] & opcode_l[4'b0011] & funct3_d[3'b010];
    assign inst_csrrc   = opcode_h[3'b111] & opcode_l[4'b0011] & funct3_d[3'b011];
    assign inst_csrrwi  = opcode_h[3'b111] & opcode_l[4'b0011] & funct3_d[3'b101];
    assign inst_csrrsi  = opcode_h[3'b111] & opcode_l[4'b0011] & funct3_d[3'b110];
    assign inst_csrrci  = opcode_h[3'b111] & opcode_l[4'b0011] & funct3_d[3'b111];

    assign inst_ecall   = opcode_h[3'b111] & opcode_l[4'b0011] & ~(|inst[31:7]);
    assign inst_ebreak  = opcode_h[3'b111] & opcode_l[4'b0011] & ~(|inst[31:21]) & inst[20] & ~(|inst[19:7]);
    assign inst_mret    = opcode_h[3'b111] & opcode_l[4'b0011] & funct7_h[3'b001] & funct7_l[4'b1000] & (rs2==5'b00010) & ~(|inst[19:7]);


    //enable alu op
    assign op_add = inst_add | inst_addi | inst_lui | inst_auipc;
    assign op_sub = inst_sub;
    assign op_sll = inst_sll | inst_slli;
    assign op_slt = inst_slt | inst_slti;
    assign op_sltu = inst_sltu | inst_sltiu;
    assign op_xor = inst_xor | inst_xori;
    assign op_srl = inst_srl | inst_srli;
    assign op_sra = inst_sra | inst_srai;
    assign op_or = inst_or | inst_ori;
    assign op_and = inst_and | inst_andi;

    // enable div op
    assign div = inst_div | inst_divu;
    assign rem = inst_rem | inst_remu;
    assign signed_div = inst_div | inst_rem;

    //enable csr op
    assign csr_we        = (op_csrrw | op_csrrs | op_csrrc);
    assign op_csrrw      = inst_csrrw | inst_csrrwi;
    assign op_csrrs      = inst_csrrs | inst_csrrsi;
    assign op_csrrc      = inst_csrrc | inst_csrrci;
    assign csr_addr      = inst[31:20];
    assign csr_wdata_sel = inst_csrrwi | inst_csrrsi | inst_csrrci;
    assign csr_vec_l     = {29'b0, inst_ecall, inst_ebreak, inst_mret};


    // define control signal for access mem
    wire data_ram_en;
    wire data_ram_we;
    wire [2:0] data_size_sel;
    wire data_unsigned;

    // warp op signal
    assign alu_op = {
        op_add, op_sub, op_sll, op_slt,
        op_sltu, op_xor, op_srl, op_sra,
        op_or, op_and
    };

    assign bru_op = {
        inst_jal, inst_jalr, inst_beq, inst_bne,
        inst_blt, inst_bge, inst_bltu, inst_bgeu
    };

    assign lsu_op = {
        data_ram_en, data_ram_we, data_size_sel, data_unsigned
    };

    assign mul_op = {
        inst_mul, inst_mulh, inst_mulhu, inst_mulhsu
    };

    assign div_op = {
        div, rem, signed_div
    };

    assign csr_op = {
        csr_we, op_csrrw, op_csrrs, op_csrrc
    };

    // pc to src1
    assign sel_src1[0] = inst_auipc;
    // 0   to src1
    assign sel_src1[1] = inst_lui;
    // rs1  to src1 
    // assign sel_src1[2] = 

    // imm to src2
    assign sel_src2 =   inst_lui | inst_auipc | inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu |
                        inst_sb | inst_sh | inst_sw | inst_addi | inst_slti | inst_sltiu | inst_xori | 
                        inst_ori | inst_andi | inst_slli | inst_srli | inst_srai;
    // rs2 to src2
    // assign sel_src2[1] =

    wire [6:0] sel_imm;
    // I
    assign sel_imm[0] = inst_jalr | inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu |
                        inst_addi | inst_slti | inst_sltiu | inst_xori | inst_ori | inst_andi;
    // S
    assign sel_imm[1] = inst_sb | inst_sh | inst_sw;
    // B
    assign sel_imm[2] = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
    // U
    assign sel_imm[3] = inst_lui | inst_auipc;
    // J
    assign sel_imm[4] = inst_jal;
    // shamt
    assign sel_imm[5] = inst_slli | inst_srli | inst_srai;
    // zimm
    assign sel_imm[6] = inst_csrrwi | inst_csrrsi | inst_csrrci;

    /*这里我觉得立即数是根据指令类型来的，不如多一个把他们分类成某一个指令。
    比如sel_imm改成type_?
    */

    assign imm  = sel_imm[0] ? imm_i 
                : sel_imm[1] ? imm_s
                : sel_imm[2] ? imm_b
                : sel_imm[3] ? imm_u
                : sel_imm[4] ? imm_j 
                : sel_imm[5] ? {27'b0, shamt} 
                : sel_imm[6] ? zimm : 32'b0;

// lsu part begin
    assign data_ram_en = inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lw | inst_sb | inst_sh | inst_sw;
    assign data_ram_we = inst_sb | inst_sh | inst_sw;
    // byte
    assign data_size_sel[0] = inst_lb | inst_lbu | inst_sb;
    // half word
    assign data_size_sel[1] = inst_lh | inst_lhu | inst_sh;
    // word
    assign data_size_sel[2] = inst_lw | inst_sw;
    assign data_unsigned = inst_lbu | inst_lhu;
// lsu part end


    // rf_result from bru
    assign sel_rf_res[0] = inst_jal | inst_jalr;
    // rf_result from lsu
    assign sel_rf_res[1] = inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu;
    // rf_result from csr
    assign sel_rf_res[2] = inst_csrrw | inst_csrrwi | inst_csrrs | inst_csrrsi | inst_csrrc | inst_csrrci;
    // rf_result from m module
    assign sel_rf_res[3] = inst_mul | inst_mulh | inst_mulhu | inst_mulhsu |
                            inst_div | inst_divu | inst_rem | inst_remu;

    assign rf_we =  inst_lui | inst_auipc | inst_jal | inst_jalr |
                    inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu |
                    inst_addi | inst_slti | inst_sltiu | inst_xori | 
                    inst_ori | inst_andi | inst_slli | inst_srli | inst_srai |
                    inst_add | inst_sub | inst_sll | inst_slt | inst_sltu |
                    inst_xor | inst_srl | inst_sra | inst_or | inst_and |
                    inst_mul | inst_mulh | inst_mulhu | inst_mulhsu |
                    inst_div | inst_divu | inst_rem | inst_remu |
                    // inst_fence | inst_fence_i | inst_ecall | inst_ebreak |
                    inst_csrrw | inst_csrrs | inst_csrrc | inst_csrrwi | inst_csrrsi | inst_csrrci;
    assign rf_waddr = rd;

endmodule
