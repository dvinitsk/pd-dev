/*
 * Module: control
 *
 * Description: Control path — sets mux selects and ALU op based on opcode.
 */

`include "constants.svh"

module control #(
    parameter int DWIDTH=32
)(
    input  logic [DWIDTH-1:0] insn_i,
    input  logic [6:0]        opcode_i,
    input  logic [6:0]        funct7_i,
    input  logic [2:0]        funct3_i,

    output logic        pcsel_o,
    output logic        immsel_o,
    output logic        regwren_o,
    output logic        rs1sel_o,   // 0=rs1_data, 1=PC
    output logic        rs2sel_o,   // 0=rs2_data, 1=imm
    output logic        memren_o,
    output logic        memwren_o,
    output logic [1:0]  wbsel_o,    // 00=ALU, 01=MEM, 10=PC+4
    output logic [3:0]  alusel_o
);

    always_comb begin
        // defaults
        pcsel_o   = 1'b0;
        immsel_o  = 1'b0;
        regwren_o = 1'b0;
        rs1sel_o  = 1'b0;
        rs2sel_o  = 1'b0;
        memren_o  = 1'b0;
        memwren_o = 1'b0;
        wbsel_o   = 2'b00;
        alusel_o  = ADD;

        case (opcode_i)
            R_TYPE: begin
                regwren_o = 1'b1;
                case ({funct7_i, funct3_i})
                    {7'b0000000, 3'b000}: alusel_o = ADD;
                    {7'b0100000, 3'b000}: alusel_o = SUB;
                    {7'b0000000, 3'b001}: alusel_o = SLL;
                    {7'b0000000, 3'b010}: alusel_o = SLT;
                    {7'b0000000, 3'b011}: alusel_o = SLTU;
                    {7'b0000000, 3'b100}: alusel_o = XOR;
                    {7'b0000000, 3'b101}: alusel_o = SRL;
                    {7'b0100000, 3'b101}: alusel_o = SRA;
                    {7'b0000000, 3'b110}: alusel_o = OR;
                    {7'b0000000, 3'b111}: alusel_o = AND;
                    default:              alusel_o = ADD;
                endcase
            end

            IMM: begin
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;
                case (funct3_i)
                    3'b000: alusel_o = ADD;
                    3'b100: alusel_o = XOR;
                    3'b110: alusel_o = OR;
                    3'b111: alusel_o = AND;
                    3'b001: alusel_o = SLL;
                    3'b101: alusel_o = insn_i[30] ? SRA : SRL;
                    3'b010: alusel_o = SLT;
                    3'b011: alusel_o = SLTU;
                    default: alusel_o = ADD;
                endcase
            end

            LOADS: begin
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;
                memren_o  = 1'b1;
                wbsel_o   = 2'b01;
                alusel_o  = ADD;
            end

            STORES: begin
                immsel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                memwren_o = 1'b1;
                alusel_o  = ADD;
            end

            BRANCHES: begin
                // ALU computes PC + imm (branch target); comparison in branch_control
                pcsel_o  = 1'b1;
                rs1sel_o = 1'b1;  // alu_op1 = PC
                rs2sel_o = 1'b1;  // alu_op2 = imm
                alusel_o = PCADD;
            end

            JAL: begin
                // ALU computes PC + imm (jump target)
                pcsel_o   = 1'b1;
                regwren_o = 1'b1;
                rs1sel_o  = 1'b1;  // alu_op1 = PC
                rs2sel_o  = 1'b1;  // alu_op2 = imm
                wbsel_o   = 2'b10; // writeback PC+4
                alusel_o  = PCADD;
            end

            JALR: begin
                pcsel_o   = 1'b1;
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;  // alu_op2 = imm, alu_op1 = rs1
                wbsel_o   = 2'b10;
                alusel_o  = ADD;   // rs1 + imm
            end

            LUI: begin
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs1sel_o  = 1'b0;
                rs2sel_o  = 1'b1;
                // LUI: rd = imm. Use ADD with rs1=0 so result = 0 + imm = imm
                alusel_o  = ADD;
            end

            AUIPC: begin
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs1sel_o  = 1'b1;  // alu_op1 = PC
                rs2sel_o  = 1'b1;  // alu_op2 = imm
                alusel_o  = ADD;
            end

            default: begin
                // nothing
            end
        endcase
    end

endmodule : control
