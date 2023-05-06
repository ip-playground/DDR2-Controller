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
    output  wire                        bready,

    output  wire                        arvalid,
    input   wire                        arready,
    output  reg     [ADDR_WIDTH-1:0]    araddr,
    output  wire              [7:0]     arlen,
    input   wire                        rvalid,
    output  wire                        rready,
    input   wire                        rlast,
    input   wire    [DATA_WIDTH-1:0]    rdata

);


//state_w
parameter   IDLE    = 3'b000;
parameter   AW      = 3'b001;
parameter   W       = 3'b010;   
parameter   B       = 3'b011;
parameter   AR      = 3'b101;
parameter   R       = 3'b110;   
parameter   RUN     = 3'b111;   
reg     [2:0]   state_w;

reg     [2:0]   state_ar;
reg     [2:0]   state_r;
reg     [5:0]   ar_cnt;
reg             mark;
reg             same_ba_col_r;
wire    [ADDR_WIDTH-1:0]   next_araddr;
assign next_araddr = araddr + 'd16;
//initial  awaddr = 'd0;

reg     [3:0]   w_cnt;
reg     [3:0]   r_cnt;

assign awvalid  = state_w == AW;
assign awlen    = WBURST_LEN;
assign wlast    = w_cnt == awlen + 1;
assign wvalid   = state_w == W;
assign bready   = 1'b1;
assign arlen    = WBURST_LEN;
//让初始化后的前面9us单纯写，之后开始读
parameter   wr_circle = 1500;//9us/5ns = 1800
integer     cnt_circle;
always @(posedge clk or negedge rstn) begin
    if(!rstn) 
        cnt_circle <= 'd0;
    else if(init_end && cnt_circle < wr_circle)
        cnt_circle <= cnt_circle + 1;
end


parameter   delay_wr_gap = 30;
parameter   delay_rd_gap = 50;
integer  cnt_wr_gap;
integer  cnt_rd_gap;
reg         wr_req;
reg         rd_req;

// always @(posedge clk or negedge rstn) begin
//     if(!rstn) 
//         cnt_wr_gap <= 'd0;
//     else if( cnt_wr_gap >= delay_wr_gap) 
//         cnt_wr_gap <= 'd0;        
//     else if(init_end && cnt_circle < wr_circle)
//         cnt_wr_gap <= cnt_wr_gap + 'd1;        
// end

// //每隔50ns请求一次写请求，被允许后置低
// always @(posedge clk or negedge rstn) begin
//     if(!rstn) 
//         wr_req <= 1'b0;
//     else if(state_w == IDLE && wr_req == 1'b1) 
//         wr_req <= 1'b0;
//     else if(cnt_wr_gap >= delay_wr_gap) 
//         wr_req <= 1'b1;   
// end

// always @(posedge clk or negedge rstn) begin
//     if(!rstn) 
//         cnt_rd_gap <= 'd0;
//     else if( cnt_rd_gap >= delay_rd_gap) 
//         cnt_rd_gap <= 'd0;        
//     else if(init_end && cnt_circle == wr_circle)
//         cnt_rd_gap <= cnt_rd_gap + 'd1;        
// end
// always @(posedge clk or negedge rstn) begin
//     if(!rstn) 
//         rd_req <= 1'b0;
//     else if(arvalid == 1'b1 && arready == 1'b1 ) 
//         rd_req <= 1'b0;
//     else if(cnt_rd_gap >= delay_rd_gap && cnt_circle == wr_circle) 
//         rd_req <= 1'b1;   
// end
always @(posedge clk or negedge rstn) begin
    if(!rstn) 
        cnt_wr_gap <= 'd0;
    else if( cnt_wr_gap >= delay_wr_gap) 
        cnt_wr_gap <= 'd0;        
    else if(init_end)
        cnt_wr_gap <= cnt_wr_gap + 'd1;        
end

//每隔50ns请求一次写请求，被允许后置低
always @(posedge clk or negedge rstn) begin
    if(!rstn) 
        wr_req <= 1'b0;
    else if(state_w == IDLE && wr_req == 1'b1) 
        wr_req <= 1'b0;
    else if(cnt_wr_gap >= delay_wr_gap) 
        wr_req <= 1'b1;   
end

always @(posedge clk or negedge rstn) begin
    if(!rstn) 
        cnt_rd_gap <= 'd0;
    else if( cnt_rd_gap >= delay_rd_gap) 
        cnt_rd_gap <= 'd0;        
    else if(init_end)
        cnt_rd_gap <= cnt_rd_gap + 'd1;        
end
always @(posedge clk or negedge rstn) begin
    if(!rstn) 
        rd_req <= 1'b0;
    else if(arvalid == 1'b1 && arready == 1'b1 ) 
        rd_req <= 1'b0;
    else if(cnt_rd_gap >= delay_rd_gap) 
        rd_req <= 1'b1;   
end

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
       awaddr <= 'd16;
       w_cnt <= 'd0;
       state_w <= IDLE;
       wdata <= 'd0;
    end else begin
        case(state_w)
            IDLE:begin
                // if(w_trig) 
                if(wr_req)
                    state_w <= AW;
            end
            AW:  if(awready)begin
                   state_w <= W;
                   w_cnt <= 8'd0;
            end
            W:begin
                w_cnt <= w_cnt + 1;
                if(wlast)
                  state_w <= B;
                else if(wready) 
                  wdata <= w_cnt;
            end
            B:begin
                if (bvalid) begin 
                    awaddr <= awaddr + 'd16;
                    state_w <= IDLE;
                end
            end
        endcase

    end
end  




assign arvalid = state_ar == IDLE && rd_req == 1'b1;
always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
       araddr <= 'd16;
       ar_cnt <= 'd0;
       state_ar <= IDLE;
       mark <= 1'b0;
       same_ba_col_r <= 0;
    end else begin
        case(state_ar)
            IDLE:begin
                if(arready && rd_req)begin 
                    state_ar <= RUN;
                    ar_cnt <= same_ba_col_r == 1'b1 ? 'd2 : 'd0;
               end
           end
            RUN:begin
                ar_cnt <= ar_cnt + 'd1;
                // if(ar_cnt == 'd4) 
                //     mark <= 1'b1;
                // else if(state_r == RUN)
                //     mark <= 1'b0;
                if(ar_cnt == 'd8) begin
                    same_ba_col_r <= araddr[ADDR_WIDTH-1 : `COL_BITS] ^ next_araddr[ADDR_WIDTH-1 : `COL_BITS] == 'd0 ? 1'b1 : 1'b0;
                    araddr <= next_araddr;
                    state_ar <= IDLE;  
                end 
            end
        endcase
    end
end


assign rready = state_r == IDLE;
always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
       r_cnt <= 'd0;
       state_r <= IDLE;
    end else begin
        case(state_r)
            IDLE:begin
                // if(mark) begin
                if(rvalid) begin
                    state_r <= RUN;
                    r_cnt <= 'd0;
                end
            end
            RUN:begin
                r_cnt <= r_cnt + 'd1;
                if(rlast)
                    state_r <= IDLE; 
            end
        endcase
    end
end
// always@(posedge clk or negedge rstn) begin
//     if(!rstn) begin
//        araddr <= 'd16;
//        r_cnt <= 'd0;
//        state_r <= IDLE;
//     end else begin
//         case(state_r)
//             IDLE:begin
//                 if(rd_req)
//                     state_r <= AR;
//             end
//             AR:  if(arready)begin
//                    state_r <= R;
//                    r_cnt <= 8'd0;
//             end
//             R:begin
//                 r_cnt <= r_cnt + 1;
//                 if(rlast)
//                   state_r <=  IDLE;
//             end
//         endcase

//     end
// end

endmodule
