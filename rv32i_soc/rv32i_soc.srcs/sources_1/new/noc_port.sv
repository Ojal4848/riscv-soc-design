module noc_port (
    input  logic        clk,
    input  logic        rst_n,

    // Request interface (Processor/Bus side)
    input  logic [31:0] req_addr,
    input  logic [31:0] req_wdata,
    input  logic        req_write,
    input  logic        req_valid,
    output logic        req_ready,

    // NoC transmit interface
    output logic [34:0] noc_tx_flit,  // [34:33] Flit Type, [32] Control/Op, [31:0] Payload
    output logic        noc_tx_valid,
    input  logic        noc_tx_ready
);

    typedef enum logic [1:0] {
        IDLE,
        SEND_HEAD,
        SEND_TAIL
    } state_t;

    state_t state;

    // Latched request information
    logic [31:0] addr_reg;
    logic [31:0] wdata_reg;
    logic        write_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            req_ready    <= 1'b1;
            noc_tx_valid <= 1'b0;
            noc_tx_flit  <= 35'd0;

            addr_reg     <= 32'h0;
            wdata_reg    <= 32'h0;
            write_reg    <= 1'b0;
        end else begin
            case (state)

                // ------------------------------------------------------------
                // IDLE: Wait for request from processor
                // ------------------------------------------------------------
                IDLE: begin
                    req_ready    <= 1'b1;
                    noc_tx_valid <= 1'b0;

                    if (req_valid && req_ready) begin
                        // Latch request parameters
                        addr_reg  <= req_addr;
                        wdata_reg <= req_wdata;
                        write_reg <= req_write;

                        // Construct HEAD flit (2'b01 = HEAD)
                        noc_tx_flit <= {2'b01, req_write, req_addr};
                        
                        req_ready    <= 1'b0; // Block new requests while sending packet
                        noc_tx_valid <= 1'b1;

                        state <= SEND_HEAD;
                    end
                end

                // ------------------------------------------------------------
                // SEND_HEAD: Hold HEAD flit until accepted by NoC router
                // ------------------------------------------------------------
                SEND_HEAD: begin
                    req_ready    <= 1'b0;
                    noc_tx_valid <= 1'b1;

                    if (noc_tx_valid && noc_tx_ready) begin
                        // HEAD accepted by NoC -> Prepare TAIL flit (2'b11 = TAIL)
                        noc_tx_flit  <= {2'b11, write_reg, wdata_reg};
                        noc_tx_valid <= 1'b1;

                        state <= SEND_TAIL;
                    end
                end

                // ------------------------------------------------------------
                // SEND_TAIL: Hold TAIL flit until accepted by NoC router
                // ------------------------------------------------------------
                SEND_TAIL: begin
                    noc_tx_valid <= 1'b1;

                    if (noc_tx_valid && noc_tx_ready) begin
                        // TAIL accepted -> Packet transfer complete
                        noc_tx_valid <= 1'b0;
                        req_ready    <= 1'b1; // Re-enable request interface

                        state <= IDLE;
                    end else begin
                        req_ready    <= 1'b0; // Explicitly hold ready LOW while waiting on TAIL
                    end
                end

                default: begin
                    state        <= IDLE;
                    req_ready    <= 1'b1;
                    noc_tx_valid <= 1'b0;
                    noc_tx_flit  <= 35'd0;
                    addr_reg     <= 32'h0;
                    wdata_reg    <= 32'h0;
                    write_reg    <= 1'b0;
                end

            endcase
        end
    end

endmodule
