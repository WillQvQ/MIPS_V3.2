`timescale 1ns / 1ps
module    icache(
    // control signal
    input   logic           clk,
    input   logic           reset,
    // dram side
    input   logic   [31:0]  dram_data,
    input   logic           dram_val,
    output  logic           dram_req,
    output  logic   [31:0]  dram_req_addr,
    // cpu side
    input   logic   [31:0]  cpu_addr,
    input   logic           ins_req,            // instruction request
    output  logic    [31:0] instr,        // instruction for cpu
    output  logic           hit,
    output  logic           abort
    );
    
    parameter BLOCK_SIZE = 8;
    logic   [31:0]  counter;
    logic   [31:0]  cpu_addr_dly;
    logic           ins_req_dly;
    logic           dram_req_dly;
    logic   [31:0]  dram_data_shift[7:0];
    logic   [275:0] I_SRAM_data0, I_SRAM_data1; // {val, tag, data}
    logic   [275:0] I_SRAM_data;                     // {  1,  19,  256}      
    logic           hit0, hit1;
    logic   [275:0] wr_cache_data;
    logic           dram_data_ready;
    logic   [275:0] I_SRAM0[255:0], I_SRAM1[255:0];
    logic   [3:0]   LRU_c0[255:0], LRU_c1[255:0];
    integer i;
    
    assign wr_cache_data = {1'b1, cpu_addr_dly[31:13],
                                            dram_data_shift[7],dram_data_shift[6],
                                            dram_data_shift[5],dram_data_shift[4],
                                            dram_data_shift[3],dram_data_shift[2],
                                            dram_data_shift[1],dram_data_shift[0]};
    
    // instruction sram block
    always@(posedge clk)
    begin
        if(reset)
            for(i=0;i<256;i=i+1) 
                begin I_SRAM0[i] <= 276'b0; 
                        I_SRAM1[i] <= 276'b0;
                end
        else if(dram_data_ready)
            if(I_SRAM0[cpu_addr_dly[12:5]][275] && I_SRAM1[cpu_addr_dly[12:5]][275])
            begin
                if(LRU_c0[cpu_addr_dly[12:5]] > LRU_c1[cpu_addr_dly[12:5]])
                      I_SRAM0[cpu_addr_dly[12:5]] <= wr_cache_data;
                else I_SRAM1[cpu_addr_dly[12:5]] <= wr_cache_data;
            end
            else if(I_SRAM0[cpu_addr_dly[12:5]][275])
                I_SRAM1[cpu_addr_dly[12:5]] <= wr_cache_data;
            else
                I_SRAM0[cpu_addr_dly[12:5]] <= wr_cache_data;
    end
    
    //LRU counter block
     always @(posedge clk)
      if(reset) 
            for(i=0;i<256;i=i+1) 
                begin LRU_c0[i] <= 4'b0; 
                        LRU_c1[i] <= 4'b0;
                end
      else if(!abort && hit0)
        for(i=0;i<256;i=i+1)
            begin
                if(i == {24'b0,cpu_addr_dly[12:5]} || i == {24'b0,cpu_addr[12:5]})
                    LRU_c0[i] <=4'b0;
                else
                    LRU_c0[i] <= LRU_c0[i] + (LRU_c0[i]!=4'b1111);
                LRU_c1[i] <= LRU_c1[i] + (LRU_c1[i]!=4'b1111);
            end
      else if(!abort && hit1)
         for(i=0;i<256;i=i+1)
            begin
                LRU_c0[i] <= LRU_c0[i] + (LRU_c0[i]!=4'b1111);
                if(i == {24'b0,cpu_addr_dly[12:5]} || i == {24'b0,cpu_addr[12:5]})
                    LRU_c1[i] <=4'b0;
                else
                    LRU_c1[i] <= LRU_c1[i] + (LRU_c1[i]!=4'b1111);
            end
    
    always @(posedge clk)
        if(reset)
            begin I_SRAM_data0 <= 276'b0; I_SRAM_data1 <= 276'b0; end
        else if( ins_req | ({dram_req_dly, dram_req}==2'b10) )
            begin I_SRAM_data0 <= I_SRAM0[cpu_addr[12:5]];
                    I_SRAM_data1 <= I_SRAM1[cpu_addr[12:5]];
            end

    // output signals
    assign  hit0 = I_SRAM_data0[275] & (cpu_addr_dly[31:13]==I_SRAM_data0[274:256]);
    assign  hit1 = I_SRAM_data1[275] & (cpu_addr_dly[31:13]==I_SRAM_data1[274:256]);
    assign  hit  = hit0 | hit1;
    assign  abort = (~hit & ins_req_dly) | dram_req | dram_req_dly;
    assign  dram_data_ready = (BLOCK_SIZE==counter);    
    
    assign  I_SRAM_data = hit1 ? I_SRAM_data1 : I_SRAM_data0;
    
    always@(*)
        case(cpu_addr_dly[4:2])
            0:    instr = I_SRAM_data[31:0];
            1:    instr = I_SRAM_data[63:32];
            2:    instr = I_SRAM_data[95:64];
            3:    instr = I_SRAM_data[127:96];
            4:    instr = I_SRAM_data[159:128];
            5:    instr = I_SRAM_data[191:160];
            6:    instr = I_SRAM_data[223:192];
            7:    instr = I_SRAM_data[255:224];
            default:instr = I_SRAM_data[31:0];
        endcase
    
    always@(posedge clk)
    begin
        if( reset )
            dram_req    <=    0;
        else if( ~hit & ins_req_dly )
            dram_req    <=    1;
        else if( dram_data_ready )
            dram_req    <=    0;
    end
    
    always@(posedge clk)
        dram_req_dly    <=    dram_req;
    
    // phisical address of instructions
    assign    dram_req_addr    =    {cpu_addr_dly[31:5],5'b0};
    
    // input signal buffer
    always@(posedge clk)
    begin
        if( reset )
            ins_req_dly    <=    0;
        else
            ins_req_dly    <=    ins_req;
    end
    
    always@(posedge clk)
    begin
        if( reset )
            cpu_addr_dly    <=    0;
        else if( (ins_req_dly & ~hit) || dram_req )
            cpu_addr_dly    <=    cpu_addr_dly;
        else if(ins_req)
            cpu_addr_dly    <=    cpu_addr;
    end
    
    // block counter
    always@(posedge clk)
    begin
        if( reset )
            counter <= 0;
        else if( dram_data_ready )
            counter <= 0;
        else if( dram_val )
            counter <= counter + 1'b1;
    end
    
    // dram data buffer
    always@(posedge clk)
    begin
        if( reset )
        begin
            dram_data_shift[0]    <=    0;
            dram_data_shift[1]    <=    0;
            dram_data_shift[2]    <=    0;
            dram_data_shift[3]    <=    0;
            dram_data_shift[4]    <=    0;
            dram_data_shift[5]    <=    0;
            dram_data_shift[6]    <=    0;
            dram_data_shift[7]    <=    0;
        end
        else if( dram_data_ready )
        begin
            dram_data_shift[0]    <=    0;
            dram_data_shift[1]    <=    0;
            dram_data_shift[2]    <=    0;
            dram_data_shift[3]    <=    0;
            dram_data_shift[4]    <=    0;
            dram_data_shift[5]    <=    0;
            dram_data_shift[6]    <=    0;
            dram_data_shift[7]    <=    0;
        end
        else if(dram_val)
        begin
            dram_data_shift[0]    <=    dram_data_shift[1];
            dram_data_shift[1]    <=    dram_data_shift[2];
            dram_data_shift[2]    <=    dram_data_shift[3];
            dram_data_shift[3]    <=    dram_data_shift[4];
            dram_data_shift[4]    <=    dram_data_shift[5];
            dram_data_shift[5]    <=    dram_data_shift[6];
            dram_data_shift[6]    <=    dram_data_shift[7];
            dram_data_shift[7]    <=    dram_data;
        end
    end

    
endmodule
