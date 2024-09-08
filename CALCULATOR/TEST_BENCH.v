`timescale 1ns / 1ps
module Calculator_tb;
reg [3:0] A;
reg [3:0] B;
reg [1:0] op;
wire [7:0] result;
Calculator uut (.A(A),.B(B),.op(op),.result(result));
initial begin
    A = 0;
    B = 0;
    op = 2'b00;
    $monitor("A = %d, B = %d, op = %b, result = %d", A, B, op, result);
    #10 A = 4'd4; B = 4'd5; op = 2'b00;
    #10 A = 4'd6; B = 4'd5;  op = 2'b01;
    #10 A = 4'd5;  B = 4'd4;  op = 2'b10;
    #10 A = 4'd8;  B = 4'd2;  op = 2'b11;
    #10 $finish;
end
endmodule
