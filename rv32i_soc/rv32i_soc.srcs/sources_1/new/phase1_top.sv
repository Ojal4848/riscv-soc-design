`timescale 1ns / 1ps

module phase1_top (
    input  logic        clk,
    input  logic        rst_n,
    output logic        uart_tx,
    inout  wire         i2c_scl,
    inout  wire         i2c_sda,
    output logic [34:0] noc_tx_flit,
    output logic        noc_tx_valid,
    input  logic        noc_tx_ready
);

    logic [31:0] cpu_addr, cpu_wdata, cpu_rdata;
    logic [3:0]  cpu_wstrb;
    logic        cpu_req, cpu_write;
    logic        sel_itcm, sel_dtcm, sel_ahb_bridge, sel_i2c, sel_noc_port;
    logic [31:0] ram_rdata, ahb_hrdata, ahb_haddr, ahb_hwdata;
    logic        ahb_hwrite, ahb_hready = 1'b1;

    // AXI Response & Control Wires for Bridge
    logic        s_axi_awready, s_axi_wready, s_axi_bvalid, s_axi_arready, s_axi_rvalid;
    logic [1:0]  s_axi_bresp, s_axi_rresp;
    logic [2:0]  m_ahb_hsize, m_ahb_hburst;
    logic [1:0]  m_ahb_htrans;
    logic [3:0]  m_ahb_hprot;
    logic        m_ahb_hresp;

    // Bus Read Mux: Route ITCM RAM data when address is ITCM, otherwise bridge data
    assign cpu_rdata = (sel_ahb_bridge) ? ahb_hrdata : ram_rdata;

    // Core Instantiation
    rv32i_core core_inst (
        .clk        (clk), 
        .rst_n      (rst_n),
        .mem_addr   (cpu_addr), 
        .mem_wdata  (cpu_wdata),
        .mem_rdata  (cpu_rdata), 
        .mem_req    (cpu_req), 
        .mem_write  (cpu_write),
        .mem_wstrb  (cpu_wstrb)
    );

    // Address Decoder
    address_decoder decoder_inst (
        .cpu_addr      (cpu_addr), 
        .cpu_req       (cpu_req),
        .sel_itcm      (sel_itcm), 
        .sel_dtcm      (sel_dtcm),
        .sel_ahb_bridge(sel_ahb_bridge), 
        .sel_i2c       (sel_i2c),
        .sel_noc_port  (sel_noc_port)
    );

    // ITCM RAM Memory Instantiation
    ram_memory itcm_ram (
        .clk        (clk),
        
        // Port A: Instruction TCM (Fetch path)
        .itcm_addr  (cpu_addr),
        .itcm_rdata (ram_rdata),
        
        // Port B: Data TCM (Load/Store path)
        .dtcm_we    (sel_itcm && cpu_write),
        .dtcm_be    (cpu_wstrb),             
        .dtcm_addr  (cpu_addr),
        .dtcm_wdata (cpu_wdata),
        .dtcm_rdata ()                     
    );

    // AXI to AHB Bridge
    axi_to_ahb_bridge bridge_inst (
        .clk            (clk), 
        .rst_n          (rst_n),
        
        // AXI Slave Write Address Channel
        .s_axi_awaddr   (cpu_addr), 
        .s_axi_awvalid  (sel_ahb_bridge && cpu_write),
        .s_axi_awready  (s_axi_awready),
        .s_axi_awprot   (3'b000),
        
        // AXI Slave Write Data Channel
        .s_axi_wdata    (cpu_wdata), 
        .s_axi_wstrb    (cpu_wstrb),
        .s_axi_wvalid   (sel_ahb_bridge && cpu_write),
        .s_axi_wready   (s_axi_wready),
        
        // AXI Slave Write Response Channel
        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bready   (1'b1), 
        
        // AXI Slave Read Address Channel
        .s_axi_araddr   (cpu_addr),
        .s_axi_arvalid  (sel_ahb_bridge && !cpu_write), 
        .s_axi_arready  (s_axi_arready),
        .s_axi_arprot   (3'b000),
        
        // AXI Slave Read Data Channel
        .s_axi_rdata    (ahb_hrdata),
        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rresp    (s_axi_rresp),
        .s_axi_rready   (1'b1), 
        
        // AHB Master Interface
        .m_ahb_haddr    (ahb_haddr),
        .m_ahb_hwrite   (ahb_hwrite), 
        .m_ahb_hwdata   (ahb_hwdata),
        .m_ahb_hrdata   (ahb_hrdata), 
        .m_ahb_hready   (ahb_hready),
        .m_ahb_hsize    (m_ahb_hsize),
        .m_ahb_htrans   (m_ahb_htrans),
        .m_ahb_hburst   (m_ahb_hburst),
        .m_ahb_hprot    (m_ahb_hprot),
        .m_ahb_hresp    (1'b0)
    );

    // UART Wrapper Peripheral (0x4000_0000)
    uart_wrapper uart_inst (
        .clk    (clk), 
        .rst_n  (rst_n), 
        .sel    (sel_ahb_bridge && !sel_i2c),
        .we     (ahb_hwrite), 
        .wdata  (ahb_hwdata), 
        .rdata  (), 
        .tx     (uart_tx)
    );

    // I2C Wrapper Peripheral (0x4000_1000)
    i2c_wrapper i2c_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .haddr        (ahb_haddr),
        .hwdata       (ahb_hwdata),
        .hwrite       (ahb_hwrite),
        .htrans_valid (sel_i2c),
        .hrdata       (),
        .i2c_scl      (i2c_scl),
        .i2c_sda      (i2c_sda)
    );

    // NoC Port Interface (0x5000_0000)
    noc_port noc_inst (
        .clk          (clk), 
        .rst_n        (rst_n),
        .req_addr     (cpu_addr), 
        .req_wdata    (cpu_wdata), 
        .req_write    (cpu_write),
        .req_valid    (sel_noc_port), 
        .req_ready    (),
        .noc_tx_flit  (noc_tx_flit), 
        .noc_tx_valid (noc_tx_valid), 
        .noc_tx_ready (noc_tx_ready)
    );

endmodule