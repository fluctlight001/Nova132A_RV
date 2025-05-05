`include "define.vh"
module IF2 (
    input  wire clk,
    input  wire rst_n,
    input  wire [`StallBus    -1:0] stall,

    input  wire br_e,

    input  wire [`IF12IF2_WD  -1:0] if12if2_bus,
    output wire [`IF22ID_WD   -1:0] if22id_bus,

    input  wire [31:0] inst_sram_rdata
);
    reg [`IF12IF2_WD-1:0] if12if2_bus_r;
    reg flag;//判断是否要用buffer存储inst
    reg [31:0] inst_buffer;

    always @ (posedge clk) begin
        if (!rst_n) begin
            if12if2_bus_r <= 0;
            flag <= 0;
            inst_buffer <= 0;
        end
        else if ((stall[1]&(!stall[2])) | br_e)begin
            if12if2_bus_r <= 0;
            flag <= 0;
            inst_buffer <= 0;
        end
        else if (!stall[1]) begin
            if12if2_bus_r <= if12if2_bus;
            flag <= 0;
            inst_buffer <= 0;
        end
        else if (flag) begin
            
        end
        else begin
            flag <= 1;
            inst_buffer <= inst_sram_rdata;
        end
    end

    assign if22id_bus = {
        if12if2_bus_r,
        // inst_sram_rdata
        (|if12if2_bus_r) ? flag ? inst_buffer : inst_sram_rdata : 32'b0
    };
endmodule
