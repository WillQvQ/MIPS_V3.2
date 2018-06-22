`timescale 1ns / 1ps
module    icache(
    input   logic           clk,
    input   logic           reset,
    input   logic   [31:0]  mem_data,
    input   logic           mem_val,
    output  logic           mem_req,
    output  logic   [31:0]  mem_addr,
    input   logic   [31:0]  instraddr,
    input   logic           ins_req,        
    output  logic   [31:0]  instr,
    output  logic           hit,
    output  logic           abort_out
    );
    
    parameter BLOCK_SIZE = 8;

    logic   [31:0]  counter;
    logic   [31:0]  instraddr_delay;
    logic           ins_req_delay;
    logic           mem_req_delay;
    logic   [31:0]  mem_data_shift[7:0];
    logic   [280:0] block_data0, block_data1; 
    logic   [280:0] block_data;
    //{val:1, tag:24, data:256}
    logic   [2:0]   block_id,block_id_delay;
    logic           hit0, hit1;
    logic   [280:0] wr_cache_data;
    logic           mem_data_ready;
    logic   [280:0] icache0[7:0], icache1[7:0];
    logic   [3:0]   LRU_c0[7:0], LRU_c1[7:0];
    assign  block_id = instraddr[7:5];
    assign  block_id_delay = instraddr_delay[7:5];
    assign  wr_cache_data = {1'b1, instraddr_delay[31:8],
                                    mem_data_shift[7],mem_data_shift[6],
                                    mem_data_shift[5],mem_data_shift[4],
                                    mem_data_shift[3],mem_data_shift[2],
                                    mem_data_shift[1],mem_data_shift[0]};
    
    // icache 模块
    always@(posedge clk)
    begin
        if(reset)begin
            icache0[0] <= 281'b0; icache1[0] <= 281'b0;
            icache0[1] <= 281'b0; icache1[1] <= 281'b0;
            icache0[2] <= 281'b0; icache1[2] <= 281'b0;
            icache0[3] <= 281'b0; icache1[3] <= 281'b0;
            icache0[4] <= 281'b0; icache1[4] <= 281'b0;
            icache0[5] <= 281'b0; icache1[5] <= 281'b0;
            icache0[6] <= 281'b0; icache1[6] <= 281'b0;
            icache0[7] <= 281'b0; icache1[7] <= 281'b0;
        end
        else if(mem_data_ready)
            if(icache0[block_id_delay][280] && icache1[block_id_delay][280])
            begin
                if(LRU_c0[block_id_delay] > LRU_c1[block_id_delay])
                      icache0[block_id_delay] <= wr_cache_data;
                else icache1[block_id_delay] <= wr_cache_data;
            end
            else if(icache0[block_id_delay][280])
                icache1[block_id_delay] <= wr_cache_data;
            else
                icache0[block_id_delay] <= wr_cache_data;
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
            if(block_id_delay == 0 || block_id == 0)
                LRU_c0[0] <=4'b0;
            else 
                LRU_c0[0] <= LRU_c0[0] + (LRU_c0[0]!=4'b1111);      
            if(block_id_delay == 1 || block_id == 1)
                LRU_c0[1] <=4'b0;
            else 
                LRU_c0[1] <= LRU_c0[1] + (LRU_c0[1]!=4'b1111);      
            if(block_id_delay == 2 || block_id == 2)
                LRU_c0[2] <=4'b0;
            else 
                LRU_c0[2] <= LRU_c0[2] + (LRU_c0[2]!=4'b1111);       
            if(block_id_delay == 3 || block_id == 3)
                LRU_c0[3] <=4'b0;
            else 
                LRU_c0[3] <= LRU_c0[3] + (LRU_c0[3]!=4'b1111);       
            if(block_id_delay == 4 || block_id == 4)
                LRU_c0[4] <=4'b0;
            else 
                LRU_c0[4] <= LRU_c0[4] + (LRU_c0[4]!=4'b1111);       
            if(block_id_delay == 5 || block_id == 5)
                LRU_c0[5] <=4'b0;
            else 
                LRU_c0[5] <= LRU_c0[5] + (LRU_c0[5]!=4'b1111);       
            if(block_id_delay == 6 || block_id == 6)
                LRU_c0[6] <=4'b0;
            else 
                LRU_c0[6] <= LRU_c0[6] + (LRU_c0[6]!=4'b1111);       
            if(block_id_delay == 7 || block_id == 7)
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
            if(block_id_delay == 0 || block_id == 0)
                LRU_c1[0] <=4'b0;
            else 
                LRU_c1[0] <= LRU_c1[0] + (LRU_c1[0]!=4'b1111);      
            if(block_id_delay == 1 || block_id == 1)
                LRU_c1[1] <=4'b0;
            else 
                LRU_c1[1] <= LRU_c1[1] + (LRU_c1[1]!=4'b1111);      
            if(block_id_delay == 2 || block_id == 2)
                LRU_c1[2] <=4'b0;
            else 
                LRU_c1[2] <= LRU_c1[2] + (LRU_c1[2]!=4'b1111);       
            if(block_id_delay == 3 || block_id == 3)
                LRU_c1[3] <=4'b0;
            else 
                LRU_c1[3] <= LRU_c1[3] + (LRU_c1[3]!=4'b1111);       
            if(block_id_delay == 4 || block_id == 4)
                LRU_c1[4] <=4'b0;
            else 
                LRU_c1[4] <= LRU_c1[4] + (LRU_c1[4]!=4'b1111);       
            if(block_id_delay == 5 || block_id == 5)
                LRU_c1[5] <=4'b0;
            else 
                LRU_c1[5] <= LRU_c1[5] + (LRU_c1[5]!=4'b1111);       
            if(block_id_delay == 6 || block_id == 6)
                LRU_c1[6] <=4'b0;
            else 
                LRU_c1[6] <= LRU_c1[6] + (LRU_c1[6]!=4'b1111);       
            if(block_id_delay == 7 || block_id == 7)
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
            begin block_data0 <= 281'b0; block_data1 <= 281'b0; end
        else if( ins_req | ({mem_req_delay, mem_req}==2'b10) )
            begin block_data0 <= icache0[block_id];
                    block_data1 <= icache1[block_id];
            end

    // 输出信号处理
    assign  hit0 = block_data0[280] & (instraddr_delay[31:8]==block_data0[279:256]);
    assign  hit1 = block_data1[280] & (instraddr_delay[31:8]==block_data1[279:256]);
    assign  hit  = hit0 | hit1;

    logic   abort, abort_delay;
    assign  abort_out   = abort | abort_delay;
    assign  abort       = (~hit & ins_req_delay) | mem_req | mem_req_delay;
    assign  mem_data_ready = (BLOCK_SIZE==counter);    
    
    assign  block_data = hit1 ? block_data1 : block_data0;
    
    always@(*)
        case(instraddr_delay[4:2])
            0:    instr = block_data[31:0];
            1:    instr = block_data[63:32];
            2:    instr = block_data[95:64];
            3:    instr = block_data[127:96];
            4:    instr = block_data[159:128];
            5:    instr = block_data[191:160];
            6:    instr = block_data[223:192];
            7:    instr = block_data[255:224];
            default:instr = block_data[31:0];
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
        abort_delay     <=  abort;

    always@(posedge clk)
        mem_req_delay   <=  mem_req;

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
    
    // 从memory读取数据的位移寄存器
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
