/*
 * Module: register_file
 *
 * Description: Register file 
 *
 * -------- REPLACE THIS FILE WITH THE RF MODULE DEVELOPED IN PD4 -----------
 *
 */
`include "constants.svh"

module register_file #(
    parameter int DWIDTH = 32
)(
    input  logic              clk,
    input  logic              rst,
    input  logic [4:0]        rs1_i,
    input  logic [4:0]        rs2_i,
    input  logic [4:0]        rd_i,
    input  logic [DWIDTH-1:0] datawb_i,
    input  logic              regwren_i,
    output logic [DWIDTH-1:0] rs1data_o,
    output logic [DWIDTH-1:0] rs2data_o
);

    // Match reference: rf_registers[1:31], x0 hardwired to 0
    logic [DWIDTH-1:0] rf_registers [1:31];

    assign rs1data_o = (rs1_i == 5'd0) ? ZERO : rf_registers[rs1_i];
    assign rs2data_o = (rs2_i == 5'd0) ? ZERO : rf_registers[rs2_i];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 1; i < 32; i++) rf_registers[i] <= ZERO;
            rf_registers[2] <= 32'h01100000;  // x2 (sp) init for pattern checker
        end else if (regwren_i && (rd_i != 5'd0)) begin
            rf_registers[rd_i] <= datawb_i;
        end
    end

endmodule : register_file
