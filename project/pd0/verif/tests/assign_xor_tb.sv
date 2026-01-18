import constants_pkg::*;

module top;

  logic clk;
  logic reset;

  clockgen clkg(
    .clk (clk),
    .rst (reset)
  );

  logic op1_i;
  logic op2_i;
  logic res_o;

  // ---------------------------------------------------------------------------
  // Device under test
  // ---------------------------------------------------------------------------
  assign_xor dut (
    .op1_i (op1_i),
    .op2_i (op2_i),
    .res_o (res_o)
  );

  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  function automatic void xor_model(
     input logic a,
     input logic b,
     output logic exp_res
  );
 
    exp_res = '0;
    exp_res = a ^ b;
  endfunction
 
  task automatic apply_xor_test(
    input logic a,
    input logic b,
    input string name
  );
  logic exp_res;

  test_count++;

  op1_i = a;
  op2_i = b;
  @(posedge clk);

  xor_model(a, b, exp_res);
  if(res_o === exp_res) begin
    pass_count++;
    $display("PASS [%0d] %-16s a=%0d b=%0d | res=%0d",
             test_count, name, a, b, res_o);
  end else begin
    fail_count++;
    $display("FAIL [%0d] %-16s a=%0d b=%0d", test_count, name, a, b);
    $display("   Expected: res=%0d", exp_res);
    $display("   Actual:   res=%0d", res_o);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test suites
  // ---------------------------------------------------------------------------
 task automatic test_simple_cases();
   $display("\n--- Simple XOR cases ---");
   apply_xor_test(1'b0, 1'b0, "0 ^ 0");
   apply_xor_test(1'b0, 1'b1, "0 ^ 1");
   apply_xor_test(1'b1, 1'b0, "1 ^ 0");
   apply_xor_test(1'b1, 1'b1, "1 ^ 1");
 endtask

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin
    // Wait for reset to deassert
    wait (reset == 1'b0);
    @(posedge clk);

    $display("========================================");
    $display("   Starting XOR unit tests   ");
    $display("========================================");

    test_simple_cases();

    $display("\n========================================");
    $display(" XOR summary: total=%0d pass=%0d fail=%0d",
             test_count, pass_count, fail_count);
    $display("========================================");

    if (fail_count == 0)
      $display("ALL TESTS PASSED ✅");
    else
      $display("SOME TESTS FAILED ❌");

    $finish;
  end

endmodule
