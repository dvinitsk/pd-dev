import constants_pkg::*;

module top;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int DWIDTH = 8;  // You can change to 32, 64, etc. later

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
  logic [1:0]          sel_i;
  logic [DWIDTH-1:0]   op1_i;
  logic [DWIDTH-1:0]   op2_i;
  logic [DWIDTH-1:0]   res_o;
  logic                zero_o;
  logic                neg_o;

  // ---------------------------------------------------------------------------
  // DUT instantiation
  // ---------------------------------------------------------------------------
  alu #(.DWIDTH(DWIDTH)) dut (
    .sel_i  (sel_i),
    .op1_i  (op1_i),
    .op2_i  (op2_i),
    .res_o  (res_o),
    .zero_o (zero_o),
    .neg_o  (neg_o)
  );

  // ---------------------------------------------------------------------------
  // Test bookkeeping
  // ---------------------------------------------------------------------------
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  // ---------------------------------------------------------------------------
  // ALU reference model
  // ---------------------------------------------------------------------------
  function automatic void alu_model(
    input  logic [1:0]          sel,
    input  logic [DWIDTH-1:0]   a,
    input  logic [DWIDTH-1:0]   b,
    output logic [DWIDTH-1:0]   exp_res,
    output logic                exp_zero,
    output logic                exp_neg
  );
    exp_res = '0;

    unique case (sel)
      ADD: exp_res = a + b;
      SUB: exp_res = a - b;
      AND: exp_res = a & b;
      OR:  exp_res = a | b;
      default: exp_res = '0;
    endcase

    exp_zero = (exp_res == '0);
    exp_neg  = exp_res[DWIDTH-1];
  endfunction

  // ---------------------------------------------------------------------------
  // Generic "apply one test" task
  // ---------------------------------------------------------------------------
  task automatic apply_alu_test(
    input  logic [1:0]          sel,
    input  logic [DWIDTH-1:0]   a,
    input  logic [DWIDTH-1:0]   b,
    input  string               name
  );
    logic [DWIDTH-1:0] exp_res;
    logic              exp_zero;
    logic              exp_neg;

    test_count++;

    sel_i = sel;
    op1_i = a;
    op2_i = b;

    // Let design settle for one cycle
    @(posedge clk);

    alu_model(sel, a, b, exp_res, exp_zero, exp_neg);

    if (res_o === exp_res && zero_o === exp_zero && neg_o === exp_neg) begin
      pass_count++;
      $display("PASS [%0d] %-16s sel=%b a=%0d b=%0d | res=%0d zero=%b neg=%b",
               test_count, name, sel, a, b, res_o, zero_o, neg_o);
    end else begin
      fail_count++;
      $display("FAIL [%0d] %-16s sel=%b a=%0d b=%0d", test_count, name, sel, a, b);
      $display("   Expected: res=%0d zero=%b neg=%b", exp_res, exp_zero, exp_neg);
      $display("   Actual:   res=%0d zero=%b neg=%b", res_o, zero_o, neg_o);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test suites
  // ---------------------------------------------------------------------------
  task automatic test_simple_cases();
    $display("\n--- Simple ALU cases ---");
    apply_alu_test(ADD, 8'd1,  8'd2,  "ADD 1+2");
    apply_alu_test(ADD, 8'd10, 8'd5,  "ADD 10+5");
    apply_alu_test(SUB, 8'd10, 8'd3,  "SUB 10-3");
    apply_alu_test(AND, 8'hF0, 8'h0F, "AND F0&0F");
    apply_alu_test(OR,  8'h80, 8'h01, "OR  80|01");
  endtask

  task automatic test_edge_cases();
    $display("\n--- Edge ALU cases ---");
    apply_alu_test(ADD, 8'd0,      8'd0,      "ADD 0+0");
    apply_alu_test(SUB, 8'd0,      8'd1,      "SUB 0-1");
    apply_alu_test(ADD, 8'h7F,     8'd1,      "ADD max_pos+1");
    apply_alu_test(SUB, 8'h80,     8'd1,      "SUB min_neg-1");
    apply_alu_test(AND, 8'hFF,     8'h00,     "AND FF&00");
    apply_alu_test(OR,  8'h00,     8'h00,     "OR 0|0");
  endtask

  task automatic test_random_cases(int num = 20);
    $display("\n--- Random ALU cases (%0d) ---", num);
    for (int i = 0; i < num; i++) begin
      logic [1:0]        sel_r = aluSel_e'($urandom_range(0, 3));
      logic [DWIDTH-1:0] a_r;
      logic [DWIDTH-1:0] b_r;
      logic [31:0]       rand_word_a;
      logic [31:0]       rand_word_b;

      // Generate full 32-bit randoms, then explicitly truncate
      rand_word_a = $urandom();
      rand_word_b = $urandom();

      a_r = rand_word_a[DWIDTH-1:0];
      b_r = rand_word_b[DWIDTH-1:0];

      apply_alu_test(sel_r, a_r, b_r, $sformatf("RAND_%0d", i));
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
    $display("   Starting ALU unit tests   ");
    $display("========================================");

    test_simple_cases();
    test_edge_cases();
    test_random_cases(50);

    $display("\n========================================");
    $display(" ALU summary: total=%0d pass=%0d fail=%0d",
             test_count, pass_count, fail_count);
    $display("========================================");

    if (fail_count == 0)
      $display("ALL TESTS PASSED ✅");
    else
      $display("SOME TESTS FAILED ❌");

    $finish;
  end

endmodule
