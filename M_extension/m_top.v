module m_top(
    input wire clk,
    input wire rst_n,
    input wire [5:0] stall,
    output wire stallreq,

    input wire [3:0] mul_op, // mul, mulh, mulhu, mulhsu
    input wire [2:0] div_op, // div rem signed 

    input wire [31:0] a, b,
    output wire [31:0] result
);

// common
wire stallreq_for_mul, stallreq_for_div;
wire sign_flag;
wire inst_mul, inst_mulh, inst_mulhu, inst_mulhsu;
wire div, rem, signed_div;
wire [32:0] src_a, src_b;
wire [31:0] result_h, result_l, quotient, remainder;

wire [31:0] a_locked, b_locked;
wire mul_en_locked, div_en_locked;

assign {inst_mul,inst_mulh,inst_mulhu,inst_mulhsu} = mul_op;
assign {div,rem,signed_div} = div_op;

wire mul_en;
wire div_en;
assign mul_en = |mul_op;
assign div_en = div | rem;

// 用于锁定数据，避免在流水线阻塞时出现数据变化
lock_unit u_lock_unit(
    .clk              (clk              ),
    .rst_n            (rst_n            ),
    .stall            (stall            ),
    .a                (a                ),
    .b                (b                ),
    .mul_en           (mul_en           ),
    .div_en           (div_en           ),
    .stallreq_for_mul (stallreq_for_mul ),
    .stallreq_for_div (stallreq_for_div ),
    .a_locked         (a_locked         ),
    .b_locked         (b_locked         ),
    .mul_en_locked    (mul_en_locked    ),
    .div_en_locked    (div_en_locked    )
);

assign src_a = inst_mul | inst_mulhu  | (~signed_div & div_en) ? {1'b0,a_locked}
             : inst_mulhsu | inst_mulh | signed_div ? (a_locked[31] ? {1'b1,~a_locked+1'b1} : {1'b0,a_locked}) 
             : 32'b1;
assign src_b = inst_mul | inst_mulhu | inst_mulhsu | (~signed_div & div_en) ? {1'b0,b_locked}
             : inst_mulh | signed_div ? (b_locked[31] ? {1'b1,~b_locked+1'b1} : {1'b0,b_locked})
             : 32'b1;

assign sign_flag = src_a[32]^src_b[32];
wire [1:0] exception;
assign exception[0] = (b_locked == 0);
assign exception[1] = ((a_locked == {1'b1, {31{1'b0}}}) && (b_locked == {32{1'b1}}));

// mul 
multiplier u_multiplier(
    .clk       (clk       ),
    .rst_n     (rst_n     ),
    .stallreq  (stallreq_for_mul),
    .in_valid  (mul_en_locked    ),
    // .out_valid (out_valid ),
    .a         (src_a     ),
    .b         (src_b     ),
    .result_h  (result_h  ),
    .result_l  (result_l  )
);

wire [63:0] unsigend_mul_result, signed_mul_result;
assign unsigend_mul_result = {result_h,result_l};
assign signed_mul_result = sign_flag ? {~unsigend_mul_result+1'b1} : {sign_flag,unsigend_mul_result[62:0]};


// div
divider u_divider(
    	.clk       (clk       ),
        .rst_n     (rst_n     ),
        .stallreq  (stallreq_for_div),
        .in_valid  (div_en_locked    ),
        // .out_valid (out_valid ),
        .a         (src_a     ),
        .b         (src_b     ),
        .quotient  (quotient  ),
        .remainder (remainder )
    );

assign stallreq = stallreq_for_mul | stallreq_for_div;
assign result = 
                inst_mul    ? result_l :
                inst_mulh   ? signed_mul_result[63:32] :
                inst_mulhu  ? result_h :
                inst_mulhsu ? signed_mul_result[63:32] :
                div & exception[0] ? {32{1'b1}} :
                div & exception[1] ? {1'b1,{31{1'b0}}} :
                div & ~signed_div ? quotient :
                div &  signed_div ? sign_flag ? ~quotient+1'b1 : {sign_flag, quotient[30:0]} :
                rem & exception[0] ? a_locked :
                rem & exception[1] ? 0 : 
                rem & ~signed_div ? remainder :
                rem &  signed_div ? src_a[32] ? {~remainder+1'b1} : {src_a[32], remainder[30:0]} :
                32'b0;


endmodule