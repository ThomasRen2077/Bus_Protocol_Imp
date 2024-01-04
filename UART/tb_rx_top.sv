`timescale 1ns / 1ps

module uart_rx_tb;
 
    logic clk;
    logic rst;
    logic baud_pulse;

//  LCR is used in RX
    logic sticky_parity;
    logic eps;
    logic pen;
    logic [1:0] wls;

    logic rx;

    logic push;
    logic pe;            // parity error
    logic fe;            // frame error
    logic bi;
    
    uart_rx_top rx_dut (clk, rst, baud_pulse, sticky_parity, eps, pen, wls, rx, push, pe, fe, bi);
    
    initial begin
        clk = 0;
        rst = 0;
        baud_pulse = 0;
        sticky_parity = 0;
        eps = 0;
        pen = 1'b1;
        wls = 2'b11;
        rx = 1;
    end
    
    always #5 clk =~clk;
    
    logic [7:0] rx_reg = 8'h45;
    
    initial begin
        rst = 1'b1;
        repeat(5)@(negedge clk);
        
        /////start
        rst = 0;
        rx = 1'b0;
        repeat(16) @(posedge baud_pulse);

        ///////send 8 bytes data
        for(int i = 0; i < 8; i++) begin
            rx = rx_reg[i];
            repeat(16) @(posedge baud_pulse);
        end

        /////generate parity
        rx = ~^rx_reg;
        repeat(16) @(posedge baud_pulse);

        ///// generate stop
        rx = 1;
        repeat(16) @(posedge baud_pulse);
    end
    
    
    ////////////////
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
