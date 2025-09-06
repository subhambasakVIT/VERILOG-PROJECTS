`include "vedic_8x8.v"

module test_vedic_8;

	reg [7:0] a;
	reg [7:0] b;

	wire [15:0] c;

	// Instantiate the Unit Under Test (UUT)
	vedic_8X8 uut (.a(a),.b(b), .c(c));

	initial 
    begin
        
        $dumpfile("vedic_8x8.vcd");
        $dumpvars(0,test_vedic_8);

		a = 0;
		b = 0;
		#50;
		
		a = 8'd255;
		b = 8'd255;
		#50;
		
		a = 8'd5;
		b = 8'd3;
		#50;
		
		a = 8'd4;
		b = 8'd2;
		#50;
		
		a = 8'd2;
		b = 8'd2;
		#50;
		
		a = 8'd6;
		b = 8'd8;
		#50;
        
		

	end
      
endmodule
