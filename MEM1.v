`include "define.vh"
module MEM1 (
    input  wire clk,
    input  wire rst_n,
    input  wire [`StallBus      -1:0] stall,

    input  wire [`EX2MEM1_WD    -1:0] ex2mem1_bus,
    output wire [`MEM12MEM2_WD  -1:0] mem12mem2_bus,

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

    assign mem12mem2_bus = {
        ex2mem1_bus_r,
        data_sram_rdata
    };
endmodule