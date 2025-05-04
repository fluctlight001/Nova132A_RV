`include "define.vh"
module IF1 (
    input  wire clk,
    input  wire rst_n,
    input  wire [`StallBus-1:0]     stall,

    output wire [`IF12IF2_WD-1:0]   if12if2_bus,

    input  wire [32:0]  br_bus,

    output wire         inst_sram_en,
    output wire [ 3:0]  inst_sram_we,
    output wire [31:0]  inst_sram_addr,
    output wire [31:0]  inst_sram_wdata
);
    reg         pc_valid;
    reg  [31:0] pc;
    wire [31:0] next_pc;

    wire        br_e;
    wire [31:0] br_addr;

    assign {
        br_e, br_addr
    } = br_bus;

    always @ (posedge clk) begin
        if (!rst_n) begin
            pc_valid <= 1'b0;
            pc <= 32'h7fff_fffc;
        end
        else if (!stall[0]) begin
            pc_valid <= 1'b1;
            pc <= next_pc;
        end
    end

    assign next_pc = br_e ? br_addr : pc + 4'h4;

    assign if12if2_bus = {
        pc
    };

    assign inst_sram_en     = br_e ? 1'b0 : pc_valid;
    assign inst_sram_we     = 4'b0;
    assign inst_sram_addr   = pc;
    assign inst_sram_wdata  = 32'b0;


endmodule
