/*
 * Module: pd2
 *
 * Description: Top level module
 */

  module pd2 #(
      parameter int AWIDTH = 32,
      parameter int DWIDTH = 32
  )(
      input logic clk,
      input logic reset
  );

  //Fetch
  logic [AWIDTH-1:0] pc_fetch;
  logic [DWIDTH-1:0] insn_fetch;

  fetch #(
    .DWIDTH(DWIDTH),
    .AWIDTH(AWIDTH)
  ) fetch1 (
    .clk(clk),
    .rst(reset),
    .pc_o(pc_fetch)
  );

  //Decode
  logic [AWIDTH-1:0] pc_decode;
  logic [DWIDTH-1:0] insn_decode;
  logic [6:0] opcode;
  logic [4:0] rd;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [4:0] shamt;
  logic [DWIDTH-1:0] imm;

  decode decode1 (
    .clk(clk),
    .rst(reset),
    .insn_i(insn_fetch),
    .pc_i(pc_fetch),
    .pc_o(pc_decode),
    .insn_o(insn_decode),
    .opcode_o(opcode),
    .rd_o(rd),
    .rs1_o(rs1),
    .rs2_o(rs2),
    .funct7_o(funct7),
    .funct3_o(funct3),
    .shamt_o(shamt),
    .imm_o(imm)
  );

  //Control
  logic pcsel;
  logic immsel;
  logic regwren;
  logic rs1sel;
  logic rs2sel;
  logic memren;
  logic memwren;
  logic [1:0] wbsel;
  logic [3:0] alusel;

  control control1 (
    .insn_i(insn_decode),
    .opcode_i(opcode),
    .funct7_i(funct7),
    .funct3_i(funct3),
    .pcsel_o(pcsel),
    .immsel_o(immsel),
    .regwren_o(regwren),
    .rs1sel_o(rs1sel),
    .rs2sel_o(rs2sel),
    .memren_o(memren),
    .memwren_o(memwren),
    .wbsel_o(wbsel),
    .alusel_o(alusel)
  );

  //Memory
  memory #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH)
  ) mem1 (
    .clk(clk),
    .rst(reset),
    .addr_i(pc_fetch),
    .data_i('0),
    .read_en_i(1'b1),
    .write_en_i(1'b0),
    .data_o(insn_fetch),
    .data_vld_o()
  );
endmodule : pd2
