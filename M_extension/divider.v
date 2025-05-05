module divider(
    input wire clk,
    input wire rst_n,
    output wire stallreq,
    input wire in_valid,
    // output wire out_valid,

    input wire [31:0] a,b,
    
    output reg [31:0] quotient, //商
    output reg [31:0] remainder //余数
);
    wire out_valid;
    reg [6:0] cnt;
    wire [31:0] sub_result;
    wire carry;
    wire [31:0] temp;

    always @ (posedge clk) begin
        if (!rst_n) begin
            cnt <= 0;
        end
        else if (cnt != 0) begin
            cnt <= cnt -1;
        end
        else if (in_valid) begin
            cnt <= 32;
        end
    end

    assign temp = {remainder[30:0],quotient[31]};
    assign carry = temp < b ? 0 : 1;
    assign sub_result = carry ? temp - b : temp;

    always @ (posedge clk) begin
        if (!rst_n) begin
            quotient <= 0;
            remainder <= 0;
        end
        else if (cnt != 0) begin
            {remainder, quotient} <= {sub_result, quotient[30:0], carry};
        end
        else if (in_valid) begin
            quotient <= a;
            remainder <= 0;
        end
    end
    
    assign out_valid = (cnt==0);
    assign stallreq = in_valid | (~(cnt==0));
endmodule