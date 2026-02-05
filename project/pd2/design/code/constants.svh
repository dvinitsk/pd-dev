/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;

/*
 * Define constants as required...
 */

//9 different OPCODES in integer instructions
parameter logic [6:0] R_TYPE = 7'b0110011; //R-type
parameter logic [6:0] IMM = 7'b0010011; //I-type
parameter logic [6:0] LOADS = 7'b0000011; //I-type
parameter logic [6:0] STORES = 7'b0100011; //S-type
parameter logic [6:0] BRANCHES = 7'b1100011; //B-type
parameter logic [6:0] JAL = 7'b1101111; //J-type
parameter logic [6:0] JALR = 7'b1100111; //I-type
parameter logic [6:0] LUI = 7'b0110111; //U-type
parameter logic [6:0] AUIPC = 7'b0010111; //U-type

`endif
