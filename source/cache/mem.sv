`timescale 1ns / 1ps

module mem#(parameter N = 64, L = 128)(
    input   logic           clk, reset,
    input   logic           writereq,
    input   logic           readreq,
    input   logic [31:0]    writeadr, writedata,
    input   logic [31:0]    instradr,
    output  logic [31:0]    instr,
    input   logic           instrreq,
    output  logic           instrval,readval,writeval,
    input   logic [31:0]    readadr,
    output  logic [31:0]    readdata,
    input   logic [7:0]     checka,
    output  logic [31:0]    check
);
    logic [N-1:0]   RAM [L-1:0];
    logic [31:0]    word;
    logic [4:0]     instrcnt;
    logic [4:0]     readcnt;
    logic [4:0]     writecnt;
    logic [31:0]    instradr2;
    logic [31:0]    readadr2;
    logic [31:0]    writeadr2;
    assign instradr2= instradr[31:2] + instrcnt - 1;
    assign readadr2 = readadr[31:2] + readcnt - 1;
    assign writeadr2= writeadr[31:2] + writecnt - 1;
    initial begin
        instrcnt = 0;
        readcnt = 0;
        writecnt = 0;
        $readmemh("C:/Users/will131/Documents/workspace/MIPS_V3.2/memfile.dat",RAM);
    end
    always @(posedge clk)begin
        if(instrreq) begin
            if(instrcnt==0)begin
                instrcnt <= 1;
            end
            else if(instrcnt==9)begin
                instrcnt<= 0;
                instrval<= 0;
            end
            else begin
                instrval<= 1;
                instr   <= instradr2[0] ? RAM[instradr2[31:1]][31:0] : RAM[instradr2[31:1]][63:32]; 
                instrcnt<= instrcnt + 1;
            end 
        end
    end
    always @(posedge clk)begin
        if(readreq) begin
            if(readcnt==0)begin
                readcnt <= 1;
            end
            else if(readcnt==9)begin
                readcnt <= 0;
                readval <= 0;
            end
            else begin
                readval <= 1;
                readdata<= readadr2[0] ? RAM[readadr2[31:1]][31:0] : RAM[readadr2[31:1]][63:32]; 
                readcnt <= readcnt + 1;
            end 
        end
    end    
    always @(posedge clk)begin
        if(writereq) begin
            if(writecnt==0)begin
                writecnt <= 1;
            end
            else if(writecnt==9)begin
                writecnt <= 0;
                writeval <= 0;
            end
            else begin
                writeval<= 1;
                writecnt<= writecnt + 1;
                if(writeadr2[0])
                    RAM[writeadr2[31:1]][31:0]   <= writedata;
                else
                    RAM[writeadr2[31:1]][63:32]  <= writedata;                
            end 
        end
    end

endmodule