`timescale 1ns/1ps

module tb;
    logic clk = 0;
    logic rst = 0;
    logic tx_enable = 0;
    logic [7:0] dout;

    always #5 clk = ~clk;
    
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end
 
    initial begin
        tx_enable = 0;
        repeat(5) @(posedge clk);
        tx_enable = 1;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    initial begin
        #20000;
        $finish();
    end
 
    simple_spi dut(clk, rst, tx_enable, dout);
 
endmodule
