`timescale 1ns / 1ps

module tb_phase1;
    logic        clk;
    logic        rst_n;
    logic        uart_tx;
    wire         i2c_scl;
    wire         i2c_sda;
    logic [34:0] noc_tx_flit;
    logic        noc_tx_valid;
    logic        noc_tx_ready;

    // Pull-up resistors required for I2C open-drain lines
    pullup(i2c_scl);
    pullup(i2c_sda);

    phase1_top uut (
        .clk          (clk),
        .rst_n        (rst_n),
        .uart_tx      (uart_tx),
        .i2c_scl      (i2c_scl),
        .i2c_sda      (i2c_sda),
        .noc_tx_flit  (noc_tx_flit),
        .noc_tx_valid (noc_tx_valid),
        .noc_tx_ready (noc_tx_ready)
    );

    // 100MHz Clock Generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        noc_tx_ready = 1;

        // Hold in reset for 20 ns then release
        #20;
        rst_n = 1;

        #50000; // Extended simulation time to 50us so I2C frames can finish
        $finish;
    end
endmodule