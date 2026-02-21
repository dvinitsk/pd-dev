/*
 * Module: register_file
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) clk
 * 2) reset signal rst
 * 3) 5-bit rs1 address rs1_i
 * 4) 5-bit rs2 address rs2_i
 * 5) 5-bit rd address rd_i
 * 6) DWIDTH-wide data writeback datawb_i
 * 7) register write enable regwren_i
 * Outputs:
 * 1) 32-bit rs1 data rs1data_o
 * 2) 32-bit rs2 data rs2data_o
 */

 module register_file #(
     parameter int DWIDTH=32
 )(
     // inputs
     input logic clk,
     input logic rst,
     input logic [4:0] rs1_i,
     input logic [4:0] rs2_i,
     input logic [4:0] rd_i,
     input logic [DWIDTH-1:0] datawb_i,
     input logic regwren_i,
     // outputs
     output logic [DWIDTH-1:0] rs1data_o,
     output logic [DWIDTH-1:0] rs2data_o
 );

    /*
     * Process definitions to be filled by
     * student below...
     */

    logic [DWIDTH-1:0] registers [31:0];

    //comb reads
    always_comb begin
        //index 0 is reserved for 0, if not assign rs1 address value to rs1data
        if (rs1_i == 5'd0) begin
            rs1data_o = ZERO;
        end else begin
            rs1data_o = registers[rs1_i];
        end

        if (rs2_i == 5'd0) begin
            rs2data_o = ZERO;
        end else begin
            rs2data_o = registers[rs2_i];
        end
    end

    //sequential writes
    always_ff @(posedge clk) begin
        if (rst) begin //reset and stack pointer reset (x2)
            //loop through each register and reset its value to 0
            for (int i = 0; i < 32; i++) begin
                registers[i] <= ZERO;
            end
            registers[2] <= 32'hFFFFFFFC; //on reset stack pointer x2 from high memory to low memory
        end else begin
            //if write enabled and destination is not 0 write to destination on posedge clk
            if (regwren_i && rd_i != 5'd0) begin
                registers[rd_i] <= datawb_i;
            end
        end
    end

endmodule : register_file
