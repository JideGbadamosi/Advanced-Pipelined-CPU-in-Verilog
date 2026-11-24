module sixbcounter (q, clock, enable, clear);
input clock, enable, clear;
output [5:0] q;

wire [5:0] t, en_ff, d_ff;
assign t[0] = enable;

genvar i;
generate
    for (i = 1; i < 6; i = i + 1) begin
        assign t[i] = t[i-1] & q[i-1];
    end
endgenerate

generate
    for (i = 0; i < 6; i = i + 1) begin : bitff
        assign en_ff[i] = t[i] | clear;
        assign d_ff[i] = ~(q[i] | clear);
        dffe_ref countff(.q(q[i]), .d(d_ff[i]), .clk(clock), .en(en_ff[i]), .clr(1'b0));
    end
endgenerate

endmodule