`timescale 1ns / 1ps

module top#(parameter N = 64)(
    input   logic           clk, reset,
    output  logic [N-1:0]   writedata, dataadr,
    output  logic [1:0]     memwrite,
    output  logic [N-1:0]   readdata,
    output  logic [7:0]     pclow,
    input   logic [4:0]     checkra,
    output  logic [N-1:0]   checkr,
    output  logic           regwriteW,
    output  logic [4:0]     writeregW,
    input   logic [7:0]     rx_data,
    output  logic [31:0]    rx_check,
    output  logic [31:0]    instr
);
    logic dword,memread;
    logic ready;
    logic [31:0] instradr;
    mips mips(clk,reset,dataadr,writedata,memwrite,instradr,instr,dword,memread,readdata,pclow,checkra,checkr,regwriteW,writeregW,ready);
    cache cache(clk,dword,memread,memwrite,dataadr,writedata,instradr,instr,readdata,ready,rx_data,rx_check);

endmodule