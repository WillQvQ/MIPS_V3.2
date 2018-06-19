`timescale 1ns / 1ps

module memblock#(parameter N = 64, L = 128)(
    input   logic           clk, 
    input   logic           blockwrite,
    input   logic           blockread,
    input   logic [31:0]    instraddr,
    input   logic [31:0]    readaddr, 
    input   logic [31:0]    writeaddr, 
    input   logic [255:0]   writeblock,
    output  logic [255:0]   readblock,
    output  logic [255:0]   instrblock,
    output  logic           ready
);
    logic [N-1:0] RAM [L-1:0];
    logic [7:0]   cnt;
    initial ready = 1;
    initial cnt = 8'b0;
    initial $readmemh("C:/Users/will131/Documents/workspace/MIPS_V3.2/memfile.dat",RAM);
    assign readblock = {RAM[readaddr*4],RAM[readaddr*4+1],RAM[readaddr*4+2],RAM[readaddr*4+3]};
    assign instrblock = {RAM[instraddr*4],RAM[instraddr*4+1],RAM[instraddr*4+2],RAM[instraddr*4+3]};
    always @(negedge clk)begin
        if((cnt==0) & blockread)begin
            if(blockwrite)
                {RAM[writeaddr*4],RAM[writeaddr*4+1],RAM[writeaddr*4+2],RAM[writeaddr*4+3]} <= writeblock;
            ready <= 0;
            cnt <= 8'd5;
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