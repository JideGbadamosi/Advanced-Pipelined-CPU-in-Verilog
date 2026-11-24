module divisionregister (r, q, clock, start, step, dividend, next_r, next_q);

input clock, start, step;
input [31:0] dividend, next_r, next_q;
output [31:0] r, q;

wire [31:0] r_in, q_in;
wire holdit, loadit;

assign r_in = start ? 32'b0 : next_r;
assign q_in = start ? dividend : next_q;

assign holdit = ~(start | step);
assign loadit = ~holdit;

genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : rff
        dffe_ref rbit(.q(r[i]), .d(r_in[i]), .clk(clock), .en(loadit), .clr(1'b0));
    end
endgenerate

generate
    for (i = 0; i < 32; i = i + 1) begin : qff
        dffe_ref qbit(.q(q[i]), .d(q_in[i]), .clk(clock), .en(loadit), .clr(1'b0));
    end
endgenerate

endmodule