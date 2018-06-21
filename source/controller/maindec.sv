`timescale 1ns / 1ps


module maindec(
    input   logic       clk, reset,   
    input   logic [5:0] op,
    output  logic       regwrite, memtoreg, regdst, readreq,
    output  logic [1:0] memwrite, 
    output  logic [1:0] alusrc,
    output  logic       bne, branch, jump,
    output  logic [2:0] aluop, readtype
); 
    parameter RTYPE = 6'b000000;
    parameter LD    = 6'b110111;
    parameter LWU   = 6'b100111;
    parameter LW    = 6'b100011;
    parameter LBU   = 6'b100100;
    parameter LB    = 6'b100000;
    parameter SD    = 6'b111111;
    parameter SW    = 6'b101011;
    parameter SB    = 6'b101000;
    parameter BEQ   = 6'b000100;
    parameter BNE   = 6'b000101;
    parameter J     = 6'b000010;
    parameter ADDI  = 6'b001000;
    parameter ANDI  = 6'b001100;
    parameter ORI   = 6'b001101;
    parameter SLTI  = 6'b001010;
    parameter DADDI = 6'b011000;
    logic [16:0] controls;
    assign {regwrite,memtoreg,regdst, memwrite, alusrc,
            bne,branch,jump, aluop, readtype,readreq} = controls; 
    always_comb
        case (op)
            RTYPE:  controls <= 17'b101_00_00_000_111_0000;
            SD:     controls <= 17'b000_11_01_000_000_0000;
            SW:     controls <= 17'b000_01_01_000_000_0000;
            SB:     controls <= 17'b000_10_01_000_000_0000;
            LD:     controls <= 17'b110_00_01_000_000_1001;
            LWU:    controls <= 17'b110_00_01_000_000_0011;
            LW:     controls <= 17'b110_00_01_000_000_0001;
            LBU:    controls <= 17'b110_00_01_000_000_0111;
            LB:     controls <= 17'b110_00_01_000_000_0101;
            ADDI:   controls <= 17'b100_00_01_000_000_0000;
            ANDI:   controls <= 17'b100_00_10_000_001_0000;
            ORI:    controls <= 17'b100_00_10_000_010_0000;
            SLTI:   controls <= 17'b100_00_01_000_011_0000;
            DADDI:  controls <= 17'b100_00_01_000_100_0000;
            BEQ:    controls <= 17'b000_00_00_010_000_0000;
            BNE:    controls <= 17'b000_00_00_110_000_0000;
            J:      controls <= 17'b000_00_00_001_000_0000;
        endcase
endmodule