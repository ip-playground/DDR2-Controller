/*
 *******************************************************************************
 *  Filename    :   ddr2_init.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *  Created     :   3/27/2023
 *
 *******************************************************************************
 */

 `include "define.v" 

 module ddr2_ref(
    input                               ck,
    input                               rst_n,
    input                               init_end,
    output  reg                         aref_req,
    input                               aref_en,
    output  reg     [3:0]               aref_cmd,
    // output  reg     [`BA_BITS-1:0]      aref_ba,
    output  wire    [`ADDR_BITS-1:0]    aref_addr,
    output  wire                        aref_end
 );

//cmd
localparam          NOP         =   4'b0111;
localparam          PRE         =   4'b0010;
localparam          AREF        =   4'b0001;

//cnt
localparam          DELAY_tREFI =   `tREFI/`tCK;
localparam          PRE1        =   0;
localparam          AREF1       =   PRE1 + `tRPA/`tCK;
localparam          AREF1_END   =   AREF1 + `tRFC/`tCK;

//

integer             cnt_tREFI;
integer             cnt_cmd;
reg                 aref_flag;

always @(posedge ck or negedge rst_n) begin
    if(!rst_n) 
        cnt_tREFI <= 'd0;
    else if( cnt_tREFI >= DELAY_tREFI) 
        cnt_tREFI <= 'd0;        
    else if(init_end)
        cnt_tREFI <= cnt_tREFI + 'd1;
        
end

//每隔7.8us请求一次刷新，被允许后置低
always @(posedge ck or negedge rst_n) begin
    if(!rst_n) 
        aref_req <= 1'b0;
    else if(aref_en) 
        aref_req <= 1'b0;
    else if(cnt_tREFI >= DELAY_tREFI) 
        aref_req <= 1'b1;
end

always @(posedge ck or negedge rst_n) begin
    if(!rst_n) 
        aref_flag <= 1'b0;
    else if(aref_en)
        aref_flag <= 1'b1;
    else if(aref_end)
        aref_flag <= 1'b0;
end

always @(posedge ck or negedge rst_n) begin
    if(!rst_n)
        cnt_cmd <= 'd0;
    else if(aref_flag)
        cnt_cmd <= cnt_cmd + 'd1;
    else 
        cnt_cmd <= 'd0;
end

assign  aref_end = cnt_cmd >= AREF1_END ? 1'b1 : 1'b0;
assign  aref_addr = `ADDR_BITS'b0_0100_0000_0000;

always @(posedge ck or negedge rst_n) begin
    if(!rst_n) 
        aref_cmd <= NOP;
    else if(aref_flag) begin
        case(cnt_cmd)
            PRE1:       aref_cmd <= PRE;
            AREF1:      aref_cmd <= AREF;
            default:    aref_cmd <= NOP;
        endcase
    end
end

 endmodule
