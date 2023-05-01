/*
 *******************************************************************************
 *  Filename    :   ddr2_write.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *
 *******************************************************************************
 */
`include "define.v" 
module ddr2_write (
    input   wire                                        ck,
    input   wire                                        rst_n,
    input   wire                                        awvalid,
    output  reg                                         awready,
    input   wire    [`BA_BITS+`ROW_BITS+`COL_BITS-1:0]  awaddr,
    input   wire                                 [7:0]  awlen,
    input   wire                                        wvalid,
    output  reg                                         wready,
    input   wire                                        wlast,
    input   wire                      [`DQ_BITS*2-1:0]  wdata,
    output  wire                                        bvalid,
    input   wire                                        bready,
    input   wire                                        init_end,
    output  reg                       [`ADDR_BITS-1:0]  write_addr,
    output  reg                         [`BA_BITS-1:0]  write_ba,
    output  reg                                  [3:0]  write_cmd,
    output  reg                         [`DQ_BITS-1:0]  write_dq
);

parameter AL = `tRCD/`tCK - 1;
parameter WL = AL + `CL - 1;     

//state
parameter   W_IDLE      = 4'b0001;       
parameter   W_ACT       = 4'b0010;
parameter   W_WRITE     = 4'b0100;       
parameter   W_PRE       = 4'b1000;


//cmd
parameter   CMD_ACT     = 4'b0011;
parameter   CMD_NOP     = 4'b0111;
parameter   CMD_WR      = 4'b1000;
parameter   CMD_PRE     = 4'b0010;

reg     [3:0]   state;
integer cnt;
integer write_cnt;

always @(posedge ck or negedge rst_n) begin
    if(!rst_n) begin
        state <= W_IDLE;
        write_cmd <= CMD_NOP;
        cnt <= 'd0;
        write_cnt <= 'd0;
    end
    else begin
        case(state)
            W_IDLE:if(awvalid & awready) begin
                state <= W_ACT;
                {write_ba, write_addr} <= awaddr[`BA_BITS+`ROW_BITS+`COL_BITS-1:`COL_BITS];
                write_cmd <= CMD_ACT;
                cnt <= cnt + 1;
            end
            W_ACT:begin
                if(cnt == (`tRCD/`tCK - AL)) begin
                    state <= W_WRITE;
                    write_addr <= {(`ROW_BITS-`COL_BITS)'d0,awaddr[`COL_BITS-1:2],2'd0};
                    write_cmd  <= CMD_WR;
                    write_cnt <= write_cnt + 2;
                end else write_cmd <= CMD_NOP;   
                cnt <= cnt + 1;
            end
            //每隔一个周期,发出一个写命令。
            //一次写地址可以写4x8位数据（ddr2里突发为4），这里设总线突发为8,即需要8x16位数据，需要发4次写命令
            //若总线突发为2,则一次写命令即可
            W_WRITE:begin
                if(write_cnt == awlen) begin
                    state <= W_PRE;
                    write_cmd <= CMD_PRE;
                end
            end
        endcase
    end
end




endmodule