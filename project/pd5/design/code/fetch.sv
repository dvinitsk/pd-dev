/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o
 */

module fetch #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=32'h01000000
)(
    input  logic clk,
    input  logic rst,
    input  logic [AWIDTH-1:0] next_pc_i,
    input  logic              pcsel_i,
    output logic [AWIDTH-1:0] pc_o
);
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_o <= BASEADDR;
        end else if (pcsel_i) begin
            pc_o <= next_pc_i;
        end else begin
            pc_o <= pc_o + 32'd4;
        end
    end
endmodule : fetch
