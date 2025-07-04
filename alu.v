module alu(
    input wire [9:0] alu_op,
    input wire [31:0] alu_src1,
    input wire [31:0] alu_src2,
    output wire [31:0] alu_result
);

    wire op_add;
    wire op_sub;
    wire op_sll;
    wire op_slt;
    wire op_sltu;
    wire op_xor;
    wire op_srl;
    wire op_sra;
    wire op_or;
    wire op_and;
    
    assign {
        op_add, op_sub, op_sll, op_slt,
        op_sltu, op_xor, op_srl, op_sra,
        op_or, op_and
    } = alu_op;
    
    wire [31:0] add_sub_result;
    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire [31:0] and_result;
    wire [31:0] or_result; 
    wire [31:0] xor_result;
    wire [31:0] sll_result;
    wire [31:0] srl_result;
    wire [31:0] sra_result;

    assign and_result = alu_src1 & alu_src2;
    assign or_result = alu_src1 | alu_src2;
    assign xor_result = alu_src1 ^ alu_src2;

    wire [31:0] adder_a;
    wire [31:0] adder_b;
    wire        adder_cin;
    wire [31:0] adder_result;
    wire        adder_cout;

    assign adder_a = alu_src1;
    assign adder_b = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
    assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1 : 1'b0;
    assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

    assign add_sub_result = adder_result;

    assign slt_result[31:1] = 31'b0;
    assign slt_result[0] = (alu_src1[31] & ~alu_src2[31]) 
                         | (~(alu_src1[31]^alu_src2[31]) & adder_result[31]);
    
    assign sltu_result[31:1] = 31'b0;
    assign sltu_result[0] = ~adder_cout;

    assign sll_result = alu_src1 << alu_src2[4:0];
    assign srl_result = alu_src1 >> alu_src2[4:0];
    assign sra_result = ($signed(alu_src1)) >>> alu_src2[4:0];

    assign alu_result = ({32{op_add|op_sub  }} & add_sub_result)
                      | ({32{op_slt         }} & slt_result)
                      | ({32{op_sltu        }} & sltu_result)
                      | ({32{op_and         }} & and_result)
                      | ({32{op_or          }} & or_result)
                      | ({32{op_xor         }} & xor_result)
                      | ({32{op_sll         }} & sll_result)
                      | ({32{op_srl         }} & srl_result)
                      | ({32{op_sra         }} & sra_result);
                      
endmodule
