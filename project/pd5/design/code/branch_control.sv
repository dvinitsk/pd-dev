/*
 *  -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD3 -----------
 * Module: branch_control
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) 7-bit instruction opcode opcode_i
 * 2) 3-bit funct3 funct3_i
 * 3) 32-bit rs1 data rs1_i
 * 4) 32-bit rs2 data rs2_i
 *
 * Outputs:
 * 1) 1-bit operands are equal signal breq_o
 * 2) 1-bit rs1 < rs2 signal brlt_o
 */

 module branch_control #(
    parameter int DWIDTH=32
)(
    input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    output logic breq_o,
    output logic brlt_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    logic eq, signed_lt, unsigned_lt;
    assign eq         = (rs1_i == rs2_i);
    assign signed_lt  = ($signed(rs1_i) < $signed(rs2_i));
    assign unsigned_lt = (rs1_i < rs2_i);

    always_comb begin
        breq_o = 1'b0;
        brlt_o = 1'b0;
        case (funct3_i[2:1])
            2'b00: breq_o = funct3_i[0] ? !eq : eq;         // BEQ/BNE
            2'b10: brlt_o = funct3_i[0] ? !signed_lt : signed_lt;   // BLT/BGE
            2'b11: brlt_o = funct3_i[0] ? !unsigned_lt : unsigned_lt; // BLTU/BGEU
            default: ;  // 2'b01 invalid
        endcase
    end

endmodule : branch_control

