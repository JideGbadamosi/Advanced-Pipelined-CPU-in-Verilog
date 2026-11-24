# 5-Stage Pipelined CPU (Verilog)

A 32-bit pipelined processor written in structural Verilog for Duke ECE 350. It has full bypassing, load-use and multiply/divide stalls, branch/jump flushing, and arithmetic exceptions. It passes the course's full autograder test suite.

## Design

- **Pipeline:** Fetch, Decode, Execute, Memory, Writeback. The PC and the F/D, D/X, X/M and M/W latches update on the falling clock edge. ROM, RAM and the register file sample on the rising edge.
- **Bypassing:** M to X and W to X into both ALU operands (the younger value wins), and W to M for store data. The register file writes in the first half of the cycle and reads in the second, so no W to D path is needed.
- **Stalls:** a load followed by a dependent instruction stalls one cycle. A mul or div holds PC, F/D and D/X in X until the unit is done, and sends bubbles into X/M.
- **Control flow:** branches and jumps resolve in X with a not-taken assumption. A taken one flushes F/D and D/X, a 2-cycle penalty.
- **Exceptions:** overflow on add, addi, sub, mul and div, and divide by zero, write a status code to $r30 (1 add, 2 addi, 3 sub, 4 mul, 5 div) instead of the result. `setx` sets $r30 and `bex` branches if it is nonzero. Because the status goes through the normal write path, it bypasses like any other value.
- **Register indirection:** Decode computes an effective rd, rs1 and rs2 for every instruction (for example jal writes $r31, setx writes $r30, and sw reads rd as a source), so hazard and bypass logic is the same for all instructions.

## Instruction set

`add sub and or sll sra mul div` (R-type), `addi sw lw` (I-type), `j bne jal jr blt bex setx`. Memory is word-addressed with separate instruction and data memories.

## Files (`src/`)

| File | Purpose |
| --- | --- |
| `processor.v` | The pipeline: stages, latches, hazard detection, bypassing, branch logic, exceptions |
| `pipereg.v` | Parameterized-width register with enable and clear, used for pipeline latches |
| `alu.v` | ALU with a carry-lookahead adder/subtractor, AND, OR, shifts, and `isNotEqual`, `isLessThan` and `overflow` flags |
| `multdiv.v` | Multiply/divide unit: radix-2 Booth multiplier and restoring divider, with ready and exception outputs |
| `booths.v`, `productregister.v` | Booth multiplier step and its product register |
| `restorediv.v`, `divisionregister.v` | Restoring-divider step and its remainder/quotient register |
| `sixbcounter.v` | 6-bit counter that times the 32 iterations of a mul or div |
| `regfile.v` | 32 x 32-bit register file with two read ports (mux-tree reads, $r0 always zero) |
| `register.v`, `dffe_ref.v` | 32-bit register and the D flip-flop with enable and clear |
| `Wrapper.v`, `ROM.v`, `RAM.v` | Course-provided harness connecting the processor to instruction memory, data memory and the register file |

`Wrapper.v`, `ROM.v`, `RAM.v` and `dffe_ref.v` come from the course skeleton. The rest is my design.

## Running

The code is simulated with Icarus Verilog through the ECE 350 autotester and Wrapper testbench, which are not included here. Compile all of `src/*.v` with the course `Wrapper_tb.v` and run a test program with `vvp`.

## Notes

- Multdiv runs on the rising clock rather than the inverted one, which saves a cycle per operation.
- The register file keeps one 32-bit net per register. An earlier version used a single 1024-bit vector with tristate reads and simulated far too slowly on the grader.
- Parts of the design and debugging were done with AI assistance (Claude), which the course permits.
