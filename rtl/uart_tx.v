`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/28 15:40:22
// Design Name: 
// Module Name: uart_tx
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


module  uart_tx 
(
    input   wire             clk     ,
    input   wire             reset_n   ,
    input   wire     [7:0]   tx_data     ,
    input   wire             tx_en     ,
    
    output  reg              tx_out
);

// parameter   BAUD_CNT_MAX = 5207;
parameter   BAUD_CNT_MAX = 56;

reg             work_en     ;
reg     [13:0]  baud_cnt    ;
reg             bit_flag    ;
reg     [3:0]   bit_cnt     ;

//work_en
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        work_en <= 1'b0;
    else    if(tx_en == 1'b1)
        work_en <= 1'b1;
    else    if((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        work_en <= 1'b0;
//baud_cnt
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        baud_cnt <= 14'd0;
    else    if((work_en == 1'b0) || (baud_cnt == BAUD_CNT_MAX - 1))
        baud_cnt <= 14'd0;
    else    if(work_en == 1'b1)
        baud_cnt <= baud_cnt + 1'b1;
//bit_flag
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        bit_flag <= 1'b0;
    else    if(baud_cnt == 14'd1)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
//bit_cnt
always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        bit_cnt <= 4'd0;
    else    if((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        bit_cnt <= 4'd0;
    else    if((work_en == 1'b1) && (bit_flag == 1'b1))
        bit_cnt <= bit_cnt + 1'b1;

always@(posedge clk or negedge reset_n)
    if(reset_n == 1'b0)
        tx_out <= 1'b1;
    else    if(bit_flag == 1'b1)
        case(bit_cnt)
            0: tx_out <= 1'b0;
            1: tx_out <= tx_data[0];
            2: tx_out <= tx_data[1];
            3: tx_out <= tx_data[2];
            4: tx_out <= tx_data[3];
            5: tx_out <= tx_data[4];
            6: tx_out <= tx_data[5];
            7: tx_out <= tx_data[6];
            8: tx_out <= tx_data[7];
            9: tx_out <= 1'b1;
        endcase


endmodule
