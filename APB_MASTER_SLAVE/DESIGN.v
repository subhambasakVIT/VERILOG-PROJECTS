`timescale 1ns / 1ps
module apb_master(
    input clk,
    input reset_n,
    input transfer,
    input [31:0] addr,
    input [31:0] wdata,
    input write,
    output reg PSELx,
    output reg PENABLE,
    output reg [31:0] PADDR,
    output reg [31:0] PWDATA,
    output reg PWRITE,
    input wire PREADY
    );
    
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;
    
    reg [1:0] curr_state , next_state;
    
    //FSM: State transfer Logic
    always @(posedge clk or negedge reset_n)
        begin
            if(!reset_n)
                curr_state <= IDLE;
            else
                curr_state <= next_state;
        end
        
    //FSM: Next State Logic
    always @(*)
        begin
            case(curr_state)
                IDLE: begin
                    if(transfer)
                        next_state = SETUP;
                    else
                        next_state = IDLE;
                end
                
                SETUP : begin
                    next_state = ACCESS;
                    end
                ACCESS : begin
                    if(PREADY)
                        if(transfer)
                            next_state = SETUP;
                        else
                            next_state = IDLE;
                    else
                        next_state = ACCESS;
               end
               default: next_state = IDLE;
            endcase
        end
    
    //FSM : Output Logic
    always @(posedge clk or negedge reset_n)
        begin
            if(!reset_n)
                begin
                    PSELx <= 1'b0;
                    PENABLE <= 1'b0;
                    PADDR <= 32'b0;
                    PWDATA <= 32'b0;
                    PWRITE <= 1'b0;
                end
            else
                begin
                    case(next_state)
                        IDLE: 
                            begin
                                PSELx <= 1'b0;
                                PENABLE <=1'b0;
                            end
                
                        SETUP : 
                            begin
                                PSELx <= 1'b1;
                                PENABLE <= 1'b0;
                                PADDR <= addr;
                                PWDATA <= wdata;
                                PWRITE <= write;
                            end
                        ACCESS : 
                            begin
                                PSELx <= 1'b1;
                                PENABLE <=1'b1;
                            end
                    endcase
                end
        end
endmodule
