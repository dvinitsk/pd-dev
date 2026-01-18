module top;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int DWIDTH = 32;  

  // ---------------------------------------------------------------------------
  // Clock / reset using clockgen (must match test_pd.cpp scope: TOP.top.clkg)
  // ---------------------------------------------------------------------------
  logic clk;
  logic reset;

  clockgen clkg (
    .clk (clk),
    .rst (reset)
  );

  // ---------------------------------------------------------------------------
  // DUT interface
  // ---------------------------------------------------------------------------
  logic [DWIDTH-1:0]   in_i;
  logic [DWIDTH-1:0]   out_o;

  // ---------------------------------------------------------------------------
  // DUT instantiation
  // ---------------------------------------------------------------------------
  reg_rst #(.DWIDTH(DWIDTH)) dut (
    .clk    (clk),
    .rst    (reset),
    .in_i   (in_i),
    .out_o  (out_o)
  );

  // ---------------------------------------------------------------------------
  // Test bookkeeping
  // ---------------------------------------------------------------------------
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  // ---------------------------------------------------------------------------
  // Generic "apply one test" task
  // ---------------------------------------------------------------------------
  task automatic apply_reg_test(
    input   logic [DWIDTH-1:0]  a,
    input   logic               rst_test,
    input   string              name
  );
    logic [DWIDTH-1:0] exp_res;
    string index;

    test_count++;
    in_i = a;
    reset = rst_test;

    // Let design settle for one cycle
    @(posedge clk);
    
    if(rst_test)
      exp_res = '0;
    else
      exp_res = a; 

    if (out_o === exp_res) begin
      pass_count++;
      index = $sformatf("[%0d]", test_count);
      $display("PASS %4s %-45s reset=%0b a=%08h | res=%08h", index, name, rst_test, a, out_o);
    end else begin
      fail_count++;
      $display("FAIL %4s %-45s reset=%0b a=%08h ", index, name, rst_test, a);
      $display("   Expected: res=%08h", exp_res);
      $display("   Actual:   res=%08h", out_o);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test suites
  // ---------------------------------------------------------------------------
  task automatic test_simple_cases();
    $display("\n--- Simple REG cases ---");
    apply_reg_test('d0, 0, "Capture 0, no reset");
    apply_reg_test('d1, 0, "Capture 1, no reset");
  endtask

  task automatic test_edge_cases();
    $display("\n--- Edge REG cases ---");
    apply_reg_test(32'hFFFFFFFF, 0, "Capture all 1's, no reset");
    apply_reg_test(32'h80000000, 0, "Capture only MSB on, no reset");
    apply_reg_test(32'h00000001, 0, "Capture only LSB on, no reset");
    apply_reg_test(32'hFFFF0000, 0, "Capture only upper halfword on, no reset");
    apply_reg_test(32'h0000FFFF, 0, "Capture only lower halfword on, no reset");
  endtask
  
  task automatic test_reset_cases();
    $display("\n--- Reset REG cases ---");
    apply_reg_test(32'h12345678,      0, "Capture with no reset");
    apply_reg_test(32'h11111111,      1, "Capture with reset"); 
    apply_reg_test(32'hDEADBEEF,      0, "Capture after a previous reset, with no reset");
    apply_reg_test(32'hAAAAAAAA,      0, "Capture one value, with reset");
    apply_reg_test(32'hBBBBBBBB,      0, "Capture another value, with no reset");
    apply_reg_test(32'hDEADCAFE,      1, "Capture a third value, with reset");
    apply_reg_test(32'hDEADBEEF,      0, "Capture a fourth value, with no reset");
    endtask

  task automatic test_random_cases(int num = 20);
    $display("\n--- Random REG cases (%0d) ---", num);
    for (int i = 0; i < num; i++) begin
      logic [DWIDTH-1:0]  a_rand = $urandom();  
      logic               rst_case = $urandom_range(0, 1)[0]; //trucate to just the first bit
      apply_reg_test(a_rand, rst_case, $sformatf("RAND_%0d", i));
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin
    // Wait for reset to deassert
    wait (reset == 1'b0);
    @(posedge clk);

    $display("========================================");
    $display("   Starting reg_rst unit tests   ");
    $display("========================================");

    test_simple_cases();
    test_edge_cases();
    test_reset_cases();
    test_random_cases(50);

    $display("\n========================================");
    $display(" REG summary: total=%0d pass=%0d fail=%0d",
             test_count, pass_count, fail_count);
    $display("========================================");

    if (fail_count == 0)
      $display("ALL TESTS PASSED ✅");
    else
      $display("SOME TESTS FAILED ❌");

    $finish;
  end

endmodule
