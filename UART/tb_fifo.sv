`timescale 1ns/1ps

module fifo_tb;
    logic clk;
    logic rst;
    logic en;
    logic push_in;
    logic pop_in;
    logic [7:0] din;
    logic [7:0] dout;
    logic empty;
    logic full;
    logic overrun;
    logic underrun;
    logic [3:0] threshold;
    logic thre_trigger;

    initial begin
        rst = 1'b0;
        clk = 1'b0;
        en = 1'b0;
        din = '0;
    end

    fifo_top dut_fifo (clk, rst, en, push_in, pop_in, din, dout, empty, full, overrun, underrun, threshold, thre_trigger);

    always #5 clk = ~ clk;

    initial begin
        rst = 1'b1;
        repeat(5) @(negedge clk);
// 20 writes
        for(int i = 0; i<20 ; i++) begin
            rst = 1'b0;
            push_in = 1'b1;
            din = $urandom();
            pop_in = 1'b0;
            en = 1'b1;
            threshold = 4'ha;
            @(negedge clk);
        end

// 20 reads
        for(int i = 0; i<20 ; i++) begin
            rst = 1'b0;
            push_in = 1'b0;
            din = '0;
            pop_in = 1'b1;
            en = 1'b1;
            threshold = 4'ha;
            @(negedge clk);
        end
    end
endmodule