module regfile(
    input  wire         clk,
    
    input  wire [ 4:0]  rs1,
    input  wire [ 4:0]  rs2,
    output wire [31:0]  rdata1,
    output wire [31:0]  rdata2,

    input  wire         we,
    input  wire [ 4:0]  waddr,
    input  wire [31:0]  wdata
);
    reg [31:0] rf [31:0];

    always @ (posedge clk) begin
        if (we) begin
            rf[waddr] <= wdata;
        end
    end

    assign rdata1 = ~(|rs1) ? 32'b0 : we & (rs1 == waddr) ? wdata : rf[rs1];
    assign rdata2 = ~(|rs2) ? 32'b0 : we & (rs2 == waddr) ? wdata : rf[rs2];
endmodule