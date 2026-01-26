/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o (WIRE FROM MEMORY MOD?)
 */

module fetch #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=32'h01000000
    )(
	// inputs
	input logic clk,
	input logic rst,
	// outputs	
	output logic [AWIDTH - 1:0] pc_o, 
    output logic [DWIDTH - 1:0] insn_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */

    always_ff @(posedge clk) begin
        if (rst)
            pc_o <= BASEADDR; //reset to base address
        else
            pc_o <= pc_o + 32'd4; //pc_o increases by 4 bytes because instruction size is 32 bits
    end

endmodule : fetch
				
