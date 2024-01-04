`timescale 1ns / 1ps

module uart_tx_top (
    input logic clk, 
    input logic rst,
    input logic baud_pulse,
    input logic thre,

//  LCR is used in TX
    input logic set_break,
    input logic sticky_parity,
    input logic eps,
    input logic pen,
    input logic stb,
    input logic [1:0] wls,

    input logic [7:0] din,

    output logic pop,
    output logic sreg_empty,
    output logic tx 
);

// Set up Finite State Machine
    localparam STATE_IDLE = 2'b00;
    localparam STATE_STRT = 2'b01;
    localparam STATE_TRAN = 2'b10;
    localparam STATE_PARI = 2'b11;
    logic [1:0] state_reg;
    logic [1:0] state_next;
    
    logic [4:0] count = 5'd15;
    logic [2:0] bit_count = '0;
    logic [7:0] shift_reg;

    logic tx_data;
    logic next_pop;
    logic next_sreg_empty;

    logic d_parity;
    logic parity_out;


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
                STATE_IDLE: if((~thre) && (count == 0))                         state_next = STATE_STRT;
                STATE_STRT: if(count == 0)                                      state_next = STATE_TRAN;
                STATE_TRAN: if((bit_count == 0) && (count == 0) && pen)         state_next = STATE_PARI;
                            else if((bit_count == 0) && (count == 0) && ~pen)   state_next = STATE_IDLE;
                STATE_PARI: if(count == 0)                                      state_next = STATE_IDLE;
                default:                                                        state_next = STATE_IDLE;
            endcase
        end
    end

// Update counter register
    always_ff@(posedge clk, posedge rst) begin
        if(rst)     count <= 0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_IDLE:     if(count != 0)                    count <= count - 1;
                                else                              count <= 5'd15;
                STATE_STRT:     if(count != 0)                    count <= count - 1;
                                else                              count <= 5'd15;
                STATE_TRAN:     if(count != 0)                    count <= count - 1;
                                else if(bit_count != 0)           count <= 5'd15;
                                else if(pen)                      count <= 5'd15;
                                else                              count <= (~stb)? 5'd15 : (wls == 2'b00) ? 5'd23 : 5'd31;
                STATE_PARI:     if(count != 0)                    count <= count - 1;
                                else                              count <= (~stb)? 5'd15 : (wls == 2'b00) ? 5'd23 : 5'd31;
                default:                                          count <= count;
            endcase
        end
    end

// Update bit_count register
    always@(posedge clk, posedge rst) begin
        if(rst) bit_count <= '0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_IDLE:   if((~thre) && (count == 0))                   bit_count <= {1'b1, wls};
                STATE_TRAN:   if(bit_count != 0 && (count == 0))            bit_count <= bit_count - 1;
            endcase
        end
    end    

// Update shift_register
    always_ff@(posedge clk, posedge rst) begin
        if(rst) shift_reg <= 'x;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_IDLE:   if((~thre) && (count == 0))                   shift_reg <= din;
                STATE_STRT:   if(count == 0)                                shift_reg  <= (shift_reg >> 1);
                STATE_TRAN:   if(bit_count != 0 && (count == 0))            shift_reg  <= (shift_reg >> 1);
            endcase
        end
    end    


// Update tx
    always_ff@(posedge clk, posedge rst) begin
        if(rst) tx <= 1'b1;
        else    tx <= tx_data & ~set_break;
    end    

// Update pop
    always_ff@(posedge clk, posedge rst) begin
        if(rst) pop <= 1'b0;
        else    pop <= next_pop;
    end    

// Update sreg_empty
    always_ff@(posedge clk, posedge rst) begin
        if(rst) sreg_empty <= 1'b0;
        else    sreg_empty <= next_sreg_empty;
    end    


// Control Signal Table
    task cs
    (
        input logic           cs_tx_data,
        input logic           cs_pop,
        input logic           cs_sreg_empty
    );
    begin
        tx_data = cs_tx_data;
        next_pop = cs_pop;
        next_sreg_empty = cs_sreg_empty;
    end
    endtask

    always_comb begin
        cs( tx, pop, sreg_empty);

        if(baud_pulse) begin
            case(state_reg)
            //                                                                  tx_data             next_pop            next_sreg_empty
                STATE_IDLE: if((~thre) && (count == 0))                         cs( 1'b0,               1'b1,               1'b0     );
                STATE_STRT: if(count == 0)                                      cs( shift_reg[0],       1'b0,               1'b0     );
                STATE_TRAN: if((bit_count != 0) && (count == 0))                cs( shift_reg[0],       1'b0,               1'b0     );
                            else if((bit_count == 0) && (count == 0) && pen)    cs( parity_out,         1'b0,               1'b1     );
                            else if((bit_count == 0) && (count == 0) && ~pen)   cs( 1'b1,               1'b0,               1'b1     );
                STATE_PARI: if(count == 0)                                      cs( 1'b1,               1'b0,               1'b1     );
            endcase
        end
    end

// compute parity
    always_comb begin
        case(wls)
            2'b00: d_parity = ^din[4:0];
            2'b01: d_parity = ^din[5:0];
            2'b10: d_parity = ^din[6:0];
            2'b11: d_parity = ^din[7:0];             
        endcase
    end

   always_ff @(posedge clk, posedge rst) begin
        if(rst)    parity_out <= 0;
        else if(baud_pulse) begin
            case(state_reg)
                STATE_TRAN: begin
                    case({sticky_parity, eps})
                        2'b00: parity_out <= ~d_parity;
                        2'b01: parity_out <= d_parity;
                        2'b10: parity_out <= 1'b1;
                        2'b11: parity_out <= 1'b0;
                    endcase
                end
            endcase
        end
   end

    
endmodule