module register #(parameter WIDTH=1) (q, d, clk, en, clr);

input clk, en, clr;
input [31:0] d;
output [31:0] q;
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : thirtytworeg
        dffe_ref regis(q[i], d[i], clk, en, clr);
end
endgenerate


endmodule