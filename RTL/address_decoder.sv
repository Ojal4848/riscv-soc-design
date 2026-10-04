module address_decoder (
    input  logic [31:0] cpu_addr,
    input  logic        cpu_req,

    output logic        sel_itcm,
    output logic        sel_dtcm,
    output logic        sel_ahb_bridge,
    output logic        sel_i2c,
    output logic        sel_noc_port
);

    always_comb begin
        // Default: no peripheral selected
        sel_itcm       = 1'b0;
        sel_dtcm       = 1'b0;
        sel_ahb_bridge = 1'b0;
        sel_i2c        = 1'b0;
        sel_noc_port   = 1'b0;

        if (cpu_req) begin
            // ITCM: 0x0000_0000 - 0x0000_3FFF
            if ((cpu_addr >= 32'h0000_0000) && (cpu_addr <= 32'h0000_3FFF)) begin
                sel_itcm = 1'b1;
            end
            // DTCM: 0x2000_0000 - 0x2000_3FFF
            else if ((cpu_addr >= 32'h2000_0000) && (cpu_addr <= 32'h2000_3FFF)) begin
                sel_dtcm = 1'b1;
            end
            // AHB Bridge / UART: 0x4000_0000 - 0x4000_00FF
            else if ((cpu_addr >= 32'h4000_0000) && (cpu_addr <= 32'h4000_00FF)) begin
                sel_ahb_bridge = 1'b1;
            end
            // AHB Bridge / I2C: 0x4000_1000 - 0x4000_10FF
            else if ((cpu_addr >= 32'h4000_1000) && (cpu_addr <= 32'h4000_10FF)) begin
                sel_ahb_bridge = 1'b1;
                sel_i2c        = 1'b1;
            end
            // NoC Port: 0x5000_0000 - 0x5000_00FF
            else if ((cpu_addr >= 32'h5000_0000) && (cpu_addr <= 32'h5000_00FF)) begin
                sel_noc_port = 1'b1;
            end
        end
    end

endmodule