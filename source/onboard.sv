`timescale 1ns / 1ps

module onboard(
    input   logic 			reset,clken,quick,show,high1low,clkon,
	input	logic	[1:0]	getone,
    input   logic 			CLK100MHZ,
    input   logic   [7:0]	addr,
    output  logic 	[6:0]	seg,
    output  logic 	[7:0]	an,
    output  logic 	[7:0]	clks,
    input   logic           rx_pin_in,
    output  logic           tx_pin_out
);
	logic clk,CLK380,CLK48,CLK04,CLK1_6,clkrun;
	
	logic [7:0] tx_buf;

	logic [63:0]writedata64, dataadr64;
	logic [31:0]writedata, dataadr;
	logic [1:0] memwrite;
	logic [63:0]readdata64;
	logic [31:0]readdata;
	logic [2:0]cnt;
	logic [3:0]digit;   
	logic [31:0]data;   
	logic [7:0] pclow;
    logic [7:0] checka;
    logic [31:0]check;
    logic [63:0]check64;
    logic [31:0]showdata;
    logic [31:0]memdata;
	logic [4:0] wreg,sreg;
	logic [7:0] rx_data;
	logic [7:0] clkshow;
	logic [127:0] tx_show;
	logic [4:0] show_len;
    logic       we;
	clkdiv clkdiv(CLK100MHZ,CLK380,CLK48,CLK1_6,CLK0_4);
	assign sreg = we ? wreg:addr[4:0];
	assign readdata = readdata64[31:0];
	assign dataadr = dataadr64[31:0];
	assign check = high1low ? check64[63:32] : check64[31:0];
	assign writedata = high1low ? writedata64[63:32] : writedata64[31:0];
	assign clkrun = quick ? CLK1_6:CLK0_4;
	assign clk = clkrun & clken;
	top top(clk,reset,writedata64,dataadr64,memwrite,readdata64,pclow,sreg,check64,addr,memdata,we,wreg,tx_show,show_len);
	assign clkshow = clkon ? clks:{sreg[3:0],2'b0,memwrite};
	assign data = show ? showdata:{clks,pclow,3'b0,wreg,check64[7:0]};//disp<->pclow
	initial cnt=2'b0;
    initial clks = 8'b0;
    always@(posedge clk,posedge reset) 
		if(reset)clks <= 8'b0;
		else clks <= clks + 1;
	always@(posedge CLK380)  
		begin  
			case(getone)
				0:showdata = check;
				1:showdata = memdata;
				2:showdata = dataadr;
				3:showdata = writedata;
			endcase
			an=8'b11111111;   
			an[cnt]=0;  
			case(cnt)   
				0:digit=data[3:0];
				1:digit=data[7:4];
				2:digit=data[11:8];
				3:digit=data[15:12];
				4:digit=data[19:16];
				5:digit=data[23:20];
				6:digit=data[27:24];
				7:digit=data[31:28];  
			endcase  
			case(digit)  
				0:seg=   7'b1000000;  
				1:seg=   7'b1111001;  
				2:seg=   7'b0100100;       
				3:seg=   7'b0110000;  
				4:seg=   7'b0011001;  
				5:seg=   7'b0010010;  
				6:seg=   7'b0000010;  
				7:seg=   7'b1111000;  
				8:seg=   7'b0000000;  
				9:seg=   7'b0010000;  
				10:seg=  7'b0001000;
				11:seg=  7'b0000011;
				12:seg=  7'b1000110;
				13:seg=  7'b0100001;
				14:seg=  7'b0000110;
				15:seg=  7'b0001110;
				default:seg=7'b1111110;  
			endcase 
			cnt <=cnt+1'b1; 
		end  
	logic rst_n;
	assign rst_n = ~reset;	
	
	uart_top uart_top(CLK100MHZ,clk,rst_n,tx_pin_out,rx_pin_in,tx_show,show_len,rx_data);
endmodule  