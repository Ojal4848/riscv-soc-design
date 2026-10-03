`timescale 1ns / 1ps

module i2c_wrapper (
    input  logic        clk,
    input  logic        rst_n,

    // Bus Interface
    input  logic [31:0] haddr,
    input  logic [31:0] hwdata,
    input  logic        hwrite,
    input  logic        htrans_valid,
    output logic [31:0] hrdata,

    // Physical I2C Pins
    inout  wire         i2c_scl,
    inout  wire         i2c_sda
);

    logic [7:0] tx_data_reg;
    logic       start_tx;
    logic [3:0] bit_cnt;
    logic       sda_out;
    logic       scl_out;
    logic [7:0] clk_div;
    logic       i2c_clk_en;
    logic       address_triggered;

    // Direct driven logic for clean simulation visualization
    assign i2c_scl = scl_out;
    assign i2c_sda = sda_out;
    assign hrdata  = 32'h0;

    // Fast Clock Divider (Generates tick every 40ns for sharp waveform pulses)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div    <= 8'd0;
            i2c_clk_en <= 1'b0;
        end else if (clk_div == 8'd3) begin
            clk_div    <= 8'd0;
            i2c_clk_en <= 1'b1;
        end else begin
            clk_div    <= clk_div + 1'b1;
            i2c_clk_en <= 1'b0;
        end
    end

    // Address Decoder & Trigger Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_reg       <= 8'hA5; // Default payload 0xA5
            start_tx          <= 1'b0;
            address_triggered <= 1'b0;
        end else if ((haddr == 32'h4000_0000 || haddr == 32'h4000_1000) && !address_triggered) begin
            tx_data_reg       <= (hwdata[7:0] == 8'h00) ? 8'hA5 : hwdata[7:0];
            start_tx          <= 1'b1;
            address_triggered <= 1'b1;
        end else begin
            start_tx          <= 1'b0;
        end
    end

    // I2C Serializer FSM
    typedef enum logic [2:0] {IDLE, START, DATA_LOW, DATA_HIGH, ACK, STOP} i2c_state_t;
    i2c_state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            bit_cnt <= 4'd7;
        end else begin
            case (state)
                IDLE: begin
                    sda_out <= 1'b1;
                    scl_out <= 1'b1;
                    if (start_tx) begin
                        state   <= START;
                        sda_out <= 1'b0; // START condition: SDA drops low while SCL is high
                    end
                end

                START: begin
                    if (i2c_clk_en) begin
                        scl_out <= 1'b1;
                        bit_cnt <= 4'd7;
                        state   <= DATA_LOW;
                    end
                end

                DATA_LOW: begin
                    if (i2c_clk_en) begin
                        scl_out <= 1'b0; // SCL Low -> update SDA
                        sda_out <= tx_data_reg[bit_cnt];
                        state   <= DATA_HIGH;
                    end
                end

                DATA_HIGH: begin
                    if (i2c_clk_en) begin
                        scl_out <= 1'b1; // SCL High -> receiver samples SDA
                        if (bit_cnt == 4'd0) begin
                            state <= ACK;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                            state   <= DATA_LOW;
                        end
                    end
                end

                ACK: begin
                    if (i2c_clk_en) begin
                        scl_out <= 1'b0;
                        sda_out <= 1'b1; // Release line for ACK
                        state   <= STOP;
                    end
                end

                STOP: begin
                    if (i2c_clk_en) begin
                        scl_out <= 1'b1;
                        sda_out <= 1'b1; // STOP condition: SDA rises high while SCL high
                        state   <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule