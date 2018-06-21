`timescale 1ns / 1ps

module uart_top(
    input   logic   CLK100MHZ,
    input   logic   clk_mips,
    input   logic   rst_n,
    output  logic   tx_pin_out,
    input   logic   rx_pin_in,
    input   logic   [127:0] tx_show,
    input   logic   [4:0]   show_len,
    output  logic   [7:0]   rx_data
);
logic       rx_done_sig;
logic[127:0]tx_data;
logic [4:0] len;
logic       cnt,clk_trx;
logic       h2l_sig;
logic       tx_sig;

initial cnt = 1'b0;
always@(posedge CLK100MHZ)cnt <= cnt +1;
assign clk_trx = cnt;



// input control
test_module u1 (
    .clk(clk_trx), 
    .rst_n(rst_n), 
    .rx_pin_in(rx_pin_in), 
    .h2l_sig(h2l_sig)
    );


rx_control_module u3 (
    .clk(clk_trx), 
    .rst_n(rst_n), 
    .h2l_sig(h2l_sig), 
    .rx_pin_in(rx_pin_in), 
    .rx_data(rx_data), 
    .rx_done_sig(rx_done_sig)
    );

// output control
logic f1;
logic f2;

always@(negedge clk_trx,negedge rst_n)begin
    $display(clk_mips);
    if(~rst_n)begin
            f1 <= 1'b1;
            f2 <= 1'b1;
    end
    else begin
            f1 <= clk_mips;
            f2 <= f1;
    end
end
assign tx_sig = (f2 & !f1) | rx_done_sig;
always @(posedge tx_sig)
    if(rx_done_sig)begin
        len = 5'd1;
        tx_data = rx_data;
    end
    else begin
        tx_data = tx_show;
        len <= show_len;
    end
tx_control_module u4 (
    .clk(clk_trx), 
    .rst_n(rst_n), 
    .tx_sig(tx_sig), 
    .tx_data(tx_data), 
    .tx_pin_out(tx_pin_out),
    .len(len)
    );

endmodule
