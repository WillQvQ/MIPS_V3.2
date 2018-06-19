`timescale 1ns / 1ps

module cache#(parameter N = 64, L = 128)(
    input   logic           clk, 
    input   logic           dword,
    input   logic           memread,
    input   logic [1:0]     memwrite,
    input   logic [N-1:0]   dataadr, writedata,
    input   logic [31:0]    instradr,
    output  logic [31:0]    instr,
    output  logic [N-1:0]   readdata,
    input   logic [7:0]     checka,
    output  logic [31:0]    check,
    output  logic           ready,
    input   logic [7:0]     rx_data,
    output  logic [31:0]    rx_check,
    output  logic [31:0]    rx_checkh,
    output  logic [31:0]    rx_checkl
);
    logic [63:0] readdata64;
    logic [255:0] cache[7:0];
    logic [31:0] cacheid[7:0];
    logic [7:0] cacheused;
    logic [7:0] dirty;
    logic [255:0] writeblock,readblock;
    logic [31:0] blockaddr;
    logic [31:0] instrblockaddr;
    logic [2:0] instrblockmod;
    logic [2:0] instrinblock;
    logic       instrhit;
    logic [31:0] datablockaddr;
    logic [2:0] datablockmod;
    logic [2:0] datainblock;
    logic       datahit;
    logic       blockwrite,blockread;
    logic       memready;
    logic [2:0] blockmod;
    logic [7:0] cnt;
    logic [31:0] word;
    logic [31:0] writeblockaddr;
    logic [2:0] writeblockmod;
    logic [2:0] writeinblock;
    logic       writehit;
    assign writeblockaddr = {5'b0,dataadr[31:5]};
    assign writeinblock = dataadr[4:3];
    assign writeblockmod = writeblockaddr[2:0];
    initial begin
        cacheused = 8'b0;
        dirty = 8'b0;
        ready = 1;
        cnt = 8'b0;
        blockaddr <= 32'b0;
        cacheid[0] = 32'b0;
        cacheid[1] = 32'b0;
        cacheid[2] = 32'b0;
        cacheid[3] = 32'b0;
        cacheid[4] = 32'b0;
        cacheid[5] = 32'b0;
        cacheid[6] = 32'b0;
        cacheid[7] = 32'b0;
        cache[0] = 256'b0;
        cache[1] = 256'b0;
        cache[2] = 256'b0;
        cache[3] = 256'b0;
        cache[4] = 256'b0;
        cache[5] = 256'b0;
        cache[6] = 256'b0;
        cache[7] = 256'b0;
    end
    assign readdata = dword ? readdata64 : {32'b0,word};
    assign word = dataadr[2] ? readdata64[31:0] : readdata64[63:32];
    assign instrblockaddr = {5'b0,instradr[31:5]};
    assign instrinblock = instradr[4:2];
    assign instrblockmod = instrblockaddr[2:0];
    always_comb begin
        case(instrinblock)
            3'd0:instr = cache[instrblockmod][255:224];
            3'd1:instr = cache[instrblockmod][223:192];
            3'd2:instr = cache[instrblockmod][191:160];
            3'd3:instr = cache[instrblockmod][159:128];
            3'd4:instr = cache[instrblockmod][127:96];
            3'd5:instr = cache[instrblockmod][95:64];
            3'd6:instr = cache[instrblockmod][63:32];
            3'd7:instr = cache[instrblockmod][31:0];
        endcase
    end
    always_comb begin
        case(datainblock)
            3'd0:readdata64 = cache[datablockmod][255:160];
            3'd1:readdata64 = cache[datablockmod][159:128];
            3'd2:readdata64 = cache[datablockmod][127:64];
            3'd3:readdata64 = cache[datablockmod][63:0];
        endcase
    end
    assign datablockaddr = {5'b0,dataadr[31:5]};
    assign datainblock  = dataadr[4:3];
    assign datablockmod = datablockaddr[2:0];
    assign instrhit = cacheused[instrblockmod] & (cacheid[instrblockmod] == instrblockaddr);
    assign datahit = cacheused[datablockmod] & (cacheid[datablockmod] == datablockaddr);
    memblock mem(clk, blockwrite, blockread, blockaddr, writeblock, readblock, memready);
    always @(negedge clk)begin
        if(memready) begin
            if (cnt==0)begin
                if(!instrhit)begin 
                    blockread <= 1;
                    blockaddr <= instrblockaddr;
                    blockmod <= instrblockmod;
                    cnt <= 8'd3;
                    ready <= 0;
                end
                if(!datahit)begin
                    blockread <= 1;
                    blockaddr <= datablockaddr;
                    blockmod <= datablockmod;
                    cnt <= 8'd3;
                    ready <= 0;
                end
            end
            else if(cnt==1) begin
                cacheused[blockmod]=1;
                cacheid[blockmod] <= blockaddr;
                cache[blockmod]<= readblock;
                ready <= 1;
                cnt <= cnt - 1;
            end
            else if(cnt!=0)
                cnt <= cnt - 1;
        end 
        else if (memwrite==2)begin
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
            ready <= 0;
            cnt <= 8'd20;
        end
        else if (memwrite==1)begin
            case (dataadr[2])
                0:  RAM[dataadr[N-1:3]][63:32]  <= writedata[31:0];
                1:  RAM[dataadr[N-1:3]][31:0]   <= writedata[31:0];
            endcase
            ready <= 0;
            cnt <= 8'd20;
        end
        if (memwrite==3)begin
            RAM[dataadr[N-1:3]] <= writedata;
            ready <= 0;
            cnt <= 8'd20;
        end
        else begin
            blockread <= 0;
        end 
    end
endmodule