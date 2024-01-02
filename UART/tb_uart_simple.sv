`timescale 1ns / 1ps

module tb();
  
    logic clk;
    logic rst;
    logic rx;
    logic [7:0] dintx;
    logic newd;
    logic tx; 
    logic [7:0] doutrx;
    logic donetx;
    logic donerx;
  
    uart_top #(1000000, 9600) dut (clk, rst, rx, dintx, newd, tx, doutrx, donetx, donerx);

 
    initial begin
      clk = 1'b0;
    end
  
    always #5 clk = ~ clk;  
  
    
    logic [7:0] rx_data = 0;
    logic [7:0] tx_data = 0;
    
    initial begin
        rst = 1;
        repeat(5) @(negedge dut.utx.uclk);
        rst = 0;
    
        for(int i = 0 ; i < 10; i++) begin
            rst = 0;
            newd = 1;
            dintx = $urandom();
        
            wait(tx == 0);
            @(negedge dut.utx.uclk);
        
            for(int j = 0; j < 8; j++) begin
                @(negedge dut.utx.uclk);
                tx_data = {tx,tx_data[7:1]};
            end
            
            @(posedge donetx);
        end
    
        for(int i = 0 ; i < 10; i++) begin
            rst = 0;
            newd = 0;
        
            rx = 1'b0;
            @(negedge dut.utx.uclk);
        
            for(int j = 0; j < 8; j++) begin
                @(negedge dut.utx.uclk);
                rx = $urandom;
                rx_data = {rx, rx_data[7:1]};
            end
        
            @(posedge donerx);
            @(negedge dut.utx.uclk);
            @(negedge dut.utx.uclk);
            rx_data = 8'b0;
        end
    
    
    end
    
 
 
endmodule
