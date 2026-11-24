module booths (new_product_high, product_high, multiplier_bit, previous_bit, multiplicand);

input [32:0] product_high;
input [31:0] multiplicand;
input multiplier_bit, previous_bit;
output [32:0] new_product_high;
wire do_subtract, do_add_or_sub;
wire carry_out;
wire [31:0] sum_lower32;
wire sum_bit32;
wire [32:0] sum_all33;

assign do_subtract = multiplier_bit & ~previous_bit;
assign do_add_or_sub = multiplier_bit ^ previous_bit;
SUB adder_unit(.data_result(sum_lower32), .c32(carry_out), .data_operandA(product_high[31:0]), .data_operandB(multiplicand), .ctrl_sub(do_subtract)); //c31 not necessary

assign sum_bit32 = product_high[32] ^ multiplicand[31] ^ do_subtract ^ carry_out;
assign sum_all33 = {sum_bit32, sum_lower32};

assign new_product_high = do_add_or_sub ? sum_all33 : product_high;

endmodule