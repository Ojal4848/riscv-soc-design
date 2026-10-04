module axi_to_ahb_bridge (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Write Address Channel
    input  logic [31:0] s_axi_awaddr,
    input  logic [2:0]  s_axi_awprot,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // AXI4-Lite Write Response Channel
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  logic [31:0] s_axi_araddr,
    input  logic [2:0]  s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // AXI4-Lite Read Data Channel
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // AHB-Lite Master Interface
    output logic [31:0] m_ahb_haddr,
    output logic        m_ahb_hwrite,
    output logic [1:0]  m_ahb_htrans,
    output logic [2:0]  m_ahb_hsize,
    output logic [2:0]  m_ahb_hburst,
    output logic [3:0]  m_ahb_hprot,
    output logic [31:0] m_ahb_hwdata,
    input  logic [31:0] m_ahb_hrdata,
    input  logic        m_ahb_hready,
    input  logic        m_ahb_hresp
);

    typedef enum logic [2:0] {
        IDLE,
        AHB_WRITE,
        WRITE_RESP,
        AHB_READ,
        READ_RESP
    } state_t;

    state_t state;

    logic [31:0] awaddr_reg;
    logic [2:0]  awprot_reg;
    logic [31:0] wdata_reg;
    logic [3:0]  wstrb_reg;

    logic aw_received;
    logic w_received;

    logic [2:0]  decoded_hsize;
    logic        write_valid_strobe;
    logic        write_aligned;

    logic [31:0] next_write_addr;
    logic [3:0]  next_write_strobe;
    logic [31:0] next_write_data;

    assign m_ahb_hburst = 3'b000;

    assign next_write_addr   = aw_received ? awaddr_reg : s_axi_awaddr;
    assign next_write_strobe = w_received  ? wstrb_reg  : s_axi_wstrb;
    assign next_write_data   = w_received  ? wdata_reg  : s_axi_wdata;

    always_comb begin
        write_valid_strobe = 1'b1;
        decoded_hsize      = 3'b010;
        write_aligned      = 1'b1;

        case (next_write_strobe)
            4'b0001, 4'b0010, 4'b0100, 4'b1000: decoded_hsize = 3'b000;
            4'b0011, 4'b1100:                 decoded_hsize = 3'b001;
            4'b1111:                          decoded_hsize = 3'b010;
            default: begin
                write_valid_strobe = 1'b1;
                decoded_hsize      = 3'b010;
                write_aligned      = 1'b1;
            end
        endcase
    end

    assign s_axi_awready = (state == IDLE);
    assign s_axi_wready  = (state == IDLE);
    assign s_axi_arready = (state == IDLE) && !s_axi_awvalid && !s_axi_wvalid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 32'h0;

            m_ahb_haddr  <= 32'h0;
            m_ahb_hwrite <= 1'b0;
            m_ahb_htrans <= 2'b00;
            m_ahb_hsize  <= 3'b010;
            m_ahb_hprot  <= 4'b0011;
            m_ahb_hwdata <= 32'h0;

            awaddr_reg   <= 32'h0;
            wdata_reg    <= 32'h0;
            wstrb_reg    <= 4'b0;
            aw_received  <= 1'b0;
            w_received   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    s_axi_rvalid <= 1'b0;
                    m_ahb_htrans <= 2'b00;

                    if (s_axi_awvalid && s_axi_awready) begin
                        awaddr_reg  <= s_axi_awaddr;
                        aw_received <= 1'b1;
                    end

                    if (s_axi_wvalid && s_axi_wready) begin
                        wdata_reg  <= s_axi_wdata;
                        wstrb_reg  <= s_axi_wstrb;
                        w_received <= 1'b1;
                    end

                    if ((aw_received || s_axi_awvalid) && (w_received || s_axi_wvalid)) begin
                        aw_received  <= 1'b0;
                        w_received   <= 1'b0;

                        m_ahb_haddr  <= next_write_addr;
                        m_ahb_hwdata <= next_write_data;
                        m_ahb_hwrite <= 1'b1;
                        m_ahb_htrans <= 2'b10;
                        m_ahb_hsize  <= decoded_hsize;
                        state        <= AHB_WRITE;
                    end
                end

                AHB_WRITE: begin
                    if (m_ahb_hready) begin
                        m_ahb_htrans <= 2'b00;
                        s_axi_bresp  <= 2'b00;
                        state        <= WRITE_RESP;
                    end
                end

                WRITE_RESP: begin
                    s_axi_bvalid <= 1'b1;
                    if (s_axi_bready || 1'b1) begin
                        s_axi_bvalid <= 1'b0;
                        state        <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule