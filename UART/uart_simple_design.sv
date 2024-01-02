`timescale 1ns /1ps

module uart_top
#(
    parameter clk_freq = 1000000,
    parameter baud_rate = 9600
) (
    input clk,rst, 
    input rx,
    input [7:0] dintx,
    input newd,
    output tx, 
    output [7:0] doutrx,
    output donetx,
    output donerx
);
    
    uarttx #(clk_freq, baud_rate) utx (clk, rst, newd, dintx, tx, donetx);   
    
    uartrx #(clk_freq, baud_rate) rtx (clk, rst, rx, donerx, doutrx);    
    
endmodule


module uarttx
#(
    parameter  clk_freq = 1000000,
    parameter  baud_rate = 9600
) (
    input  logic clk, 
    input  logic rst,
    input  logic newd,
    input  logic [7:0] tx_data,
    output logic tx,
    output logic donetx
);


// Set up Transmitter Clk
    localparam  clkcount = (clk_freq / baud_rate);
    integer     count = 0;
    logic       uclk = 0;

    always_ff @( posedge clk ) begin
        if(count < clkcount/2) count <= count + 1;
        else begin
            count <= 0;
            uclk <= ~uclk;
        end
    end


// Set up Finite State Machine
    logic [7:0] din;
    integer bit_counts = 0;
    localparam STATE_IDLE = 2'b00;
    localparam STATE_STRT = 2'b01;
    localparam STATE_TRAN = 2'b10;
    localparam STATE_DONE = 2'b11;
    logic [1:0] state_reg;
    logic [1:0] state_next;

// State Transition Logic
    always @( posedge uclk ) begin
        if ( rst )
            state_reg <= STATE_IDLE;
        else
            state_reg <= state_next;
    end

    always_comb begin
        state_next = state_reg;
        case(state_reg)
            STATE_IDLE: if(newd)            state_next = STATE_STRT;
            STATE_STRT:                     state_next = STATE_TRAN;
            STATE_TRAN: if(bit_counts == 7) state_next = STATE_DONE;
            STATE_DONE:                     state_next = STATE_IDLE;
            default:                        state_next = STATE_IDLE;
        endcase
    end

// Control Signal Table
    task cs
    (
        input logic           cs_tx,
        input logic           cs_done_tx
    );
    begin
        tx = cs_tx;
        donetx = cs_done_tx;
    end
    endtask

    always_comb begin
        case(state_reg)
        //                              tx                  donetx
            STATE_IDLE:             cs( 1'b1,               1'b0);
            STATE_STRT:             cs( 1'b0,               1'b0);
            STATE_TRAN:             cs( din[bit_counts],    1'b0);
            STATE_DONE:             cs( 1'b1,               1'b1);
        endcase
    end

// Data Transitions Under Different States
    always_ff @(posedge uclk) begin
        case(state_reg)
            STATE_IDLE: begin 
                bit_counts <= 0;
                din <= din;
                if(newd) din <= tx_data;
            end
            STATE_STRT:begin
                bit_counts <= 0;
                din <= din;
            end
            STATE_TRAN: begin
                bit_counts <= bit_counts + 1;
                din <= din;
            end
            STATE_DONE: begin
                bit_counts <= 0;
                din <= din;
            end
        endcase
    end
    
endmodule

module uartrx
#(
    parameter  clk_freq = 1000000,
    parameter  baud_rate = 9600
) (
    input  logic clk, 
    input  logic rst,
    input  logic rx,
    output logic done,
    output logic [7:0] rx_data
);


// Set up Receiver Clk
    localparam  clkcount = (clk_freq / baud_rate);
    integer     count = 0;
    logic       uclk = 0;

    always_ff @( posedge clk ) begin
        if(count < clkcount/2) count <= count + 1;
        else begin
            count <= 0;
            uclk <= ~uclk;
        end
    end


// Set up Finite State Machine
    integer bit_counts = 0;
    localparam STATE_IDLE = 2'b00;
    localparam STATE_STRT = 2'b01;
    localparam STATE_DONE = 2'b10;
    logic [1:0] state_reg;
    logic [1:0] state_next;

// State Transition Logic
    always @( posedge uclk ) begin
        if ( rst )
            state_reg <= STATE_IDLE;
        else
            state_reg <= state_next;
    end

    always_comb begin
        state_next = state_reg;
        case(state_reg)
            STATE_IDLE: if(rx == 1'b0)      state_next = STATE_STRT;
            STATE_STRT: if(bit_counts == 7) state_next = STATE_DONE;
            STATE_DONE:                     state_next = STATE_IDLE;
            default:                        state_next = STATE_IDLE;
        endcase
    end

// Control Signal Table
    task cs
    (
        input logic           cs_done
    );
    begin
        done = cs_done;
    end
    endtask

    always_comb begin
        case(state_reg)
        //                              donetx
            STATE_IDLE:             cs( 1'b0);
            STATE_STRT:             cs( 1'b0);
            STATE_DONE:             cs( 1'b1);
            default:                cs( 1'b0);
        endcase
    end

// Data Transitions Under Different States
    always_ff @(posedge uclk) begin
        case(state_reg)
            STATE_IDLE: begin 
                bit_counts <= 0;
                rx_data <= '0;
            end
            STATE_STRT: begin
                bit_counts <= bit_counts + 1;
                rx_data <= {rx, rx_data[7:1]};
            end
            STATE_DONE: begin
                bit_counts <= 0;
                rx_data <= rx_data;
            end
        endcase
    end
    
endmodule