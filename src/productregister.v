module productregister (hi, lo, e, clock, start, step, multiplier, hi_sum);

input clock, start, step;
input [31:0] multiplier;
input [32:0] hi_sum;
output [32:0] hi;
output [31:0] lo;
output e;

wire [32:0] hi_shift, d_hi;
wire [31:0] lo_shift, d_lo;
wire e_shift, d_e, load;

assign hi_shift = {hi_sum[32], hi_sum[32:1]};
assign lo_shift = {hi_sum[0], lo[31:1]};
assign e_shift = lo[0];

assign d_hi = start ? 33'b0 : hi_shift;
assign d_lo = start ? multiplier : lo_shift;
assign d_e = start ? 1'b0 : e_shift;

assign load = start | step;

genvar i;
generate
    for (i = 0; i < 33; i = i + 1) begin : hiff
        dffe_ref hibit(.q(hi[i]), .d(d_hi[i]), .clk(clock), .en(load), .clr(1'b0));
    end
endgenerate

generate
    for (i = 0; i < 32; i = i + 1) begin : loff
        dffe_ref lobit(.q(lo[i]), .d(d_lo[i]), .clk(clock), .en(load), .clr(1'b0));
    end
endgenerate

dffe_ref extraff(.q(e), .d(d_e), .clk(clock), .en(load), .clr(1'b0));

endmodule