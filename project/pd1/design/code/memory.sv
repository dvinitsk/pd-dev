/*
 * module: memory
 *
 * description: byte-addressable memory implementation. supports both read and write operations.
 * reads are combinational and writes are performed on the rising clock edge.
 *
 * inputs:
 * 1) clk
 * 2) rst signal
 * 3) awidth address addr_i
 * 4) dwidth data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 *
 * outputs:
 * 1) dwidth data output data_o
 */

module memory #(
  // parameters
  parameter int awidth = 32,
  parameter int dwidth = 32,
  parameter logic [31:0] base_addr = 32'h01000000
) (
  // inputs
  input logic clk,
  input logic rst,
  input logic [awidth-1:0] addr_i = base_addr,
  input logic [dwidth-1:0] data_i,
  input logic read_en_i,
  input logic write_en_i,
  // outputs
  output logic [dwidth-1:0] data_o
)

  logic [dwidth-1:0] temp_memory [0:`mem_depth];
  // byte-addressable memory
  logic [7:0] main_memory [0:`mem_depth];  // byte-addressable memory
  logic [awidth-1:0] address;
  assign address = addr_i - base_addr;

  initial begin
    $readmemh(`mem_path, temp_memory);
    // load data from temp_memory into main_memory
    for (int i = 0; i < `line_count; i++) begin
      main_memory[4*i]     = temp_memory[i][7:0];
      main_memory[4*i + 1] = temp_memory[i][15:8];
      main_memory[4*i + 2] = temp_memory[i][23:16];
      main_memory[4*i + 3] = temp_memory[i][31:24];
    end
    $display("imemory: loaded %0d 32-bit words from %s", `line_count, `mem_path);
  end

  /*
   * process definitions to be filled by
   * student below....
   */

  //Read from Main Memory (reads are combinational)
  always_comb begin
    if (read_en_i) begin
        data_o = {main_memory[address + 3], 
                  main_memory[address + 2],
                  main_memory[address + 1], 
                  main_memory[address]}; 
    end else begin
        data_o = '0; 
    end
  end

  //Write to memory (writes are positive-edge triggered)
  always_ff @(posedge clk) begin
    if (write_en_i) begin
        main_memory[address] <= data_i[7:0];
        main_memory[address + 1] <= data_i[15:8];
        main_memory[address + 2] <= data_i[23:16];
        main_memory[address + 3] <= data_i[31:24];
    end
  end

endmodule : memory
