`include "constants.svh"

module pd4 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

    // --- Stage signals ---
    logic [AWIDTH-1:0] f_pc;
    logic [DWIDTH-1:0] f_insn;

    logic [AWIDTH-1:0] d_pc;
    logic [DWIDTH-1:0] d_insn;
    logic [6:0]        d_opcode;
    logic [4:0]        d_rd;
    logic [4:0]        d_rs1;
    logic [4:0]        d_rs2;
    logic [6:0]        d_funct7;
    logic [2:0]        d_funct3;
    logic [4:0]        d_shamt;
    logic [DWIDTH-1:0] d_imm;

    logic        ctrl_pcsel;
    logic        ctrl_immsel;
    logic        ctrl_regwren;
    logic        ctrl_rs1sel;
    logic        ctrl_rs2sel;
    logic        ctrl_memren;
    logic        ctrl_memwren;
    logic [1:0]  ctrl_wbsel;
    logic [3:0]  ctrl_alusel;

    logic [4:0]        r_read_rs1;
    logic [4:0]        r_read_rs2;
    logic [DWIDTH-1:0] r_read_rs1_data;
    logic [DWIDTH-1:0] r_read_rs2_data;
    logic              r_write_enable;
    logic [4:0]        r_write_destination;
    logic [DWIDTH-1:0] r_write_data;

    logic breq, brlt;

    logic [AWIDTH-1:0] e_pc;
    logic [DWIDTH-1:0] e_alu_res;
    logic              e_br_taken;

    logic [AWIDTH-1:0] m_pc;
    logic [AWIDTH-1:0] m_address;
    logic [1:0]        m_size_encoded;
    logic [DWIDTH-1:0] m_data;

    logic [AWIDTH-1:0] w_pc;
    logic              w_enable;
    logic [4:0]        w_destination;
    logic [DWIDTH-1:0] w_data;

    logic [DWIDTH-1:0] alu_op1, alu_op2;
    logic [DWIDTH-1:0] mem_data_out;

    logic [AWIDTH-1:0] next_pc;
    logic [DWIDTH-1:0] wb_data;
    logic              pc_taken;  // use ALU target as next PC (branch taken, JAL, or JALR)

    // --- Combinational connections ---
    assign r_read_rs1       = d_rs1;
    assign r_read_rs2       = d_rs2;
    assign alu_op1          = ctrl_rs1sel ? d_pc : r_read_rs1_data;
    assign alu_op2          = ctrl_rs2sel ? d_imm : r_read_rs2_data;
    assign e_pc             = d_pc;
    assign e_br_taken       = (d_opcode == BRANCHES) & (breq | brlt);
    assign pc_taken         = ctrl_pcsel & ((d_opcode == JAL) | (d_opcode == JALR) | e_br_taken);
    assign r_write_enable   = ctrl_regwren;
    assign r_write_destination = d_rd;

    // --- Module instances ---
    fetch #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) fetch_stage (
        .clk(clk),
        .rst(reset),
        .next_pc_i(next_pc),
        .pcsel_i(pc_taken),
        .pc_o(f_pc)
    );

    decode #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) decode_stage (
        .clk(clk),
        .rst(reset),
        .insn_i(f_insn),
        .pc_i(f_pc),
        .pc_o(d_pc),
        .insn_o(d_insn),
        .opcode_o(d_opcode),
        .rd_o(d_rd),
        .rs1_o(d_rs1),
        .rs2_o(d_rs2),
        .funct7_o(d_funct7),
        .funct3_o(d_funct3),
        .shamt_o(d_shamt),
        .imm_o(d_imm)
    );

    control #(.DWIDTH(DWIDTH)) ctrl (
        .insn_i(d_insn),
        .opcode_i(d_opcode),
        .funct7_i(d_funct7),
        .funct3_i(d_funct3),
        .pcsel_o(ctrl_pcsel),
        .immsel_o(ctrl_immsel),
        .regwren_o(ctrl_regwren),
        .rs1sel_o(ctrl_rs1sel),
        .rs2sel_o(ctrl_rs2sel),
        .memren_o(ctrl_memren),
        .memwren_o(ctrl_memwren),
        .wbsel_o(ctrl_wbsel),
        .alusel_o(ctrl_alusel)
    );

    register_file #(.DWIDTH(DWIDTH)) regfile (
        .clk(clk),
        .rst(reset),
        .rs1_i(r_read_rs1),
        .rs2_i(r_read_rs2),
        .rd_i(r_write_destination),
        .datawb_i(r_write_data),
        .regwren_i(r_write_enable),
        .rs1data_o(r_read_rs1_data),
        .rs2data_o(r_read_rs2_data)
    );

    branch_control #(.DWIDTH(DWIDTH)) br_ctrl (
        .opcode_i(d_opcode),
        .funct3_i(d_funct3),
        .rs1_i(r_read_rs1_data),
        .rs2_i(r_read_rs2_data),
        .breq_o(breq),
        .brlt_o(brlt)
    );

    alu #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) execute_stage (
        .pc_i(e_pc),
        .rs1_i(alu_op1),
        .rs2_i(alu_op2),
        .funct3_i(d_funct3),
        .funct7_i(d_funct7),
        .alusel_i(ctrl_alusel),
        .res_o(e_alu_res),
        .brtaken_o()
    );

    memory #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) mem (
        .clk(clk),
        .rst(reset),
        .addr1_i(f_pc),
        .data1_o(f_insn),
        .addr2_i(e_alu_res),
        .data2_i(r_read_rs2_data),
        .read_en2_i(1'b1),
        .write_en2_i(ctrl_memwren),
        .load_en2_i(ctrl_memren),
        .funct3_i(d_funct3),
        .data2_o(mem_data_out)
    );

    writeback #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) wb_stage (
        .pc_i(d_pc),
        .alu_res_i(e_alu_res),
        .memory_data_i(mem_data_out),
        .wbsel_i(ctrl_wbsel),
        .brtaken_i(pc_taken),
        .writeback_data_o(wb_data),
        .next_pc_o(next_pc)
    );

    assign r_write_data = wb_data;

    // M and W stage probe assignments
    assign m_pc          = d_pc;
    assign m_address     = e_alu_res;
    assign m_size_encoded = d_funct3[1:0];
    // M_DATA probe: reference uses MEM_DATA_O (memory read at address), not store data
    assign m_data        = mem_data_out;
    assign w_pc          = d_pc;
    assign w_enable      = r_write_enable;
    assign w_destination = r_write_destination;
    assign w_data        = r_write_data;

    // --- Program termination logic ---
    wire [31:0] data_out = f_insn;
    reg is_program = 0;
    always_ff @(posedge clk) begin
        if (data_out == 32'h00000073) $finish;
        if (data_out == 32'h00008067) is_program = 1;
        if (is_program && (regfile.rf_registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
    end

endmodule : pd4
