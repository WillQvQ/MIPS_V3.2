`timescale 1ns / 1ps

module mem1#(parameter N = 64, L = 128)(
    input   logic           clk, reset,
    input   logic [1:0]     memwrite,
    input   logic           datareq,
    input   logic [N-1:0]   dataadr, writedata,
    input   logic [31:0]    instradr,
    output  logic [31:0]    instr,
    input   logic           instrreq,
    output  logic           dataabort,instrabort,
    output  logic [N-1:0]   readdata,
    input   logic [7:0]     checka,
    output  logic [31:0]    check
);
    logic [N-1:0]   RAM [L-1:0];
    logic [31:0]    word;
    logic [4:0]     instrcnt;
    logic [4:0]     datacnt;
    initial begin
        instrabort <= 1;
        instr <= 32'b0;
        instrcnt <= 0;
        datacnt <= 0;
        $readmemh("C:/Users/will131/Documents/workspace/MIPS_V3.2/memfile.dat",RAM);
    end
    always @(posedge clk)begin
        if(instrreq) begin
            case(instrcnt)
                5'd1:begin 
                    instrcnt <= instrcnt + 1;
                end
                5'd2:begin 
                    instrcnt <= instrcnt + 1;
                    instrabort <= 1;
                end
                5'd20:begin
                    instrcnt<=0;
                    instr <= instradr[2] ? RAM[instradr[31:3]][31:0] : RAM[instradr[31:3]][63:32]; 
                    instrabort <= 0;
                end
                default :instrcnt <= instrcnt + 1;
            endcase        
        end
    end
    always @(negedge clk)begin
        if(datareq) begin
            if(datacnt==0)begin
                dataabort <= 1;
                datacnt <= 1;
            end
            else if(datacnt==20)begin
                datacnt <= 0;
                dataabort <= 0;
            end
            else begin
                readdata <= {32'b0,word}; 
                datacnt <= datacnt + 1;
            end 
        end
    end
    assign check = checka[0] ? RAM[checka[7:1]][31:0] : RAM[checka[7:1]][63:32];
    assign word = dataadr[2] ? RAM[dataadr[N-1:3]][31:0] : RAM[dataadr[N-1:3]][63:32];
    always @(posedge clk)
        begin
        if (memwrite==3)//D
            RAM[dataadr[N-1:3]] <= writedata;
        else if (memwrite==2) //B
                case (dataadr[2:0])
                    3'b111:  RAM[dataadr[N-1:3]][7:0]   <= writedata[7:0];
                    3'b110:  RAM[dataadr[N-1:3]][15:8]  <= writedata[7:0];
                    3'b101:  RAM[dataadr[N-1:3]][23:16] <= writedata[7:0];
                    3'b100:  RAM[dataadr[N-1:3]][31:24] <= writedata[7:0];
                    3'b011:  RAM[dataadr[N-1:3]][39:32] <= writedata[7:0];
                    3'b010:  RAM[dataadr[N-1:3]][47:40] <= writedata[7:0];
                    3'b001:  RAM[dataadr[N-1:3]][55:48] <= writedata[7:0];
                    3'b000:  RAM[dataadr[N-1:3]][63:56] <= writedata[7:0];
                endcase
        else if (memwrite==1) //W
            case (dataadr[2])
                    0:  RAM[dataadr[N-1:3]][63:32]  <= writedata[31:0];
                    1:  RAM[dataadr[N-1:3]][31:0]   <= writedata[31:0];
                endcase
        end 
endmodule