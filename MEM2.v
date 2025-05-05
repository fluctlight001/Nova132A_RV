`include "define.vh"
module MEM2 (
    input  wire clk,
    input  wire rst_n,
    input  wire [5:0] stall,

    input  wire [`MEM12MEM2_WD-1:0] mem12mem2_bus,
    output wire [`MEM22WB_WD  -1:0] mem22wb_bus,
    output wire [`BYPASS_WD   -1:0] mem22rf_bus
);
    reg [`MEM12MEM2_WD-1:0] mem12mem2_bus_r;
    always @ (posedge clk) begin
        if (!rst_n) begin
            mem12mem2_bus_r <= 0;
        end
        else if (stall[5]&(!stall[6])) begin
            mem12mem2_bus_r <= 0;
        end
        else if (!stall[5]) begin
            mem12mem2_bus_r <= mem12mem2_bus;
        end
    end

    wire [`LSU_WD-1:0] lsu_op;
    wire [3:0] data_ram_sel;
    wire [2:0] sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] ex_result;
    wire [31:0] pc,inst,rdata;
    // wire [63:0] csr_vec;
    // wire [3:0] csr_op;
    // wire [11:0] csr_addr;
    // wire [31:0] csr_wdata;
    // wire [31:0] csr_rdata;
    // wire [31:0] csr_result;
    // assign csr_result = stall_flag ? csr_rdata_r : csr_rdata;

    assign {
        // csr_vec,
        // csr_op,
        // csr_addr,
        // csr_wdata,
        lsu_op,
        data_ram_sel,
        sel_rf_res,
        rf_we,
        rf_waddr,
        ex_result,
        pc,
        inst
    } = mem12mem2_bus_r;

    wire        data_ram_en;
    wire        data_ram_we;
    wire [2:0]  data_size_sel;
    wire        data_unsigned;

    assign {
        data_ram_en, data_ram_we, data_size_sel, data_unsigned
    } = lsu_op;

    wire [31:0] mem_result;
    wire [31:0] rf_wdata;

    wire [7:0] b_data;
    wire [15:0] h_data;
    wire [31:0] w_data;

    assign b_data = data_ram_sel[3] ? rdata[31:24] :
                    data_ram_sel[2] ? rdata[23:16] :
                    data_ram_sel[1] ? rdata[15: 8] :
                    data_ram_sel[0] ? rdata[ 7: 0] : 8'b0;
    assign h_data = data_ram_sel[2] ? rdata[31:16] :
                    data_ram_sel[0] ? rdata[15: 0] : 16'b0;
    assign w_data = rdata;

    assign mem_result = data_size_sel[0] & data_unsigned ? {{24{1'b0}},b_data} :
                        data_size_sel[0] ? {{24{b_data[7]}},b_data} :
                        data_size_sel[1] & data_unsigned ? {{16{1'b0}},h_data} :
                        data_size_sel[1] ? {{16{h_data[15]}},h_data} :
                        data_size_sel[2] ? w_data : 32'b0;

    // wire except_en;
    // wire [31:0] new_pc;
    // csr u_csr(
    //     .clk       (clk       ),
    //     .rst_n     (rst_n     ),
    //     .stall     (stall[3]&stall[4]),
    //     .pc        (pc        ),
    //     .csr_vec   (csr_vec   ),
    //     .csr_op    (csr_op    ),
    //     .csr_addr  (csr_addr  ),
    //     .csr_wdata (csr_wdata ),
    //     .csr_rdata (csr_rdata ),
    //     .except_en (except_en ),
    //     .new_pc    (new_pc    )
    // );
    
    assign rf_wdata = sel_rf_res[1] ? mem_result : ex_result;
                    // : sel_rf_res[2] ? csr_result 

    assign mem22wb_bus = {
        rf_we,
        rf_waddr,
        rf_wdata,
        pc,
        inst
    };

    assign mem22rf_bus = {
        rf_we,
        rf_waddr,
        rf_wdata
    };
endmodule