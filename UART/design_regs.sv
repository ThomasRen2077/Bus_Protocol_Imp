`timescale 1ns/1ps

// Structs of registers
// FIFO Control Register
   typedef struct packed {
    logic [1:0] rx_trigger;        //Receive trigger
    logic [1:0] reserved;          //reserved
    logic       dma_mode;          //DMA mode select
    logic       tx_rst;            //Transmit FIFO Reset
    logic       rx_rst;            //Receive FIFO Reset
    logic       ena;               //FIFO enabled
  } fcr_t; //FIFO Control Register
 
// Line Control Register
   typedef struct packed {
    logic       dlab;              //Divisor Latch Access bit
    logic       set_break;         //Break Control
    logic       stick_parity;      //Sticky Parity Enable  
    logic       eps;               //Even parity or Odd Parity
    logic       pen;               //Parity Enable
    logic       stb;               //Stop bit length
    logic [1:0] wls;               //Word Length Status
  } lcr_t;   
  
// Line Status Register   
typedef struct packed {
    logic       rx_fifo_error;     //RX FIFO Error
    logic       temt;              //Transmitter Emtpy
    logic       thre;              //Transmitter Holding Register Empty
    logic       bi;                //Break Interrupt
    logic       fe;                //Framing Error
    logic       pe;                //Parity Error
    logic       oe;                //Overrun Error
    logic       dr;                //Data Ready
  } lsr_t; 
  
// Struct to hold all registers
 typedef struct {
 fcr_t       fcr;                  //FIFO Control Register
 lcr_t       lcr;                  //Line Control Register
 lsr_t       lsr;                  //Line Status Register
 logic [7:0] scr;                  //Scratch Pad Register
 } csr_t;
  
// Divisor Latch
 typedef struct packed {
    logic [7:0] dmsb;               //Divisor Latch MSB
    logic [7:0] dlsb;               //Divisor Latch LSB
  } div_t;


module regs_uart(
    input logic clk,
    input logic rst,

    input logic wr_i,
    input logic rd_i,

    input logic rx_fifo_empty_i,
    input logic rx_oe,
    input logic rx_pe,
    input logic rx_fe,
    input logic rx_bi,

    input logic [7:0] rx_fifo_in,

    input logic [2:0] addr_i,
    input logic [7:0] din_i,

    output logic tx_push_o,
    output logic rx_pop_o,

    output logic baud_out,

    output logic tx_rst,
    output logic rx_rst,

    output logic [3:0] rx_fifo_threshold,

    output logic [7:0] dout_o,
    output logic csr_t csr_o
);

// Instantiate control status registers
    csr_t csr;
    assign csr_o = csr;

// THR: temporary buffer for storing data to be transmitted serially (Use TX FIFO here)
// If wr = 1, addr = 0 and dlab = 0, store data to TX FIFO
    assign tx_push_o = wr_i & (addr_i == 3'b000) & (~csr.lcr.dlab);

// RHR: temporary buffer for holding the date received by the shift register serially (rx_data here)
// If rd = 1, addr = 0 and dlab = 0, read data from TX FIFO
    assign rx_pop_o = rd_i & (addr_i == 3'b000) & (~csr.lcr.dlab);
    logic [7:0] rx_data;

    always_ff @(posedge clk) begin
        if(rx_pop_o) begin
            rx_data <= rx_fifo_in;
        end
    end

// Registers Output Data
    always@(posedge clk) begin
        case(addr_i)
            0: dout_o <= csr.lcr.dlab ? dl.dlsb : rx_data;      // Least Significant byte of divisor Latch or Receive Hold Register depends on Divisor Latch Access bit of LCR
            1: dout_o <= csr.lcr.dlab ? dl.dmsb : 8'h00;        // Most Significant byte of divisor Latch or Interrupt Enable Register(not implemented) depends on Divisor Latch Access bit of LCR
            2: dout_o <= 8'h00;                                 // Interrupt Identification Register
            3: dout_o <= lcr_temp;                              // Line Control Register
            4: dout_o <= 8'h00;                                 // Modem Control Register(not implemented)
            5: dout_o <= lsr_temp;                              // Line Status Register
            6: dout_o <= 8'h00;                                 // Modem Status Register(not implemented)
            7: dout_o <= scr_temp;                              // Scratch Pad Register
            default: ;
        endcase
    end

endmodule