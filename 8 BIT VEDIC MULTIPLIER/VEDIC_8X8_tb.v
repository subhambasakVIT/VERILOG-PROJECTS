`include "vedic_8x8.v"
`timescale 1ns / 1ps

module vedic_8X8_tb;

    // Inputs
    reg  [7:0] a;
    reg  [7:0] b;

    // Output
    wire [15:0] c;

    // Expected Result
    reg [15:0] expected;

    integer i,j;
    integer errors;

    //---------------------------------------------------
    // DUT Instantiation
    //---------------------------------------------------
    vedic_8X8 DUT (
        .a(a),
        .b(b),
        .c(c)
    );

    //---------------------------------------------------
    // Monitor
    //---------------------------------------------------
    initial
    begin
        $monitor("TIME=%0t | A=%0d (0x%h) | B=%0d (0x%h) | DUT_OUT=%0d (0x%h)",
                 $time,a,a,b,b,c,c);
    end

    //---------------------------------------------------
    // Test Sequence
    //---------------------------------------------------
    initial
    begin

        errors = 0;

        $display("===========================================");
        $display("      8x8 VEDIC MULTIPLIER TEST START      ");
        $display("===========================================");

        //------------------------------------------------
        // Corner Test Cases
        //------------------------------------------------

        a = 0;   b = 0;   #10;
        check_result();

        a = 0;   b = 255; #10;
        check_result();

        a = 255; b = 0;   #10;
        check_result();

        a = 1;   b = 255; #10;
        check_result();

        a = 255; b = 1;   #10;
        check_result();

        a = 255; b = 255; #10;
        check_result();

        a = 15;  b = 15;  #10;
        check_result();

        a = 128; b = 128; #10;
        check_result();

        //------------------------------------------------
        // Random Testing
        //------------------------------------------------

        $display("\n================================");
        $display(" RANDOM TESTING");
        $display("================================");

        for(i=0;i<1000;i=i+1)
        begin
            a = $random;
            b = $random;

            #10;

            expected = a * b;

            if(c !== expected)
            begin
                errors = errors + 1;

                $display("ERROR @ %0t", $time);
                $display("A=%0d B=%0d",a,b);
                $display("Expected=%0d (0x%h)",expected,expected);
                $display("Got     =%0d (0x%h)",c,c);
                $display("--------------------------------");
            end
        end

        //------------------------------------------------
        // Exhaustive Verification
        //------------------------------------------------

        $display("\n================================");
        $display(" EXHAUSTIVE TESTING");
        $display("================================");

        for(i=0;i<256;i=i+1)
        begin
            for(j=0;j<256;j=j+1)
            begin
                a = i;
                b = j;

                #1;

                expected = i*j;

                if(c !== expected)
                begin
                    errors = errors + 1;

                    $display("FAIL:");
                    $display("A=%0d B=%0d",i,j);
                    $display("Expected=%0d",expected);
                    $display("Got=%0d",c);
                end
            end
        end

        //------------------------------------------------
        // Final Report
        //------------------------------------------------

        $display("\n================================");
        $display(" TEST SUMMARY");
        $display("================================");

        if(errors==0)
        begin
            $display("ALL TESTS PASSED");
            $display("No mismatches detected.");
        end
        else
        begin
            $display("TOTAL ERRORS = %0d", errors);
        end

        $display("================================");

        $finish;
    end

    //---------------------------------------------------
    // Task : Check Result
    //---------------------------------------------------
    task check_result;
    begin
        expected = a * b;

        if(c === expected)
        begin
            $display("PASS : A=%0d B=%0d --> OUT=%0d",
                      a,b,c);
        end
        else
        begin
            errors = errors + 1;

            $display("FAIL : A=%0d B=%0d",a,b);
            $display("Expected = %0d (0x%h)",expected,expected);
            $display("Got      = %0d (0x%h)",c,c);
        end
    end
    endtask

endmodule
