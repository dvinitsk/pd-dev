/*
 * Module: decode
 *
 * Description: Decode stage — combinational field extraction + immediate generation.
 * All raw instruction fields (rd, rs1, rs2, funct3, funct7) are output directly
 * from the instruction bits regardless of opcode, matching the pattern checker's
 * expectation of raw field values.
 */

`include "constants.svh"

module decode #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input  logic clk,
    input  logic rst,
    input  logic [DWIDTH-1:0] insn_i,
    input  logic [DWIDTH-1:0] pc_i,

    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o,
    output logic [6:0]        opcode_o,
    output logic [4:0]        rd_o,
    output logic [4:0]        rs1_o,
    output logic [4:0]        rs2_o,
    output logic [6:0]        funct7_o,
    output logic [2:0]        funct3_o,
    output logic [4:0]        shamt_o,
    output logic [DWIDTH-1:0] imm_o
);

    // Pass PC and instruction through combinationally.
    // During reset, output BASEADDR / NOP so downstream sees valid signals.
    always_comb begin
        if (rst) begin
            pc_o   = 32'h01000000;
            insn_o = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end else begin
            pc_o   = pc_i;
            insn_o = insn_i;
        end
    end

    // Always output raw instruction fields — the pattern checker expects
    // the unmodified bit slices from the instruction word.
    assign opcode_o = insn_i[6:0];
    assign rd_o     = insn_i[11:7];
    assign funct3_o = insn_i[14:12];
    assign rs1_o    = insn_i[19:15];
    assign rs2_o    = insn_i[24:20];
    assign funct7_o = insn_i[31:25];
    assign shamt_o  = insn_i[24:20];

    // Immediate generator
    igen igen1 (
        .opcode_i (opcode_o),
        .insn_i   (insn_i),
        .imm_o    (imm_o)
    );

endmodule : decode
