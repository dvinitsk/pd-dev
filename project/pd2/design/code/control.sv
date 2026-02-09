/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * Inputs:
 * 1) DWIDTH instruction ins_i
 * 2) 7-bit opcode opcode_i
 * 3) 7-bit funct7 funct7_i
 * 4) 3-bit funct3 funct3_i
 *
 * Outputs:
 * 1) 1-bit PC select pcsel_o
 * 2) 1-bit Immediate select immsel_o
 * 3) 1-bit register write en regwren_o
 * 4) 1-bit rs1 select rs1sel_o
 * 5) 1-bit rs2 select rs2sel_o
 * 6) k-bit ALU select alusel_o
 * 7) 1-bit memory read en memren_o
 * 8) 1-bit memory write en memwren_o
 * 9) 2-bit writeback sel wbsel_o
 */

`include "constants.svh"

module control #(
	parameter int DWIDTH=32
)(
	// inputs
    input logic [DWIDTH-1:0] insn_i,
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,

    // outputs
    output logic pcsel_o,
    output logic immsel_o,
    output logic regwren_o,
    output logic rs1sel_o, //register1 = 0 or PC = 1
    output logic rs2sel_o, //register2 = 0 or Imm = 1
    output logic memren_o,
    output logic memwren_o,
    output logic [1:0] wbsel_o, //00 = ALU, 01 = MEM, 10 = PC+4
    output logic [3:0] alusel_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    //control driving comb block
    always_comb begin
        
        //initialize
        pcsel_o = 0;
        immsel_o = 0;
        regwren_o = 0;
        rs1sel_o = 0; 
        rs2sel_o = 0;
        memren_o = 0;
        memwren_o = 0;
        wbsel_o = 0;
        alusel_o = ADD;

        case (opcode_i)

        //R-types
            R_TYPE: begin
                regwren_o = 1'b1;
                rs2sel_o  = 1'b0;

                 //based on funct7 and funct3 pick alusel_o
                case ({funct7_i, funct3_i})
                    {7'b0000000, 3'b000}: alusel_o = ADD;
                    {7'b0100000, 3'b000}: alusel_o = SUB;
                    {7'b0000000, 3'b001}: alusel_o = SLL;
                    {7'b0000000, 3'b010}: alusel_o = SLT;
                    {7'b0000000, 3'b011}: alusel_o = SLTU;
                    {7'b0000000, 3'b100}: alusel_o = XOR;
                    {7'b0000000, 3'b101}: alusel_o = SRL;
                    {7'b0100000, 3'b101}: alusel_o = SRA;
                    {7'b0000000, 3'b111}: alusel_o = AND;
                    {7'b0000000, 3'b110}: alusel_o = OR;
                    default: alusel_o = ADD;
                endcase
            end

        //I-type:
            IMM: begin
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;

                case (funct3_i)
                    3'b000: alusel_o = ADD; //ADDI
                    3'b100: alusel_o = XOR; //XORI
                    3'b110: alusel_o = OR; //ORI
                    3'b111: alusel_o = AND; //ANDI
                    3'b001: alusel_o = SLL; //SLLI

                    //31:25 -> 0100000 = SRAI, 0000000 = SRLI (30 bit is diff)
                    3'b101: begin
                        if (insn_i[30]) begin
                            alusel_o = SRA; //SRAI
                        end else begin
                            alusel_o = SRL; //SRLI
                        end
                    end
                    
                    3'b010: alusel_o = SLT; //SLTI
                    3'b011: alusel_o = SLTU; //SLTIU
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

            JALR: begin
                pcsel_o   = 1'b1;
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;
                wbsel_o   = 2'b10;
                alusel_o  = ADD;
            end

        //S-type:
            STORES: begin
                immsel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                memwren_o = 1'b1;
                alusel_o  = ADD;
            end

        //B-type:
            BRANCHES: begin
                pcsel_o   = 1'b1;
                alusel_o  = SUB;
            end

            //J-type:
            JAL: begin
                pcsel_o   = 1'b1;
                regwren_o = 1'b1;
                wbsel_o   = 2'b10;
            end
            
        //U-type:
            LUI: begin
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;
            end

            AUIPC: begin
                immsel_o  = 1'b1;
                regwren_o = 1'b1;
                rs1sel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                alusel_o  = ADD;
            end

            default: begin
                //empty by design
            end
        endcase
    end
endmodule : control
