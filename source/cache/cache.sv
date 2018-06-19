`timescale 1ns / 1ps

module cache#(parameter N = 64)(
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
    logic [63:0] readdata64,writedata64;
    logic [255:0] RAM[7:0];
    logic [31:0] cacheid[7:0];
    logic [7:0] cacheused;
    logic [7:0] dirty;
    logic [255:0] writeblock,readblock,instrblock;
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
    logic [2:0] rxblockmod;
    logic [2:0] rxinblock;
    logic [31:0]instraddr;
    logic [31:0]readaddr,writeaddr;
    assign check = 32'b0;   //UNUSED
    assign rx_checkh = 32'b0;//UNUSED
    assign rx_checkl = 32'b0;//UNUSED
    assign rxinblock  = rx_data[4:3];
    assign rxblockmod = rx_data[2:0];
    always_comb begin
        case(rxinblock)
            2'd0:rx_check = RAM[rxblockmod][255:192];
            2'd1:rx_check = RAM[rxblockmod][191:128];
            2'd2:rx_check = RAM[rxblockmod][127:64];
            2'd3:rx_check = RAM[rxblockmod][63:0];
        endcase
    end
    initial begin
        cacheused = 8'b0;
        dirty = 8'b0;
        ready = 1;
        cnt = 8'b0;
        readaddr <= 32'b0;
        cacheid[0] = 32'b0;
        cacheid[1] = 32'b0;
        cacheid[2] = 32'b0;
        cacheid[3] = 32'b0;
        cacheid[4] = 32'b0;
        cacheid[5] = 32'b0;
        cacheid[6] = 32'b0;
        cacheid[7] = 32'b0;
        RAM[0] = 256'b0;
        RAM[1] = 256'b0;
        RAM[2] = 256'b0;
        RAM[3] = 256'b0;
        RAM[4] = 256'b0;
        RAM[5] = 256'b0;
        RAM[6] = 256'b0;
        RAM[7] = 256'b0;
    end
    assign writeblockaddr = {5'b0,dataadr[31:5]};
    assign writeinblock = dataadr[4:3];
    assign writeblockmod = writeblockaddr[2:0];
    assign readdata = dword ? readdata64 : {32'b0,word};
    assign word = dataadr[2] ? readdata64[31:0] : readdata64[63:32];
    assign instrblockaddr = {5'b0,instradr[31:5]};
    assign instrinblock = instradr[4:2];
    assign instrblockmod = instrblockaddr[2:0];
    assign datablockaddr = {5'b0,dataadr[31:5]};
    assign datainblock  = dataadr[4:3];
    assign datablockmod = datablockaddr[2:0];
    assign instrhit = cacheused[instrblockmod] & (cacheid[instrblockmod] == instrblockaddr);
    assign datahit = cacheused[datablockmod] & (cacheid[datablockmod] == datablockaddr);
    assign writehit = cacheused[writeblockmod] & (cacheid[writeblockmod] == writeblockaddr);
    always_comb begin
        case(instrinblock)
            3'd0:instr = RAM[instrblockmod][255:224];
            3'd1:instr = RAM[instrblockmod][223:192];
            3'd2:instr = RAM[instrblockmod][191:160];
            3'd3:instr = RAM[instrblockmod][159:128];
            3'd4:instr = RAM[instrblockmod][127:96];
            3'd5:instr = RAM[instrblockmod][95:64];
            3'd6:instr = RAM[instrblockmod][63:32];
            3'd7:instr = RAM[instrblockmod][31:0];
        endcase
    end
    always_comb begin
        case(datainblock)
            2'd0:readdata64 = RAM[datablockmod][255:192];
            2'd1:readdata64 = RAM[datablockmod][191:128];
            2'd2:readdata64 = RAM[datablockmod][127:64];
            2'd3:readdata64 = RAM[datablockmod][63:0];
        endcase
    end
    memblock mem(clk, blockwrite, blockread, instraddr, readaddr, writeaddr, writeblock, readblock, instrblock, memready);
    always @(posedge clk)begin
        writeaddr <= blockmod;
    end
    always @(negedge clk)begin
        if(memready) begin
            if (cnt==0)begin
                if(!instrhit)begin 
                    blockread <= 1;
                    instraddr <= instrblockaddr;
                    cnt <= 8'd3;
                    ready <= 0;
                    if(dirty[instrblockmod])begin
                        blockwrite <= 1;
                        dirty[instrblockmod] <= 0;
                        writeblock = RAM[instrblockmod];
                    end
                end
                if(!datahit&memread)begin
                    blockread <= 1;
                    readaddr <= datablockaddr;
                    blockmod <= datablockmod;
                    cnt <= 8'd3;
                    ready <= 0;
                    if(dirty[datablockmod])begin
                        blockwrite <= 1;
                        dirty[datablockmod] <= 0;
                        writeblock = RAM[datablockmod];
                    end
                end
                if(!writehit&memwrite)begin
                    blockread <= 1;
                    readaddr <= writeblockaddr;
                    blockmod <= writeblockmod;
                    cnt <= 8'd3;
                    ready <= 0;
                    if(dirty[writeblockmod])begin
                        blockwrite <= 1;
                        dirty[writeblockmod] <= 0;
                        writeblock = RAM[writeblockmod];
                    end
                end
            end
            else if (cnt==2) begin
                cacheused[instrblockmod]=1;
                cacheid[instrblockmod] <= instraddr;
                RAM[instrblockmod]<= instrblock;
                cnt <= 1;
            end
            else if(cnt==1) begin
                ready <= 1;
                cnt <= 0;
                case(writeinblock)
                    3'd0: writedata64 = RAM[writeblockmod][255:192] ;
                    3'd1: writedata64 = RAM[writeblockmod][191:128] ;
                    3'd2: writedata64 = RAM[writeblockmod][127:64];
                    3'd3: writedata64 = RAM[writeblockmod][63:0];
                endcase
                if (memwrite==2)begin
                    case (dataadr[2:0])
                        3'b111:  writedata64[7:0]   = writedata[7:0];
                        3'b110:  writedata64[15:8]  = writedata[7:0];
                        3'b101:  writedata64[23:16] = writedata[7:0];
                        3'b100:  writedata64[31:24] = writedata[7:0];
                        3'b011:  writedata64[39:32] = writedata[7:0];
                        3'b010:  writedata64[47:40] = writedata[7:0];
                        3'b001:  writedata64[55:48] = writedata[7:0];
                        3'b000:  writedata64[63:56] = writedata[7:0];
                    endcase
                    dirty[writeblockmod]=1;
                end
                else if (memwrite==1)begin
                    case (dataadr[2])
                        0:  writedata64[63:32]  = writedata[31:0];
                        1:  writedata64[31:0]   = writedata[31:0];
                    endcase
                    dirty[writeblockmod]=1;
                end
                else if (memwrite==3)begin
                    writedata64 = writedata;
                    dirty[writeblockmod]=1;
                end
                else begin
                    cacheused[blockmod]=1;
                    cacheid[blockmod] <= readaddr;
                    RAM[blockmod]<= readblock;
                end
                case(writeinblock)
                    3'd0:RAM[writeblockmod][255:192] = writedata64;
                    3'd1:RAM[writeblockmod][191:128] = writedata64;
                    3'd2:RAM[writeblockmod][127:64] = writedata64;
                    3'd3:RAM[writeblockmod][63:0] = writedata64;
                endcase
            end
            else if(cnt!=0)
                cnt <= cnt - 1;
        end 
        else begin
            blockread <= 0;
            blockwrite <= 0;
        end 
    end
endmodule