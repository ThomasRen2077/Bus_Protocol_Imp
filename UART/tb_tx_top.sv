////////////////////////////////////////////////////
`timescale 1ns / 1ps

module uart_tx_tb;
 
    logic clk = 0; 
    logic rst;
    logic baud_pulse;
    logic thre;

//  LCR is used in TX
    logic set_break;
    logic sticky_parity;
    logic eps;
    logic pen;
    logic stb;
    logic [1:0] wls;

    logic [7:0] din;

    logic pop;
    logic sreg_empty;
    logic tx;

// Instaniate tx module
    uart_tx_top tx_dut (clk, rst, baud_pulse, thre, set_break, sticky_parity, eps, pen, stb, wls, din, pop, sreg_empty, tx);
 

// Set up clk
    always #5 clk =~clk;

// Set up reset
    initial begin
        rst = 1'b1; 
        repeat(5)@(negedge clk);
        rst = 0;
    end

// Set up signals
    initial begin
        repeat(10)@(negedge clk);
        rst = 0;
        clk = 0;
        baud_pulse = 0;
        thre = 0;
        set_break = 0;
        sticky_parity = 0;  //sticky parity is off
        eps = 1;            //even parity
        pen = 1'b1;         //parity enabled
        stb = 1 ;           // stop will be for 2-bit duration
        wls = 2'b11;        //data width : 8-bits
        din = $urandom;
    end

    
    integer count = 5;
    
    always@(posedge clk) begin
        if(rst == 0) begin
            if(count  != 0) begin
                count <= count - 1;
                baud_pulse <= 1'b0;
            end
            else begin
                count <= 5;
                baud_pulse <= 1'b1;
            end
        end
    end
 
endmodule
