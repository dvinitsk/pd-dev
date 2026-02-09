/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * 2) input instruction insn_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */
 `include "constants.svh"

module igen #(
    parameter int DWIDTH=32
    )(
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] insn_i,
    output logic [31:0] imm_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */

    always_comb begin
        case(opcode_i)

            //R-type:
            R_TYPE: imm_o = ZERO;

            //I-type:
            IMM: imm_o = {{20{insn_i[31]}}, insn_i[31:20]};
            LOADS: imm_o = {{20{insn_i[31]}}, insn_i[31:20]};
            JALR: imm_o = {{20{insn_i[31]}}, insn_i[31:20]};

            //S-type:
            STORES: imm_o = {{20{insn_i[31]}}, insn_i[31:25],insn_i[11:7]};

            //B-type:
            BRANCHES: imm_o = {{19{insn_i[31]}},insn_i[31],insn_i[7],insn_i[30:25], insn_i[11:8],1'd0};

            //J-type:
            JAL: imm_o = {{11{insn_i[31]}},insn_i[31],insn_i[19:12],insn_i[20], insn_i[30:21],1'd0};

            //U-type:
            LUI: imm_o = {insn_i[31:12],12'd0};
            AUIPC: imm_o = {insn_i[31:12],12'd0};

            default: imm_o = ZERO;
        endcase
    end

endmodule : igen
