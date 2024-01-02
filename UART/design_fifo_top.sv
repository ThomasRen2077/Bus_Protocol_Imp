`timescale 1ns/1ps

module fifo_top (
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic push_in,
    input  logic pop_in,

    input  logic [7:0] din,
    output logic [7:0] dout,

    output logic empty,
    output logic full,
    output logic overrun,
    output logic underrun,

    input  logic [3:0] threshold,
    output logic thre_trigger
);
    logic [7:0] mem [16];
    logic [3:0] waddr = '0;

    logic push, pop;

// empty flag
    logic empty_t;
    always_ff@(posedge clk, posedge rst) begin
        if(rst) empty_t <= 1'b0;
        else begin
            case({push, pop})
                2'b01: empty_t <= (~|(waddr) | ~en ); // empty flag is set when FIFO is not enabled or the pop addr is '0;
                2'b10: empty_t <= 1'b0;
                default: empty_t <= empty_t;
            endcase
        end
    end

// full flag
    logic full_t;
    always_ff@(posedge clk, posedge rst) begin
        if(rst) full_t <= 1'b0;
        else begin
            case({push, pop})
                2'b10: full_t <= (&(waddr) | ~en ); // full flag is set when FIFO is not enabled or the push addr is '1;
                2'b01: full_t <= 1'b0;
                default: full_t <= full_t;
            endcase
        end
    end

// push, pop
    assign push = push_in & ~full_t;
    assign pop = pop_in & ~empty_t;

// read fifo -> always the first element
    assign dout = mem [0];

// write pointer update
    always_ff@(posedge clk, posedge rst) begin
        if(rst) waddr <= 4'b0;
        else begin
            case({push, pop})
                2'b10: if(waddr != 4'hf && full_t == 1'b0)  waddr <= waddr + 1;
                       else                                 waddr <= waddr;
                2'b01: if(waddr != 4'h0 && empty_t == 1'b0) waddr <= waddr - 1;
                       else                                 waddr <= waddr;
                       default:                             waddr <= waddr;
            endcase
        end
    end

// memory update
    always_ff@(posedge clk, posedge rst) begin
        if(rst) begin
            for(int i = 0; i < 16; i++) begin
                mem[i] <= '0;
            end
        end
        else begin
            case({push, pop})
                2'b01: begin
                    for(int i = 0; i < 15; i++) begin
                        mem[i] <= mem[i + 1];
                    end
                    mem[15] <= 8'h00;
                end
                2'b10: mem[waddr] <= din;
                2'b11: begin
                    for(int i = 0; i < 15; i++) begin
                        mem[i] <= mem[i + 1];
                    end
                    mem[15] <= 8'h00;
                    mem[waddr - 1] <= din;
                end
                default: mem <= mem;
            endcase
        end
    end

// underrun, read on empty fifo
    logic underrun_t;
    always_ff@(posedge clk, posedge rst) begin
        if(rst)                     underrun_t <= 1'b0;
        else if(pop_in & empty_t)   underrun_t <= 1'b1;
        else                        underrun_t <= 1'b0;
    end

// overrun, push on full fifo
    logic overrun_t = 1'b0;
    always_ff@(posedge clk, posedge rst) begin
        if(rst)                     overrun_t <= 1'b0;
        else if(push_in & full_t)   overrun_t <= 1'b1;
        else                        overrun_t <= 1'b0;
    end

// threshold 
    logic thre_t;
    always_ff@(posedge clk, posedge rst) begin
        if(rst)             thre_t <= 1'b0;
        else if(push ^ pop) thre_t <= (waddr >= threshold) ? 1'b1 : 1'b0;
    end

// assign pins
    assign empty = empty_t;
    assign full = full_t;
    assign overrun = overrun_t;
    assign underrun = underrun_t;
    assign thre_trigger = thre_t;
    
endmodule