`timescale 1ns / 1ps

module tb_Vedic_2x2;
    reg [1:0] a, b;
    wire [3:0] c;
    
    Vedic_2x2 uut (
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        a = 2'd1;
        b = 2'd2;
        #100;
        a = 2'd2;
        b = 2'd2;
        #100;
        a = 2'd3;
        b = 2'd2;
        #100;
        a = 2'd3;
        b = 2'd3;
        #100;
        $finish;
    end
endmodule
