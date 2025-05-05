`include "define.vh"
module EX (
    input wire clk,
    input wire rst_n,
    input wire [5:0] stall,
    output wire stallreq_ex,

    input  wire [`ID2EX_WD  -1:0] id2ex_bus,
    output wire [`EX2MEM1_WD-1:0] ex2mem1_bus,
    output wire [`BYPASS_WD -1:0] ex2rf_bus,

    output wire [32:0] br_bus,

    output wire data_sram_en,
    output wire [3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata
);

    reg [`ID2EX_WD-1:0] id2ex_bus_r;
    always @ (posedge clk) begin
        if (!rst_n) begin
            id2ex_bus_r <= 0;
        end
        else if ((stall[3]&(!stall[4])) | br_bus[32]) begin
            id2ex_bus_r <= 0;
        end
        else if (!stall[3]) begin
            id2ex_bus_r <= id2ex_bus;
        end
    end

    wire [31:0] src1, src2;
    wire [31:0] imm;
    wire [`ALU_WD-1:0] alu_op;
    wire [`BRU_WD-1:0] bru_op;
    wire [`LSU_WD-1:0] lsu_op;
    wire [`MUL_WD-1:0] mul_op;
    wire [`DIV_WD-1:0] div_op;
    wire [ 3:0] sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] pc,inst;
    wire [31:0] rdata1, rdata2;

    // wire [3:0] csr_op;
    // wire [11:0] csr_addr;
    // wire csr_wdata_sel;
    // wire [31:0] csr_wdata;
    // wire [63:0] csr_vec;

    //要改成63：0的话，这里还需要从csr里拉 mie[7] & mstatus[3] 过来判断是否中断屏蔽
    // assign csr_cancel = |csr_vec[31:0];

    assign {
        src1,
        src2,
        imm,
        alu_op,
        bru_op,
        lsu_op,
        mul_op,
        div_op,
        sel_rf_res,
        rf_we,
        rf_waddr,
        pc,
        inst
    } = id2ex_bus_r;

    wire [31:0] alu_result;
    alu u_alu(
    	.alu_op     (alu_op     ),
        .alu_src1   (src1       ),
        .alu_src2   (src2       ),
        .alu_result (alu_result )
    );
    
    wire br_e;
    wire [31:0] br_addr;
    wire [31:0] br_result;
    bru u_bru(
    	.pc        (pc        ),
        .bru_op    (bru_op    ),
        .rdata1    (src1      ),
        .rdata2    (src2      ),
        .imm       (imm       ),
        .br_e      (br_e      ),
        .br_addr   (br_addr   ),
        .br_result (br_result )
    );
    assign br_bus = {br_e,br_addr};

    wire [3:0] data_ram_sel;
    wire data_sram_en_tmp;
    lsu u_lsu(
    	.lsu_op          (lsu_op          ),
        .rdata1          (src1            ),
        .rdata2          (src2            ),
        .imm             (imm             ),
        .data_sram_en    (data_sram_en    ),
        .data_sram_we    (data_sram_we    ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata ),
        .data_ram_sel    (data_ram_sel    )
    );
    // assign data_sram_en = data_sram_en_tmp;

    wire [31:0] m_result;
    wire stallreq_for_m;
    m_top u_m_top(
        .clk      (clk              ),
        .rst_n    (rst_n            ),
        .stall    (stall            ),
        .stallreq (stallreq_for_m   ),
        .mul_op   (mul_op           ),
        .div_op   (div_op           ),
        .a        (src1             ),
        .b        (src2             ),
        .result   (m_result         )
    );
    

    wire [31:0] ex_result;
    assign ex_result    = sel_rf_res[0] ? br_result 
                        : sel_rf_res[3] ? m_result 
                        : alu_result;
    // assign csr_wdata = csr_wdata_sel ? imm : src1;
    
    assign ex2mem_bus = {
        // csr_vec,
        // csr_op,
        // csr_addr,
        // csr_wdata,
        lsu_op,
        data_ram_sel,
        sel_rf_res[2:0],
        rf_we,
        rf_waddr,
        ex_result,
        pc,
        inst
    };

    assign ex2rf_bus = {
        rf_we,
        rf_waddr,
        ex_result
    };

    assign stallreq_ex = stallreq_for_m;
endmodule
