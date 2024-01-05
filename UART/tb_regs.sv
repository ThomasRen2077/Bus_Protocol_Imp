`timescale 1ns/1ps

module uart_reg_tb;
    logic clk;
    logic rst;

    logic wr_i;
    logic rd_i;

    logic rx_fifo_empty_i;
    logic rx_oe;
    logic rx_pe;
    logic rx_fe;
    logic rx_bi;

    logic [7:0] rx_fifo_in;

    logic [2:0] addr_i;
    logic [7:0] din_i;

    logic tx_push_o;
    logic rx_pop_o;

    logic baud_out;

    logic tx_rst;
    logic rx_rst;

    logic [3:0] rx_fifo_threshold;

    logic [7:0] dout_o;
    logic csr_t csr_o;
    
    regs_uart dut (clk, rst, wr_i, rd_i, rx_fifo_empty_i, rx_oe, rx_pe, rx_fe, rx_bi, rx_fifo_in, addr_i, din_i, tx_push_o, rx_pop_o, baud_out, tx_rst, rx_rst, rx_fifo_threshold, dout_o, csr);
    
    always #5 clk = ~clk;
    
    initial begin
// Reset
        rst = 1;
        repeat(5) @(negedge clk);
        rst = 0; 

// Make DLAB 1
// Write DLAB of LCR (3H) to 1
        @(negedge clk);
        wr_i = 1;
        addr_i = 3'h3;
        din_i <= 8'b1000_0000;
    
// Update LSB of Divior Latch
        @(negedge clk);
        addr_i = 3'h0;
        din_i <= 8'b0000_1000;
    
// Update MSB of Divior latch
        @(negedge clk);
        addr_i = 3'h1;
        din_i <= 8'b0000_0001;  // 0000_0001_0000_1000
    
// Make DLAB 0 
// Write DLAB of LCR (3H) to 0
        @(negedge clk);
        addr_i = 3'h3;
        din_i <= 8'b0000_0000;

        #20;
        $finish();
    end
 
endmodule
