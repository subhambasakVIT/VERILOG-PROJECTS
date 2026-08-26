//=================================================================
// axi4_lite_top.sv
//
// Integration wrapper: connects the AXI4-Lite master directly to
// the AXI4-Lite slave (back-to-back) for end-to-end simulation.
// Exposes the master's simple command interface and the slave's
// register-bank debug port to the outside world.
//=================================================================

module axi4_lite_top #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32,
    parameter int NUM_REGS   = 16
)(
    input  logic                      clk,
    input  logic                      rstn,

    // User command interface (drives the master)
    input  logic                      i_start,
    input  logic                      i_write,
    input  logic [ADDR_WIDTH-1:0]     i_addr,
    input  logic [DATA_WIDTH-1:0]     i_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] i_wstrb,
    output logic                      o_busy,
    output logic                      o_done,
    output logic [DATA_WIDTH-1:0]     o_rdata,
    output logic [1:0]                o_resp,

    // Slave register-bank debug port
    output logic [DATA_WIDTH-1:0]     regs_dbg [NUM_REGS]
);

    // AXI4-Lite interconnect wires (master <-> slave)
    logic [ADDR_WIDTH-1:0]     awaddr;
    logic [2:0]                awprot;
    logic                      awvalid;
    logic                      awready;

    logic [DATA_WIDTH-1:0]     wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                      wvalid;
    logic                      wready;

    logic [1:0]                bresp;
    logic                      bvalid;
    logic                      bready;

    logic [ADDR_WIDTH-1:0]     araddr;
    logic [2:0]                arprot;
    logic                      arvalid;
    logic                      arready;

    logic [DATA_WIDTH-1:0]     rdata;
    logic [1:0]                rresp;
    logic                      rvalid;
    logic                      rready;

    axi4_lite_master #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_master (
        .clk       (clk),
        .rstn      (rstn),

        .i_start   (i_start),
        .i_write   (i_write),
        .i_addr    (i_addr),
        .i_wdata   (i_wdata),
        .i_wstrb   (i_wstrb),
        .o_busy    (o_busy),
        .o_done    (o_done),
        .o_rdata   (o_rdata),
        .o_resp    (o_resp),

        .m_awaddr  (awaddr),
        .m_awprot  (awprot),
        .m_awvalid (awvalid),
        .m_awready (awready),

        .m_wdata   (wdata),
        .m_wstrb   (wstrb),
        .m_wvalid  (wvalid),
        .m_wready  (wready),

        .m_bresp   (bresp),
        .m_bvalid  (bvalid),
        .m_bready  (bready),

        .m_araddr  (araddr),
        .m_arprot  (arprot),
        .m_arvalid (arvalid),
        .m_arready (arready),

        .m_rdata   (rdata),
        .m_rresp   (rresp),
        .m_rvalid  (rvalid),
        .m_rready  (rready)
    );

    axi4_lite_slave #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .NUM_REGS   (NUM_REGS)
    ) u_slave (
        .clk       (clk),
        .rstn      (rstn),

        .s_awaddr  (awaddr),
        .s_awprot  (awprot),
        .s_awvalid (awvalid),
        .s_awready (awready),

        .s_wdata   (wdata),
        .s_wstrb   (wstrb),
        .s_wvalid  (wvalid),
        .s_wready  (wready),

        .s_bresp   (bresp),
        .s_bvalid  (bvalid),
        .s_bready  (bready),

        .s_araddr  (araddr),
        .s_arprot  (arprot),
        .s_arvalid (arvalid),
        .s_arready (arready),

        .s_rdata   (rdata),
        .s_rresp   (rresp),
        .s_rvalid  (rvalid),
        .s_rready  (rready),

        .regs_dbg  (regs_dbg)
    );

endmodule : axi4_lite_top
