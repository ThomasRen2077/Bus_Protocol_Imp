`timescale 1ns/1ps

module fsm_spi (
    input logic clk,
    input logic rst,
    input logic tx_enable,
    output logic mosi,
    output logic cs,
    output logic sclk
);
    typedef enum logic [1:0] {IDLE = 0, START_TX = 1, TX_DATA = 2, END_TX = 3} state_type;
    state_type state, next_state;

    logic [7:0] din = 8'hef;
    logic spi_sclk = 0;
    logic [2:0] ccount = 0;
    integer count = 0;

    always@(posedge clk) begin
        if(!rst && tx_enable) begin
            ccount <= (ccount < 3) ?   ccount + 1 : '0;
        end
    end

    always@(posedge clk) begin
        if(!rst && tx_enable) begin
            if(ccount == 3)         spi_sclk = ~spi_sclk;
        end
    end

////////
    always @(*) begin
        next_state = state;
        case(state)
            IDLE:       next_state = (!rst && tx_enable)?                   TX_DATA  :  IDLE;
            TX_DATA:    next_state = (count == 8)?                          IDLE     :  TX_DATA;
            default:    next_state = IDLE;
        endcase
    end

    always @(posedge sclk) begin
        if(rst)     state <= IDLE;
        else        state <= next_state;
    end

    always @(posedge sclk) begin
        case(state)
            TX_DATA:            mosi <= (count < 8)? din[7 - count] : 1'b0;
            default:            mosi <= 1'b0;
        endcase
    end

    assign cs = (state == IDLE || state == END_TX);

    always @(posedge sclk) begin
        case(state)
            IDLE:              count <= 0;      
            TX_DATA:           count <= (count < 8) ? count + 1 : 0;
            default :          count <= 0;
        endcase
    end

    assign sclk = spi_sclk;

endmodule

module spi_slave (
    input logic sclk,
    input logic mosi,
    input logic cs,
    output logic [7:0] dout,
    output logic done
);

    integer count = 0;
    typedef enum logic { IDLE = 0, SAMPLE = 1 } state_type;
    state_type state, next_state;

    logic [7:0] data = 0;

    always@(*) begin
        next_state = state;
        case(state)
            IDLE:       next_state = cs? IDLE : SAMPLE;
            SAMPLE:     next_state = (count == 8)? IDLE : SAMPLE;
            default:    next_state = IDLE;
        endcase
    end

    always@(negedge sclk) begin
        state <= next_state;
    end

    always@(negedge sclk) begin
        case(state)
            IDLE:   count <= '0;
            SAMPLE: count <= (count == 8)? '0 : count + 1;
            default:count <= '0;
        endcase
    end

    always@(negedge sclk) begin
        case(state)
            IDLE:   done <= '0;
            SAMPLE: done <= (count == 8);
            default:done <= '0;
        endcase
    end

    always@(negedge sclk) begin
        case(state)
            IDLE:   data <= data;
            SAMPLE: data <= (count == 8)? data : {data[6:0], mosi};
            default:data <= '0;
        endcase
    end

    assign dout = data;
endmodule

module simple_spi(
    input logic clk,
    input logic rst,
    input logic tx_enable,
    output logic [7 : 0] dout,
    output logic done
);
    logic mosi;
    logic ss;
    logic sclk;
    fsm_spi     spi_m(clk, rst, tx_enable, mosi, ss, sclk);
    spi_slave   spi_s(sclk, mosi, ss, dout, done);
endmodule