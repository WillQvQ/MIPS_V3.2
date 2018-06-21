`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      朱笛
// Module Name:    dcache
// Create Date:    09:42 06/10/2014
//
// Design Name: 	 直接相连16KB dcache
//             n = 14, k = 5;
//             tag = 18'b[31:14] index = 9'b[13:5] offset = 5'b[4:2];
//
// Cache写策略:     写回法+写分配法
//	
//////////////////////////////////////////////////////////////////////////////////
module	dcache(
	// control signal
	input            clk,        // cache clk, the same as cpu
	input            reset,        	// cache reset
	// dram side(write)
	output         	dram_wr_req,    //	request writing data to dram
	output     [31:0]	dram_wr_addr,    //	write data address
	output reg	[31:0]	dram_wr_data,    //	write data
	input        	dram_wr_val,    //	write a word valid
	// dram side(read)
	output         	dram_rd_req,    //	request reading data from dram
	output     [31:0]	dram_rd_addr,    //	read data address
	input    	[31:0]	dram_rd_data,    //	read data
	input            dram_rd_val,    //	read a word valid
	// cpu side
	input    	[31:0]	cpu_addr,    	// cpu address
	input            data_req,    	// data request
	input            wren,        	// write/read
	input    	[31:0]	cpu_wr_data,    // write data come from cpu
	output    [31:0]	cpu_rd_data,    // read data and send to cpu
	output        	hit,        	// cache hit or miss
	output        	ram_abort    	// waiting for cache
	);
	
	parameter    BLOCK_SIZE	=	8;
	parameter    CPU_EXEC    =	0;
	parameter    WR_DRAM    =	1;
	parameter    RD_DRAM    =	2;
	
	
	reg    [1:0]    	state;            // FSM
	wire    [275:0]    D_SRAM_block;        // { val(1), dirty(1), tag(18), data(8*32) }
	reg    [31:0]    D_SRAM_word;        // one word of the block
	wire            dirty;            // dirty bit
	reg    [17:0]    tag_dly;            // data cache block tag bake up
	reg    [31:0]    cpu_addr_dly;        // cpu address bake up
	reg    [31:0]    cpu_wr_data_dly;    	// cpu write data bake up
	reg            cpu_wr_wait_flag;    	// cpu write wait flag
	wire            dram_wr_ready;        // dram write data ready
	wire            dram_rd_ready;        // dram read data ready
	reg            dram_rd_req_dly;    	// reading request delay
	reg    [31:0]    wr_counter,rd_counter;	// counter for block
	reg    [31:0]    dram_data_shift[7:0];	// 8*32 shift registers
    
	reg    [275:0]    D_SRAM[7:0];        // the data_cache storage space
	
	
	// phisical write/read address for dram
	assign	dram_wr_addr	=	{2'b0,tag_dly,cpu_addr_dly[13:5],3'b0};
	assign	dram_rd_addr	=	{2'b0,cpu_addr_dly[31:5],3'b0};
    
	// cpu/dram writes data_cache
	always@(posedge clk)
	begin
    if(reset)
        begin
            D_SRAM[0] <= 0;
            D_SRAM[1] <= 0;
            D_SRAM[2] <= 0;
            D_SRAM[3] <= 0;
            D_SRAM[4] <= 0;
            D_SRAM[5] <= 0;
            D_SRAM[6] <= 0;
            D_SRAM[7] <= 0;
        end
    else if(dram_rd_ready)	// dram write cache block
    begin
    	// add your codes here...
    	// 将主存的数据块写入D-Cache的某一数据块(xx_dly)
    	D_SRAM[cpu_addr_dly[13:5]]	<=	{1'b1, 1'b0, cpu_addr_dly[31:14],
                            dram_data_shift[7],dram_data_shift[6],
                            dram_data_shift[5],dram_data_shift[4],
                            dram_data_shift[3],dram_data_shift[2],
                            dram_data_shift[1],dram_data_shift[0]};
    end
    else if( hit & data_req & wren )
    begin
    	// wirte dirty bit
    	D_SRAM[cpu_addr[13:5]][274]	<=	1'b1;
    	// add your codes here...
    	// 正常命中情况下，CPU向D-Cache某个块的写入一个字
    	case(cpu_addr[4:2])
        0: D_SRAM[cpu_addr[13:5]][31:0]    <= cpu_wr_data;
        1: D_SRAM[cpu_addr[13:5]][63:32]   <= cpu_wr_data;
        2: D_SRAM[cpu_addr[13:5]][95:64]   <= cpu_wr_data;
        3: D_SRAM[cpu_addr[13:5]][127:96]  <= cpu_wr_data;
        4: D_SRAM[cpu_addr[13:5]][159:128] <= cpu_wr_data;
        5: D_SRAM[cpu_addr[13:5]][191:160] <= cpu_wr_data;
        6: D_SRAM[cpu_addr[13:5]][223:192] <= cpu_wr_data;
        7: D_SRAM[cpu_addr[13:5]][255:224] <= cpu_wr_data;
        default:D_SRAM[cpu_addr[13:5]] <= D_SRAM[cpu_addr[13:5]];
    	endcase
    end
    else if( cpu_wr_wait_flag & ( {dram_rd_req_dly,dram_rd_req} == 2'b10 ) )
    begin
    	// wirte dirty bit
    	D_SRAM[cpu_addr_dly[13:5]][274]	<=	1'b1;
    	// add your codes here...
    	// 发生缺失，将目标数据块搬入Cache后，使能CPU之前，向D-Cache写入原数据cpu_wr_data的备份（xx_dly）
    	case(cpu_addr_dly[4:2])
        0: D_SRAM[cpu_addr_dly[13:5]][31:0]    <= cpu_wr_data_dly;
        1: D_SRAM[cpu_addr_dly[13:5]][63:32]   <= cpu_wr_data_dly;
        2: D_SRAM[cpu_addr_dly[13:5]][95:64]   <= cpu_wr_data_dly;
        3: D_SRAM[cpu_addr_dly[13:5]][127:96]  <= cpu_wr_data_dly;
        4: D_SRAM[cpu_addr_dly[13:5]][159:128] <= cpu_wr_data_dly;
        5: D_SRAM[cpu_addr_dly[13:5]][191:160] <= cpu_wr_data_dly;
        6: D_SRAM[cpu_addr_dly[13:5]][223:192] <= cpu_wr_data_dly;
        7: D_SRAM[cpu_addr_dly[13:5]][255:224] <= cpu_wr_data_dly;
        default:D_SRAM[cpu_addr_dly[13:5]] <= D_SRAM[cpu_addr_dly[13:5]];
    	endcase
    end
	end

	// data_cache writes dram
	always@(posedge clk)
    if(reset)
    	dram_wr_data	<=	0;
    else if( dram_wr_req )
    begin
    	// add your codes here...
    	// 取出D-Cache中想要的块，逐字赋值给dram_wr_data写入主存
    	case(wr_counter[2:0])
        0:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][31:0];
        1:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][63:32];
        2:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][95:64];
        3:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][127:96];
        4:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][159:128];
        5:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][191:160];
        6:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][223:192];
        7:	dram_wr_data <= D_SRAM[cpu_addr_dly[13:5]][255:224];
        default:dram_wr_data	<= D_SRAM[cpu_addr_dly[13:5]][31:0];
    	endcase
    end
	
	// cpu read data_cache    
	assign	cpu_rd_data    =	D_SRAM_word;
	assign	D_SRAM_block	=	D_SRAM[cpu_addr[13:5]];
	
	always@(posedge clk)
	begin
    if(reset)
    	D_SRAM_word <= 0;
    else if( hit & data_req & ~wren )
    begin
    	// add your codes here...
    	// 从目标块D_SRAM_block中取出正确的字D_SRAM_word，用于CPU读
    	case(cpu_addr[4:2])
        0:	D_SRAM_word <= D_SRAM_block[31:0];
        1:	D_SRAM_word <= D_SRAM_block[63:32];
        2:	D_SRAM_word <= D_SRAM_block[95:64];
        3:	D_SRAM_word <= D_SRAM_block[127:96];
        4:	D_SRAM_word <= D_SRAM_block[159:128];
        5:	D_SRAM_word <= D_SRAM_block[191:160];
        6:	D_SRAM_word <= D_SRAM_block[223:192];
        7:	D_SRAM_word <= D_SRAM_block[255:224];
        default:D_SRAM_word <= D_SRAM_block[31:0];
    	endcase
    end
	end
	
	// set hit and dirty bit(if the block has been changed by cpu)
	assign	hit = D_SRAM_block[275] & (cpu_addr[31:14]==D_SRAM_block[273:256]);	
	assign	dirty	=	D_SRAM_block[274];

	// write/read data_cache miss, waiting...
	assign	ram_abort = ( dram_wr_req || dram_rd_req || dram_rd_req_dly );
	
	// data_cache state machine
	always@(posedge clk)
	begin
    if(reset)
    	state	<=	CPU_EXEC;
    else
    	case(state)
        CPU_EXEC:if( ~hit & dirty & data_req )	// dirty block write back to dram
            	state	<=	WR_DRAM;
            else if( ~hit & data_req )       // request new block from dram
            	state	<=	RD_DRAM;
            else
            	state	<=	CPU_EXEC;
        WR_DRAM:if(dram_wr_ready)
            	state	<=	RD_DRAM;
            else
            	state	<=	WR_DRAM;
        RD_DRAM:if(dram_rd_ready)
            	state	<=	CPU_EXEC;	
            else
            	state	<=	RD_DRAM;
        default:	state	<=	CPU_EXEC;	
    	endcase
	end
	
	// dram write/read request
	assign	dram_wr_req	=	( WR_DRAM == state );
	assign	dram_rd_req	=	( RD_DRAM == state );
	
	// dram read request delay
	always@(posedge clk)
    dram_rd_req_dly	<=	dram_rd_req;
	
	// cpu tag bake up
	always@(posedge clk)
	begin
    if( reset )
    	tag_dly	<=	0;
    else if( ( ~hit & dirty & data_req ) & ~dram_wr_req & ~dram_rd_req )
    	tag_dly	<=	D_SRAM_block[273:256];
	end

	// cpu address bake up
	always@(posedge clk)
	begin
    if( reset )
    	cpu_addr_dly	<=	0;
    else if( ( ~hit & dirty & data_req & wren ) | ( ~hit & data_req ) )
    	cpu_addr_dly	<=	cpu_addr;
	end
	
	// cpu write data bake up
	always@(posedge clk)
	begin
    if( reset )
    	cpu_wr_data_dly	<=	0;
    else if( ~hit & data_req & wren )
    	cpu_wr_data_dly	<=	cpu_wr_data;
	end
	
	// cpu write wait flag(wait until target block has been moved to cache)
	always@(posedge clk)
	begin
    if( reset )
    	cpu_wr_wait_flag	<=	0;
    else if( ~hit & data_req & wren )
    	cpu_wr_wait_flag	<=	1;
    else if( ~dram_wr_req & ~dram_rd_req )
    	cpu_wr_wait_flag	<=	0;
	end
	
	// block counter
	always@(posedge clk)
	begin
    if( reset )
    begin
    	wr_counter	<=	0;
    	rd_counter	<=	0;
    end
    else
    begin
    	if( dram_wr_ready  )
        wr_counter	<=	0;
    	else if( dram_wr_val & dram_wr_req )
        wr_counter	<=	wr_counter + 1'b1;
    	if( dram_rd_ready  )
        rd_counter	<=	0;
    	else if( dram_rd_val & dram_rd_req  )
        rd_counter	<=	rd_counter + 1'b1;
    end
	end
	
	// count to BLOCK_SIZE
	// add your codes here...
	// 对dram_wr_ready和dram_rd_ready进行assign赋值
	assign dram_wr_ready = (BLOCK_SIZE == wr_counter);
	assign dram_rd_ready = (BLOCK_SIZE == rd_counter);
	
	// dram data buffer
	always @(posedge clk)
	  begin
    // add your codes here...
    // 8*32的移位寄存器dram_data_shift
    if(reset)
    begin
    	dram_data_shift[0] <= 0;
    	dram_data_shift[1] <= 0;
    	dram_data_shift[2] <= 0;
    	dram_data_shift[3] <= 0;
    	dram_data_shift[4] <= 0;
    	dram_data_shift[5] <= 0;
    	dram_data_shift[6] <= 0;
    	dram_data_shift[7] <= 0;
    end
    else if(dram_rd_ready)
    begin
    	dram_data_shift[0] <= 0;
    	dram_data_shift[1] <= 0;
    	dram_data_shift[2] <= 0;
    	dram_data_shift[3] <= 0;
    	dram_data_shift[4] <= 0;
    	dram_data_shift[5] <= 0;
    	dram_data_shift[6] <= 0;
    	dram_data_shift[7] <= 0;
    end
    else if(dram_rd_val)
    begin
    	dram_data_shift[0] <= dram_data_shift[1];
    	dram_data_shift[1] <= dram_data_shift[2];
    	dram_data_shift[2] <= dram_data_shift[3];
    	dram_data_shift[3] <= dram_data_shift[4];
    	dram_data_shift[4] <= dram_data_shift[5];
    	dram_data_shift[5] <= dram_data_shift[6];
    	dram_data_shift[6] <= dram_data_shift[7];
    	dram_data_shift[7] <= dram_rd_data;
    end
	 end
	
	
endmodule
