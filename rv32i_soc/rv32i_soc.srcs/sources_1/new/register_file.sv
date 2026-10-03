module register_file (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        we,
    input  logic [4:0]  rs1,        // Renamed from rs1_addr
    input  logic [4:0]  rs2,        // Renamed from rs2_addr
    input  logic [4:0]  rd,         // Renamed from rd_addr
    input  logic [31:0] wdata,      // Renamed from rd_data
    output logic [31:0] rdata1,     // Renamed from rs1_data
    output logic [31:0] rdata2      // Renamed from rs2_data (fixes VRFC 10-3180 error)
);

    // 32 registers: x0 to x31
    logic [31:0] registers [0:31];

    // Read registers: x0 is hardwired to 0
    assign rdata1 = (rs1 == 5'd0) ? 32'h00000000 : registers[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'h00000000 : registers[rs2];

    // Write registers with Asynchronous Reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'h00000000;
            end
        end
        else if (we && (rd != 5'd0)) begin
            registers[rd] <= wdata;
        end
    end

endmodule