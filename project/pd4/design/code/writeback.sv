/*
 * Module: writeback
 *
 * Description: Write-back control stage implementation
 *
 * Inputs:
 * 1) PC pc_i
 * 2) result from alu alu_res_i
 * 3) data from memory memory_data_i
 * 4) data to select for write-back wbsel_i
 * 5) branch taken signal brtaken_i
 *
 * Outputs:
 * 1) DWIDTH wide write back data write_data_o
 * 2) AWIDTH wide next computed PC next_pc_o
 */

 module writeback #(
     parameter int DWIDTH=32,
     parameter int AWIDTH=32
 )(
     input logic [AWIDTH-1:0] pc_i,
     input logic [DWIDTH-1:0] alu_res_i,
     input logic [DWIDTH-1:0] memory_data_i,
     input logic [1:0] wbsel_i,
     input logic brtaken_i,
     output logic [DWIDTH-1:0] writeback_data_o,
     output logic [AWIDTH-1:0] next_pc_o
 );

    localparam logic [AWIDTH-1:0] PC_INC = 32'd4;

    // Writeback data: 00=ALU result, 01=memory data, 10=PC+4 (for JAL/JALR)
    always_comb begin
        case (wbsel_i)
            2'b00: writeback_data_o = alu_res_i;
            2'b01: writeback_data_o = memory_data_i;
            2'b10: writeback_data_o = pc_i + PC_INC;
            default: writeback_data_o = alu_res_i;
        endcase
    end

    // Next PC: branch target when taken, else sequential PC+4
    assign next_pc_o = brtaken_i ? alu_res_i : (pc_i + PC_INC);

endmodule : writeback
