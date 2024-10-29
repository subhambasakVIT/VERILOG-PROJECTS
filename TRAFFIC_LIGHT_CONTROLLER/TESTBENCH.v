`timescale 1ns / 1ps

module Traffic_light_controller_tb;
reg clk,rst;
wire [2:0]M1;
wire [2:0]M2;
wire [2:0]M3;
wire [2:0]M4;
Traffic_light_controller dut(.clk(clk), .rst(rst), .M1(M1), .M2(M2), .M3(M3), .M4(M4));

initial
begin
    clk=1'b0;
    forever #(100/2) clk=~clk;
end

initial
begin
     rst=0;
     #10;
     rst=1;
     #10;
     rst=0;
     #(10*200);
     $finish;
end
endmodule
