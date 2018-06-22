`timescale 1ns / 1ps

module    dcache(
    input   logic           clk,       
    input   logic           reset,          
    output  logic           mem_write_req,
    output  logic   [31:0]  mem_write_addr,
    output  logic   [31:0]  mem_write_data,
    input   logic           mem_write_val,
    output  logic           mem_read_req,
    output  logic   [31:0]  mem_read_addr,
    input   logic   [31:0]  mem_read_data,
    input   logic           mem_read_val,
    input   logic   [31:0]  dataaddr,
    input   logic           datareq,
    input   logic           wren,
    input   logic   [31:0]  writedata,
    output  logic   [31:0]  readdata,
    output  logic           hit,
    output  logic           abort_out
  );
    
    parameter    BLOCK_SIZE =    8;
    
    logic   [1:0]   state;            
    logic   [281:0] block_data; 
    //val:1 dirty:1 tag:24 data:256
    logic   [31:0]  word;   
    logic           dirty;  
    logic   [23:0]  tag_delay;  
    logic   [31:0]  dataaddr_delay;
    logic   [31:0]  writedata_delay;
    logic           cpu_write_wait_flag;
    logic           mem_write_ready;
    logic           mem_read_ready;
    logic           mem_read_req_delay;
    logic   [31:0]  write_counter,read_counter;
    logic   [31:0]  dram_data_shift[7:0]; 
    logic   [281:0] dcache[7:0];
    
    
    assign  mem_write_addr  =   {tag_delay,block_id_delay,5'b0};
    assign  mem_read_addr   =   {dataaddr_delay[31:5],5'b0};
    
    assign  block_id_delay  =   dataaddr_delay[7:5];
    assign  block_id        =   dataaddr[7:5];

    always@(posedge clk)begin
        if(reset) begin
            dcache[0] <= 0;
            dcache[1] <= 0;
            dcache[2] <= 0;
            dcache[3] <= 0;
            dcache[4] <= 0;
            dcache[5] <= 0;
            dcache[6] <= 0;
            dcache[7] <= 0;
        end
        else if(mem_read_ready) begin
            // 当从memory读取完毕时，把位移寄存器里的数据写入块
            dcache[block_id_delay]    <=    
                {1'b1, 1'b0, dataaddr_delay[31:8],
                dram_data_shift[7],dram_data_shift[6],
                dram_data_shift[5],dram_data_shift[4],
                dram_data_shift[3],dram_data_shift[2],
                dram_data_shift[1],dram_data_shift[0]};
        end
        else if(hit & datareq & wren) begin
            // 缓存命中，直接写入cache块中
            case(dataaddr[4:2])
                0:      dcache[block_id][31:0]    <= writedata;
                1:      dcache[block_id][63:32]   <= writedata;
                2:      dcache[block_id][95:64]   <= writedata;
                3:      dcache[block_id][127:96]  <= writedata;
                4:      dcache[block_id][159:128] <= writedata;
                5:      dcache[block_id][191:160] <= writedata;
                6:      dcache[block_id][223:192] <= writedata;
                7:      dcache[block_id][255:224] <= writedata;
                default:dcache[block_id] <= dcache[block_id];
            endcase
            dcache[block_id][280]   <=  1;
        end
        else if(cpu_write_wait_flag & mem_read_req_delay & ~mem_read_req)begin
            // 发生缺失，延后写入
            case(dataaddr_delay[4:2])
                0:      dcache[block_id_delay][31:0]    <= writedata_delay;
                1:      dcache[block_id_delay][63:32]   <= writedata_delay;
                2:      dcache[block_id_delay][95:64]   <= writedata_delay;
                3:      dcache[block_id_delay][127:96]  <= writedata_delay;
                4:      dcache[block_id_delay][159:128] <= writedata_delay;
                5:      dcache[block_id_delay][191:160] <= writedata_delay;
                6:      dcache[block_id_delay][223:192] <= writedata_delay;
                7:      dcache[block_id_delay][255:224] <= writedata_delay;
                default:dcache[block_id_delay]  <= dcache[block_id_delay];
            endcase
            dcache[block_id_delay][280] <=  1;
        end
    end

    // 从cache写入memory
    always@(posedge clk)
        if(reset)
            mem_write_data  <=  0;
        else if(mem_write_req) begin
            case(write_counter[2:0])
                0:      mem_write_data <= dcache[block_id_delay][31:0];
                1:      mem_write_data <= dcache[block_id_delay][63:32];
                2:      mem_write_data <= dcache[block_id_delay][95:64];
                3:      mem_write_data <= dcache[block_id_delay][127:96];
                4:      mem_write_data <= dcache[block_id_delay][159:128];
                5:      mem_write_data <= dcache[block_id_delay][191:160];
                6:      mem_write_data <= dcache[block_id_delay][223:192];
                7:      mem_write_data <= dcache[block_id_delay][255:224];
                default:mem_write_data <= dcache[block_id_delay][31:0];
            endcase
        end
    
    // 从cache读到CPU  
    assign    readdata    =    word;
    assign    block_data  =    dcache[block_id];
    
    always@(posedge clk) begin
        if(reset)
            word <= 0;
        else if(hit & datareq & ~wren) begin
            case(dataaddr[4:2])
                0:      word <= block_data[31:0];
                1:      word <= block_data[63:32];
                2:      word <= block_data[95:64];
                3:      word <= block_data[127:96];
                4:      word <= block_data[159:128];
                5:      word <= block_data[191:160];
                6:      word <= block_data[223:192];
                7:      word <= block_data[255:224];
                default:word <= block_data[31:0];
            endcase
        end
        else word <= 0;
    end
    
    // 控制部分

    assign  hit     =   block_data[281] & (dataaddr[31:8]==block_data[279:256]);    
    assign  dirty   =   block_data[280];

    logic   abort, abort_delay;
    logic   reqstart;
    logic   r1, r2;

    always@(negedge clk,posedge reset)begin
        if(reset)begin
            r1<=0;
            r2<=0;
        end
        else begin
            r2 <= r1;
            r1 <= datareq;
        end
    end
    assign  reqstart = r1&~r2;
    assign  abort   =   (mem_write_req || mem_read_req || mem_read_req_delay ||reqstart);
    assign  abort_out = abort | abort_delay;

    // 控制状态机
    parameter    CPU_EXEC   =    0;
    parameter    WR_DRAM    =    1;
    parameter    RD_DRAM    =    2;

    always@(posedge clk)
        if(reset)
            state   <=  CPU_EXEC;
        else case(state)
            CPU_EXEC:// 把dirty的块写回memory
                    if(~hit & dirty & datareq)   
                        state    <=    WR_DRAM;
                    else if(~hit & datareq) 
                        state    <=    RD_DRAM;
                    else
                        state    <=    CPU_EXEC;
            WR_DRAM:if(mem_write_ready)
                        state    <=    RD_DRAM;
                    else
                        state    <=    WR_DRAM;
            RD_DRAM:if(mem_read_ready)
                        state    <=    CPU_EXEC;    
                    else
                        state    <=    RD_DRAM;
                default: state   <=    CPU_EXEC;    
            endcase
    
    assign    mem_write_req   =    (WR_DRAM == state);
    assign    mem_read_req    =    (RD_DRAM == state);
    
    // 信号延迟部分
    always@(posedge clk)
        abort_delay         <=  abort;

    always@(posedge clk)
        mem_read_req_delay  <=  mem_read_req;
    
    always@(posedge clk)
        if(reset)
            tag_delay       <=  0;
        else if((~hit & dirty & datareq) & ~mem_write_req & ~mem_read_req)
            tag_delay       <=  block_data[279:256];

    always@(posedge clk)
        if(reset)
            dataaddr_delay  <=  0;
        else if((~hit & dirty & datareq & wren) | (~hit & datareq))
            dataaddr_delay  <=  dataaddr;
    
    always@(posedge clk)
        if(reset)
            writedata_delay <=  0;
        else if(~hit & datareq & wren)
            writedata_delay <=  writedata;
    
    always@(posedge clk)
        if(reset)
            cpu_write_wait_flag <= 0;
        else if(~hit & datareq & wren)
            cpu_write_wait_flag <= 1;
        else if(~mem_write_req & ~mem_read_req)
            cpu_write_wait_flag <= 0;

    // 读写计数部分，用于判定读写memory是否完成
    always@(posedge clk) begin
        if(reset) begin
            write_counter   <=    0;
            read_counter    <=    0;
        end
        else begin
            if(mem_write_ready)
                write_counter   <=  0;
            else if(mem_write_val & mem_write_req)
                write_counter   <=  write_counter + 1'b1;
            if(mem_read_ready)
                read_counter    <=  0;
            else if(mem_read_val & mem_read_req)
                read_counter    <=  read_counter + 1'b1;
        end
    end
    
    assign mem_write_ready  =   (BLOCK_SIZE == write_counter);
    assign mem_read_ready   =   (BLOCK_SIZE == read_counter);
    
    // 8字的移位寄存器，用于接收从memory读取的数�?
    always @(posedge clk) begin
        if(reset) begin
            dram_data_shift[0] <= 0;
            dram_data_shift[1] <= 0;
            dram_data_shift[2] <= 0;
            dram_data_shift[3] <= 0;
            dram_data_shift[4] <= 0;
            dram_data_shift[5] <= 0;
            dram_data_shift[6] <= 0;
            dram_data_shift[7] <= 0;
        end
        else if(mem_read_ready) begin
            dram_data_shift[0] <= 0;
            dram_data_shift[1] <= 0;
            dram_data_shift[2] <= 0;
            dram_data_shift[3] <= 0;
            dram_data_shift[4] <= 0;
            dram_data_shift[5] <= 0;
            dram_data_shift[6] <= 0;
            dram_data_shift[7] <= 0;
        end
        else if(mem_read_val) begin
            dram_data_shift[0] <= dram_data_shift[1];
            dram_data_shift[1] <= dram_data_shift[2];
            dram_data_shift[2] <= dram_data_shift[3];
            dram_data_shift[3] <= dram_data_shift[4];
            dram_data_shift[4] <= dram_data_shift[5];
            dram_data_shift[5] <= dram_data_shift[6];
            dram_data_shift[6] <= dram_data_shift[7];
            dram_data_shift[7] <= mem_read_data;
        end
    end
endmodule
