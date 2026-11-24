/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	 
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

	/* YOUR CODE STARTS HERE */
    //fetch stage
wire clock_n;
wire fetch_en;
assign clock_n = ~clock;
wire [31:0] pc, pc_next;
wire [31:0] pc_plusone;
SUB  pcpo(.data_result(pc_plusone), .data_operandA(pc), .data_operandB(32'b1), .ctrl_sub(1'b0));
assign address_imem = pc;

wire [31:0] fd_pc, fd_ir, fd_ir_input;
register fd_pcreg(.q(fd_pc), .d(pc_plusone), .clk(clock_n), .en(fetch_en), .clr(reset));
register fd_irreg(.q(fd_ir), .d(fd_ir_input), .clk(clock_n), .en(fetch_en), .clr(reset));
genvar i;
generate
    for(i=0;i<32;i=i+1) begin : pcff
    dffe_ref pcbit(.q(pc[i]), .d(pc_next[i]), .clk(clock_n), .en(fetch_en), .clr(reset));
    end
endgenerate
//decode stage, first part is identifying the opcode, immediate, shamt, and ALUop go in the execute stage
wire [4:0] d_opcode, d_rd, d_rs, d_rt;
assign d_opcode = fd_ir[31:27];
assign d_rd = fd_ir[26:22];
assign d_rs = fd_ir[21:17];
assign d_rt = fd_ir[16:12];
wire d_is_rtype, d_is_addi, d_is_sw, d_is_lw, d_is_j, d_is_bne, d_is_jal, d_is_jr, d_is_blt, d_is_bex, d_is_setx;
assign d_is_rtype = (d_opcode == 5'b00000);
assign d_is_addi = (d_opcode == 5'b00101);
assign d_is_sw = (d_opcode == 5'b00111);
assign d_is_lw = (d_opcode == 5'b01000);
assign d_is_j = (d_opcode == 5'b00001);
assign d_is_bne = (d_opcode == 5'b00010);
assign d_is_jal = (d_opcode == 5'b00011);
assign d_is_jr = (d_opcode == 5'b00100);
assign d_is_blt = (d_opcode == 5'b00110);
assign d_is_bex = (d_opcode == 5'b10110);
assign d_is_setx = (d_opcode == 5'b10101);
//this is the logic for rd, rs1, rs2. Bypassing and stalling logic comes from this
wire [4:0] d_eff_rd, d_eff_rs1, d_eff_rs2;
wire d_writes_rd, d_rs1_from_rs, d_rs1_from_rd;

assign d_writes_rd = d_is_rtype | d_is_addi | d_is_lw;
assign d_eff_rd = d_writes_rd ? d_rd : (d_is_jal ? 5'd31 : (d_is_setx ? 5'd30 : 5'd0));

assign d_rs1_from_rs = d_is_rtype | d_is_addi | d_is_lw | d_is_sw;
assign d_rs1_from_rd = d_is_bne | d_is_blt | d_is_jr;
assign d_eff_rs1 = d_rs1_from_rs ? d_rs : (d_rs1_from_rd ? d_rd : (d_is_bex ? 5'd30 : 5'd0));

assign d_eff_rs2 = d_is_rtype ? d_rt : (d_is_sw ? d_rd : ((d_is_bne | d_is_blt) ? d_rs : 5'd0));

assign ctrl_readRegA = d_eff_rs1;
assign ctrl_readRegB = d_eff_rs2;

//this is the D/X latch in the slides, using the newly made piperegister module that has a parameterized width, which will come in handy now
//edit, added branches and jumps
wire [31:0] dx_pc, dx_a, dx_b, dx_ir, dx_ir_input;
wire [4:0] dx_rd, dx_rs1, dx_rs2, dx_rd_input, dx_rs1_input, dx_rs2_input;
wire dx_en;

pipereg #(32) dx_pcreg(.q(dx_pc), .d(fd_pc), .clk(clock_n), .en(dx_en), .clr(reset));
pipereg #(32) dx_areg(.q(dx_a), .d(data_readRegA), .clk(clock_n), .en(dx_en), .clr(reset));
pipereg #(32) dx_breg(.q(dx_b), .d(data_readRegB), .clk(clock_n), .en(dx_en), .clr(reset));
pipereg #(32) dx_irreg(.q(dx_ir), .d(dx_ir_input), .clk(clock_n), .en(dx_en), .clr(reset));
pipereg #(5) dx_rdreg(.q(dx_rd), .d(dx_rd_input), .clk(clock_n), .en(dx_en), .clr(reset));
pipereg #(5) dx_rs1reg(.q(dx_rs1), .d(dx_rs1_input), .clk(clock_n), .en(dx_en), .clr(reset));
pipereg #(5) dx_rs2reg(.q(dx_rs2), .d(dx_rs2_input), .clk(clock_n), .en(dx_en), .clr(reset));

//ok now this is the execute (X) stage, it needs its own instruction flags from the Decode/Execute Instruction Register latch
wire [4:0] x_opcode, x_shamt, x_aluop;
wire [16:0] x_imm;
wire [26:0] x_target;
wire [31:0] x_imm_ext;

assign x_opcode = dx_ir[31:27];
assign x_shamt = dx_ir[11:7];
assign x_aluop = dx_ir[6:2];
assign x_imm = dx_ir[16:0];
assign x_target = dx_ir[26:0];
assign x_imm_ext = {{15{x_imm[16]}}, x_imm};
wire x_is_rtype, x_is_addi, x_is_sw, x_is_lw, x_is_j, x_is_bne, x_is_jal, x_is_jr, x_is_blt, x_is_bex, x_is_setx;

assign x_is_rtype = (x_opcode == 5'b00000);
assign x_is_addi = (x_opcode == 5'b00101);
assign x_is_sw = (x_opcode == 5'b00111);
assign x_is_lw = (x_opcode == 5'b01000);
assign x_is_j = (x_opcode == 5'b00001);
assign x_is_bne = (x_opcode == 5'b00010);
assign x_is_jal = (x_opcode == 5'b00011);
assign x_is_jr = (x_opcode == 5'b00100);
assign x_is_blt = (x_opcode == 5'b00110);
assign x_is_bex = (x_opcode == 5'b10110);
assign x_is_setx = (x_opcode == 5'b10101);
//this is all the stuff that goes into the primary alu like in the sides (Lecture slideshow 9:cpu is the reference)
wire [31:0] x_opA, x_opB, x_alu_b, x_alu_out;
wire [4:0] x_alu_op;
wire x_uses_imm, x_is_branch, x_ne, x_lt, x_ovf;

//assign x_opA = dx_a; moved to the bottom to account for bypassing
//assign x_opB = dx_b;

assign x_uses_imm = x_is_addi | x_is_lw | x_is_sw;
assign x_is_branch = x_is_bne | x_is_blt;

assign x_alu_b = x_uses_imm ? x_imm_ext : x_opB;
assign x_alu_op = x_uses_imm ? 5'b00000 : (x_is_branch ? 5'b00001 : x_aluop);

alu mainalu(.data_operandA(x_opA), .data_operandB(x_alu_b), .ctrl_ALUopcode(x_alu_op), .ctrl_shiftamt(x_shamt), .data_result(x_alu_out), .isNotEqual(x_ne), .isLessThan(x_lt), .overflow(x_ovf));
// ok now we're doing the execute stages outputs and then the exewcute/datamem latch, we're almost done i think! update i lied
wire [31:0] x_result, x_status, x_final_result;
wire [4:0] x_final_rd;
wire [31:0] xm_result, xm_store_data, xm_ir;
wire [4:0] xm_dest;

wire x_is_add, x_is_sub, x_ovf_add, x_ovf_addi, x_ovf_sub, x_any_ovf, x_is_mul, x_is_div, x_is_muldiv;
wire x_ovf_mul, x_ovf_div;
wire md_running, md_ready, md_exception, md_done, md_stall, md_start_mul, md_start_div; // added for multiply divide stall
wire [31:0] md_result;
//added mult/div section
assign x_is_mul = x_is_rtype & (x_aluop == 5'b00110);
assign x_is_div = x_is_rtype & (x_aluop == 5'b00111);
assign x_is_muldiv = x_is_mul | x_is_div;
assign md_start_mul = x_is_mul & ~md_running;
assign md_start_div = x_is_div & ~md_running; // if its already running then it cant start again
multdiv muldivunitincpu(.data_operandA(x_opA), .data_operandB(x_opB), .ctrl_MULT(md_start_mul), .ctrl_DIV(md_start_div), .clock(clock), .data_result(md_result), .data_exception(md_exception), .data_resultRDY(md_ready)); //bug where it cant be on clock_n oor one of the tests times out, so had to switch it to clock
assign md_done = md_running & md_ready;
assign md_stall = x_is_muldiv & ~md_done;

dffe_ref mdrunff(.q(md_running), .d(md_stall), .clk(clock_n), .en(1'b1), .clr(reset)); //basically keeps track of the stall
//end added mult/div section
//assign x_result = x_is_jal ? dx_pc : (x_is_setx ? {5'b0, x_target} : x_alu_out); before mult/divide
assign x_result = x_is_jal ? dx_pc : (x_is_setx ? {5'b0, x_target} : (x_is_muldiv ? md_result : x_alu_out)); // added mult/div
//selected only when the instruction is jal,  if not jal, gives regular alu output
assign x_is_add = x_is_rtype & (x_aluop == 5'b00000);
assign x_is_sub = x_is_rtype & (x_aluop == 5'b00001);
assign x_ovf_add = x_ovf & x_is_add;
assign x_ovf_addi = x_ovf & x_is_addi;
assign x_ovf_sub = x_ovf & x_is_sub;
assign x_ovf_mul = x_is_mul & md_exception;
assign x_ovf_div = x_is_div & md_exception;
//assign x_any_ovf = x_ovf_add | x_ovf_addi | x_ovf_sub;
//assign x_status = x_ovf_addi ? 32'd2 : (x_ovf_sub ? 32'd3 : 32'd1);
assign x_any_ovf = x_ovf_add | x_ovf_addi | x_ovf_sub | x_ovf_mul | x_ovf_div;

assign x_status = x_ovf_div ? 32'd5 : (x_ovf_mul ? 32'd4 : (x_ovf_addi ? 32'd2 : (x_ovf_sub ? 32'd3 : 32'd1)));

assign x_final_result = x_any_ovf ? x_status : x_result;
assign x_final_rd = x_any_ovf ? 5'd30 : dx_rd;

wire [31:0] xm_ir_input;
wire [4:0] xm_dest_input, xm_rs2_input; //review! This is the nop that goes into X/M during every cycle the mul waits

assign xm_ir_input = md_stall ? 32'b0 : dx_ir;
assign xm_dest_input = md_stall ? 5'b0 : x_final_rd;
assign xm_rs2_input = md_stall ? 5'b0 : dx_rs2;

pipereg #(32) xm_resultreg(.q(xm_result), .d(x_final_result), .clk(clock_n), .en(1'b1), .clr(reset));
pipereg #(32) xm_storereg(.q(xm_store_data), .d(x_opB), .clk(clock_n), .en(1'b1), .clr(reset));
pipereg #(32) xm_irreg(.q(xm_ir), .d(xm_ir_input), .clk(clock_n), .en(1'b1), .clr(reset));
pipereg #(5) xm_destreg(.q(xm_dest), .d(xm_dest_input), .clk(clock_n), .en(1'b1), .clr(reset));
//added for store-data bypass, essentially when a lw is followed by a sw, then when lw is in w, the sw in m requires that new value in w , also rs2 is sw's rd
wire [4:0] xm_rs2;
pipereg #(5) xm_rs2reg(.q(xm_rs2), .d(xm_rs2_input), .clk(clock_n), .en(1'b1), .clr(reset));
//ok now this is the memory stage whihc is pretty easy thanks to the wrapper and ram doing most of the work
wire m_is_sw;
assign m_is_sw = (xm_ir[31:27] == 5'b00111);

assign address_dmem = xm_result;
//assign data = xm_store_data; need to change to account for store-data bypass
assign wren = m_is_sw;
//memory/writeback latch, simple enough
wire [31:0] mw_result, mw_load_data, mw_ir;
wire [4:0] mw_dest;
pipereg #(32) mw_resultreg(.q(mw_result), .d(xm_result), .clk(clock_n), .en(1'b1), .clr(reset));
pipereg #(32) mw_loadreg(.q(mw_load_data), .d(q_dmem), .clk(clock_n), .en(1'b1), .clr(reset));
pipereg #(32) mw_irreg(.q(mw_ir), .d(xm_ir), .clk(clock_n), .en(1'b1), .clr(reset));
pipereg #(5) mw_destreg(.q(mw_dest), .d(xm_dest), .clk(clock_n), .en(1'b1), .clr(reset));
//now THIS is the final writeback stage, we have completed the base cpu at this point, now need to debug and stuff and add mul/div
wire w_is_lw;
wire [31:0] w_data;

assign w_is_lw = (mw_ir[31:27] == 5'b01000);
assign w_data = w_is_lw ? mw_load_data : mw_result;
assign ctrl_writeReg = mw_dest;
assign data_writeReg = w_data;
assign ctrl_writeEnable = (mw_dest != 5'b00000);
//branch, jump logic
wire [31:0] x_branch_target, x_jump_target, x_redirect_pc;
wire x_bex_taken, x_redirect;

SUB branchadd(.data_result(x_branch_target), .data_operandA(dx_pc), .data_operandB(x_imm_ext), .ctrl_sub(1'b0));
assign x_jump_target = {dx_pc[31:27], x_target};
assign x_bex_taken = x_is_bex & (x_opA != 32'b0); //bex is taken when the instruction is bex and $r30 (the status register, read as x_opA) is nonzero

//im highly iffy on this, will need to come back and review logic, might not be right
//update, just fixed it
assign x_redirect = x_is_j | x_is_jal | x_is_jr | (x_is_bne & x_ne) | (x_is_blt & x_lt) | x_bex_taken;
assign x_redirect_pc = x_is_jr ? x_opA : ((x_is_bne | x_is_blt) ? x_branch_target : x_jump_target);
assign pc_next = x_redirect ? x_redirect_pc : pc_plusone;
//this is the hazard control logic, basically says if a lw is detected and that rd in x is the same as one of the registers its going to read in D, then inserts a barrier to stop F/D and halt decode from passing on the value of rs1 or rs2 to the execute stage until the lw has made it past memory
wire rs1_hazard, rs2_hazard, load_use_stall, d_bub;
assign rs1_hazard = (d_eff_rs1 == dx_rd) & (dx_rd != 5'b00000);
assign rs2_hazard = (d_eff_rs2 == dx_rd) & (dx_rd != 5'b00000) & ~d_is_sw;
assign load_use_stall = x_is_lw & (rs1_hazard | rs2_hazard);
//assign fetch_en = ~load_use_stall;
assign fetch_en = ~(load_use_stall | md_stall); //added mult/div stall so it can use either
assign dx_en = ~md_stall;
assign d_bub = x_redirect | load_use_stall;

assign fd_ir_input = x_redirect ? 32'b0 : q_imem; //THESE ARE THE NOPS THAT GO THROUGH F/D and D/X IF A JUMP or branch IS TAKEN
assign dx_ir_input = d_bub ? 32'b0 : fd_ir;
assign dx_rd_input = d_bub ? 5'b0 : d_eff_rd;
assign dx_rs1_input = d_bub ? 5'b0 : d_eff_rs1;
assign dx_rs2_input = d_bub ? 5'b0 : d_eff_rs2;

//this is the bypassing, it should just follow the slides
wire x_a_from_xm, x_a_from_mw, x_b_from_xm, x_b_from_mw;

assign x_a_from_xm = (dx_rs1 == xm_dest) & (xm_dest != 5'b00000);
assign x_a_from_mw = (dx_rs1 == mw_dest) & (mw_dest != 5'b00000);
assign x_opA = x_a_from_xm ? xm_result : (x_a_from_mw ? w_data : dx_a);

assign x_b_from_xm = (dx_rs2 == xm_dest) & (xm_dest != 5'b00000);
assign x_b_from_mw = (dx_rs2 == mw_dest) & (mw_dest != 5'b00000);
assign x_opB = x_b_from_xm ? xm_result : (x_b_from_mw ? w_data : dx_b);

//ok stall logic is below, its load-use, only gets used when there's a lw
wire m_store_from_w;
assign m_store_from_w = (xm_rs2 == mw_dest) & (mw_dest != 5'b00000);
assign data = m_store_from_w ? w_data : xm_store_data;

    /* END CODE */
// 	wire [31:0] pc, pc_next;
// 	wire [4:0] opcode, rd_f, rs_f, rt_f, shamt_f, aluop_f;
// 	wire [16:0] imm_f;
// 	wire [31:0] imm_ext;
// 	wire is_rtype, is_addi, is_add, is_sub;
//     wire [31:0] alu_B, alu_out, status_val;
// 	wire [4:0] alu_op;
// 	wire alu_ovf, ovf_add, ovf_addi, ovf_sub, any_ovf;
// 	genvar i; // basically creates the program counter ff
// 	generate
// 		for (i = 0; i < 32; i = i + 1) begin : pcff
// 			dffe_ref pcbit(.q(pc[i]), .d(pc_next[i]), .clk(clock), .en(1'b1), .clr(reset));
// 		end
// 	endgenerate
// //does pc+1 using the adder that we made during CP1
// 	SUB pcbump(.data_result(pc_next), .data_operandA(pc), .data_operandB(32'b1), .ctrl_sub(1'b0));

// 	assign address_imem = pc;
// //divys up the qmem, which is the data from imem, to to pull out the opcode, the register numbers, the shift amount, the alu op, and the immediate
// 	assign opcode = q_imem[31:27];
// 	assign rd_f = q_imem[26:22];
// 	assign rs_f = q_imem[21:17];
// 	assign rt_f = q_imem[16:12];
// 	assign shamt_f = q_imem[11:7];
// 	assign aluop_f = q_imem[6:2];
// 	assign imm_f = q_imem[16:0];
// 	assign imm_ext = {{15{imm_f[16]}}, imm_f};
// // basically figures out which instruction we're on by checking the opcode bc all the r types share opcode 0 so add and sub need the alu op field too to tell them apart (which is needed later for the overflow status code)
// 	assign is_rtype = (opcode == 5'b00000);
// 	assign is_addi = (opcode == 5'b00101);
// 	assign is_add = is_rtype & (aluop_f == 5'b00000);
// 	assign is_sub = is_rtype & (aluop_f == 5'b00001);

// 	assign ctrl_readRegA = rs_f;
// 	assign ctrl_readRegB = rt_f;
// 	assign alu_B = is_addi ? imm_ext : data_readRegB;
// 	assign alu_op = is_addi ? 5'b00000 : aluop_f;
// //determines opcode
// 	alu mainalu(.data_operandA(data_readRegA), .data_operandB(alu_B), .ctrl_ALUopcode(alu_op), .ctrl_shiftamt(shamt_f), .data_result(alu_out), .isNotEqual(), .isLessThan(), .overflow(alu_ovf));
// //overflow stuff
// 	assign ovf_add = alu_ovf & is_add;
// 	assign ovf_addi = alu_ovf & is_addi;
// 	assign ovf_sub = alu_ovf & is_sub;
// 	assign any_ovf = ovf_add | ovf_addi | ovf_sub;

// 	assign status_val = ovf_addi ? 32'd2 : (ovf_sub ? 32'd3 : 32'd1);
// 	assign ctrl_writeEnable = is_rtype | is_addi;
// 	assign ctrl_writeReg = any_ovf ? 5'd30 : rd_f;
// 	assign data_writeReg = any_ovf ? status_val : alu_out;
// //not doing memoru or pipelining right now so dont have to worry about this yet
// 	assign address_dmem = 32'b0;
// 	assign data = 32'b0;
// 	assign wren = 1'b0;
endmodule
