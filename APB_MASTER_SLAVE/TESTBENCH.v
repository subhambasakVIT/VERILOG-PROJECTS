`timescale 1ns / 1ps

module tb_apb_slave_like_env;

    reg clk;
    reg reset_n;
    
    wire PSELx;
    wire PENABLE;
    wire [31:0]PADDR;
    wire [31:0]PWDATA;
    wire PWRITE;
    reg PREADY;
    
    reg transfer;
    reg [31:0]addr;
    reg [31:0]wdata;
    reg write;
    
    apb_master dut(.clk(clk) , .reset_n(reset_n) , .transfer(transfer) , .addr(addr) , .wdata(wdata) , .write(write) , .PSELx(PSELx) , .PENABLE(PENABLE) , .PADDR(PADDR) , .PWDATA(PWDATA) , .PWRITE(PWRITE) , .PREADY(PREADY)); 
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    
    initial
        begin  
            reset_n = 0;
            transfer = 0;
            addr = 32'h0;
            wdata = 32'h0;
            write =1;
            PREADY =0;
            
            #20;
            reset_n = 1;
            
            @(posedge clk);
            transfer = 1;
            addr = 32'hABCD_1234;
            wdata = 32'hFACE_CAFE;
            write = 1;
            
            @(posedge clk);
            transfer = 0;
            
            repeat (3) @(posedge clk);
            PREADY = 1;
            
            @(posedge clk);
            PREADY = 0;
            
            
            repeat (5) @(posedge clk);
            
            $display("APB Slave Test Completed");
            $finish;
        end
        
        always @(posedge clk)
            begin  
                if(PSELx && PENABLE && PREADY)
                    begin
                        if(PWRITE)
                            begin
                                $display("APB SLAVE WRITE -> Addr : 0x%08h | Data: 0x%08h", PADDR , PWDATA);
                            end
                        else
                            begin
                                $display("APB SLAVE READ -> Addr : 0x%08h",PADDR);
                            end 
                    end
            end
endmodule
