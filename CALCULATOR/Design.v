`timescale 1ns / 1ps
module Calculator (
    input [3:0] A,    // 4-bit input A
    input [3:0] B,    // 4-bit input B
    input [1:0] op,   // 2-bit operation selector
    output [7:0] result // 8-bit result to handle multiplication overflow
);
    reg [7:0] result_temp;
    integer i;
    always @(*) begin
        case (op)
            2'b00: result_temp = A + B;  // Addition
            2'b01: result_temp = A - B;  // Subtraction
            2'b10: result_temp = A*B;
            2'b11: result_temp = A / B; // Division
            default: result_temp = 8'b00000000;
        endcase
    end

    assign result = result_temp;

endmodule
