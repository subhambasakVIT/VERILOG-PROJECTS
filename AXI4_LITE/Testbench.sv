//=================================================================
// axi4_lite_top_tb.sv
//
// End-to-end integration test: drives axi4_lite_top (master +
// slave wired back-to-back) through its simple user/command
// interface and checks:
//
//   1. Write-then-read consistency across the full AXI4-Lite
//      handshake on every channel.
//   2. Multiple registers can be independently written/read.
//   3. Out-of-range access returns RESP_SLVERR end-to-end.
//=================================================================

`timescale 1ns/1ps

import axi4_lite_pkg::*;

module axi4_lite_top_tb;

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 32;
    localparam int NUM_REGS   = 16;
    localparam int CLK_PERIOD = 10;

    logic clk = 0;
    logic rstn;

    always #(CLK_PERIOD/2) clk = ~clk;

    logic                      i_start;
    logic                      i_write;
    logic [ADDR_WIDTH-1:0]     i_addr;
    logic [DATA_WIDTH-1:0]     i_wdata;
    logic [(DATA_WIDTH/8)-1:0] i_wstrb;
    logic                      o_busy;
    logic                      o_done;
    logic [DATA_WIDTH-1:0]     o_rdata;
    logic [1:0]                o_resp;
    logic [DATA_WIDTH-1:0]     regs_dbg [NUM_REGS];

    axi4_lite_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .NUM_REGS   (NUM_REGS)
    ) dut (.*);

    //-----------------------------------------------------------
    // Helper tasks
    //-----------------------------------------------------------
    int errors = 0;

    task automatic check(string name, logic cond);
        if (cond) $display("[PASS] %s", name);
        else begin
            $display("[FAIL] %s", name);
            errors++;
        end
    endtask

    task automatic do_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        @(negedge clk);
        i_start = 1'b1; i_write = 1'b1; i_addr = addr; i_wdata = data; i_wstrb = '1;
        @(negedge clk);
        i_start = 1'b0;
        wait (o_done == 1'b1);
        @(negedge clk);
    endtask

    task automatic do_read(input [ADDR_WIDTH-1:0] addr);
        @(negedge clk);
        i_start = 1'b1; i_write = 1'b0; i_addr = addr; i_wdata = '0; i_wstrb = '0;
        @(negedge clk);
        i_start = 1'b0;
        wait (o_done == 1'b1);
        @(negedge clk);
    endtask

    //-----------------------------------------------------------
    // Directed test sequence
    //-----------------------------------------------------------
    initial begin
        rstn    = 0;
        i_start = 0; i_write = 0; i_addr = '0; i_wdata = '0; i_wstrb = '0;
        repeat (3) @(negedge clk);
        rstn = 1;
        @(negedge clk);

        //---------------------------------------------------
        $display("\n--- Test 1: Write/read reg0 ---");
        do_write(32'h0000_0000, 32'hDEAD_BEEF);
        check("T1: write BRESP == OKAY", o_resp == RESP_OKAY);
        do_read(32'h0000_0000);
        check("T1: read RRESP == OKAY", o_resp == RESP_OKAY);
        check("T1: read-back data matches", o_rdata == 32'hDEAD_BEEF);

        //---------------------------------------------------
        $display("\n--- Test 2: Write/read multiple registers ---");
        do_write(32'h0000_0004, 32'h0000_0001);
        do_write(32'h0000_0008, 32'h0000_0002);
        do_write(32'h0000_000C, 32'h0000_0003);

        do_read(32'h0000_0004);
        check("T2: reg1 readback", o_rdata == 32'h0000_0001);
        do_read(32'h0000_0008);
        check("T2: reg2 readback", o_rdata == 32'h0000_0002);
        do_read(32'h0000_000C);
        check("T2: reg3 readback", o_rdata == 32'h0000_0003);

        check("T2: regs_dbg[1] mirrors reg1", regs_dbg[1] == 32'h0000_0001);
        check("T2: regs_dbg[2] mirrors reg2", regs_dbg[2] == 32'h0000_0002);
        check("T2: regs_dbg[3] mirrors reg3", regs_dbg[3] == 32'h0000_0003);

        //---------------------------------------------------
        $display("\n--- Test 3: Out-of-range access -> SLVERR ---");
        do_write(32'h0000_1000, 32'hFFFF_FFFF);
        check("T3: write to bad addr -> SLVERR", o_resp == RESP_SLVERR);

        do_read(32'h0000_1000);
        check("T3: read from bad addr -> SLVERR", o_resp == RESP_SLVERR);
        check("T3: read data == 0 on error",      o_rdata == 32'h0000_0000);

        //---------------------------------------------------
        $display("\n=====================================");
        if (errors == 0) $display("ALL TOP-LEVEL TESTS PASSED");
        else              $display("%0d TOP-LEVEL TEST(S) FAILED", errors);
        $display("=====================================\n");

        $finish;
    end

endmodule : axi4_lite_top_tb
