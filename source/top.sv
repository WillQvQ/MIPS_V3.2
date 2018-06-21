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
    logic       ihit,dhit,dataabort,instrabort,instrreq;
    logic       readval0,instrval0,writeval0;
    logic       datareq,readreq0,instrreq0,writereq0;
    logic[31:0] instradr,instr;
    logic[31:0] instradr0,instr0;
    logic[31:0] readdata0,writedata0,writeadr0,readadr0;
    mips    mips(clk,reset,
                datareq,dataadr,writedata,memwrite,
                instradr,instr,instrreq,
                dataabort,instrabort,readdata,
                pclow,checkra,checkr,regwriteW,writeregW);
    mem     mem(clk,reset,
                writereq0,readreq0,writeadr0,writedata0,
                instradr0,instr0,instrreq0,
                instrval0,readval0,writeval0,
                readadr0,readdata0,checkma,checkm);
    icache icache(clk,reset,
                instr0,instrval0,instrreq0,instradr0,
                instradr,instrreq,instr,ihit,instrabort);
    dcache dcache(clk,reset,
                writereq0,writeadr0,writedata0,writeval0,
                readreq0,readadr0,readdata0,readval0,
                dataadr[31:0],datareq,memwrite[0],writedata[31:0],readdata[31:0],dhit,dataabort);
    assign readdata[63:32] = 32'b0;
endmodule