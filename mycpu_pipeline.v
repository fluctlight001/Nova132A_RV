`include "define.vh"
module mycpu_pipeline (
    input  wire clk,
    input  wire rst_n,

    output wire         inst_sram_en,
    output wire [3:0]   inst_sram_we,
    output wire [31:0]  inst_sram_addr,
    output wire [31:0]  inst_sram_wdata,
    input  wire [31:0]  inst_sram_rdata,

    output wire         data_sram_en,
    output wire [3:0]   data_sram_we,
    output wire [31:0]  data_sram_addr,
    output wire [31:0]  data_sram_wdata,
    input  wire [31:0]  data_sram_rdata,

    output wire [31:0]  debug_wb_pc,
    output wire [3:0]   debug_wb_rf_we,
    output wire [4:0]   debug_wb_rf_wnum,
    output wire [31:0]  debug_wb_rf_wdata,

    input  wire         stallreq_outside
);
    wire [`IF12IF2_WD  -1:0] if12if2_bus;
    wire [`IF22ID_WD   -1:0] if22id_bus;
    wire [`ID2EX_WD    -1:0] id2ex_bus;
    wire [`EX2MEM1_WD  -1:0] ex2mem1_bus;
    wire [`MEM12MEM2_WD-1:0] mem12mem2_bus;
    wire [`MEM22WB_WD  -1:0] mem22wb_bus;
    wire [`BYPASS_WD   -1:0] ex2rf_bus;
    wire [`BYPASS_WD   -1:0] mem12rf_bus;
    wire [`BYPASS_WD   -1:0] mem22rf_bus;
    wire [`BYPASS_WD   -1:0] wb2rf_bus;
    wire [32:0] br_bus;
    wire stallreq_ex;
    wire stallreq_id;
    wire [`StallBus    -1:0] stall;

    IF1 u_IF1(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .stall           (stall           ),
        .if12if2_bus     (if12if2_bus     ),
        .br_bus          (br_bus          ),
        .inst_sram_en    (inst_sram_en    ),
        .inst_sram_we    (inst_sram_we    ),
        .inst_sram_addr  (inst_sram_addr  ),
        .inst_sram_wdata (inst_sram_wdata )
    );

    IF2 u_IF2(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .stall           (stall           ),
        .br_e            (br_bus[32]      ),
        .if12if2_bus     (if12if2_bus     ),
        .if22id_bus      (if22id_bus      ),
        .inst_sram_rdata (inst_sram_rdata )
    );

    ID u_ID(
        .clk         (clk         ),
        .rst_n       (rst_n       ),
        .stall       (stall       ),
        .br_e        (br_bus[32]  ),
        .stallreq_id (stallreq_id ),
        .if22id_bus  (if22id_bus  ),
        .id2ex_bus   (id2ex_bus   ),
        .ex2rf_bus   (ex2rf_bus   ),
        .mem12rf_bus (mem12rf_bus ),
        .mem22rf_bus (mem22rf_bus ),
        .wb2rf_bus   (wb2rf_bus   )
    );
    
    EX u_EX(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .stall           (stall           ),
        .stallreq_ex     (stallreq_ex     ),
        .id2ex_bus       (id2ex_bus       ),
        .ex2mem1_bus     (ex2mem1_bus     ),
        .ex2rf_bus       (ex2rf_bus       ),
        .br_bus          (br_bus          ),
        .data_sram_en    (data_sram_en    ),
        .data_sram_we    (data_sram_we    ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata )
    );
    
    MEM1 u_MEM1(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .stall           (stall           ),
        .ex2mem1_bus     (ex2mem1_bus     ),
        .mem12mem2_bus   (mem12mem2_bus   ),
        .mem12rf_bus     (mem12rf_bus     ),
        .data_sram_rdata (data_sram_rdata )
    );
    
    MEM2 u_MEM2(
        .clk           (clk           ),
        .rst_n         (rst_n         ),
        .stall         (stall         ),
        .mem12mem2_bus (mem12mem2_bus ),
        .mem22wb_bus   (mem22wb_bus   ),
        .mem22rf_bus   (mem22rf_bus   )
    );
    
    WB u_WB(
        .clk               (clk               ),
        .rst_n             (rst_n             ),
        .stall             (stall             ),
        .mem22wb_bus       (mem22wb_bus       ),
        .wb2rf_bus         (wb2rf_bus         ),
        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_we    (debug_wb_rf_we    ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata )
    );

    ctrl u_ctrl(
        .rst_n            (rst_n            ),
        .stallreq_id      (stallreq_id      ),
        .stallreq_ex      (stallreq_ex      ),
        // .stallreq_outside (stallreq_outside ),
        .stall            (stall            )
    );
    
    
    

endmodule
