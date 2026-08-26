import axi4_lite_pkg::*;

module axi4_lite_master #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32
)(
    input  logic                      clk,
    input  logic                      rstn,

    //---------------------------------------------------------
    // Simple user / command interface
    //---------------------------------------------------------
    input  logic                      i_start,   // pulse: start a transaction
    input  logic                      i_write,   // 1 = write txn, 0 = read txn
    input  logic [ADDR_WIDTH-1:0]     i_addr,
    input  logic [DATA_WIDTH-1:0]     i_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] i_wstrb,
    output logic                      o_busy,
    output logic                      o_done,    // pulses for 1 cycle when txn completes
    output logic [DATA_WIDTH-1:0]     o_rdata,
    output logic [1:0]                o_resp,    // captured BRESP / RRESP

    //---------------------------------------------------------
    // AXI4-Lite Master Interface
    //---------------------------------------------------------
    // Write Address Channel
    output logic [ADDR_WIDTH-1:0]     m_awaddr,
    output logic [2:0]                m_awprot,
    output logic                      m_awvalid,
    input  logic                      m_awready,

    // Write Data Channel
    output logic [DATA_WIDTH-1:0]     m_wdata,
    output logic [(DATA_WIDTH/8)-1:0] m_wstrb,
    output logic                      m_wvalid,
    input  logic                      m_wready,

    // Write Response Channel
    input  logic [1:0]                m_bresp,
    input  logic                      m_bvalid,
    output logic                      m_bready,

    // Read Address Channel
    output logic [ADDR_WIDTH-1:0]     m_araddr,
    output logic [2:0]                m_arprot,
    output logic                      m_arvalid,
    input  logic                      m_arready,

    // Read Data Channel
    input  logic [DATA_WIDTH-1:0]     m_rdata,
    input  logic [1:0]                m_rresp,
    input  logic                      m_rvalid,
    output logic                      m_rready
);

    //-----------------------------------------------------------
    // FSM
    //-----------------------------------------------------------
    typedef enum logic [2:0] {
        S_IDLE,
        S_WRITE,        // AW & W in flight (independently)
        S_WRITE_RESP,   // waiting for B
        S_READ_ADDR,    // AR in flight
        S_READ_DATA,    // waiting for R
        S_DONE
    } state_e;

    state_e state, state_n;

    // Latched command
    logic [ADDR_WIDTH-1:0]     addr_q;
    logic [DATA_WIDTH-1:0]     wdata_q;
    logic [(DATA_WIDTH/8)-1:0] wstrb_q;

    //-----------------------------------------------------------
    // Phase-complete predicates (combinational, but built only
    // from REGISTERS (m_awvalid/m_wvalid) and AXI inputs
    // (m_awready/m_wready) -- no self-reference, no loop).
    //-----------------------------------------------------------
    logic aw_phase_done, w_phase_done;
    assign aw_phase_done = !m_awvalid || m_awready;
    assign w_phase_done  = !m_wvalid  || m_wready;

    //-----------------------------------------------------------
    // State register
    //-----------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) state <= S_IDLE;
        else       state <= state_n;
    end

    //-----------------------------------------------------------
    // Next-state logic
    //-----------------------------------------------------------
    always_comb begin
        state_n = state;
        unique case (state)
            S_IDLE:       state_n = i_start ? (i_write ? S_WRITE : S_READ_ADDR) : S_IDLE;
            S_WRITE:      state_n = (aw_phase_done && w_phase_done) ? S_WRITE_RESP : S_WRITE;
            S_WRITE_RESP: state_n = (m_bvalid && m_bready) ? S_DONE : S_WRITE_RESP;
            S_READ_ADDR:  state_n = (m_arvalid && m_arready) ? S_READ_DATA : S_READ_ADDR;
            S_READ_DATA:  state_n = (m_rvalid && m_rready) ? S_DONE : S_READ_DATA;
            S_DONE:       state_n = S_IDLE;
            default:      state_n = S_IDLE;
        endcase
    end

    //-----------------------------------------------------------
    // Command latch (captured when accepted from IDLE)
    //-----------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            addr_q  <= '0;
            wdata_q <= '0;
            wstrb_q <= '0;
        end else if (state == S_IDLE && i_start) begin
            addr_q  <= i_addr;
            wdata_q <= i_wdata;
            wstrb_q <= i_wstrb;
        end
    end

    //-----------------------------------------------------------
    // Registered VALID / READY handshake signals
    //-----------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            m_awvalid <= 1'b0;
            m_wvalid  <= 1'b0;
            m_bready  <= 1'b0;
            m_arvalid <= 1'b0;
            m_rready  <= 1'b0;
        end else begin
            unique case (state)
                S_IDLE: begin
                    if (i_start) begin
                        if (i_write) begin
                            m_awvalid <= 1'b1;
                            m_wvalid  <= 1'b1;
                        end else begin
                            m_arvalid <= 1'b1;
                        end
                    end
                end

                S_WRITE: begin
                    if (m_awvalid && m_awready) m_awvalid <= 1'b0;
                    if (m_wvalid  && m_wready)  m_wvalid  <= 1'b0;
                    if (aw_phase_done && w_phase_done) m_bready <= 1'b1;
                end

                S_WRITE_RESP: begin
                    if (m_bvalid && m_bready) m_bready <= 1'b0;
                end

                S_READ_ADDR: begin
                    if (m_arvalid && m_arready) begin
                        m_arvalid <= 1'b0;
                        m_rready  <= 1'b1;
                    end
                end

                S_READ_DATA: begin
                    if (m_rvalid && m_rready) m_rready <= 1'b0;
                end

                default: ; // S_DONE: hold (all valids/readys already 0 here)
            endcase
        end
    end

    //-----------------------------------------------------------
    // Write Address Channel (payload)
    //-----------------------------------------------------------
    assign m_awaddr = addr_q;
    assign m_awprot = 3'b000;

    //-----------------------------------------------------------
    // Write Data Channel (payload)
    //-----------------------------------------------------------
    assign m_wdata = wdata_q;
    assign m_wstrb = wstrb_q;

    //-----------------------------------------------------------
    // Read Address Channel (payload)
    //-----------------------------------------------------------
    assign m_araddr = addr_q;
    assign m_arprot = 3'b000;

    //-----------------------------------------------------------
    // User-facing status / data outputs
    //-----------------------------------------------------------
    assign o_busy = (state != S_IDLE);
    assign o_done = (state == S_DONE);

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_rdata <= '0;
            o_resp  <= RESP_OKAY;
        end else begin
            if (state == S_READ_DATA && m_rvalid && m_rready) begin
                o_rdata <= m_rdata;
                o_resp  <= m_rresp;
            end
            if (state == S_WRITE_RESP && m_bvalid && m_bready) begin
                o_resp <= m_bresp;
            end
        end
    end

endmodule : axi4_lite_master
