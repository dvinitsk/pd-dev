module top;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int DWIDTH = 8;

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
  logic [DWIDTH-1:0] op1_i;
  logic [DWIDTH-1:0] op2_i;
  logic [DWIDTH-1:0] res_o;

  // ---------------------------------------------------------------------------
  // DUT instantiation
  // ---------------------------------------------------------------------------
  three_stage_pipeline #(.DWIDTH(DWIDTH)) dut (
    .clk   (clk),
    .rst   (reset),
    .op1_i (op1_i),
    .op2_i (op2_i),
    .res_o (res_o)
  );

  // ---------------------------------------------------------------------------
  // Test bookkeeping
  // ---------------------------------------------------------------------------
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  // ---------------------------------------------------------------------------
  // Three-stage pipeline reference model
  // ---------------------------------------------------------------------------
  function automatic logic [DWIDTH-1:0] pipeline_model(
    input logic [DWIDTH-1:0] a,
    input logic [DWIDTH-1:0] b
  );
    logic [DWIDTH-1:0] add_res;
    logic [DWIDTH-1:0] sub_res;

    add_res = a + b;
    sub_res = add_res - a;
    return sub_res;
  endfunction

  // ---------------------------------------------------------------------------
  // Generic "apply one test" task
  // ---------------------------------------------------------------------------
  task automatic apply_pipeline_test(
    input  logic [DWIDTH-1:0] a,
    input  logic [DWIDTH-1:0] b,
    input  string             name
  );
    logic [DWIDTH-1:0] exp_res;

    test_count++;

    //Apply inputs
    op1_i = a;
    op2_i = b;

    //Wait for pipeline latency (Three stages -> three cycles)
    repeat (3) @(posedge clk);

    exp_res = pipeline_model(a, b);

    if (res_o === exp_res) begin
      pass_count++;
      $display("PASS [%0d] %-16s a=%0d b=%0d | res=%0d",
               test_count, name, a, b, res_o);
    end else begin
      fail_count++;
      $display("FAIL [%0d] %-16s a=%0d b=%0d",
               test_count, name, a, b);
      $display("   Expected: res=%0d", exp_res);
      $display("   Actual:   res=%0d", res_o);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test suites
  // ---------------------------------------------------------------------------
  task automatic test_simple_cases();
    $display("\n--- Simple pipeline cases ---");
    apply_pipeline_test(8'd1,  8'd2,  "1+2-1");
    apply_pipeline_test(8'd10, 8'd5,  "10+5-10");
    apply_pipeline_test(8'd3,  8'd7,  "3+7-3");
  endtask

  task automatic test_edge_cases();
    $display("\n--- Edge pipeline cases ---");
    apply_pipeline_test(8'd0,  8'd1,  "0+1-0");
    apply_pipeline_test(8'd1,  8'd0,  "1+0-1");
    apply_pipeline_test(8'h7F, 8'd1,  "max+1-max"); //overflow edge case
    apply_pipeline_test(8'h80, 8'd1,  "min+1-min"); //signed edge
    apply_pipeline_test(8'd5, 8'd5,  "5+5-5"); //cancel eachother out
  endtask

  task automatic test_random_cases(int num = 20);
    $display("\n--- Random pipeline cases (%0d) ---", num);
    for (int i = 0; i < num; i++) begin
      logic [31:0] rand_a;
      logic [31:0] rand_b;
      logic [DWIDTH-1:0] a_r;
      logic [DWIDTH-1:0] b_r;

      rand_a = $urandom();
      rand_b = $urandom();

      a_r = rand_a[DWIDTH-1:0];
      b_r = rand_b[DWIDTH-1:0];

      apply_pipeline_test(a_r, b_r, $sformatf("RAND_%0d", i));
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin

    // Wait for reset
    wait (reset == 1'b0);
    @(posedge clk);

    $display("========================================");
    $display(" Starting three-stage pipeline tests ");
    $display("========================================");

    test_simple_cases();
    test_edge_cases();
    test_random_cases(50);

    $display("\n========================================");
    $display(" Pipeline summary: total=%0d pass=%0d fail=%0d",
             test_count, pass_count, fail_count);
    $display("========================================");

    if (fail_count == 0)
      $display("ALL TESTS PASSED ✅");
    else
      $display("SOME TESTS FAILED ❌");

    $finish;
  end

endmodule
