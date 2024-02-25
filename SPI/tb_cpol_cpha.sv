`timescale 1ns / 1ps
 
module top(); 
    logic ready = 1;
    integer spi_edges = 0;   
    logic start = 0;
    logic [1:0] clk_count = 0;
    logic spi_l = 0, spi_t = 0;
    logic sclk = 1;
    logic clk = 0;
    logic cpol = 1;
    
    always #5 clk = ~clk;
    
    initial begin
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
    end

    logic start_t = 0;
 
    always@(posedge clk)    begin
        start_t <= start;
    end

    
    
    always@(posedge clk)    begin
        if(start_t == 1'b1) begin
            ready     <= 1'b0;
            spi_edges <= 16; 
            sclk      <= cpol;
        end
        else if (spi_edges > 0) begin
            spi_l <= 1'b0;
            spi_t <= 1'b0;
            
            if(clk_count == 1) begin
                spi_l <= 1'b1;
                sclk  <= ~sclk;
                spi_edges <= spi_edges - 1;
                clk_count <= clk_count + 1;
            end
            else if (clk_count == 3) begin
                spi_t <= 1'b1;
                sclk  <= ~sclk;
                spi_edges <= spi_edges - 1;
                clk_count <= clk_count + 1;
            end 
            else begin
                clk_count <= clk_count + 1;
            end
        end
        else begin
            ready <= 1'b1;
            spi_l <= 1'b0;
            spi_t <= 1'b0;
            sclk <= cpol;
        end         
    end        



    logic mosi = 0;
    logic cpha = 1;
    logic [7:0] tx_data = 8'b10101010;
    logic [2:0] bit_count = 3'b111;
    logic ready_t = 0;
    logic [7:0] tx_data_t;
    logic [2:0] state = 0;
    logic cs = 1;
    integer count = 0;

    parameter A = 0, B = 1, C = 2, D = 3, E = 4;


    always@(posedge clk) begin
        case(state)
        A: begin
            if(start)   begin
                if(!cpha) begin
                    state <= 1;
                    cs    <= 1'b0; 
                end
                else begin
                    state <= 3;
                    cs    <= 1'b0; 
                end
            end
            else    state <= 0;
        end
    
    
        B: begin
            if(count < 3) begin
                count <= count + 1;
                state <= 1;
                mosi <= tx_data[bit_count];
            end
            else begin 
                count <= 0;
                if(bit_count != 0) begin
                        bit_count <= bit_count - 1;
                        state <= 1;
                end
                else    state <= 2;
            end
        end
        
        C: begin
            cs <= 1'b1;
            bit_count <= 3'b111;
            state <= 0;
            mosi <= 1'b0;
        end
        
        
        D: begin
            tate <= 4;
        end
        
        E: begin
            state <= 1;
        end
        endcase
    end

// Slave
    
    logic [7:0] rx_data = 7'h0;
    integer r_count = 0;
    
    always@(posedge sclk) begin
        if(cs == 0) begin
            if(r_count < 8)
            begin
                rx_data <= {rx_data[6:0],mosi};
                r_count  <= r_count + 1;
            end 
        end
        else    r_count <= 8'h0;
    end
 
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    initial begin
        #20000;
        $finish();
    end

endmodule
