`include "define.vh"
module MEM1 (
    input  wire clk,
    input  wire rst_n,
    input  wire [`StallBus    -1:0] stall,

    input  wire [`EX2MEM1_WD  -1:0] ex2mem1_bus,
    output wire [`MEM12MEM2_WD-1:0] mem12mem2_bus,
    output wire [`BYPASS_WD   -1:0] mem12rf_bus,

    input  wire [31:0] data_sram_rdata
);
    reg [`EX2MEM1_WD-1:0] ex2mem1_bus_r;

    always @ (posedge clk) begin
        if (!rst_n) begin
            ex2mem1_bus_r <= 0;
        end
        else if ((stall[4]&(!stall[5]))) begin
            ex2mem1_bus_r <= 0;
        end
        else if (!stall[4]) begin
            ex2mem1_bus_r <= ex2mem1_bus;
        end
    end

    wire [`LSU_WD-1:0] lsu_op;
    wire [ 3:0] data_ram_sel;
    wire [ 2:0] sel_rf_res;
    wire        rf_we;
    wire [ 4:0] rf_waddr;
    wire [31:0] ex_result;
    wire [31:0] pc,inst;

    assign {
        lsu_op,
        data_ram_sel,
        sel_rf_res,
        rf_we,
        rf_waddr,
        ex_result,
        pc,
        inst
    } = ex2mem1_bus_r;

    assign mem12mem2_bus = {
        ex2mem1_bus_r,
        data_sram_rdata
    };

    assign mem12rf_bus = {
        rf_we,
        rf_waddr,
        ex_result
    };
endmodule