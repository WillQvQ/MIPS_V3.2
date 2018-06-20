`timescale 1ns / 1ps

module top#(parameter N = 64)(
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
    input   logic [7:0]     rx_data,
    output  logic [31:0]    rx_check,
    output  logic [31:0]    rx_checkh,
    output  logic [31:0]    rx_checkl
);
    logic hit,abort,instrreq,instrreq0,val;
    logic [31:0]instradr,instr;
    logic [31:0]instradr0,instr0;
    mips mips(clk,reset,dataadr,writedata,memwrite,instradr,instr,instrreq,hit,abort,readdata,pclow,checkra,checkr,regwriteW,writeregW);
    mem mem(clk,reset,memwrite,dataadr,writedata,instradr0,instr0,instrreq0,val,abort0,readdata,checkma,checkm);
    // assign get = 1;
    icache icache(clk,reset,instr0,val,instrreq0,instradr0,instradr,instrreq,instr,hit,abort);
    // dcache dcache(clk,reset,t11,t322,t323,t14,instrreq0,instradr0,instr0,get,instradr,instrreq,0,32'b0,instr,hit,abort);

endmodule