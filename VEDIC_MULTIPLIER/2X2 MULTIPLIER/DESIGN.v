module half_adder(input a, b, output c, s);
    assign {c, s} = a + b;
endmodule

module Vedic_2x2(input [1:0] a, b, output wire [3:0] c);

    wire p0, p1, p2, p3;
    wire sum, carry;
    wire sum0, carry0;

    assign p0 = a[0] & b[0];
    assign p1 = a[1] & b[0];
    assign p2 = a[0] & b[1];
    assign p3 = a[1] & b[1];

    assign c[0] = p0;

    half_adder ha1(.a(p1), .b(p2), .c(carry), .s(sum));
    assign c[1] = sum;

    half_adder ha2(.a(p3), .b(carry), .c(carry0), .s(sum0));
    assign c[2] = sum0;
    assign c[3] = carry0;

endmodule
