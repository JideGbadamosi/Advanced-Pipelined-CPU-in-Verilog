module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	// add your code here
	//first make the 32 dffe registers, then add the tristate buffers, then connect them to decoder
	//when creating the individual register, use  parametrization for the widths, so that it can be used in the future
// wire [31:0] write_en_unmod; this also broke my cpu because of qwire bro
// wire [31:0] write_en_mod;
// wire [1023:0] qwire;
// decoderONE writeDecoder(.out(write_en_unmod), .select(ctrl_writeReg), .enable(ctrl_writeEnable));
// assign write_en_mod = {write_en_unmod[31:1], 1'b0};
// ttregisters registerFile(.q(qwire), .d(data_writeReg), .clk(clock), .en(write_en_mod), .clr(ctrl_reset));

// wire [31:0] readA_sel;
// decoderONE readDecoderA(.out(readA_sel), .select(ctrl_readRegA), .enable(1'b1));

// wire [31:0] readB_sel;
// decoderONE readDecoderB(.out(readB_sel), .select(ctrl_readRegB), .enable(1'b1));

// genvar r, b;
// generate
//     for (r = 0; r < 32; r = r + 1) begin : readA_regs
//         for (b = 0; b < 32; b = b + 1) begin : readA_bits
//             my_tri triA(.in(qwire[r*32 + b]), .oe(readA_sel[r]), .out(data_readRegA[b]));
//         end
//     end
// endgenerate

// genvar r2, b2;
// generate
//     for (r2 = 0; r2 < 32; r2 = r2 + 1) begin : readB_regs
//         for (b2 = 0; b2 < 32; b2 = b2 + 1) begin : readB_bits
//             my_tri triB(.in(qwire[r2*32 + b2]), .oe(readB_sel[r2]), .out(data_readRegB[b2]));
//         end
//     end
// endgenerate

// endmodule

// module my_tri(in, oe, out); This broke my mf cpu
// input in, oe;
// output out;
// assign out = oe ? in : 1'bz;
// endmodule

wire [31:0] write_en_unmod; //had to basically redo my regfile here
wire [31:0] write_en_mod;
decoderONE writeDecoder(.out(write_en_unmod), .select(ctrl_writeReg), .enable(ctrl_writeEnable));
assign write_en_mod = {write_en_unmod[31:1], 1'b0};

wire [31:0] regq [0:31]; // broke up the 1024 qwire into smaller wires

genvar i;
generate
	for (i = 0; i < 32; i = i + 1) begin : registers32
		register registerstt(regq[i], data_writeReg, clock, write_en_mod[i], ctrl_reset);
	end
endgenerate

wire [31:0] a1 [0:15];
wire [31:0] a2 [0:7];
wire [31:0] a3 [0:3];
wire [31:0] a4 [0:1];
wire [31:0] b1 [0:15];
wire [31:0] b2 [0:7];
wire [31:0] b3 [0:3];
wire [31:0] b4 [0:1];
genvar j;
generate
	for (j = 0; j < 16; j = j + 1) begin : lvl1
		assign a1[j] = ctrl_readRegA[0] ? regq[2*j+1] : regq[2*j];
		assign b1[j] = ctrl_readRegB[0] ? regq[2*j+1] : regq[2*j];
	end
	for (j = 0; j < 8; j = j + 1) begin : lvl2
		assign a2[j] = ctrl_readRegA[1] ? a1[2*j+1] : a1[2*j];
		assign b2[j] = ctrl_readRegB[1] ? b1[2*j+1] : b1[2*j];
	end
	for (j = 0; j < 4; j = j + 1) begin : lvl3
		assign a3[j] = ctrl_readRegA[2] ? a2[2*j+1] : a2[2*j];
		assign b3[j] = ctrl_readRegB[2] ? b2[2*j+1] : b2[2*j];
	end
	for (j = 0; j < 2; j = j + 1) begin : lvl4
		assign a4[j] = ctrl_readRegA[3] ? a3[2*j+1] : a3[2*j];
		assign b4[j] = ctrl_readRegB[3] ? b3[2*j+1] : b3[2*j];
	end
endgenerate
assign data_readRegA = ctrl_readRegA[4] ? a4[1] : a4[0];
assign data_readRegB = ctrl_readRegB[4] ? b4[1] : b4[0];
endmodule

module ttregisters #(parameter WIDTH=1) (q, d, clk, en, clr);

input [31:0] d, en;
input clk, clr;
output [1023:0] q; // output [31:0] q [0:31]; doesnt work so I have to recompile it a different way
wire [31:0] qmodwire [0:31];

genvar i;
generate
	for (i = 0; i < 32; i = i + 1) begin : registers32
	register registerstt(qmodwire[i], d, clk, en[i], clr);
	assign q[i * 32 +: 32] = qmodwire[i];
	end
endgenerate

endmodule

module decoderONE (out, select, enable);
input [4:0] select;
input enable;
output [31:0] out;
assign out = enable << select;
endmodule

