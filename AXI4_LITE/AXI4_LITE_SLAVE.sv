0import axi4_lite_pkg::*;

module axi4_lite_slave #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32,
    parameter int NUM_REGS   = 16
)(
    input  logic                      clk,
    input  logic                      rstn,

    //---------------------------------------------------------
    // AXI4-Lite Slave Interface
    //---------------------------------------------------------
    // Write Address Channel
    input  logic [ADDR_WIDTH-1:0]     s_awaddr,
    input  logic [2:0]                s_awprot,
    input  logic                      s_awvalid,
    output logic                      s_awready,

    // Write Data Channel
    input  logic [DATA_WIDTH-1:0]     s_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] s_wstrb,
    input  logic                      s_wvalid,
    output logic                      s_wready,

    // Write Response Channel
    output logic [1:0]                s_bresp,
    output logic                      s_bvalid,
    input  logic                      s_bready,

    // Read Address Channel
    input  logic [ADDR_WIDTH-1:0]     s_araddr,
    input  logic [2:0]                s_arprot,
    input  logic                      s_arvalid,
    output logic                      s_arready,

    // Read Data Channel
    output logic [DATA_WIDTH-1:0]     s_rdata,
    output logic [1:0]                s_rresp,
    output logic                      s_rvalid,
    input  logic                      s_rready,

    //---------------------------------------------------------
    // Debug / observation port (register bank contents)
    //---------------------------------------------------------
    output logic [DATA_WIDTH-1:0]     regs_dbg [NUM_REGS]
);

    localparam int ADDR_LSB = $clog2(DATA_WIDTH/8); // byte-offset bits  (=2 for 32-bit)
    localparam int REG_BITS = $clog2(NUM_REGS);     // register index bits (=4 for 16 regs)

    // Register bank
    logic [DATA_WIDTH-1:0] regs [NUM_REGS];

    always_comb regs_dbg = regs;

    //-----------------------------------------------------------
    // WRITE CHANNEL (AW + W -> B)
    //-----------------------------------------------------------
    typedef enum logic [0:0] {W_IDLE, W_RESP} wstate_e;
    wstate_e wstate;

    logic aw_hs, w_hs;
    logic [ADDR_WIDTH-1:0]     awaddr_q;
    logic [DATA_WIDTH-1:0]     wdata_q;
    logic [(DATA_WIDTH/8)-1:0] wstrb_q;

    assign s_awready = (wstate == W_IDLE) && !aw_hs;
    assign s_wready  = (wstate == W_IDLE) && !w_hs;

    // Effective (address/data/strb) seen this cycle, whether captured
    // earlier or arriving on this very handshake.
    logic [ADDR_WIDTH-1:0]     eff_awaddr;
    logic [DATA_WIDTH-1:0]     eff_wdata;
    logic [(DATA_WIDTH/8)-1:0] eff_wstrb;
    logic [REG_BITS-1:0]       w_reg_index;
    logic                      w_decoded_valid;

    assign eff_awaddr = aw_hs ? awaddr_q : s_awaddr;
    assign eff_wdata  = w_hs  ? wdata_q  : s_wdata;
    assign eff_wstrb  = w_hs  ? wstrb_q  : s_wstrb;

    assign w_reg_index     = eff_awaddr[ADDR_LSB +: REG_BITS];
    assign w_decoded_valid = (eff_awaddr >> (ADDR_LSB + REG_BITS)) == '0;

    logic aw_hs_eff, w_hs_eff;
    assign aw_hs_eff = aw_hs || (s_awvalid && s_awready);
    assign w_hs_eff  = w_hs  || (s_wvalid  && s_wready);

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            aw_hs    <= 1'b0;
            w_hs     <= 1'b0;
            awaddr_q <= '0;
            wdata_q  <= '0;
            wstrb_q  <= '0;
            wstate   <= W_IDLE;
            s_bvalid <= 1'b0;
            s_bresp  <= RESP_OKAY;
            for (int i = 0; i < NUM_REGS; i++) regs[i] <= '0;
        end else begin
            case (wstate)
                W_IDLE: begin
                    // capture AW
                    if (s_awvalid && s_awready) begin
                        awaddr_q <= s_awaddr;
                        aw_hs    <= 1'b1;
                    end
                    // capture W
                    if (s_wvalid && s_wready) begin
                        wdata_q <= s_wdata;
                        wstrb_q <= s_wstrb;
                        w_hs    <= 1'b1;
                    end

                    // once both halves of the write transaction are present
                    if (aw_hs_eff && w_hs_eff) begin
                        if (w_decoded_valid) begin
                            for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                if (eff_wstrb[b]) begin
                                    regs[w_reg_index][b*8 +: 8] <= eff_wdata[b*8 +: 8];
                                end
                            end
                            s_bresp <= RESP_OKAY;
                        end else begin
                            s_bresp <= RESP_SLVERR;
                        end

                        s_bvalid <= 1'b1;
                        aw_hs    <= 1'b0;
                        w_hs     <= 1'b0;
                        wstate   <= W_RESP;
                    end
                end

                W_RESP: begin
                    if (s_bvalid && s_bready) begin
                        s_bvalid <= 1'b0;
                        wstate   <= W_IDLE;
                    end
                end

                default: wstate <= W_IDLE;
            endcase
        end
    end

    //-----------------------------------------------------------
    // READ CHANNEL (AR -> R)
    //-----------------------------------------------------------
    typedef enum logic [0:0] {R_IDLE, R_RESP} rstate_e;
    rstate_e rstate;

    assign s_arready = (rstate == R_IDLE);

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rstate   <= R_IDLE;
            s_rvalid <= 1'b0;
            s_rdata  <= '0;
            s_rresp  <= RESP_OKAY;
        end else begin
            case (rstate)
                R_IDLE: begin
                    if (s_arvalid && s_arready) begin
                        if ((s_araddr >> (ADDR_LSB + REG_BITS)) == '0) begin
                            s_rdata <= regs[s_araddr[ADDR_LSB +: REG_BITS]];
                            s_rresp <= RESP_OKAY;
                        end else begin
                            s_rdata <= '0;
                            s_rresp <= RESP_SLVERR;
                        end
                        s_rvalid <= 1'b1;
                        rstate   <= R_RESP;
                    end
                end

                R_RESP: begin
                    if (s_rvalid && s_rready) begin
                        s_rvalid <= 1'b0;
                        rstate   <= R_IDLE;
                    end
                end

                default: rstate <= R_IDLE;
            endcase
        end
    end

endmodule : axi4_lite_slave
