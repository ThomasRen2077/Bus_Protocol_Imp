`timescale 1ns /1ps

module all_mod(
        input logic clk, rst, wr, rd,
        input logic rx,
        input logic [2:0] addr,
        input logic [7:0] din,
        output logic tx,
        output logic [7:0] dout
    );
 
    csr_t csr;
    logic baud_pulse, pen, thre, stb; 
 
    logic tx_fifo_pop;
    logic [7:0] tx_fifo_out;
    logic tx_fifo_push; 
 
    logic r_oe, r_pe, r_fe, r_bi;
    logic rx_fifo_push, rx_fifo_pop;
    logic tx_rst, rx_rst;
    logic [7:0] rx_fifo_out;
    logic [3:0] rx_fifo_threshold;
    logic [7:0] rx_out;
 
// UART Registers
    regs_uart uart_regs_inst (
        .clk (clk),
        .rst (rst),
        .wr_i (wr),
        .rd_i (rd),
        
        .rx_fifo_empty_i (),
        .rx_oe (),
        .rx_pe (r_pe),
        .rx_fe (r_fe),
        .rx_bi (r_bi),
        .rx_fifo_in(rx_fifo_out),

        .addr_i (addr),
        .din_i (din),
        .tx_push_o (tx_fifo_push),
        .rx_pop_o (rx_fifo_pop),
        .baud_out (baud_pulse),
        .tx_rst (tx_rst),
        .rx_rst (rx_rst),
        .rx_fifo_threshold (rx_fifo_threshold),
        .dout_o (dout),
        .csr_o (csr)
    );
 
// TX logic
    uart_tx_top uart_tx_inst (
        .clk (clk),
        .rst (rst),
        .baud_pulse (baud_pulse),
        .pen (csr.lcr.pen),
        .thre (1'b0),
        .stb (csr.lcr.stb),
        .sticky_parity (csr.lcr.stick_parity),
        .eps (csr.lcr.eps),
        .set_break (csr.lcr.set_break),
        .din (tx_fifo_out),
        .wls (csr.lcr.wls),
        .pop (tx_fifo_pop),
        .sreg_empty (),                     ///sreg empty ier
        .tx (tx)
    );
 
// TX FIFO
    fifo_top tx_fifo_inst (
        .rst (rst),
        .clk (clk),
        .en (csr.fcr.ena),
        .push_in (tx_fifo_push),
        .pop_in (tx_fifo_pop),
        .din (din),
        .dout (tx_fifo_out),
        .empty (),                          /// fifo empty ier
        .full (),
        .overrun (),
        .underrun (),
        .threshold (4'h0),
        .thre_trigger ()
    );
 
// RX LOGIC
 
    uart_rx_top uart_rx_inst (
        .clk (clk),
        .rst (rst),
        .baud_pulse (baud_pulse),
        
        .sticky_parity (csr.lcr.stick_parity),
        .eps (csr.lcr.eps),
        .pen (csr.lcr.pen),
        .wls (csr.lcr.wls),
        
        .rx (rx),

        .push (rx_fifo_push),
        .pe (r_pe),
        .fe (r_fe),
        .bi (r_bi),
        
        .data_out(rx_out)
    );
 
 
// RX FIFO
 
    fifo_top rx_fifo_inst (
        .rst (rst),
        .clk (clk),
        .en (csr.fcr.ena),
        .push_in (rx_fifo_push),
        .pop_in (rx_fifo_pop),
        .din (rx_out),
        .dout (rx_fifo_out),
        .empty (),                      /// fifo empty ier
        .full (),
        .overrun (),
        .underrun (),
        .threshold (rx_fifo_threshold),
        .thre_trigger ()
    );
 
 
 
endmodule
