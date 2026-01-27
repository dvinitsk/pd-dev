module top;
  logic clk;
  logic reset;

  logic [31:0] pc_out;
  logic [31:0] insn_out;

  clockgen clkg (
    .clk (clk),
    .rst (reset)
  );

  // ---------------------------------------------------------------------------
  // DUT interface
  // ---------------------------------------------------------------------------
  fetch fetch_dut(
    .clk(clk),
    .rst(reset),
    .pc_o(pc_out),
    .insn_o(insn_out)
  );
 
  logic [31:0] addr_in;
  logic [31:0] data_in;
  logic read_enable;
  logic write_enable;
  logic [31:0] data_out;

  memory memory_dut(
    .clk(clk),
    .rst(reset),
    .addr_i(addr_in),
    .data_i(data_in),
    .read_en_i(read_enable),
    .write_en_i(write_enable),
    .data_o(data_out)
  );


  //Test Bookkeeping
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  task automatic read_into_mem(
    input logic [31:0] addr,
    input logic [31:0] expected);
    begin 
      read_enable = 1'b1;
      write_enable = 1'b0;
      addr_in = addr;     //reads in address

      #1;                 //delay for the combinational read

      test_count++;
      if(data_out !== expected) begin
        fail_count++;
        $display("FAIL [READ STAGE] addr=%h expected=%h data_out=%h",
                 addr, expected, data_out);
        //$fatal;
      end else begin
        pass_count++;
        $display("PASS [READ STAGE] addr=%h expected=%h data_out=%h",
                 addr, expected, data_out);
      end
    end
  endtask


  task automatic write_into_mem(
    input logic [31:0] addr,
    input logic [31:0] data);
    begin
      read_enable = 1'b0;
      write_enable = 1'b1;
      addr_in = addr;     
      data_in = data;
      @(posedge clk);     //  writes take place on posedge
      #1;                 //  allow signal to settle
      
      write_enable = 1'b0;
      read_into_mem(addr, data);
    end
  endtask

  //Read into Memory Stage (Correct address and data)
  task automatic test_simple_read_cases();
    $display("\n--- Simple memory read cases ---");
    read_into_mem(32'h01000000, 32'hfd010113);
    read_into_mem(32'h01000004, 32'h02112623);
    read_into_mem(32'h01000008, 32'h00012e23);
  endtask 

  //Read into Memory Stage (Incorrect address or data)
  task automatic test_fail_read_cases();
    $display("\n--- Simple memory read cases ---");
    read_into_mem(32'h0100000C, 32'hfd010112); //incorrect data
    read_into_mem(32'h0100000D, 32'h010007b7); //incorrect address
    read_into_mem(32'h0100000E, 32'h0412e230); //both incorrect
  endtask 

  initial begin
    read_enable = 0;
    write_enable = 0;
    addr_in = 32'h01000000;
    data_in = 0;

    @(negedge reset);
    #1;

    test_simple_read_cases();
    test_fail_read_cases();
    $display("\nRESULT: %0d/%0d passed %0d failed\n", pass_count, test_count, fail_count);
    $finish;
  end

endmodule
