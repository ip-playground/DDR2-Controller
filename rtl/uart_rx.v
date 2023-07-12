`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/28 15:41:05
// Design Name: 
// Module Name: uart_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module  uart_rx 
(
    input   wire            clk     ,
    input   wire            reset_n   ,
    input   wire            rx          ,
     
    output  reg     [7:0]   data     ,
    output  reg             valid 
);

parameter   BAUD_CNT_MAX = 5207;
// parameter   BAUD_CNT_MAX = 54;

reg             rx_reg1         ;
reg             rx_reg2         ;
reg             rx_reg3         ;
reg             start_flag      ;
reg             work_en         ;
reg     [13:0]  baud_cnt        ;
reg             bit_flag        ;
reg     [3:0]   bit_cnt         ;
reg     [7:0]   rx_data         ;
reg             rx_flag         ;

//rx_reg1
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        rx_reg1 <= 1'b1;
    else
        rx_reg1 <= rx;
//rx_reg2,打一拍
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        rx_reg2 <= 1'b1;
    else
        rx_reg2 <= rx_reg1;
//rx_reg3,打两拍
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        rx_reg3 <= 1'b1;
    else
        rx_reg3 <= rx_reg2;

//start_flag
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        start_flag <= 1'b0;
    else    if((rx_reg3 == 1'b1) && (rx_reg2 == 1'b0) && (work_en == 1'b0))
        start_flag <= 1'b1;
    else
        start_flag <= 1'b0;
//work_en
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        work_en <= 1'b0;
    else    if(start_flag == 1'b1)
        work_en <= 1'b1;
    else    if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        work_en <= 1'b0;
    else
        work_en <= work_en;
//baud_cnt
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        baud_cnt <= 14'd0;
    else    if((baud_cnt == BAUD_CNT_MAX - 1) || (work_en == 1'b0))
        baud_cnt <= 14'd0;
    else
        baud_cnt <= baud_cnt + 1'b1;
///bit_flag
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        bit_flag <= 1'b0;
    else    if(baud_cnt == BAUD_CNT_MAX / 2 - 1)
        bit_flag <= 1'b1;
    else    
        bit_flag <= 1'b0;
//bit_cnt
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        bit_cnt <= 4'd0;
    else    if((bit_cnt == 4'd8) &&(bit_flag == 1'b1))
        bit_cnt <= 4'd0;
    else    if(bit_flag == 1'b1)
        bit_cnt <= bit_cnt + 1'b1;
//rx_data
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        rx_data <= 8'b0;
    else    if((bit_cnt >= 4'd1) && (bit_cnt <= 4'd8) && (bit_flag == 1'b1))
        rx_data <= {rx_reg3,rx_data[7:1]}; //高位在前，低位在后8765_4321

//rx_flag
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        rx_flag <= 1'b0;
    else    if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        rx_flag <= 1'b1;
    else
        rx_flag <= 1'b0;
//data
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        data <= 8'b0;
    else    if(rx_flag == 1'b1)
        data <= rx_data;
//valid
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        valid <= 1'b0;
    else
        valid <= rx_flag;

endmodule
