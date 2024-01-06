`timescale 1ns / 1ps

module uart_rx_top (
    input logic clk, 
    input logic rst,
    input logic baud_pulse,

//  LCR is used in RX
    input logic sticky_parity,
    input logic eps,
    input logic pen,
    input logic [1:0] wls,

    input logic rx,

    output logic push,
    output logic pe,            // parity error
    output logic fe,            // frame error
    output logic bi,
    
    output logic [7:0] data_out
);

// Detect a fall edge
    logic rx_reg = 1;
    logic fall_edge;

    always_ff @(posedge clk, posedge rst) begin
        if(rst) rx_reg <= 1;
        else    rx_reg <= rx;
    end

    assign fall_edge = ~ rx_reg;

// Set up Finite State Machine
    localparam STATE_IDLE = 3'b000;
    localparam STATE_STRT = 3'b001;
    localparam STATE_TRAN = 3'b010;
    localparam STATE_PARI = 3'b011;
    localparam STATE_STOP = 3'b100;

    logic [2:0] state_reg;
    logic [2:0] state_next;
    
    logic [4:0] count = '0;
    logic [2:0] bit_count = '0;
    logic pe_reg;                           

// State Transition Logic
    always_ff @( posedge clk ) begin
        if ( rst )
            state_reg <= STATE_IDLE;
        else
            state_reg <= state_next;
    end

    always_comb begin
        state_next = state_reg;
        if(baud_pulse) begin
            case(state_reg)
                STATE_IDLE: if(fall_edge)                                       state_next = STATE_STRT;
                STATE_STRT: if(count == 7 && rx)                                state_next = STATE_IDLE;
                            else if(count == 0)                                 state_next = STATE_TRAN;
                STATE_TRAN: if((bit_count == 0) && (count == 0) && pen)         state_next = STATE_PARI;
                            else if((bit_count == 0) && (count == 0) && ~pen)   state_next = STATE_STOP;
                STATE_PARI: if(count == 0)                                      state_next = STATE_STOP;
                STATE_STOP: if(count == 0)                                      state_next = STATE_IDLE;
                default:                                                        state_next = STATE_IDLE;
            endcase
        end
    end

// Update counter register
    always_ff@(posedge clk, posedge rst) begin
        if(rst)     count <= '0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_IDLE:     if(fall_edge)                     count <= 5'd15;
                STATE_STRT:     begin                             count <= count - 1;
                                if(count == 7 && rx)              count <= 5'd15;
                                else if(count == 0)               count <= 5'd15;
                                end
                STATE_TRAN:     begin                             count <= count - 1;
                                if(count == 0)                    count <= 5'd15;
                                end
                STATE_PARI:     begin                             count <= count - 1;
                                if(count == 0)                    count <= 5'd15;
                                end
                STATE_STOP:     begin                             count <= count - 1;
                                if(count == 0)                    count <= 5'd15;
                                end
                default:                                          count <= count;
            endcase
        end
    end

// Update bit_count register
    always_ff@(posedge clk, posedge rst) begin
        if(rst) bit_count <= '0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_STRT:   if(count == 0)                                bit_count <= {1'b1, wls};
                STATE_TRAN:   if(bit_count != 0 && (count == 0))            bit_count <= bit_count - 1;
            endcase
        end
    end    

// Update data_out
    always_ff@(posedge clk, posedge rst) begin
        if(rst) data_out <= '0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_TRAN:   begin
                    if(count == 7)  begin 
                        case(wls)
                        2'b00: data_out <= {3'b000, rx, data_out[4:1]}; 
                        2'b01: data_out <= {2'b00 , rx, data_out[5:1]}; 
                        2'b10: data_out <= {1'b0  , rx, data_out[6:1]}; 
                        2'b11: data_out <= {        rx, data_out[7:1]}; 
                        endcase
                    end
                end
            endcase
        end
    end

// compute parity
    always_ff@(posedge clk, posedge rst) begin
        if(rst) pe_reg <= '0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_TRAN:   begin
                    if(count == 0 && bit_count == 0)  begin 
                        case({sticky_parity, eps})
                            2'b00: pe_reg <= ~^{rx,data_out};       // odd parity -> pe : no. of 1's even
                            2'b01: pe_reg <= ^{rx,data_out};        // even parity -> pe : no. of 1's odd
                            2'b10: pe_reg <= ~rx;                   // parity should be 1 -> pe : parity is 0
                            2'b00: pe_reg <= rx;                    // parity should be 0 -> pe : parity is 1
                        endcase
                    end
                end
            endcase
        end
    end

    always_ff@(posedge clk, posedge rst) begin
        if(rst) pe <= '0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_PARI: if(count == 7)    pe <= pe_reg;
            endcase
        end
    end

// Detect whether there is a frame error
    always_ff @(posedge clk, posedge rst) begin
        if(rst) fe <= 0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_STOP: if(count == 7)    fe <= ~rx;
            endcase
        end
    end

// Update push 
    always_ff @(posedge clk, posedge rst) begin
        if(rst) push <= 0;
        else begin
            push <= 1'b0;
            if(baud_pulse) begin
                case(state_reg)
                    STATE_STOP: if(count == 7)    push <= 1'b1;
                endcase
            end
        end
    end


// Update bi
    assign bi = 0;

    
endmodule