`include "define.vh"
module ID (
    input  wire clk,
    input  wire rst_n,
    input  wire [`StallBus -1:0] stall,
    input  wire br_e,
    output wire stallreq_id,

    input  wire [`IF22ID_WD-1:0] if22id_bus,
    output wire [`ID2EX_WD -1:0] id2ex_bus,

    input  wire [`BYPASS_WD-1:0] ex2rf_bus,
    input  wire [`BYPASS_WD-1:0] mem12rf_bus,
    input  wire [`BYPASS_WD-1:0] mem22rf_bus,
    input  wire [`BYPASS_WD-1:0] wb2rf_bus
);
    reg [`IF22ID_WD-1:0] if22id_bus_r;

    always @ (posedge clk)begin
        if (!rst_n) begin
            if22id_bus_r <= 0;
        end
        else if ((stall[2]&(!stall[3])) | br_e)begin
            if22id_bus_r <= 0;
        end
        else if (!stall[2]) begin
            if22id_bus_r <= if22id_bus;
        end
    end

    wire [31:0] pc;
    wire [31:0] inst;
    assign {
        pc,
        inst
    } = if22id_bus_r;

    // decoder
    wire [ 1:0] sel_src1;
    wire        sel_src2;
    wire [31:0] imm;
    wire [`ALU_WD-1:0] alu_op;
    wire [`BRU_WD-1:0] bru_op;
    wire [`LSU_WD-1:0] lsu_op;
    wire [`MUL_WD-1:0] mul_op;
    wire [`DIV_WD-1:0] div_op;
    wire [ 3:0] sel_rf_res;
    wire        rf_we;
    wire [ 4:0] rf_waddr;
    // csr
    wire [ 3:0] csr_op;
    wire [11:0] csr_addr;
    wire        csr_wdata_sel;
    wire [31:0] csr_wdata;
    wire [63:0] csr_vec;
    wire [31:0] csr_vec_l;
    // regfile
    wire [ 4:0] rs1, rs2;
    wire [31:0] rdata1, rdata2;

    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    //bypass
    wire        ex_rf_we,    mem1_rf_we,    mem2_rf_we,    wb_rf_we;
    wire [ 4:0] ex_rf_waddr, mem1_rf_waddr, mem2_rf_waddr, wb_rf_waddr;
    wire [31:0] ex_rf_wdata, mem1_rf_wdata, mem2_rf_wdata, wb_rf_wdata;

    assign {ex_rf_we,   ex_rf_waddr,    ex_rf_wdata     } = ex2rf_bus;
    assign {mem1_rf_we, mem1_rf_waddr,  mem1_rf_wdata   } = mem12rf_bus;
    assign {mem2_rf_we, mem2_rf_waddr,  mem2_rf_wdata   } = mem22rf_bus;
    assign {wb_rf_we,   wb_rf_waddr,    wb_rf_wdata     } = wb2rf_bus;


    decoder_im u_decoder(
    	.inst       (inst       ),

        .sel_src1   (sel_src1   ),
        .sel_src2   (sel_src2   ),
        .imm        (imm        ),
        .alu_op     (alu_op     ),
        .bru_op     (bru_op     ),
        .lsu_op     (lsu_op     ),
        .mul_op     (mul_op     ),
        .div_op     (div_op     ),
        .csr_op     (csr_op     ),
        .csr_addr   (csr_addr   ),
        .csr_wdata_sel(csr_wdata_sel),
        .csr_vec_l  (csr_vec_l  ),
        .sel_rf_res (sel_rf_res ),
        .rf_we      (rf_we      ),
        .rf_waddr   (rf_waddr   )
    );

    regfile u_regfile(
        .clk    (clk    ),
        .rs1    (rs1    ),
        .rs2    (rs2    ),
        .rdata1 (rdata1 ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );

    wire [31:0] src1, src2;
    assign src1 = ex_rf_we   & (ex_rf_waddr == rs1)   & (|rs1) ? ex_rf_wdata
                : mem1_rf_we & (mem1_rf_waddr == rs1) & (|rs1) ? mem1_rf_wdata
                : mem2_rf_we & (mem2_rf_waddr == rs1) & (|rs1) ? mem2_rf_wdata
                : wb_rf_we   & (wb_rf_waddr == rs1)   & (|rs1) ? wb_rf_wdata
                : sel_src1[0] ? pc
                : sel_src1[1] ? 0
                : rdata1;
    assign src2 = ex_rf_we   & (ex_rf_waddr == rs2)   & (|rs2) ? ex_rf_wdata
                : mem1_rf_we & (mem1_rf_waddr == rs2) & (|rs2) ? mem1_rf_wdata
                : mem2_rf_we & (mem2_rf_waddr == rs2) & (|rs2) ? mem2_rf_wdata
                : wb_rf_we   & (wb_rf_waddr == rs2)   & (|rs2) ? wb_rf_wdata
                : sel_src2 ? imm
                : rdata2;

    // assign csr_vec = {32'b0, csr_vec_l};
    assign id2ex_bus = {
        // csr_vec,
        // csr_op,
        // csr_addr,
        // csr_wdata_sel,
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
    };

    reg ex_load_buffer;
    reg ex_csr_buffer;

    always @ (posedge clk) begin
        if (!rst_n) begin
            ex_load_buffer <= 1'b0;
            ex_csr_buffer <= 1'b0;
        end
        else if (stall[2]&(!stall[3]) | br_e) begin
            ex_load_buffer <= 1'b0;
            ex_csr_buffer <= 1'b0;
        end
        else if (!stall[2]) begin
            ex_load_buffer <= sel_rf_res[1];
            ex_csr_buffer <= sel_rf_res[2];
        end
    end
    wire ex_is_load;
    wire ex_is_csr;
    assign ex_is_load = ex_load_buffer;
    assign ex_is_csr = ex_csr_buffer;
    wire stallreq_load;
    wire stallreq_csr;
    assign stallreq_load = ex_is_load & ex_rf_we & ((ex_rf_waddr==rs1 & rs1!=0)|(ex_rf_waddr==rs2 & rs2!=0));
    assign stallreq_csr  = ex_is_csr  & ex_rf_we & ((ex_rf_waddr==rs1 & rs1!=0)|(ex_rf_waddr==rs2 & rs2!=0));
    assign stallreq_id = stallreq_load | stallreq_csr;
    
endmodule
