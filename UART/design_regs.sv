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
  } fcr_t; 
 
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

// DLSB, Least Significant byte of divisor Latch
// If wr = 1, addr = 0 and dlab = 1, write to dlsb
    div_t dl;
    logic wr_dlsb;
    assign wr_dlsb = wr_i & (addr_i == 3'b000) & (csr.lcr.dlab);

    always_ff @(posedge clk) begin
        if(wr_dlsb)     dl.dlsb <= din_i;
    end

// DMSB, Most Significant byte of divisor Latch
// If wr = 1, addr = 1 and dlab = 1, write to dmsb
    logic wr_dmsb;
    assign wr_dmsb = wr_i & (addr_i == 3'b001) & (csr.lcr.dlab);

    always_ff @(posedge clk) begin
        if(wr_dmsb)     dl.dmsb <= din_i;
    end

// Detect update of Divisor Latch
    logic dl_updated;
    always_ff @ (posedge clk) begin
        dl_updated <= wr_dlsb | wr_dmsb;
    end

// Generate Baud_pulse
// Set counter;
    logic [15:0] baud_counter;
    always_ff @(posedge clk, posedge rst) begin
        if(rst)                                     baud_counter <= '0;
        else if(dl_updated | (baud_counter == 0))   baud_counter <= {dl.dmsb, dl.dlsb};
        else                                        baud_counter <= baud_counter - 1;
    end

// Pulse when counter reaches 0 and divior is not 0
    always @(posedge clk) begin
        baud_out <= (| dl) & (baud_counter == 0); 
    end

// FIFO Control Register (FCR)
// If wr = 1, addr = 2, write to FCR
    logic wr_fcr;
    assign wr_fcr = wr_i & (addr_i == 3'h2);

    always_ff @(posedge clk, posedge rst) begin
        if(rst)             csr.fcr <= '0;
        else if(wr_fcr) begin
            csr.fcr.rx_trigger <= din_i[7:6];
            csr.fcr.dma_mode   <= din_i[3];
            csr.fcr.tx_rst     <= din_i[2];
            csr.fcr.rx_rst     <= din_i[1];
            csr.fcr.ena        <= din_i[0];
        end
        else begin
            csr.fcr.tx_rst     <= 1'b0;
            csr.fcr.rx_rst     <= 1'b0;
        end
    end

    assign tx_rst = csr.fcr.tx_rst;
    assign rx_rst = csr.fcr.rx_rst;

// Based on Value of rx_trigger, set threshold count for rx fifo
    always_comb begin
        if(csr.fcr.ena == 1'b0) begin
            rx_fifo_threshold = 4'd0;
        end
        else
            case(csr.fcr.rx_trigger)
            2'b00: rx_fifo_threshold = 4'd1;
            2'b01: rx_fifo_threshold = 4'd4;
            2'b10: rx_fifo_threshold = 4'd8;
            2'b11: rx_fifo_threshold = 4'd14;
            endcase
    end

// Line Control Register (LCR) -> defines format of transmitted data
// If wr = 1, addr = 3, write to LCR
    logic wr_lcr;
    assign wr_lcr = wr_i & (addr_i == 3'h3);

    always_ff @(posedge clk, posedge rst) begin
        if(rst)             csr.lcr <= '0;
        else if (wr_lcr)    csr.lcr <= din_i;
    end

// If rd = 1, addr = 3, read LCR
    logic [7:0] lcr_temp;
    logic read_lcr; 
    assign read_lcr = rd_i & (addr_i == 3'h3);

    always_ff @( posedge clk ) begin
        if(read_lcr)        lcr_temp <= csr.lcr;
    end

// Line Status Register (LSR)
    always@(posedge clk, posedge rst) begin
        if(rst)     csr.lsr <= 8'h60;                           // both fifo and shift register are empty thr_e = 1 , t_empt = 1  // 0110 0000
        else begin
                    csr.lsr.dr <=  ~rx_fifo_empty_i;
                    csr.lsr.oe <=   rx_oe;
                    csr.lsr.pe <=   rx_pe;
                    csr.lsr.fe <=   rx_fe;
                    csr.lsr.bi <=   rx_bi;
        end
    end
 
// If rd = 1, addr = 5, read LSR
    logic [7:0] lsr_temp; 
    logic read_lsr;
    assign read_lsr = rd_i & (addr_i == 3'h5); 
    
    always@(posedge clk) begin
        if(read_lsr)        lsr_temp <= csr.lsr; 
    end

// Scratch pad register (SCR), provide temporary storage for our data without affecting any operation
// If wr = 1, addr = 7, write to SCR
    logic wr_scr;
    assign wr_scr = wr_i & (addr_i == 3'h7);

    always_ff @(posedge clk, posedge rst) begin
        if(rst)             csr.scr <= '0;
        else if (wr_scr)    csr.scr <= din_i;
    end
 
// If rd = 1, addr = 7, read SCR
    logic [7:0] scr_temp; 
    logic read_scr;
    assign read_scr = rd_i & (addr_i == 3'h7); 
    
    always@(posedge clk) begin
        if(read_scr)        scr_temp <= csr.scr; 
    end

// Read Register
    always_ff @(posedge clk) begin
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