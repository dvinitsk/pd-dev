module top;
  logic clk;
  logic reset;

  // Clock generator
  clockgen clkg (
    .clk(clk),
    .rst(reset)
  );

  // ---------------------------------------------------------------------------
  // DUT interface
  // ---------------------------------------------------------------------------
  logic [31:0] pc_fetch;
  logic [31:0] insn_fetch;
  logic [31:0] pc_decode;
  logic [31:0] insn_decode;
  logic [6:0] opcode;
  logic [4:0] rd, rs1, rs2;
  logic [6:0] funct7;
  logic [2:0] funct3;
  logic [4:0] shamt;
  logic [31:0] imm;

  // Control signals
  logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
  logic [1:0] wbsel;
  logic [3:0] alusel;

  // Instantiate PD2 top module
  pd2 dut (
    .clk(clk),
    .reset(reset)
  );

  // Test Bookkeeping
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  // Helper task to wait for a clock cycle
  task automatic tick();
    @(posedge clk);
    #1; // Small delay for signals to settle
  endtask

  // Task to check fetch stage outputs
  task automatic check_fetch_stage(
    input logic [31:0] expected_pc,
    input logic [31:0] expected_insn,
    input string test_name
  );
    begin
      test_count++;
      if (dut.pc_fetch !== expected_pc || dut.insn_fetch !== expected_insn) begin
        fail_count++;
        $display("FAIL [FETCH] %s: expected PC=%h INSN=%h, got PC=%h INSN=%h",
                 test_name, expected_pc, expected_insn, dut.pc_fetch, dut.insn_fetch);
      end else begin
        pass_count++;
        $display("PASS [FETCH] %s: PC=%h INSN=%h",
                 test_name, expected_pc, expected_insn);
      end
    end
  endtask

  // Task to check decode stage outputs
  task automatic check_decode_stage(
    input logic [31:0] expected_pc,
    input logic [6:0] expected_opcode,
    input logic [4:0] expected_rd,
    input logic [4:0] expected_rs1,
    input logic [4:0] expected_rs2,
    input logic [2:0] expected_funct3,
    input logic [6:0] expected_funct7,
    input logic [31:0] expected_imm,
    input string test_name
  );
    begin
      test_count++;
      if (dut.pc_decode !== expected_pc ||
          dut.opcode !== expected_opcode ||
          dut.rd !== expected_rd ||
          dut.rs1 !== expected_rs1 ||
          dut.rs2 !== expected_rs2 ||
          dut.funct3 !== expected_funct3 ||
          dut.funct7 !== expected_funct7 ||
          dut.imm !== expected_imm) begin
        fail_count++;
        $display("FAIL [DECODE] %s:", test_name);
        $display("  Expected: PC=%h OP=%b RD=%d RS1=%d RS2=%d F3=%b F7=%b IMM=%h",
                 expected_pc, expected_opcode, expected_rd, expected_rs1, expected_rs2,
                 expected_funct3, expected_funct7, expected_imm);
        $display("  Got:      PC=%h OP=%b RD=%d RS1=%d RS2=%d F3=%b F7=%b IMM=%h",
                 dut.pc_decode, dut.opcode, dut.rd, dut.rs1, dut.rs2,
                 dut.funct3, dut.funct7, dut.imm);
      end else begin
        pass_count++;
        $display("PASS [DECODE] %s: PC=%h OP=%b RD=%d RS1=%d RS2=%d IMM=%h",
                 test_name, expected_pc, expected_opcode, expected_rd, expected_rs1, expected_rs2, expected_imm);
      end
    end
  endtask

  // Task to check control signals
  task automatic check_control_signals(
    input logic expected_pcsel,
    input logic expected_immsel,
    input logic expected_regwren,
    input logic expected_rs1sel,
    input logic expected_rs2sel,
    input logic expected_memren,
    input logic expected_memwren,
    input logic [1:0] expected_wbsel,
    input logic [3:0] expected_alusel,
    input string test_name
  );
    begin
      test_count++;
      if (dut.pcsel !== expected_pcsel ||
          dut.immsel !== expected_immsel ||
          dut.regwren !== expected_regwren ||
          dut.rs1sel !== expected_rs1sel ||
          dut.rs2sel !== expected_rs2sel ||
          dut.memren !== expected_memren ||
          dut.memwren !== expected_memwren ||
          dut.wbsel !== expected_wbsel ||
          dut.alusel !== expected_alusel) begin
        fail_count++;
        $display("FAIL [CONTROL] %s:", test_name);
        $display("  Expected: pcsel=%b immsel=%b regwren=%b rs1sel=%b rs2sel=%b memren=%b memwren=%b wbsel=%b alusel=%h",
                 expected_pcsel, expected_immsel, expected_regwren, expected_rs1sel, expected_rs2sel,
                 expected_memren, expected_memwren, expected_wbsel, expected_alusel);
        $display("  Got:      pcsel=%b immsel=%b regwren=%b rs1sel=%b rs2sel=%b memren=%b memwren=%b wbsel=%b alusel=%h",
                 dut.pcsel, dut.immsel, dut.regwren, dut.rs1sel, dut.rs2sel,
                 dut.memren, dut.memwren, dut.wbsel, dut.alusel);
      end else begin
        pass_count++;
        $display("PASS [CONTROL] %s: alusel=%h regwren=%b memren=%b memwren=%b",
                 test_name, expected_alusel, expected_regwren, expected_memren, expected_memwren);
      end
    end
  endtask

  // Test: Initial reset behavior
  task automatic test_reset();
    $display("\n--- Testing Reset ---");
    // After reset, PC should start at BASEADDR
    tick();
    check_fetch_stage(32'h01000000, 32'hfd010113, "Reset PC");
  endtask

  // Test: PC increment
  task automatic test_pc_increment();
    $display("\n--- Testing PC Increment ---");
    tick();
    check_fetch_stage(32'h01000004, 32'h02112623, "PC += 4");
    tick();
    check_fetch_stage(32'h01000008, 32'h00012e23, "PC += 4");
  endtask

  // Test: Decode I-type instruction (ADDI)
  task automatic test_decode_i_type();
    $display("\n--- Testing I-Type Decode (ADDI) ---");
    // Wait for first instruction to propagate through decode
    tick();
    tick();
    // Instruction: fd010113 = addi sp, sp, -48
    // opcode=0010011, rd=00010, funct3=000, rs1=00010, imm=ffffffd0
    check_decode_stage(
      32'h01000000,  // PC
      7'b0010011,    // opcode (I-type immediate)
      5'd2,          // rd (sp = x2)
      5'd2,          // rs1 (sp = x2)
      5'd0,          // rs2 (not used for I-type)
      3'b000,        // funct3 (ADDI)
      7'd0,          // funct7 (not used for I-type)
      32'hffffffd0,  // imm (sign-extended -48)
      "ADDI decode"
    );
  endtask

  // Test: Control signals for I-type
  task automatic test_control_i_type();
    $display("\n--- Testing I-Type Control Signals ---");
    tick();
    tick();
    // For ADDI: immsel=1, regwren=1, rs2sel=1, alusel=ADD
    check_control_signals(
      1'b0,   // pcsel
      1'b1,   // immsel
      1'b1,   // regwren
      1'b0,   // rs1sel
      1'b1,   // rs2sel
      1'b0,   // memren
      1'b0,   // memwren
      2'b00,  // wbsel (ALU)
      4'd0,   // alusel (ADD)
      "ADDI control"
    );
  endtask

  // Test: R-type instruction
  task automatic test_r_type();
    $display("\n--- Testing R-Type Instructions ---");
    // Need to advance to an R-type instruction in the test program
    // This would require knowing what's in your test1.x at specific addresses
    // For now, this is a template
    $display("  (Skipped - requires specific test program analysis)");
  endtask

  // Main test sequence
  initial begin
    $display("\n========================================");
    $display("PD2 Testbench");
    $display("========================================");

    // Wait for reset to deassert
    @(negedge reset);
    #1;

    // Run tests
    test_reset();
    test_pc_increment();
    test_decode_i_type();
    test_control_i_type();
    test_r_type();

    // Print summary
    $display("\n========================================");
    $display("Test Summary");
    $display("========================================");
    $display("RESULT: %0d/%0d passed, %0d failed\n", pass_count, test_count, fail_count);
    
    if (fail_count == 0) begin
      $display("*** ALL TESTS PASSED ***\n");
    end else begin
      $display("*** SOME TESTS FAILED ***\n");
    end

    $finish;
  end

endmodule
