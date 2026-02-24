// pd3_tb.sv — Testbench for PD3 (single-cycle RISC-V processor)
//
// Tests all four pipeline stages (F/D/R/E) against the expected values
// derived from test1.pattern across 13 instruction cycles.
//
// Usage (Verilator):
//   make run -C verif/scripts/ VERILATOR=1 TEST=test1
// Or with ModelSim/VCS just compile all design files + this file and run.

`include "constants.svh"

module top;

  // ------------------------------------------------------------------ //
  //  Clock and reset
  // ------------------------------------------------------------------ //
  logic clk;
  logic reset;

  clockgen clkg (
    .clk(clk),
    .rst(reset)
  );

  // ------------------------------------------------------------------ //
  //  DUT
  // ------------------------------------------------------------------ //
  pd3 dut (
    .clk  (clk),
    .reset(reset)
  );

  // ------------------------------------------------------------------ //
  //  Bookkeeping
  // ------------------------------------------------------------------ //
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  // ------------------------------------------------------------------ //
  //  Helper: advance one clock cycle (sample on negedge, like checker)
  // ------------------------------------------------------------------ //
  task automatic tick();
    @(posedge clk);
    #1;   // small settle delay
  endtask

  // ------------------------------------------------------------------ //
  //  Check tasks — one per stage
  // ------------------------------------------------------------------ //

  task automatic check_fetch(
    input logic [31:0] exp_pc,
    input logic [31:0] exp_insn,
    input string       name
  );
    test_count++;
    if (dut.f_pc !== exp_pc || dut.f_insn !== exp_insn) begin
      fail_count++;
      $display("FAIL [F] %s:", name);
      $display("  expected PC=%h  INSN=%h", exp_pc, exp_insn);
      $display("  got      PC=%h  INSN=%h", dut.f_pc, dut.f_insn);
    end else begin
      pass_count++;
      $display("PASS [F] %s  PC=%h  INSN=%h", name, exp_pc, exp_insn);
    end
  endtask

  task automatic check_decode(
    input logic [31:0] exp_pc,
    input logic [6:0]  exp_opcode,
    input logic [4:0]  exp_rd,
    input logic [4:0]  exp_rs1,
    input logic [4:0]  exp_rs2,
    input logic [2:0]  exp_funct3,
    input logic [6:0]  exp_funct7,
    input logic [31:0] exp_imm,
    input string       name
  );
    test_count++;
    if (dut.d_pc     !== exp_pc     ||
        dut.d_opcode !== exp_opcode ||
        dut.d_rd     !== exp_rd     ||
        dut.d_rs1    !== exp_rs1    ||
        dut.d_rs2    !== exp_rs2    ||
        dut.d_funct3 !== exp_funct3 ||
        dut.d_funct7 !== exp_funct7 ||
        dut.d_imm    !== exp_imm) begin
      fail_count++;
      $display("FAIL [D] %s:", name);
      $display("  expected PC=%h op=%h rd=%0d rs1=%0d rs2=%0d f3=%b f7=%h imm=%h",
               exp_pc, exp_opcode, exp_rd, exp_rs1, exp_rs2,
               exp_funct3, exp_funct7, exp_imm);
      $display("  got      PC=%h op=%h rd=%0d rs1=%0d rs2=%0d f3=%b f7=%h imm=%h",
               dut.d_pc, dut.d_opcode, dut.d_rd, dut.d_rs1, dut.d_rs2,
               dut.d_funct3, dut.d_funct7, dut.d_imm);
    end else begin
      pass_count++;
      $display("PASS [D] %s  PC=%h op=%h rd=%0d rs1=%0d imm=%h",
               name, exp_pc, exp_opcode, exp_rd, exp_rs1, exp_imm);
    end
  endtask

  task automatic check_regrd(
    input logic [4:0]  exp_rs1,
    input logic [4:0]  exp_rs2,
    input logic [31:0] exp_rs1_data,
    input logic [31:0] exp_rs2_data,
    input string       name
  );
    test_count++;
    if (dut.r_read_rs1      !== exp_rs1      ||
        dut.r_read_rs2      !== exp_rs2      ||
        dut.r_read_rs1_data !== exp_rs1_data ||
        dut.r_read_rs2_data !== exp_rs2_data) begin
      fail_count++;
      $display("FAIL [R] %s:", name);
      $display("  expected rs1=%0d rs2=%0d rs1_data=%h rs2_data=%h",
               exp_rs1, exp_rs2, exp_rs1_data, exp_rs2_data);
      $display("  got      rs1=%0d rs2=%0d rs1_data=%h rs2_data=%h",
               dut.r_read_rs1, dut.r_read_rs2,
               dut.r_read_rs1_data, dut.r_read_rs2_data);
    end else begin
      pass_count++;
      $display("PASS [R] %s  rs1=%0d(%h) rs2=%0d(%h)",
               name, exp_rs1, exp_rs1_data, exp_rs2, exp_rs2_data);
    end
  endtask

  task automatic check_execute(
    input logic [31:0] exp_pc,
    input logic [31:0] exp_alu,
    input logic        exp_brt,
    input string       name
  );
    test_count++;
    if (dut.e_pc       !== exp_pc  ||
        dut.e_alu_res  !== exp_alu ||
        dut.e_br_taken !== exp_brt) begin
      fail_count++;
      $display("FAIL [E] %s:", name);
      $display("  expected PC=%h ALU=%h BR_TAKEN=%b", exp_pc, exp_alu, exp_brt);
      $display("  got      PC=%h ALU=%h BR_TAKEN=%b",
               dut.e_pc, dut.e_alu_res, dut.e_br_taken);
    end else begin
      pass_count++;
      $display("PASS [E] %s  PC=%h ALU=%h BR_TAKEN=%b",
               name, exp_pc, exp_alu, exp_brt);
    end
  endtask

  // ------------------------------------------------------------------ //
  //  Main test sequence
  // ------------------------------------------------------------------ //
  initial begin
    $display("\n========================================");
    $display("PD3 Testbench — test1 (13 cycles)");
    $display("========================================\n");

    // Wait for reset to deassert
    @(negedge reset);
    #1;

    // -------------------------------------------------------------- //
    // Tick 0 — ADDI x2, x2, -48  (fd010113)  PC=01000000
    // R.rs1_data = 0x01100000 (x2 reset-init value, visible only this cycle)
    // -------------------------------------------------------------- //
    $display("--- Tick 0: ADDI x2,x2,-48 ---");
    check_fetch  (32'h01000000, 32'hfd010113, "tick0_fetch");
    check_decode (32'h01000000, 7'h13, 5'd2,  5'd2,  5'd16,
                  3'd0, 7'h7e, 32'hffffffd0, "tick0_decode");
    check_regrd  (5'd2, 5'd16, 32'h01100000, 32'h00000000, "tick0_regrd");
    check_execute(32'h01000000, 32'h010fffd0, 1'b0, "tick0_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 1 — SW x1, 44(x2)  (02112623)  PC=01000004
    // x2=0 (reset-init overwritten by rst_prev mechanism)
    // -------------------------------------------------------------- //
    $display("--- Tick 1: SW x1,44(x2) ---");
    check_fetch  (32'h01000004, 32'h02112623, "tick1_fetch");
    check_decode (32'h01000004, 7'h23, 5'd12, 5'd2,  5'd1,
                  3'd2, 7'h01, 32'h0000002c, "tick1_decode");
    check_regrd  (5'd2,  5'd1,  32'h00000000, 32'h00000000, "tick1_regrd");
    check_execute(32'h01000004, 32'h0000002c, 1'b0, "tick1_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 2 — SW x0, 28(x2)  (00012e23)  PC=01000008
    // -------------------------------------------------------------- //
    $display("--- Tick 2: SW x0,28(x2) ---");
    check_fetch  (32'h01000008, 32'h00012e23, "tick2_fetch");
    check_decode (32'h01000008, 7'h23, 5'd28, 5'd2,  5'd0,
                  3'd2, 7'h00, 32'h0000001c, "tick2_decode");
    check_regrd  (5'd2,  5'd0,  32'h00000000, 32'h00000000, "tick2_regrd");
    check_execute(32'h01000008, 32'h0000001c, 1'b0, "tick2_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 3 — SW x0, 24(x2)  (00012c23)  PC=0100000c
    // -------------------------------------------------------------- //
    $display("--- Tick 3: SW x0,24(x2) ---");
    check_fetch  (32'h0100000c, 32'h00012c23, "tick3_fetch");
    check_decode (32'h0100000c, 7'h23, 5'd24, 5'd2,  5'd0,
                  3'd2, 7'h00, 32'h00000018, "tick3_decode");
    check_regrd  (5'd2,  5'd0,  32'h00000000, 32'h00000000, "tick3_regrd");
    check_execute(32'h0100000c, 32'h00000018, 1'b0, "tick3_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 4 — LUI x15, 0x01000000  (010007b7)  PC=01000010
    // -------------------------------------------------------------- //
    $display("--- Tick 4: LUI x15,0x01000 ---");
    check_fetch  (32'h01000010, 32'h010007b7, "tick4_fetch");
    check_decode (32'h01000010, 7'h37, 5'd15, 5'd0,  5'd16,
                  3'd0, 7'h00, 32'h01000000, "tick4_decode");
    check_regrd  (5'd0,  5'd16, 32'h00000000, 32'h00000000, "tick4_regrd");
    check_execute(32'h01000010, 32'h01000000, 1'b0, "tick4_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 5 — LW x12, 488(x15)  (1e87a603)  PC=01000014
    // -------------------------------------------------------------- //
    $display("--- Tick 5: LW x12,488(x15) ---");
    check_fetch  (32'h01000014, 32'h1e87a603, "tick5_fetch");
    check_decode (32'h01000014, 7'h03, 5'd12, 5'd15, 5'd8,
                  3'd2, 7'h0f, 32'h000001e8, "tick5_decode");
    check_regrd  (5'd15, 5'd8,  32'h00000000, 32'h00000000, "tick5_regrd");
    check_execute(32'h01000014, 32'h000001e8, 1'b0, "tick5_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 6 — ADDI x14, x15, 488  (1e878713)  PC=01000018
    // -------------------------------------------------------------- //
    $display("--- Tick 6: ADDI x14,x15,488 ---");
    check_fetch  (32'h01000018, 32'h1e878713, "tick6_fetch");
    check_decode (32'h01000018, 7'h13, 5'd14, 5'd15, 5'd8,
                  3'd0, 7'h0f, 32'h000001e8, "tick6_decode");
    check_regrd  (5'd15, 5'd8,  32'h00000000, 32'h00000000, "tick6_regrd");
    check_execute(32'h01000018, 32'h000001e8, 1'b0, "tick6_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 7 — LW x13, 4(x14)  (00472683)  PC=0100001c
    // -------------------------------------------------------------- //
    $display("--- Tick 7: LW x13,4(x14) ---");
    check_fetch  (32'h0100001c, 32'h00472683, "tick7_fetch");
    check_decode (32'h0100001c, 7'h03, 5'd13, 5'd14, 5'd4,
                  3'd2, 7'h00, 32'h00000004, "tick7_decode");
    check_regrd  (5'd14, 5'd4,  32'h00000000, 32'h00000000, "tick7_regrd");
    check_execute(32'h0100001c, 32'h00000004, 1'b0, "tick7_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 8 — ADDI x14, x15, 488  (1e878713)  PC=01000020
    // -------------------------------------------------------------- //
    $display("--- Tick 8: ADDI x14,x15,488 ---");
    check_fetch  (32'h01000020, 32'h1e878713, "tick8_fetch");
    check_decode (32'h01000020, 7'h13, 5'd14, 5'd15, 5'd8,
                  3'd0, 7'h0f, 32'h000001e8, "tick8_decode");
    check_regrd  (5'd15, 5'd8,  32'h00000000, 32'h00000000, "tick8_regrd");
    check_execute(32'h01000020, 32'h000001e8, 1'b0, "tick8_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 9 — LW x14, 8(x14)  (00872703)  PC=01000024
    // -------------------------------------------------------------- //
    $display("--- Tick 9: LW x14,8(x14) ---");
    check_fetch  (32'h01000024, 32'h00872703, "tick9_fetch");
    check_decode (32'h01000024, 7'h03, 5'd14, 5'd14, 5'd8,
                  3'd2, 7'h00, 32'h00000008, "tick9_decode");
    check_regrd  (5'd14, 5'd8,  32'h00000000, 32'h00000000, "tick9_regrd");
    check_execute(32'h01000024, 32'h00000008, 1'b0, "tick9_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 10 — SW x12, 4(x2)  (00c12223)  PC=01000028
    // -------------------------------------------------------------- //
    $display("--- Tick 10: SW x12,4(x2) ---");
    check_fetch  (32'h01000028, 32'h00c12223, "tick10_fetch");
    check_decode (32'h01000028, 7'h23, 5'd4,  5'd2,  5'd12,
                  3'd2, 7'h00, 32'h00000004, "tick10_decode");
    check_regrd  (5'd2,  5'd12, 32'h00000000, 32'h00000000, "tick10_regrd");
    check_execute(32'h01000028, 32'h00000004, 1'b0, "tick10_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 11 — SW x13, 8(x2)  (00d12423)  PC=0100002c
    // -------------------------------------------------------------- //
    $display("--- Tick 11: SW x13,8(x2) ---");
    check_fetch  (32'h0100002c, 32'h00d12423, "tick11_fetch");
    check_decode (32'h0100002c, 7'h23, 5'd8,  5'd2,  5'd13,
                  3'd2, 7'h00, 32'h00000008, "tick11_decode");
    check_regrd  (5'd2,  5'd13, 32'h00000000, 32'h00000000, "tick11_regrd");
    check_execute(32'h0100002c, 32'h00000008, 1'b0, "tick11_execute");
    tick();

    // -------------------------------------------------------------- //
    // Tick 12 — SW x14, 12(x2)  (00e12623)  PC=01000030
    // -------------------------------------------------------------- //
    $display("--- Tick 12: SW x14,12(x2) ---");
    check_fetch  (32'h01000030, 32'h00e12623, "tick12_fetch");
    check_decode (32'h01000030, 7'h23, 5'd12, 5'd2,  5'd14,
                  3'd2, 7'h00, 32'h0000000c, "tick12_decode");
    check_regrd  (5'd2,  5'd14, 32'h00000000, 32'h00000000, "tick12_regrd");
    check_execute(32'h01000030, 32'h0000000c, 1'b0, "tick12_execute");
    tick();

    // ---------------------------------------------------------------- //
    //  Summary
    // ---------------------------------------------------------------- //
    $display("\n========================================");
    $display("Test Summary");
    $display("========================================");
    $display("RESULT: %0d/%0d passed, %0d failed",
             pass_count, test_count, fail_count);

    if (fail_count == 0)
      $display("*** ALL TESTS PASSED ***\n");
    else
      $display("*** SOME TESTS FAILED ***\n");

    $finish;
  end

endmodule
