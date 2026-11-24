module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    wire kickoff, iterate_now, busy, all_steps_done, busy_next;
    wire [5:0] cycle_tally;
    wire [31:0] held_multiplicand, multiplier_half;
    wire [32:0] accumulator, accumulator_next;
    wire trailing_bit;
    wire [32:0] overflow_window;
    wire window_all_ones, window_all_zeros;

    assign kickoff = ctrl_MULT | ctrl_DIV;
    assign all_steps_done = cycle_tally[5];
    assign iterate_now = busy & ~all_steps_done;
    assign busy_next = kickoff | iterate_now;

    dffe_ref busyff(.q(busy), .d(busy_next), .clk(clock), .en(1'b1), .clr(1'b0));
    sixbcounter count(.q(cycle_tally), .clock(clock), .enable(iterate_now), .clear(kickoff));
    register mcand(.q(held_multiplicand), .d(data_operandA), .clk(clock), .en(kickoff), .clr(1'b0));
    booths booth(.new_product_high(accumulator_next), .product_high(accumulator), .multiplier_bit(multiplier_half[0]), .previous_bit(trailing_bit), .multiplicand(held_multiplicand));
    productregister preg(.hi(accumulator), .lo(multiplier_half), .e(trailing_bit), .clock(clock), .start(kickoff), .step(iterate_now), .multiplier(data_operandB), .hi_sum(accumulator_next));

    assign overflow_window = {accumulator[31:0], multiplier_half[31]};
    assign window_all_ones = &overflow_window;
    assign window_all_zeros = ~|overflow_window;

    //AADDED FOR DIVISION
    wire div_mode, quot_neg, sign_clash, div_by_zero;
    wire [31:0] neg_A, neg_B, abs_A, abs_B, held_divisor;
    wire [31:0] rem_part, quot_part, rem_next, quot_next;
    wire [31:0] neg_quot, div_answer;
//division
    dffe_ref modeff(.q(div_mode), .d(ctrl_DIV), .clk(clock), .en(kickoff), .clr(1'b0));
    assign sign_clash = data_operandA[31] ^ data_operandB[31];
    dffe_ref signff(.q(quot_neg), .d(sign_clash), .clk(clock), .en(kickoff), .clr(1'b0));

    SUB flipA(.data_result(neg_A), .data_operandA(32'b0), .data_operandB(data_operandA), .ctrl_sub(1'b1));
    SUB flipB(.data_result(neg_B), .data_operandA(32'b0), .data_operandB(data_operandB), .ctrl_sub(1'b1));
    assign abs_A = data_operandA[31] ? neg_A : data_operandA;
    assign abs_B = data_operandB[31] ? neg_B : data_operandB;

    register dvsr(.q(held_divisor), .d(abs_B), .clk(clock), .en(kickoff), .clr(1'b0));
    restorediv divstep(.next_r(rem_next), .next_q(quot_next), .r(rem_part), .q(quot_part), .divisor(held_divisor));
    divisionregister dreg(.r(rem_part), .q(quot_part), .clock(clock), .start(kickoff), .step(iterate_now), .dividend(abs_A), .next_r(rem_next), .next_q(quot_next));

    SUB flipquot(.data_result(neg_quot), .data_operandA(32'b0), .data_operandB(quot_part), .ctrl_sub(1'b1));
    assign div_by_zero = ~|held_divisor;
    assign div_answer = div_by_zero ? 32'b0 : (quot_neg ? neg_quot : quot_part);
//end division
    assign data_result = div_mode ? div_answer : multiplier_half;
    assign data_exception = div_mode ? div_by_zero : ~(window_all_ones | window_all_zeros);
    assign data_resultRDY = busy & all_steps_done;

endmodule
    // add your code here
   // assign data_result = 32'b0;
    //ssign data_exception = 1'b0;
    //wire beginn, firstdff;
    //assign beginn = ctrl_MULT | ctrl_DIV;
    //dffe_ref starter(.q(firstdff), .d(beginn), .clk(clock), .en(1'b1), .clr(1'b0));
    //dffe_ref starter2(.q(data_resultRDY), .d(firstdff), .clk(clock), .en(1'b1), .clr(1'b0));