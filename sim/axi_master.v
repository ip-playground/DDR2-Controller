    /*
 *******************************************************************************
 *  Filename    :   axi_master.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *
 *******************************************************************************
 */
`include "../rtl/define.v" 

module axi_master #(
    parameter           ADDR_WIDTH  = `ROW_BITS + `COL_BITS + `BA_BITS,
    parameter           DATA_WIDTH  = `DQ_BITS * 2,
    parameter           DATA_LEVEL  = 2,
    parameter   [7:0]   WBURST_LEN   = 8'd8,
    parameter   [7:0]   RBURST_LEN   = 8'd8 
)(
    input   wire                        rstn,
    input   wire                        clk,
    input   wire                        init_end,
    input   wire                        w_trig,
    output  wire                        awvalid,
    input   wire                        awready,
    output  reg     [ADDR_WIDTH-1:0]    awaddr,
    output  wire    [           7:0]    awlen,
    output  wire                        wvalid,
    input   wire                        wready,
    output  wire                        wlast,
    output  reg     [DATA_WIDTH-1:0]    wdata,
    input   wire                        bvalid,
    output  wire                        bready

);


//state
parameter   INIT    = 3'b000;
parameter   AW      = 3'b001;
parameter   W       = 3'b010;   
parameter   B       = 3'b011;
reg     [2:0]   state;

//initial  awaddr = 'd0;

reg     [3:0]   w_cnt;

assign awvalid = state == AW;
assign awlen   = WBURST_LEN;
assign wlast   = w_cnt == awlen + 1;
assign wvalid  = state == W;
assign bready  = 1'b1;


parameter   delay_wr_gap = 50;
integer  cnt_wr_gap;
reg         wr_req; 
always @(posedge clk or negedge rstn) begin
    if(!rstn) 
        cnt_wr_gap <= 'd0;
    else if( cnt_wr_gap >= delay_wr_gap) 
        cnt_wr_gap <= 'd0;        
    else if(init_end)
        cnt_wr_gap <= cnt_wr_gap + 'd1;
        
end

//每隔100ns请求一次写请求，被允许后置低
always @(posedge clk or negedge rstn) begin
    if(!rstn) 
        wr_req <= 1'b0;
    else if(state == INIT && wr_req == 1'b1) 
        wr_req <= 1'b0;
    else if(cnt_wr_gap >= delay_wr_gap) 
        wr_req <= 1'b1;   
end

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
       awaddr <= 'd16;
       w_cnt <= 'd0;
       state <= INIT;
       wdata <= 'd0;
    end else begin
        case(state)
            INIT:begin
                // if(w_trig) 
                if(wr_req)
                    state <= AW;
            end
            AW:  if(awready)begin
                   state <= W;
                   w_cnt <= 8'd0;
            end
            W:begin
                w_cnt <= w_cnt + 1;
                if(wlast)
                  state <= B;
                else if(wready) 
                  wdata <= w_cnt;
            end
            B:begin
                if (bvalid) begin 
                    awaddr <= awaddr + 'd16;
                    state <= INIT;
                end
            end
        endcase

    end
end


endmodule
