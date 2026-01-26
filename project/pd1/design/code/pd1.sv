/*
 * Module: pd1
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd1 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */

logic [AWIDTH-1:0] addr;
logic [DWIDTH-1:0] dwidth;
logic read_en;
logic write_en;
logic [DWIDTH-1:0] data_in;
logic [DWIDTH-1:0] data_out;


memory #(
  .AWIDTH(AWIDTH),
  .DWIDTH(DWIDTH)
) memory_1 (
    .clk        (clk),
    .rst        (reset),
    .addr_i     (pc),  
    .data_i     (data_in),
    .read_en_i  (read_en),
    .write_en_i (write_en),
    .data_o     (insn)
);

logic [AWIDTH-1:0] pc;
logic [DWIDTH-1:0] insn; // 32 bit instruction data output

fetch #(.DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
) fetch_1 (
    .clk    (clk),
    .rst    (reset),
    .pc_o   (pc),
    .insn_o (insn)
);

endmodule : pd1
