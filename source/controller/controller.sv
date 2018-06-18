`timescale 1ns / 1ps

module controller(
    input   logic       clk, reset,
    input   logic [5:0] op, funct,
    input   logic       FlushE,
    output  logic       regdstE, regwriteE,regwriteM,regwriteW, 
    output  logic       memtoregE,memtoregM,memtoregW,
    output  logic [1:0] memwriteM,
    output  logic [1:0] alusrcE,
    output  logic [3:0] alucontrolE,
    output  logic       bneD,branchD,jumpD,
    output  logic [2:0] readtypeM,
    output  logic       memreadM
); 
    logic [2:0] aluopD,readtypeE,readtypeD;
    logic       memreadD,memreadE;
    logic [1:0] memwriteD,memwriteE;
    logic       memtoregD;
    logic       regwriteD,regdstD;
    logic [1:0] alusrcD;
    logic [3:0] alucontrolD;
    maindec maindec(clk, reset, op,
                    regwriteD,memtoregD, regdstD, memwriteD,
                    alusrcD, bneD, branchD, jumpD,
                    aluopD, readtypeD,memreadD);
    aludec aludec(funct, aluopD, alucontrolD);

    
    flopcr#(15)     regD2E(clk,reset,FlushE,//1+1+2+4+2+1+3+1 = 15
                        {regwriteD,memtoregD,memwriteD,alucontrolD,alusrcD,regdstD,readtypeD,memreadD},
                        {regwriteE,memtoregE,memwriteE,alucontrolE,alusrcE,regdstE,readtypeE,memreadE});
    flopr #(8)      regE2M(clk,reset,//1+1+2+3+1=8
                        {regwriteE,memtoregE,memwriteE,readtypeE,memreadE},
                        {regwriteM,memtoregM,memwriteM,readtypeM,memreadM});      
    flopr #(2)      regM2W(clk,reset,{regwriteM,memtoregM},
                                     {regwriteW,memtoregW});
endmodule