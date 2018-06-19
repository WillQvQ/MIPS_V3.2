`timescale 1ns / 1ps

module memblock#(parameter N = 64, L = 128)(
    input   logic           clk, 
    input   logic           blockwrite,
    input   logic           blockread,
    input   logic [31:0]   blockaddr, 
    input   logic [255:0]   writeblock,
    output  logic [255:0]   readblock,
    output  logic           ready
);
    logic [N-1:0] RAM [L-1:0];
    logic [7:0]   cnt;
    initial ready = 1;
    initial cnt = 8'b0;
    initial $readmemh("C:/Users/will131/Documents/workspace/MIPS_V3.2/memfile.dat",RAM);
    assign readblock = {RAM[blockaddr*4],RAM[blockaddr*4+1],RAM[blockaddr*4+2],RAM[blockaddr*4+3]};
    always @(negedge clk)begin
        if((cnt==0) & blockread)begin
            ready <= 0;
            cnt <= 8'd20;
        end
        else if ((cnt==0) & blockwrite) begin
            {RAM[blockaddr*4],RAM[blockaddr*4+1],RAM[blockaddr*4+2],RAM[blockaddr*4+3]} <= writeblock;
        end
        else if(cnt!=0)begin
            if(cnt==1)begin
                ready <= 1;
                cnt <= 0;
            end
            else cnt <= cnt - 1;
        end
    end 

endmodule