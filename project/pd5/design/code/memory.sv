/*
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 *
 * Module: memory
 *
 * Description: Byte-addressable unified memory with two read ports (Option 2 from PD4 README).
 * Supports instruction fetch, data loads, and data stores.
 * Extended for access sizes: lb, lh, lw, lbu, lhu, sb, sh, sw.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 * 2) data out valid signal data_vld_o
 */

module memory #(
  parameter int AWIDTH = 32,
  parameter int DWIDTH = 32,
  parameter logic [31:0] BASE_ADDR = 32'h01000000
) (
  input logic clk,
  input logic rst,

  // Read port 1: instruction fetch (always reads word at addr1_i)
  input  logic [AWIDTH-1:0] addr1_i,
  output logic [DWIDTH-1:0] data1_o,

  // Read/write port 2: data access (loads and stores)
  input  logic [AWIDTH-1:0] addr2_i,
  input  logic [DWIDTH-1:0] data2_i,
  input  logic             read_en2_i,
  input  logic             write_en2_i,
  input  logic             load_en2_i, // 1=load (use funct3 for size), 0=probe (return full word)
  input  logic [2:0]       funct3_i,   // 000=lb/sb, 001=lh/sh, 010=lw/sw, 100=lbu, 101=lhu
  output logic [DWIDTH-1:0] data2_o
);

  logic [7:0] main_memory [0:`MEM_DEPTH];
  logic [AWIDTH-1:0] addr1, addr2;
  // Match reference: address wrapping so 0x01100000 wraps to 0
  assign addr1 = ((addr1_i >= BASE_ADDR) ? (addr1_i - BASE_ADDR) : addr1_i) % `MEM_DEPTH;
  assign addr2 = ((addr2_i >= BASE_ADDR) ? (addr2_i - BASE_ADDR) : addr2_i) % `MEM_DEPTH;

  initial begin
    logic [DWIDTH-1:0] temp_memory [0:`MEM_DEPTH];
    for (int i = 0; i <= `MEM_DEPTH; i++) main_memory[i] = 8'h00;
    $readmemh(`MEM_PATH, temp_memory);
    for (int i = 0; i < `LINE_COUNT; i++) begin
      main_memory[4*i]     = temp_memory[i][7:0];
      main_memory[4*i + 1] = temp_memory[i][15:8];
      main_memory[4*i + 2] = temp_memory[i][23:16];
      main_memory[4*i + 3] = temp_memory[i][31:24];
    end
    $display("imemory: loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
  end

  // Read port 1: instruction fetch (always read full word)
  always_comb begin
    data1_o = {main_memory[(addr1 + 3) % `MEM_DEPTH], main_memory[(addr1 + 2) % `MEM_DEPTH],
               main_memory[(addr1 + 1) % `MEM_DEPTH], main_memory[addr1]};
  end

  // Read port 2: data load with size/sign handling
  logic [DWIDTH-1:0] raw_word;
  logic [7:0]  load_byte;
  logic [15:0] load_half;
  assign raw_word = {main_memory[(addr2 + 3) % `MEM_DEPTH], main_memory[(addr2 + 2) % `MEM_DEPTH],
                    main_memory[(addr2 + 1) % `MEM_DEPTH], main_memory[addr2]};
  assign load_byte = (addr2[1:0] == 2'd0) ? raw_word[7:0]   :
                     (addr2[1:0] == 2'd1) ? raw_word[15:8]  :
                     (addr2[1:0] == 2'd2) ? raw_word[23:16] : raw_word[31:24];
  assign load_half = addr2[1] ? raw_word[31:16] : raw_word[15:0];
  always_comb begin
    if (!read_en2_i) begin
      data2_o = '0;
    end else if (!load_en2_i) begin
      data2_o = raw_word;  // probe: return full word at address
    end else begin
      case (funct3_i)
        3'b000: data2_o = {{24{load_byte[7]}}, load_byte};   // lb
        3'b001: data2_o = {{16{load_half[15]}}, load_half};  // lh
        3'b010: data2_o = raw_word;                          // lw
        3'b100: data2_o = {24'b0, load_byte};                // lbu
        3'b101: data2_o = {16'b0, load_half};                // lhu
        default: data2_o = raw_word;
      endcase
    end
  end

  // Write port 2: data store with size (with address wrapping)
  always_ff @(posedge clk) begin
    if (write_en2_i) begin
      case (funct3_i)
        3'b000: main_memory[addr2] <= data2_i[7:0];
        3'b001: begin
          main_memory[addr2] <= data2_i[7:0];
          main_memory[(addr2 + 1) % `MEM_DEPTH] <= data2_i[15:8];
        end
        3'b010: begin
          main_memory[addr2] <= data2_i[7:0];
          main_memory[(addr2 + 1) % `MEM_DEPTH] <= data2_i[15:8];
          main_memory[(addr2 + 2) % `MEM_DEPTH] <= data2_i[23:16];
          main_memory[(addr2 + 3) % `MEM_DEPTH] <= data2_i[31:24];
        end
        default: begin
          main_memory[addr2] <= data2_i[7:0];
          main_memory[(addr2 + 1) % `MEM_DEPTH] <= data2_i[15:8];
          main_memory[(addr2 + 2) % `MEM_DEPTH] <= data2_i[23:16];
          main_memory[(addr2 + 3) % `MEM_DEPTH] <= data2_i[31:24];
        end
      endcase
    end
  end

endmodule : memory
