`timescale 1ns / 1ps
module Vending_Machine_tb;

reg clk;
reg [1:0] in;
reg rst;
wire out;
wire [1:0] change;
wire [1:0]c_state;
wire [1:0] n_state;

Vending_Machine uut (.clk(clk),.rst(rst),.in(in),.out(out),.change(change),.c_state(c_state), .n_state(n_state));

initial begin
    rst = 1;
    clk = 0;
    in = 2'b00;
    #6 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 2'b01;
    #10 in = 2'b10;
    #10 in = 2'b00;
    #10 in = 2'b01;
    #10 in = 2'b10;
    #10 in = 2'b00;
    #10 in = 2'b01;
    #10 in = 2'b10;
    #10 in = 2'b00;
    #10 in = 2'b01;
end

initial begin
    #100 $finish;
end
endmodule
