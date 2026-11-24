//this is a parameterized latch module, its necessary because some of the register numbers are 5 bits wide, 
//and our register module is fixed at 32 bits
module pipereg #(parameter WIDTH = 32) (q, d, clk, en, clr);

input [WIDTH-1:0] d;
input clk, en, clr;
output [WIDTH-1:0] q;

genvar i;
generate
    for (i = 0; i < WIDTH; i = i + 1) begin : bits
        dffe_ref bitffff(.q(q[i]), .d(d[i]), .clk(clk), .en(en), .clr(clr));
    end
endgenerate
endmodule