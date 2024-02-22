`timescale 1ns / 1ps
 
module top(); 
    reg ready = 1;
    integer spi_edges = 0;   
    reg start = 0;
    reg [1:0] clk_count = 0;
    reg spi_l = 0, spi_t = 0;
    reg sclk = 1;
    reg clk = 0;
    reg cpol = 1;
    
    always #5 clk = ~clk;
    
    initial begin
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
    end
    
    
    always@(posedge clk)    begin
        if(start == 1'b1) begin
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
 
 
endmodule
