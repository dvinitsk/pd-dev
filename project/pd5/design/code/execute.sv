/*
 * Module: alu
 *
 * Description: ALU for the execute stage.
 * Operation selected by alusel_i from control.
 * brtaken_o is driven by pd3 top level; ALU outputs 0 for it.
 */

`include "constants.svh"

module alu #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input  logic [AWIDTH-1:0] pc_i,
    input  logic [DWIDTH-1:0] rs1_i,
    input  logic [DWIDTH-1:0] rs2_i,
    input  logic [2:0]        funct3_i,
    input  logic [6:0]        funct7_i,
    input  logic [3:0]        alusel_i,
    output logic [DWIDTH-1:0] res_o,
    output logic              brtaken_o
);

    always_comb begin
        case (alusel_i)
            ADD:   res_o = rs1_i + rs2_i;
            SUB:   res_o = rs1_i - rs2_i;
            SLL:   res_o = rs1_i << rs2_i[4:0];
            SLT:   res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : 32'd0;
            SLTU:  res_o = (rs1_i < rs2_i) ? 32'd1 : 32'd0;
            XOR:   res_o = rs1_i ^ rs2_i;
            SRL:   res_o = rs1_i >> rs2_i[4:0];
            SRA:   res_o = $signed(rs1_i) >>> rs2_i[4:0];
            OR:    res_o = rs1_i | rs2_i;
            AND:   res_o = rs1_i & rs2_i;
            PCADD: res_o = pc_i + rs2_i;   // used for branches/JAL: PC + imm
            default: res_o = rs1_i + rs2_i;
        endcase
    end

    // Branch taken is determined in pd3 top level using branch_control outputs
    assign brtaken_o = 1'b0;

endmodule : alu
