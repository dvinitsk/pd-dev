`include "constants.svh"

module top;

  logic clk, reset;

  clockgen clkg (.clk(clk), .rst(reset));
  pd4 dut (.clk(clk), .reset(reset));

  int pass_count = 0;
  int fail_count = 0;

  task automatic tick();
    @(posedge clk); #1;
  endtask

  //Automated task to check the current instruction against what is expected
  task automatic check_insn(
    input logic [31:0] f_pc,    input logic [31:0] f_insn,
    input logic [6:0]  opcode,  input logic [4:0]  rd,     input logic [4:0] rs1,
    input logic [31:0] imm,
    input logic        pcsel,   input logic regwren, memren, memwren,
    input logic [1:0]  wbsel,
    input logic [31:0] alu_res, input logic br_taken,
    input logic [31:0] m_addr,  input logic [1:0]  m_size, input logic [31:0] m_data,
    input logic        wb_en,   input logic [4:0]  wb_dest, input logic [31:0] wb_data,
    input string name
  );
    logic ok;
    ok = (dut.f_pc           === f_pc)    &&
         (dut.f_insn         === f_insn)  &&
         (dut.d_opcode       === opcode)  &&
         (dut.d_rd           === rd)      &&
         (dut.d_rs1          === rs1)     &&
         (dut.d_imm          === imm)     &&
         (dut.ctrl_pcsel     === pcsel)   &&
         (dut.ctrl_regwren   === regwren) &&
         (dut.ctrl_memren    === memren)  &&
         (dut.ctrl_memwren   === memwren) &&
         (dut.ctrl_wbsel     === wbsel)   &&
         (dut.e_alu_res      === alu_res) &&
         (dut.e_br_taken     === br_taken)&&
         (dut.m_address      === m_addr)  &&
         (dut.m_size_encoded === m_size)  &&
         (dut.m_data         === m_data)  &&
         (dut.w_enable       === wb_en)   &&
         (dut.w_destination  === wb_dest) &&
         (dut.w_data         === wb_data);

    if (ok) begin
      pass_count++;
      $display("PASS  %s", name);
    end else begin
      fail_count++;
      $error("FAIL  %s", name);
      if (dut.f_pc           !== f_pc    ) $error("  FETCH    PC:      exp=%h got=%h",   f_pc,    dut.f_pc);
      if (dut.f_insn         !== f_insn  ) $error("  FETCH    INSN:    exp=%h got=%h",   f_insn,  dut.f_insn);
      if (dut.d_opcode       !== opcode  ) $error("  DECODE   OP:      exp=%h got=%h",   opcode,  dut.d_opcode);
      if (dut.d_rd           !== rd      ) $error("  DECODE   RD:      exp=%0d got=%0d", rd,      dut.d_rd);
      if (dut.d_rs1          !== rs1     ) $error("  DECODE   RS1:     exp=%0d got=%0d", rs1,     dut.d_rs1);
      if (dut.d_imm          !== imm     ) $error("  DECODE   IMM:     exp=%h got=%h",   imm,     dut.d_imm);
      if (dut.ctrl_pcsel     !== pcsel   ) $error("  CTRL     pcsel:   exp=%b got=%b",   pcsel,   dut.ctrl_pcsel);
      if (dut.ctrl_regwren   !== regwren ) $error("  CTRL     regwren: exp=%b got=%b",   regwren, dut.ctrl_regwren);
      if (dut.ctrl_memren    !== memren  ) $error("  CTRL     memren:  exp=%b got=%b",   memren,  dut.ctrl_memren);
      if (dut.ctrl_memwren   !== memwren ) $error("  CTRL     memwren: exp=%b got=%b",   memwren, dut.ctrl_memwren);
      if (dut.ctrl_wbsel     !== wbsel   ) $error("  CTRL     wbsel:   exp=%b got=%b",   wbsel,   dut.ctrl_wbsel);
      if (dut.e_alu_res      !== alu_res ) $error("  EXEC     ALU:     exp=%h got=%h",   alu_res, dut.e_alu_res);
      if (dut.e_br_taken     !== br_taken) $error("  EXEC     BRTAKEN: exp=%b got=%b",   br_taken,dut.e_br_taken);
      if (dut.m_address      !== m_addr  ) $error("  MEM      ADDR:    exp=%h got=%h",   m_addr,  dut.m_address);
      if (dut.m_size_encoded !== m_size  ) $error("  MEM      SIZE:    exp=%b got=%b",   m_size,  dut.m_size_encoded);
      if (dut.m_data         !== m_data  ) $error("  MEM      DATA:    exp=%h got=%h",   m_data,  dut.m_data);
      if (dut.w_enable       !== wb_en   ) $error("  WB       EN:      exp=%b got=%b",   wb_en,   dut.w_enable);
      if (dut.w_destination  !== wb_dest ) $error("  WB       DEST:    exp=%0d got=%0d", wb_dest, dut.w_destination);
      if (dut.w_data         !== wb_data ) $error("  WB       DATA:    exp=%h got=%h",   wb_data, dut.w_data);
    end
    tick();
  endtask

  //  check_insn:
  //    f_pc, f_insn,
  //    opcode, rd, rs1, imm,
  //    pcsel, regwren, memren, memwren, wbsel,
  //    alu_res, br_taken,
  //    m_addr, m_size, m_data,
  //    wb_en, wb_dest, wb_data,
  //    "name"

  initial begin
    $display("\n=== PD4 Testbench ===\n");
    @(negedge reset); #1;

    check_insn(
      32'h01000000, 32'hfd010113,
      7'h13, 5'd2,  5'd2,  32'hffffffd0,
      1'b0, 1'b1, 1'b0, 1'b0, 2'b00,
      32'h010fffd0, 1'b0,
      32'h010fffd0, 2'b00, 32'h00000000,
      1'b1, 5'd2, 32'h010fffd0,
      "ADDI"
    );

    check_insn(
      32'h01000004, 32'h02112623,
      7'h23, 5'd12, 5'd2,  32'h0000002c,
      1'b0, 1'b0, 1'b0, 1'b1, 2'b00,
      32'h010ffffc, 1'b0,
      32'h010ffffc, 2'b10, 32'h00000000,
      1'b0, 5'd12, 32'h010ffffc,
      "SW"
    );

    check_insn(
      32'h01000008, 32'h010007b7,
      7'h37, 5'd15, 5'd0,  32'h01000000,
      1'b0, 1'b1, 1'b0, 1'b0, 2'b00,
      32'h01000000, 1'b0,
      32'h01000000, 2'b00, 32'hfd010113,
      1'b1, 5'd15, 32'h01000000,
      "LUI"
    );

    check_insn(
      32'h0100000c, 32'h2487a883,
      7'h03, 5'd17, 5'd15, 32'h00000248,
      1'b0, 1'b1, 1'b1, 1'b0, 2'b01,
      32'h01000248, 1'b0,
      32'h01000248, 2'b10, 32'h0000000c,
      1'b1, 5'd17, 32'h0000000c,
      "LW"
    );

    check_insn(
      32'h01000010, 32'h24878713,
      7'h13, 5'd14, 5'd15, 32'h00000248,
      1'b0, 1'b1, 1'b0, 1'b0, 2'b00,
      32'h01000248, 1'b0,
      32'h01000248, 2'b00, 32'h0000000c,
      1'b1, 5'd14, 32'h01000248,
      "ADDI"
    );

    check_insn(
      32'h01000014, 32'h00472803,
      7'h03, 5'd16, 5'd14, 32'h00000004,
      1'b0, 1'b1, 1'b1, 1'b0, 2'b01,
      32'h0100024c, 1'b0,
      32'h0100024c, 2'b10, 32'h00000009,
      1'b1, 5'd16, 32'h00000009,
      "LW"
    );

    tick(); //skip: ADDI (repeat, already covered)

    check_insn(
      32'h0100001c, 32'h00872503,
      7'h03, 5'd10, 5'd14, 32'h00000008,
      1'b0, 1'b1, 1'b1, 1'b0, 2'b01,
      32'h01000250, 1'b0,
      32'h01000250, 2'b10, 32'h00000004,
      1'b1, 5'd10, 32'h00000004,
      "LW"
    );

    tick(); //skip: ADDI (repeat, already covered)

    check_insn(
      32'h01000024, 32'h00c72583,
      7'h03, 5'd11, 5'd14, 32'h0000000c,
      1'b0, 1'b1, 1'b1, 1'b0, 2'b01,
      32'h01000254, 1'b0,
      32'h01000254, 2'b10, 32'h00000063,
      1'b1, 5'd11, 32'h00000063,
      "LW"
    );

    tick(); //skip: ADDI (repeat, already covered)

    check_insn(
      32'h0100002c, 32'h01072603,
      7'h03, 5'd12, 5'd14, 32'h00000010,
      1'b0, 1'b1, 1'b1, 1'b0, 2'b01,
      32'h01000258, 1'b0,
      32'h01000258, 2'b10, 32'h00000078,
      1'b1, 5'd12, 32'h00000078,
      "LW"
    );

    tick(); //skip: ADDI (repeat, already covered)

    check_insn(
      32'h01000034, 32'h01472683,
      7'h03, 5'd13, 5'd14, 32'h00000014,
      1'b0, 1'b1, 1'b1, 1'b0, 2'b01,
      32'h0100025c, 1'b0,
      32'h0100025c, 2'b10, 32'h00000001,
      1'b1, 5'd13, 32'h00000001,
      "LW"
    );

    $display("\n=== RESULT: %0d passed, %0d failed ===\n", pass_count, fail_count);
    if (fail_count != 0)
      $error("*** %0d TESTS FAILED ***", fail_count);

    $finish;
  end

endmodule