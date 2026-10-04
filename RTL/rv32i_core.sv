module rv32i_core (
    input  logic        clk,
    input  logic        rst_n,

    // Bus interface matching phase1_top
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic [3:0]  mem_wstrb,
    input  logic [31:0] mem_rdata,
    output logic        mem_req,
    output logic        mem_write
);

    // ------------------------------------------------------------------------
    // Program Counter & IF/ID Pipeline Register
    // ------------------------------------------------------------------------
    logic [31:0] pc;
    logic [31:0] next_pc;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr;

    // ------------------------------------------------------------------------
    // Decode Fields
    // ------------------------------------------------------------------------
    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] imm_i, imm_s, imm_b, imm_u;

    assign opcode = if_id_instr[6:0];
    assign rd     = if_id_instr[11:7];
    assign funct3 = if_id_instr[14:12];
    assign rs1    = if_id_instr[19:15];
    assign rs2    = if_id_instr[24:20];
    assign funct7 = if_id_instr[31:25];

    assign imm_i = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    assign imm_s = {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
    assign imm_b = {{19{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0};
    assign imm_u = {if_id_instr[31:12], 12'h0};

    // ------------------------------------------------------------------------
    // 1. Register File Instantiation
    // ------------------------------------------------------------------------
    logic [31:0] rf_rdata1, rf_rdata2;
    logic [31:0] rf_wdata;
    logic        rf_we;

    register_file regfile_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .we    (rf_we),
        .rs1   (rs1),
        .rs2   (rs2),
        .rd    (rd),
        .wdata (rf_wdata),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2)
    );

    // ------------------------------------------------------------------------
    // 2. ALU Instantiation
    // ------------------------------------------------------------------------
    logic [31:0] alu_operand1, alu_operand2;
    logic [31:0] alu_result;
    logic [3:0]  alu_ctrl;
    logic        alu_zero;

    assign alu_operand1 = (opcode == 7'b0110111) ? 32'h0 : rf_rdata1; // LUI vs Normal
    
    // Immediate selection logic (Fixes LUI upper-immediate address calculation)
    assign alu_operand2 = (opcode == 7'b0110111) ? imm_u :
                          (opcode == 7'b0010011 || opcode == 7'b0000011) ? imm_i :
                          (opcode == 7'b0100011) ? imm_s : rf_rdata2;

    always_comb begin
        case (opcode)
            7'b0110011: alu_ctrl = (funct3 == 3'b000 && funct7[5]) ? 4'b0001 : 4'b0000; // SUB vs ADD
            7'b0010011: alu_ctrl = 4'b0000; // ADDI
            7'b0110111: alu_ctrl = 4'b0000; // LUI
            7'b0000011, 7'b0100011: alu_ctrl = 4'b0000; // Load/Store Address Calculation
            default: alu_ctrl = 4'b0000;
        endcase
    end

    alu alu_inst (
        .operand_a(alu_operand1),
        .operand_b(alu_operand2),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (alu_zero)
    );

    // ------------------------------------------------------------------------
    // Memory Interface Drive
    // ------------------------------------------------------------------------
    assign mem_req   = 1'b1;
    assign mem_write = (opcode == 7'b0100011); // SW / SH / SB
    assign mem_addr  = mem_write ? alu_result : pc;
    assign mem_wdata = rf_rdata2;

    always_comb begin
        if (mem_write) begin
            case (funct3)
                3'b000:  mem_wstrb = 4'b0001 << alu_result[1:0]; // SB
                3'b001:  mem_wstrb = 4'b0011 << alu_result[1:0]; // SH
                default: mem_wstrb = 4'b1111;                    // SW
            endcase
        end else begin
            mem_wstrb = 4'b0000;
        end
    end

    // ------------------------------------------------------------------------
    // Control & Next PC
    // ------------------------------------------------------------------------
    logic branch_taken;
    assign branch_taken = (opcode == 7'b1100011 && funct3 == 3'b000 && (rf_rdata1 == rf_rdata2)); // BEQ
    assign next_pc      = branch_taken ? (if_id_pc + imm_b) : (pc + 32'd4);

    assign rf_we    = (opcode == 7'b0110011 || opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b0110111) && (rd != 5'd0);
    assign rf_wdata = (opcode == 7'b0000011) ? mem_rdata : alu_result;

    // ------------------------------------------------------------------------
    // Pipeline Sequential Logic
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc          <= 32'h0000_0000;
            if_id_pc    <= 32'h0000_0000;
            if_id_instr <= 32'h0000_0013; // NOP
        end else begin
            pc       <= next_pc;
            if_id_pc <= pc;
            
            if (!mem_write) begin
                if_id_instr <= mem_rdata;
            end
        end
    end

endmodule