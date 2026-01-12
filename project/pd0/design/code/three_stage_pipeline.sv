/*
 * Module: three_stage_pipeline
 *
 * A 3-stage pipeline (TSP) where the first stage performs an addition of two
 * operands (op1_i, op2_i) and registers the output, and the second stage computes
 * the difference between the output from the first stage and op1_i and registers the
 * output. This means that the output (res_o) must be available two cycles after the
 * corresponding inputs have been observed on the rising clock edge
 *
 * Visually, the circuit should look like this:
 *               <---         Stage 1           --->
 *                                                        <---         Stage 2           --->
 *                                                                                               <--    Stage 3    -->
 *                                    |------------------>|                    |
 * -- op1_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *             | pipeline registers |     | ALU add | --> | pipeline registers |   | ALU sub |-->| pipeline register  | -- res_o -->
 * -- op2_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *
 * Inputs:
 * 1) 1-bit clock signal
 * 2) 1-bit wide synchronous reset
 * 3) DWIDTH-wide input op1_i
 * 4) DWIDTH-wide input op2_i
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 */

module three_stage_pipeline #(
parameter int DWIDTH = 8)(
        input logic clk,
        input logic rst,
        input logic [DWIDTH-1:0] op1_i,
        input logic [DWIDTH-1:0] op2_i,
        output logic [DWIDTH-1:0] res_o
    );

    /*
     * Process definitions to be filled by
     * student below...
     * [HINT] Instantiate the alu and reg_rst modules
     * and set up the necessary connections
     *
     */

//Internal Wires
//Registers
logic [DWIDTH-1:0] op1_reg;
logic [DWIDTH-1:0] op2_reg;
logic [DWIDTH-1:0] add_res_reg;

//ALU
logic [DWIDTH-1:0] add_res;
logic [DWIDTH-1:0] sub_res;

reg_rst #(
    .DWIDTH(DWIDTH)
) op1_register (
    .clk(clk),
    .rst(rst),
    .in_i(op1_i),
    .out_o(op1_reg)       
);

reg_rst #(
    .DWIDTH(DWIDTH)
) op2_register (
    .clk(clk),
    .rst(rst),
    .in_i(op2_i),
    .out_o(op2_reg)       
);

alu #(.DWIDTH(DWIDTH)
) stage_1_alu (
    .sel_i(ADD),
    .op1_i(op1_reg),  
    .op2_i(op2_reg),  
    .res_o(add_res),    
    .zero_o(),          
    .neg_o()
);

reg_rst #(.DWIDTH(DWIDTH)
) reg_add (
    .clk(clk),
    .rst(rst),
    .in_i(add_res),
    .out_o(add_res_reg)
);

alu #(.DWIDTH(DWIDTH)
) stage_2_alu (
    .sel_i(SUB),
    .op1_i(add_res_reg),  
    .op2_i(op1_reg),  
    .res_o(sub_res),  
    .zero_o(),          
    .neg_o()
);

reg_rst #(.DWIDTH(DWIDTH)
) reg_sub (
    .clk(clk),
    .rst(rst),
    .in_i(sub_res),
    .out_o(res_o)
);
endmodule: three_stage_pipeline
