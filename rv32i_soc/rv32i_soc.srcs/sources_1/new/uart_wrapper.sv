module uart_wrapper #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input  logic        clk,
    input  logic        rst_n,

    // Memory-mapped interface
    input  logic        sel,
    input  logic        we,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // UART output
    output logic        tx
);

    // Rounded integer division to minimize baud rate timing error
    localparam int CLKS_PER_BIT = (CLK_FREQ + (BAUD_RATE / 2)) / BAUD_RATE;

    logic [7:0]  tx_shift;
    logic [3:0]  tx_bit_count;
    logic [31:0] baud_count;
    logic        tx_busy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx           <= 1'b1;
            tx_shift     <= 8'h00;
            tx_bit_count <= 4'd0;
            baud_count   <= 32'd0;
            tx_busy      <= 1'b0;
        end else begin
            // Start a new UART transmission (only when idle)
            if (sel && we && !tx_busy) begin
                tx_shift     <= wdata[7:0];
                tx_bit_count <= 4'd0;
                baud_count   <= 32'd0;
                tx_busy      <= 1'b1;
                tx           <= 1'b0; // Send Start Bit
            end 
            // UART transmission in progress
            else if (tx_busy) begin
                if (baud_count == CLKS_PER_BIT - 1) begin
                    baud_count <= 32'd0;

                    if (tx_bit_count < 4'd8) begin
                        tx           <= tx_shift[tx_bit_count]; // Data bits 0 to 7
                        tx_bit_count <= tx_bit_count + 1'b1;
                    end else if (tx_bit_count == 4'd8) begin
                        tx           <= 1'b1;                   // Stop Bit
                        tx_bit_count <= tx_bit_count + 1'b1;
                    end else begin
                        tx           <= 1'b1;                   // End of Stop Bit
                        tx_busy      <= 1'b0;                   // Return to idle
                        tx_bit_count <= 4'd0;
                    end
                end else begin
                    baud_count <= baud_count + 1'b1;
                end
            end else begin
                tx <= 1'b1; // Idle line state
            end
        end
    end

    // Memory-mapped readback: Bit [8] = tx_busy, Bits [7:0] = tx_shift
    assign rdata = {23'h0, tx_busy, tx_shift};

endmodule