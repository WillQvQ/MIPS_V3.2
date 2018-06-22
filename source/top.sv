`timescale 1ns / 1ps

module top#(parameter N = 64)(
    input   logic           clk, reset,
    output  logic [N-1:0]   writedata, dataadr,
    output  logic [1:0]     memwrite,
    output  logic [N-1:0]   readdata,
    output  logic [7:0]     pclow,
    input   logic [4:0]     checkra0,
    output  logic [N-1:0]   checkr,
    input   logic [7:0]     checkma,
    output  logic [31:0]    checkm,
    output  logic           regwriteW,
    output  logic [4:0]     writeregW,
    output  logic [127:0]   tx_show,
    output  logic [4:0]     show_len
);
    logic [4:0] checkra;
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
    //演示部分
    assign checkra = writeregW;
    logic [7:0] clks;
    logic       instrreq_delay;
    initial clks = 8'b0;
    always@(posedge clk,posedge reset) 
		if(reset)
            instrreq_delay <= 0;
		else 
            instrreq_delay <= instrreq;
    always@(posedge clk,posedge reset) 
		if(reset)
            clks <= 8'b0;
		else 
            clks <= clks + 1;
    logic [7:0] abort;
    assign abort = {3'b0,(instrabort|instrreq_delay),3'b0,dataabort};
    always_ff @(posedge clk, posedge reset) begin
        if(reset)begin
            tx_show <= 128'd0;
            show_len <= 5'd2;
        end
        else if(writeval0) begin
            tx_show <= {clks,abort,16'h6666,dataadr[31:0],writeadr0,writedata0}; // 8+8+16+32+32+32 = 128
            show_len <= 5'd16;
        end
        else if(datareq & ~memwrite[0] & readval0) begin
            tx_show <= {clks,abort,16'h4444,dataadr[31:0],readadr0,readdata0}; // 8+8+16+32+32+32 = 128
            show_len <= 5'd16;
        end
        else if(datareq & ~memwrite[0]) begin
            tx_show <= {clks,abort,16'h3333,dataadr[31:0],readdata[31:0]}; // 8+8+16+32+32 = 96
            show_len <= 5'd12;
        end
        else if(datareq & memwrite[0]) begin
            tx_show <= {clks,abort,16'h5555,dataadr[31:0],writedata[31:0]}; // 8+8+16+32+32 = 96
            show_len <= 5'd12;
        end
        else if(writeregW!=0)begin
            tx_show <= {clks,abort,16'h7777,11'd0,writeregW,checkr[31:0]};// 8+8+16+16+32 = 80
            show_len <= 5'd10;
        end
        else if(instrval0)begin
            tx_show <= {clks,abort,16'h2222,instradr,instradr0,instr0};// 8+8+16+32+32+32 = 128
            show_len <= 5'd16;
        end
        else if(instrabort|instrreq_delay)begin
            tx_show <= {clks,abort,16'h1111,instradr,instr}; // 8+8+16+32+32 = 96
            show_len <= 5'd12;
        end
        else begin
            tx_show <= {clks,abort,16'h00};// 8+8+8+8 = 32
            show_len <= 5'd4;
        end
    end
endmodule