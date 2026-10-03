`timescale 1ns / 1ps

module ram_memory #(
    parameter int MEM_DEPTH = 4096   // 16 KB per bank
)(
    input  logic        clk,

    // Port A: Instruction TCM
    input  logic [31:0] itcm_addr,
    output logic [31:0] itcm_rdata,

    // Port B: Data TCM
    input  logic        dtcm_we,
    input  logic [3:0]  dtcm_be,
    input  logic [31:0] dtcm_addr,
    input  logic [31:0] dtcm_wdata,
    output logic [31:0] dtcm_rdata
);

    // 4096 words × 32 bits = 16 KB per memory
    logic [31:0] itcm [0:MEM_DEPTH-1];
    logic [31:0] dtcm [0:MEM_DEPTH-1];

    // Load compiled program into Instruction Memory ONLY
    initial begin
        // Initialize instruction memory to NOPs first
        for (int i = 0; i < MEM_DEPTH; i++) begin
            itcm[i] = 32'h00000013; // NOP (addi x0, x0, 0)
        end

        // Load instruction file (program.hex.txt or code.hex)
        $readmemh("program.hex.txt", itcm);
    end

    // Instruction Memory Read
    always_ff @(posedge clk) begin
        itcm_rdata <= itcm[itcm_addr[13:2]];
    end

    // Data Memory Read/Write (Single Driver Block for DTCM)
    always_ff @(posedge clk) begin

        // Byte-enable write
        if (dtcm_we) begin

            if (dtcm_be[0])
                dtcm[dtcm_addr[13:2]][7:0]   <= dtcm_wdata[7:0];

            if (dtcm_be[1])
                dtcm[dtcm_addr[13:2]][15:8]  <= dtcm_wdata[15:8];

            if (dtcm_be[2])
                dtcm[dtcm_addr[13:2]][23:16] <= dtcm_wdata[23:16];

            if (dtcm_be[3])
                dtcm[dtcm_addr[13:2]][31:24] <= dtcm_wdata[31:24];

        end

        // Synchronous data read
        dtcm_rdata <= dtcm[dtcm_addr[13:2]];

    end

endmodule