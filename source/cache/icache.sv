`timescale 1ns / 1ps
module    icache#(parameter BLOCK_SIZE = 8)(
    input   logic           clk,
    input   logic           reset,
    input   logic   [31:0]  mem_data,
    input   logic           mem_val,
    output  logic           mem_req,
    output  logic   [31:0]  mem_addr,
    input   logic   [31:0]  instraddr,
    input   logic           ins_req,        
    output  logic    [31:0] instr,
    output  logic           hit,
    output  logic           abort
    );
    
    ;
    logic   [31:0]  counter;
    logic   [31:0]  instraddr_delay;
    logic           ins_req_delay;
    logic           mem_req_delay;
    logic   [31:0]  mem_data_shift[7:0];
    logic   [275:0] icache_data0, icache_data1; 
    logic   [275:0] icache_data;               
    //276 = {val:1, tag:19, data:256}
    //从网上资料学习的设计方案，tag针对很大的内存，实际上我们板子上资源很少
    logic           hit0, hit1;
    logic   [275:0] wr_cache_data;
    logic           mem_data_ready;
    logic   [275:0] icache0[7:0], icache1[7:0];
    logic   [3:0]   LRU_c0[7:0], LRU_c1[7:0];
    
    assign wr_cache_data = {1'b1, instraddr_delay[31:13],
                                    mem_data_shift[7],mem_data_shift[6],
                                    mem_data_shift[5],mem_data_shift[4],
                                    mem_data_shift[3],mem_data_shift[2],
                                    mem_data_shift[1],mem_data_shift[0]};
    
    // icache 模块
    always@(posedge clk)
    begin
        if(reset)begin
            icache0[0] <= 276'b0; icache1[0] <= 276'b0;
            icache0[1] <= 276'b0; icache1[1] <= 276'b0;
            icache0[2] <= 276'b0; icache1[2] <= 276'b0;
            icache0[3] <= 276'b0; icache1[3] <= 276'b0;
            icache0[4] <= 276'b0; icache1[4] <= 276'b0;
            icache0[5] <= 276'b0; icache1[5] <= 276'b0;
            icache0[6] <= 276'b0; icache1[6] <= 276'b0;
            icache0[7] <= 276'b0; icache1[7] <= 276'b0;
        end
        else if(mem_data_ready)
            if(icache0[instraddr_delay[12:5]][275] && icache1[instraddr_delay[12:5]][275])
            begin
                if(LRU_c0[instraddr_delay[12:5]] > LRU_c1[instraddr_delay[12:5]])
                      icache0[instraddr_delay[12:5]] <= wr_cache_data;
                else icache1[instraddr_delay[12:5]] <= wr_cache_data;
            end
            else if(icache0[instraddr_delay[12:5]][275])
                icache1[instraddr_delay[12:5]] <= wr_cache_data;
            else
                icache0[instraddr_delay[12:5]] <= wr_cache_data;
    end
    
    //LRU 计数模块
    always @(posedge clk)
        if(reset) begin
            LRU_c0[0] <= 4'b0; LRU_c1[0] <= 4'b0;
            LRU_c0[1] <= 4'b0; LRU_c1[1] <= 4'b0;
            LRU_c0[2] <= 4'b0; LRU_c1[2] <= 4'b0;
            LRU_c0[3] <= 4'b0; LRU_c1[3] <= 4'b0;
            LRU_c0[4] <= 4'b0; LRU_c1[4] <= 4'b0;
            LRU_c0[5] <= 4'b0; LRU_c1[5] <= 4'b0;
            LRU_c0[6] <= 4'b0; LRU_c1[6] <= 4'b0;
            LRU_c0[7] <= 4'b0; LRU_c1[7] <= 4'b0;
        end
        else if(!abort && hit0)begin
            if({24'b0,instraddr_delay[12:5]} == 0 || {24'b0,instraddr[12:5]} == 0)
                LRU_c0[0] <=4'b0;
            else 
                LRU_c0[0] <= LRU_c0[0] + (LRU_c0[0]!=4'b1111);      
            if({24'b0,instraddr_delay[12:5]} == 1 || {24'b0,instraddr[12:5]} == 1)
                LRU_c0[1] <=4'b0;
            else 
                LRU_c0[1] <= LRU_c0[1] + (LRU_c0[1]!=4'b1111);      
            if({24'b0,instraddr_delay[12:5]} == 2 || {24'b0,instraddr[12:5]} == 2)
                LRU_c0[2] <=4'b0;
            else 
                LRU_c0[2] <= LRU_c0[2] + (LRU_c0[2]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 3 || {24'b0,instraddr[12:5]} == 3)
                LRU_c0[3] <=4'b0;
            else 
                LRU_c0[3] <= LRU_c0[3] + (LRU_c0[3]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 4 || {24'b0,instraddr[12:5]} == 4)
                LRU_c0[4] <=4'b0;
            else 
                LRU_c0[4] <= LRU_c0[4] + (LRU_c0[4]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 5 || {24'b0,instraddr[12:5]} == 5)
                LRU_c0[5] <=4'b0;
            else 
                LRU_c0[5] <= LRU_c0[5] + (LRU_c0[5]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 6 || {24'b0,instraddr[12:5]} == 6)
                LRU_c0[6] <=4'b0;
            else 
                LRU_c0[6] <= LRU_c0[6] + (LRU_c0[6]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 7 || {24'b0,instraddr[12:5]} == 7)
                LRU_c0[7] <=4'b0;
            else 
                LRU_c0[7] <= LRU_c0[7] + (LRU_c0[7]!=4'b1111);               
            LRU_c1[0] <= LRU_c1[0] + (LRU_c1[0]!=4'b1111);      
            LRU_c1[1] <= LRU_c1[1] + (LRU_c1[1]!=4'b1111);      
            LRU_c1[2] <= LRU_c1[2] + (LRU_c1[2]!=4'b1111);      
            LRU_c1[3] <= LRU_c1[3] + (LRU_c1[3]!=4'b1111);      
            LRU_c1[4] <= LRU_c1[4] + (LRU_c1[4]!=4'b1111);      
            LRU_c1[5] <= LRU_c1[5] + (LRU_c1[5]!=4'b1111);      
            LRU_c1[6] <= LRU_c1[6] + (LRU_c1[6]!=4'b1111);      
            LRU_c1[7] <= LRU_c1[7] + (LRU_c1[7]!=4'b1111);
        end
        else if(!abort && hit1)begin
            if({24'b0,instraddr_delay[12:5]} == 0 || {24'b0,instraddr[12:5]} == 0)
                LRU_c1[0] <=4'b0;
            else 
                LRU_c1[0] <= LRU_c1[0] + (LRU_c1[0]!=4'b1111);      
            if({24'b0,instraddr_delay[12:5]} == 1 || {24'b0,instraddr[12:5]} == 1)
                LRU_c1[1] <=4'b0;
            else 
                LRU_c1[1] <= LRU_c1[1] + (LRU_c1[1]!=4'b1111);      
            if({24'b0,instraddr_delay[12:5]} == 2 || {24'b0,instraddr[12:5]} == 2)
                LRU_c1[2] <=4'b0;
            else 
                LRU_c1[2] <= LRU_c1[2] + (LRU_c1[2]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 3 || {24'b0,instraddr[12:5]} == 3)
                LRU_c1[3] <=4'b0;
            else 
                LRU_c1[3] <= LRU_c1[3] + (LRU_c1[3]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 4 || {24'b0,instraddr[12:5]} == 4)
                LRU_c1[4] <=4'b0;
            else 
                LRU_c1[4] <= LRU_c1[4] + (LRU_c1[4]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 5 || {24'b0,instraddr[12:5]} == 5)
                LRU_c1[5] <=4'b0;
            else 
                LRU_c1[5] <= LRU_c1[5] + (LRU_c1[5]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 6 || {24'b0,instraddr[12:5]} == 6)
                LRU_c1[6] <=4'b0;
            else 
                LRU_c1[6] <= LRU_c1[6] + (LRU_c1[6]!=4'b1111);       
            if({24'b0,instraddr_delay[12:5]} == 7 || {24'b0,instraddr[12:5]} == 7)
                LRU_c1[7] <=4'b0;
            else 
                LRU_c1[7] <= LRU_c1[7] + (LRU_c1[7]!=4'b1111);        
            LRU_c0[0] <= LRU_c0[0] + (LRU_c0[0]!=4'b1111);      
            LRU_c0[1] <= LRU_c0[1] + (LRU_c0[1]!=4'b1111);      
            LRU_c0[2] <= LRU_c0[2] + (LRU_c0[2]!=4'b1111);      
            LRU_c0[3] <= LRU_c0[3] + (LRU_c0[3]!=4'b1111);      
            LRU_c0[4] <= LRU_c0[4] + (LRU_c0[4]!=4'b1111);      
            LRU_c0[5] <= LRU_c0[5] + (LRU_c0[5]!=4'b1111);      
            LRU_c0[6] <= LRU_c0[6] + (LRU_c0[6]!=4'b1111);      
            LRU_c0[7] <= LRU_c0[7] + (LRU_c0[7]!=4'b1111);
        end
    
    always @(posedge clk)
        if(reset)
            begin icache_data0 <= 276'b0; icache_data1 <= 276'b0; end
        else if( ins_req | ({mem_req_delay, mem_req}==2'b10) )
            begin icache_data0 <= icache0[instraddr[12:5]];
                    icache_data1 <= icache1[instraddr[12:5]];
            end

    // 输出信号处理
    assign  hit0 = icache_data0[275] & (instraddr_delay[31:13]==icache_data0[274:256]);
    assign  hit1 = icache_data1[275] & (instraddr_delay[31:13]==icache_data1[274:256]);
    assign  hit  = hit0 | hit1;
    assign  abort = (~hit & ins_req_delay) | mem_req | mem_req_delay;
    assign  mem_data_ready = (BLOCK_SIZE==counter);    
    
    assign  icache_data = hit1 ? icache_data1 : icache_data0;
    
    always@(*)
        case(instraddr_delay[4:2])
            0:    instr = icache_data[31:0];
            1:    instr = icache_data[63:32];
            2:    instr = icache_data[95:64];
            3:    instr = icache_data[127:96];
            4:    instr = icache_data[159:128];
            5:    instr = icache_data[191:160];
            6:    instr = icache_data[223:192];
            7:    instr = icache_data[255:224];
            default:instr = icache_data[31:0];
        endcase
    
    always@(posedge clk)
    begin
        if( reset )
            mem_req <= 0;
        else if( ~hit & ins_req_delay )
            mem_req <= 1;
        else if( mem_data_ready )
            mem_req <= 0;
    end
    
    
    assign mem_addr = {instraddr_delay[31:5],5'b0};
    
    // 延迟信号
    always@(posedge clk)
        mem_req_delay <= mem_req;

    always@(posedge clk)
    begin
        if( reset )
            ins_req_delay <= 0;
        else
            ins_req_delay <= ins_req;
    end
    
    always@(posedge clk)
    begin
        if( reset )
            instraddr_delay <= 0;
        else if( (ins_req_delay & ~hit) || mem_req )
            instraddr_delay <= instraddr_delay;
        else if(ins_req)
            instraddr_delay <= instraddr;
    end
    
    //统计读取的数据数量
    always@(posedge clk)
    begin
        if( reset )
            counter <= 0;
        else if( mem_data_ready )
            counter <= 0;
        else if( mem_val )
            counter <= counter + 1'b1;
    end
    
    // 从mem读取数据的位移寄存器
    always@(posedge clk)
    begin
        if( reset )
        begin
            mem_data_shift[0] <= 0;
            mem_data_shift[1] <= 0;
            mem_data_shift[2] <= 0;
            mem_data_shift[3] <= 0;
            mem_data_shift[4] <= 0;
            mem_data_shift[5] <= 0;
            mem_data_shift[6] <= 0;
            mem_data_shift[7] <= 0;
        end
        else if( mem_data_ready )
        begin
            mem_data_shift[0] <= 0;
            mem_data_shift[1] <= 0;
            mem_data_shift[2] <= 0;
            mem_data_shift[3] <= 0;
            mem_data_shift[4] <= 0;
            mem_data_shift[5] <= 0;
            mem_data_shift[6] <= 0;
            mem_data_shift[7] <= 0;
        end
        else if(mem_val)
        begin
            mem_data_shift[0] <= mem_data_shift[1];
            mem_data_shift[1] <= mem_data_shift[2];
            mem_data_shift[2] <= mem_data_shift[3];
            mem_data_shift[3] <= mem_data_shift[4];
            mem_data_shift[4] <= mem_data_shift[5];
            mem_data_shift[5] <= mem_data_shift[6];
            mem_data_shift[6] <= mem_data_shift[7];
            mem_data_shift[7] <= mem_data;
        end
    end

    
endmodule
