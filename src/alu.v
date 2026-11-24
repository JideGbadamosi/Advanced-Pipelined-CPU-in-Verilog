module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // add your code here
wire [31:0] addsubOut, andOut, orOut, sllOut, sraOut;
wire c32F, c31F, ofF;

SUB #(1) adderFINAL(.data_result(addsubOut), .c32(c32F), .c31(c31F), .data_operandA(data_operandA), .data_operandB(data_operandB), .ctrl_sub(ctrl_ALUopcode[0]));

bitwiseAND #(1) andFINAL(.out(andOut), .a(data_operandA), .b(data_operandB));
bitwiseOR #(1) orFINAL(.out(orOut), .a(data_operandA), .b(data_operandB));

sll #(1) sllFINAL(.out(sllOut), .in(data_operandA), .ctrl_shiftamt(ctrl_shiftamt));
sra #(1) sraFINAL(.out(sraOut), .in(data_operandA), .ctrl_shiftamt(ctrl_shiftamt));

overf ofFF(.of(ofF), .c31(c31F), .c32(c32F));

assign data_result = ctrl_ALUopcode[2] ? (ctrl_ALUopcode[0] ? sraOut : sllOut) : (ctrl_ALUopcode[1] ? (ctrl_ALUopcode[0] ? orOut : andOut) : addsubOut);

Misc isStuff(.isNotEqual(isNotEqual), .isLessThan(isLessThan), .overflow(overflow), .of(ofF), .data_result(data_result));

endmodule



module level1 #(parameter WIDTH = 1) (c0, c, p, g);
input c0;
input [WIDTH+6:0] p, g;
output [WIDTH+6:1] c;
wire [31:0] w;

//C1
and and1(w[1], p[0], c0);
or or1(c[1], w[1], g[0]);

//C2
and and2(w[2], c0, p[0], p[1]);
and and3(w[3], g[0], p[1]);
or or2(c[2], w[2], w[3], g[1]);

//C3
and and4(w[4], c0, p[0], p[1], p[2]);
and and5(w[5], g[0], p[1], p[2]);
and and6(w[6], g[1], p[2]);
or or3(c[3], g[2], w[4], w[5], w[6]);

//C4
and and7(w[7], c0, p[0], p[1], p[2], p[3]);
and and8(w[8], g[0], p[1], p[2], p[3]);
and and9(w[9], g[1], p[2], p[3]);
and and10(w[10], g[2], p[3]);
or or4(c[4], g[3], w[7], w[8], w[9], w[10]);

//C5
and and11(w[11], c0, p[0], p[1], p[2], p[3], p[4]);
and and12(w[12], g[0], p[1], p[2], p[3], p[4]);
and and13(w[13], g[1], p[2], p[3], p[4]);
and and14(w[14], g[2], p[3], p[4]);
and and15(w[15], g[3], p[4]);
or or5(c[5], g[4], w[11], w[12], w[13], w[14], w[15]);

//C6
and and16(w[16], c0, p[0], p[1], p[2], p[3], p[4], p[5]);
and and17(w[17], g[0], p[1], p[2], p[3], p[4], p[5]);
and and18(w[18], g[1], p[2], p[3], p[4], p[5]);
and and19(w[19], g[2], p[3], p[4], p[5]);
and and20(w[20], g[3], p[4], p[5]);
and and21(w[21], g[4], p[5]);
or or6(c[6], g[5], w[16], w[17], w[18], w[19], w[20], w[21]);

//C7
and and22(w[22], c0, p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
and and23(w[23], g[0], p[1], p[2], p[3], p[4], p[5], p[6]);
and and24(w[24], g[1], p[2], p[3], p[4], p[5], p[6]);
and and25(w[25], g[2], p[3], p[4], p[5], p[6]);
and and26(w[26], g[3], p[4], p[5], p[6]);
and and27(w[27], g[4], p[5], p[6]);
and and28(w[28], g[5], p[6]);
or or7(c[7], g[6], w[22], w[23], w[24], w[25], w[26], w[27], w[28]);
endmodule

module levelONEPONE #(parameter WIDTH=1) (G, P, p, g);
input [WIDTH+6:0] p, g;
wire [WIDTH+6:0] pg;
output G, P;
and bigand1(P, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]);
and and29(pg[7], p[7], g[6]);
and and30(pg[6], p[7], p[6], g[5]);
and and31(pg[5], p[7], p[6], p[5], g[4]);
and and32(pg[4], p[7], p[6], p[5], p[4], g[3]);
and and33(pg[3], p[7], p[6], p[5], p[4], p[3], g[2]);
and and34(pg[2], p[7], p[6], p[5], p[4], p[3], p[2], g[1]);
and and35(pg[1], p[7], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
or bigor1(G, g[7], pg[7], pg[6], pg[5], pg[4], pg[3], pg[2], pg[1]);
endmodule

module levelONEPTWO #(parameter WIDTH=1) (G0, P0, G1, G2, G3, P1, P2, P3, p, g);
input [31:0] p, g;
output G0, P0, G1, G2, G3, P1, P2, P3;
levelONEPONE #(WIDTH)
    Block0(.G(G0), .P(P0), .p(p[7:0]), .g(g[7:0]));
levelONEPONE #(WIDTH)
    Block1(.G(G1), .P(P1), .p(p[15:8]), .g(g[15:8]));
levelONEPONE #(WIDTH)
    Block2(.G(G2), .P(P2), .p(p[23:16]), .g(g[23:16]));
levelONEPONE #(WIDTH)
    Block3(.G(G3), .P(P3), .p(p[31:24]), .g(g[31:24]));

endmodule
module level2 #(parameter WIDTH=1) (c0, c8, c16, c24, c32, G0, G1, G2, G3, P0, P1, P2, P3);
input c0, G0, G1, G2, G3, P0, P1, P2, P3;
output c8, c16, c24, c32;
wire [WIDTH+8:0] WW;
and and36(WW[0], P0, c0);
or ORR1(c8, G0, WW[0]);

and and37(WW[1], P1, G0);
and and38(WW[2], P1, P0, c0);
or ORR2(c16, G1, WW[1], WW[2]);

and and39(WW[3], P2, G1);
and and40(WW[4], P2, P1, G0);
and and41(WW[5], P2, P1, P0, c0);
or ORR3(c24, G2, WW[3], WW[4], WW[5]);

and and42(WW[6], P3, G2);
and and43(WW[7], P3, P2, G1);
and and44(WW[8], P3, P2, P1, G0);
and and45(WW[9], P3, P2, P1, P0, c0);
or ORR4(c32, G3, WW[6], WW[7], WW[8], WW[9]);
endmodule

module kingCLA #(parameter WIDTH=1) (c32, p, g, c0, c);
input [31:0] p, g;
input c0;
output [31:1] c;
output c32;
wire G0, G1, G2, G3, P0, P1, P2, P3, c8, c16, c24;
assign c[8] = c8;
assign c[16] = c16;
assign c[24] = c24;

levelONEPTWO #(WIDTH)
    FinalBlocks(.G0(G0), .P0(P0), .G1(G1), .G2(G2), .G3(G3), .P1(P1), .P2(P2), .P3(P3), .p(p), .g(g));
level2 #(WIDTH)
    Final(.c0(c0), .c8(c8), .c16(c16), .c24(c24), .c32(c32), .G0(G0), .G1(G1), .G2(G2), .G3(G3), .P0(P0), .P1(P1), .P2(P2), .P3(P3));
level1 #(WIDTH) 
    first(.c0(c0), .p(p[7:0]), .g(g[7:0]), .c(c[7:1]));
level1 #(WIDTH) 
    second(.c0(c8), .p(p[15:8]), .g(g[15:8]), .c(c[15:9]));
level1 #(WIDTH) 
    third(.c0(c16), .p(p[23:16]), .g(g[23:16]), .c(c[23:17]));
level1 #(WIDTH) 
    fourth(.c0(c24), .p(p[31:24]), .g(g[31:24]), .c(c[31:25]));

endmodule

module bitwiseAND #(parameter WIDTH=1) (out, a, b);
input [31:0] a, b;
output [31:0] out;
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : andloop
        and (out[i], a[i], b[i]);
    end
endgenerate
endmodule

module bitwiseOR #(parameter WIDTH=1) (out, a, b);
input [31:0] a, b;
output [31:0] out;
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : orloop
        or (out[i], a[i], b[i]);
    end
endgenerate
endmodule

module sll #(parameter WIDTH=1) (out, in, ctrl_shiftamt);

input [4:0] ctrl_shiftamt;
input [31:0] in;
output [31:0] out;
wire [31:0] stage0, stage1, stage2, stage3, stage4;
wire [31:0] sixteenshift;
assign sixteenshift = {in[15:0], 16'b0000000000000000};
assign stage4 = ctrl_shiftamt[4] ? sixteenshift : in;
wire [31:0] eightshift;
assign eightshift = {stage4[23:0], 8'b00000000};
assign stage3 = ctrl_shiftamt[3] ? eightshift : stage4;
wire [31:0] fourshift;
assign fourshift = {stage3[27:0], 4'b0000};
assign stage2 = ctrl_shiftamt[2] ? fourshift : stage3;
wire [31:0] twoshift;
assign twoshift = {stage2[29:0], 2'b00};
assign stage1 = ctrl_shiftamt[1] ? twoshift : stage2;
wire [31:0] oneshift;
assign oneshift = {stage1[30:0], 1'b0};
assign stage0 = ctrl_shiftamt[0] ? oneshift : stage1;
assign out = stage0;
endmodule

module sra #(parameter WIDTH=1) (out, in, ctrl_shiftamt);

input [4:0] ctrl_shiftamt;
input [31:0] in;
output [31:0] out;
wire [31:0] stage0, stage1, stage2, stage3, stage4;
wire [31:0] sixteenshift;
assign sixteenshift = {{16{in[31]}}, in[31:16]};
assign stage4 = ctrl_shiftamt[4] ? sixteenshift : in;
wire [31:0] eightshift;
assign eightshift = {{8{in[31]}}, stage4[31:8]};
assign stage3 = ctrl_shiftamt[3] ? eightshift : stage4;
wire [31:0] fourshift;
assign fourshift = {{4{in[31]}}, stage3[31:4]};
assign stage2 = ctrl_shiftamt[2] ? fourshift : stage3;
wire [31:0] twoshift;
assign twoshift = {{2{in[31]}}, stage2[31:2]};
assign stage1 = ctrl_shiftamt[1] ? twoshift : stage2;
wire [31:0] oneshift;
assign oneshift = {{1{in[31]}}, stage1[31:1]};
assign stage0 = ctrl_shiftamt[0] ? oneshift : stage1;
assign out = stage0;
endmodule

module SUB #(parameter WIDTH=1) (data_result, c32, c31, data_operandA, data_operandB, ctrl_sub);

input [31:0] data_operandA, data_operandB;
input ctrl_sub;
output [31:0] data_result;
output c32, c31;
wire [31:0] bxor;
wire [31:0] p, g;
wire [31:1] c;
genvar j;
generate
    for (j = 0; j < 32; j = j + 1) begin : bxorloop
        xor (bxor[j], data_operandB[j], ctrl_sub);
    end
endgenerate
generate
    for (j = 0; j < 32; j = j + 1) begin : pgbitloop
        xor (p[j], data_operandA[j], bxor[j]);
        and (g[j], data_operandA[j], bxor[j]);
    end
endgenerate
kingCLA #(WIDTH) adder(.c32(c32), .p(p), .g(g), .c0(ctrl_sub), .c(c));
xor xorSum0(data_result[0], p[0], ctrl_sub);
generate
    for (j = 1; j < 32; j = j + 1) begin : SUMBITS
        xor (data_result[j], p[j], c[j]);
    end
endgenerate
assign c31 = c[31];
endmodule

module Misc (isNotEqual, isLessThan, overflow, of, data_result);
input [31:0] data_result;
input of;
output isNotEqual, isLessThan, overflow;
or checkIfEq(isNotEqual, data_result[0], data_result[1], data_result[2], data_result[3], data_result[4], data_result[5], data_result[6], data_result[7], data_result[8], data_result[9], data_result[10], 
data_result[11], data_result[12], data_result[13], data_result[14], data_result[15], data_result[16], data_result[17], data_result[18], data_result[19], data_result[20], data_result[21],
data_result[22], data_result[23], data_result[24], data_result[25], data_result[26], data_result[27], data_result[28], data_result[29], data_result[30], data_result[31]);

xor ltXOR(isLessThan, data_result[31], of); //needs to be opposite when of is turned on but regular when of is turned off or their both turned off, xor truth table is 0110 which is what we need
assign overflow = of;
endmodule

module overf(of, c31, c32);

input c31, c32;
output of;
xor overflowXOR(of, c31, c32); // needed for same reason as ltXOR

endmodule