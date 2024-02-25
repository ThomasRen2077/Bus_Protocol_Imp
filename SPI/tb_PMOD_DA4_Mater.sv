`timescale 1ns/1ps
module tb;
 
    logic clk100mhz = 0;
    logic cs;
    logic mosi;
    logic sclk;
    logic st_wrt = 0;
    logic [11:0] data_in = 0;
    logic done;
    
    top dut (clk100mhz, cs, mosi, sclk, st_wrt, data_in, done);
    
    always#5 clk100mhz = ~clk100mhz;
    
    initial begin
        st_wrt = 1;
        data_in = 12'b101010101010;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    initial begin
        #200000;
        $finish();
    end

 
endmodule
