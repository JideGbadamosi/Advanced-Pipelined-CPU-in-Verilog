module restorediv (next_r, next_q, r, q, divisor);

input [31:0] r, q, divisor;
output [31:0] next_r, next_q;

wire [32:0] pushed_r;
wire [31:0] t_l;
wire t_carry, didntfit, itfit;

assign pushed_r = {r, q[31]};
SUB trial_unit(.data_result(t_l), .c32(t_carry), .data_operandA(pushed_r[31:0]), .data_operandB(divisor), .ctrl_sub(1'b1));
assign didntfit = ~(pushed_r[32] ^ t_carry);
assign itfit = ~didntfit;

assign next_r = didntfit ? pushed_r[31:0] : t_l;
assign next_q = {q[30:0], itfit};

endmodule