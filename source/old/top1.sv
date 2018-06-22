`timescale 1ns / 1ps

module top1#(parameter N = 64)(
    input   logic           clk, reset,
    output  logic [N-1:0]   writedata, dataadr,
    output  logic [1:0]     memwrite,
    output  logic [N-1:0]   readdata,
    output  logic [7:0]     pclow,
    input   logic [4:0]     checkra,
    output  logic [N-1:0]   checkr,
    input   logic [7:0]     checkma,
    output  logic [31:0]    checkm,
    output  logic           regwriteW,
    output  logic [4:0]     writeregW,
    output  logic [127:0]   tx_show,
    output  logic [4:0]     show_len
);
    logic hit,instrabort,dataabort,instrreq,instrreq0,val,datareq;
    logic [31:0]instradr,instr;
    mips mips(clk,reset,datareq,dataadr,writedata,memwrite,instradr,instr,instrreq,dataabort,instrabort,readdata,pclow,checkra,checkr,regwriteW,writeregW);
    mem1 mem(clk,reset,memwrite,datareq,dataadr,writedata,instradr,instr,instrreq,dataabort,instrabort,readdata,checkma,checkm);

endmodule