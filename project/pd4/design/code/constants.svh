`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;

// Opcodes
parameter logic [6:0] R_TYPE  = 7'b0110011;
parameter logic [6:0] IMM     = 7'b0010011;
parameter logic [6:0] LOADS   = 7'b0000011;
parameter logic [6:0] STORES  = 7'b0100011;
parameter logic [6:0] BRANCHES= 7'b1100011;
parameter logic [6:0] JAL     = 7'b1101111;
parameter logic [6:0] JALR    = 7'b1100111;
parameter logic [6:0] LUI     = 7'b0110111;
parameter logic [6:0] AUIPC   = 7'b0010111;

// ALU select
parameter logic [3:0] ADD   = 4'd0;
parameter logic [3:0] SUB   = 4'd1;
parameter logic [3:0] SLL   = 4'd2;
parameter logic [3:0] SLT   = 4'd3;
parameter logic [3:0] SLTU  = 4'd4;
parameter logic [3:0] XOR   = 4'd5;
parameter logic [3:0] SRL   = 4'd6;
parameter logic [3:0] SRA   = 4'd7;
parameter logic [3:0] OR    = 4'd8;
parameter logic [3:0] AND   = 4'd9;
parameter logic [3:0] PCADD = 4'd10;  // PC + rs2 (for branches and JAL)

`endif
