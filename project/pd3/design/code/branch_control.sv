/*
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

     always_comb begin
        breq_o = 1'b0;
        brlt_o = 1'b0;

        if (opcode_i == BRANCHES) begin
            case (funct3_i)
                3'b000: breq_o = (rs1_i == rs2_i); //BEQ
                3'b001: breq_o = (rs1_i != rs2_i); //BNE
                3'b100: brlt_o = ($signed(rs1_i) < $signed(rs2_i)); //BLT
                3'b101: brlt_o = ($signed(rs1_i) >= $signed(rs2_i)); //BGE
                3'b110: brlt_o = (rs1_i < rs2_i); //BLTU
                3'b111: brlt_o = (rs1_i >= rs2_i); //BGEU
                default: begin 
                    breq_o = 1'b0;
                    brlt_o = 1'b0;
                end
            endcase
        end
     end

endmodule : branch_control

