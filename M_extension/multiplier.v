module multiplier(
    input wire clk,
    input wire rst_n,
    output wire stallreq,
    input wire in_valid,
    // output wire out_valid,

    input wire [31:0] a,b,
    
    output reg [31:0] result_h,result_l
);
    wire out_valid;
    reg [6:0] cnt;
    wire [31:0] add_result;
    wire carry;
    always @ (posedge clk) begin
        if (!rst_n) begin
            cnt <= 0;
        end
        else if (cnt != 0) begin
            cnt <= cnt - 1;
        end
        else if (in_valid) begin
            cnt <= 32;
        end
    end

    assign {carry, add_result} = result_h + (result_l[0] ? a :0);

    always @ (posedge clk) begin
        if (!rst_n) begin
            result_h <= 0;
            result_l <= 0;
        end 
        else if (cnt != 0) begin
            {result_h, result_l} <= {carry, add_result, result_l[31:1]};
        end
        else if (in_valid) begin
            result_h <= 0;
            result_l <= b;
        end
    end 

    assign out_valid = (cnt==0);
    assign stallreq = in_valid | (~(cnt==0));
endmodule