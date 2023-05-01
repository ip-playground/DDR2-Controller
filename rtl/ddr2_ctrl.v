/*
 *******************************************************************************
 *  Filename    :   ddr2_init.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *  Created     :   3/22/2023
 *
 *******************************************************************************
 */
 
`include "/home/caoshiyang/ddr2/DDR2-Controller/rtl/define.v"
module ddr2_ctrl(
    output  reg                                         clk,
    output  reg                                         rst_n,
    input   wire                                        clk800m,
    input   wire                                        rstn_async,
    output  wire                                        init_end,

    input   wire                                        awvalid,
    output  wire                                        awready,
    input   wire    [`BA_BITS+`ROW_BITS+`COL_BITS-1:0]  awaddr,
    input   wire                                 [7:0]  awlen,
    input   wire                                        wvalid,
    output  wire                                        wready,
    input   wire                                        wlast,
    input   wire                      [`DQ_BITS*2-1:0]  wdata,
    output  reg                                         bvalid,
    input   wire                                        bready,
    
    output  wire                                        ddr2_clk,
    output  wire                                        ddr2_clk_n,
    output  wire                                        ddr2_cke,
    output  wire                                        ddr2_cs_n,
    output  wire                                        ddr2_we_n,
    output  wire                                        ddr2_ras_n,
    output  wire                                        ddr2_cas_n,
    output  wire                        [`BA_BITS-1:0]  ddr2_ba,
    output  wire                      [`ADDR_BITS-1:0]  ddr2_addr,
    inout                                        [7:0]  ddr2_dq,
    inout                                               ddr2_dqm,
    inout                                               ddr2_dqs,
    inout                                               ddr2_dqs_n
   // output                  ddr2_odt   
);

// -------------------------------------------------------------------------------------
//   cloclk and reset 
// ------------------------------------------------------------------------------------------------------------------------
// generate reset sync with clk800m
// -------------------------------------------------------------------------------------
reg       rstn_clk   ;
reg [1:0] rstn_clk_l ;
always @ (posedge clk800m or negedge rstn_async)
    if(~rstn_async)
        {rstn_clk, rstn_clk_l} <= 'd0;
    else
        {rstn_clk, rstn_clk_l} <= {rstn_clk_l, 1'b1};

// -------------------------------------------------------------------------------------
//   generate cloclks
// -------------------------------------------------------------------------------------
reg clk2;
always @ (posedge clk800m or negedge rstn_clk)
    if(~rstn_clk)
        {clk,clk2} <= 2'b00;
    else
        {clk,clk2} <= {clk,clk2} + 2'b01;

// -------------------------------------------------------------------------------------
// generate reset sync with clk
// -------------------------------------------------------------------------------------
reg       rstn_aclk   ;
reg [2:0] rstn_aclk_l ;
always @ (posedge clk or negedge rstn_async)
    if(~rstn_async)
        {rstn_aclk, rstn_aclk_l} <= 'd0;
    else
        {rstn_aclk, rstn_aclk_l} <= {rstn_aclk_l, 1'b1};

// -------------------------------------------------------------------------------------
//   generate user reset
// -------------------------------------------------------------------------------------
always @ (posedge clk or negedge rstn_aclk)
    if(~rstn_aclk)
        rst_n <= 1'b0;
    else
        rst_n <= 1'b1;


//state
localparam  STATE_INIT      =   5'b0_0000;
localparam  STATE_IDLE      =   5'b0_0001;
localparam  STATE_AREF      =   5'b0_0010;
localparam  STATE_PRE       =   5'b0_0011;

localparam  STATE_WRITE     =   5'b0_0111;
localparam  STATE_WRDATA    =   5'b0_0101;
localparam  STATE_WRITE2    =   5'b0_0100;
localparam  STATE_WRWAIT    =   5'b0_0110;

localparam  STATE_READ      =   5'b1_0000;

reg         [4:0]               state;//暂时写为5位
reg         [3:0]               cmd;


//cmd
localparam  NOP             =   4'b0111;
localparam  PRE             =   4'b0010;
localparam  AREF            =   4'b0001;
localparam  WRITE           =   4'b0100;
localparam  ACT             =   4'b0011;


// -------------------------------------------------------------------------------------
//   init
// -------------------------------------------------------------------------------------
// wire                            init_end; 
wire        [`BA_BITS-1:0]      init_ba;
wire        [`ADDR_BITS-1:0]    init_addr;
wire        [3:0]               init_cmd;
wire                            init_cke;
// -------------------------------------------------------------------------------------
//   aref
// -------------------------------------------------------------------------------------
reg                             aref_req;
integer                         cnt_tREFI;
reg         [7:0]               ref_cnt;

localparam  DELAY_tREFI     =   `tREFI/`tCK;
localparam  RPA             =   `tRPA/`tCK;
localparam  RFC             =   `tRFC/`tCK;
localparam  ALLPRE_ADDR     =   `ADDR_BITS'b0_0100_0000_0000;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        cnt_tREFI <= 'd0;
    else if( cnt_tREFI >= DELAY_tREFI) 
        cnt_tREFI <= 'd0;        
    else if(init_end)
        cnt_tREFI <= cnt_tREFI + 'd1;
        
end

//每隔7.8us请求一次刷新，被允许后置低
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        aref_req <= 1'b0;
    else if(state == STATE_IDLE && aref_req == 1'b1) 
        aref_req <= 1'b0;
    else if(cnt_tREFI >= DELAY_tREFI) 
        aref_req <= 1'b1;   
end
// -------------------------------------------------------------------------------------
//   write
// -------------------------------------------------------------------------------------



reg         [`COL_BITS-3:0]     init_col_addr;
reg         [`COL_BITS-1:0]     col_addr;
reg                   [5:0]     w_cnt;
reg                   [5:0]     wrwait_cnt;
reg                   [5:0]     rp_cnt;

reg        [`DQ_BITS*2-1:0]     wdata_1;
reg        [`DQ_BITS*2-1:0]     wdata_2;
reg        [`DQ_BITS*2-1:0]     wdata_3;
reg          [`DQ_BITS-1:0]     wdata_h;
reg          [`DQ_BITS-1:0]     wdata_l;


reg          [`DQ_BITS-1:0]     dq_pre;
reg          [`DQ_BITS-1:0]     dq;
wire                            dqs;
wire                            dqs_n;
reg                             dqm_pre;
reg                             dqm;
reg                   [5:0]     time_after_cmd_wr;

localparam  AL              =   `tRCD/`tCK - 1;
localparam  WL              =   AL + `CL - 1;    
localparam  WR              =   `tWR/`tCK;

always @(posedge clk) begin
  if(!rst_n) begin
    wdata_1 <= 'd0;
    wdata_2 <= 'd0;
    wdata_3 <= 'd0;
  end else if(state == STATE_WRITE || state == STATE_WRDATA) begin
  // end else begin
    wdata_1 <= wdata;
    wdata_2 <= wdata_1;
    wdata_3 <= wdata_2;
  end
end

always @(posedge clk) begin
  {wdata_h, wdata_l} <= wdata_3;
end

always @(posedge clk) begin
  if(!rst_n) time_after_cmd_wr <= 'd9;
  else if(w_cnt == 'd5) time_after_cmd_wr <= 'd0;
  else if(time_after_cmd_wr < 'd9) time_after_cmd_wr <= time_after_cmd_wr + 'd1;
end

always @(posedge clk2) begin
  if(time_after_cmd_wr >= 'd0 && time_after_cmd_wr <= 'd7) begin
    dq_pre <= clk ? wdata_l : wdata_h;
    dqm_pre <= 0;
  end else begin
    dq_pre <= 'dz;
    dqm_pre <= 'dz;
  end
end

//delay
always @(posedge clk2) begin
  if(!rst_n) begin
    dq <= 'dz;
    dqm <= 'dz;
  end
  else begin
    dq <= dq_pre;
    dqm <= dqm_pre;
  end
end

assign dqs = time_after_cmd_wr >= 'd0 && time_after_cmd_wr <= 'd8 ? clk : 'dz;
assign dqs_n = time_after_cmd_wr >= 'd0 && time_after_cmd_wr <= 'd8 ? !clk : 'dz;
assign ddr2_dq = dq;
assign ddr2_dqs = dqs;
assign ddr2_dqs_n = dqs_n;
assign ddr2_dqm = dqm;
    
// -------------------------------------------------------------------------------------
//   state diagram
// -------------------------------------------------------------------------------------

reg         [`ADDR_BITS-1:0]    addr;
reg         [`BA_BITS-1:0]      ba;
reg         [`ROW_BITS-1:0]     row_addr;
wire                            wr_to_wr;
wire                            same_ba_col;
assign same_ba_col = (ba == awaddr[`BA_BITS + `ROW_BITS+`COL_BITS-1:`COL_BITS + `ROW_BITS])
                     && (row_addr == awaddr[`ROW_BITS+`COL_BITS-1:`COL_BITS]);

assign wr_to_wr = aref_req == 1'b0 && awvalid == 1'b1 && same_ba_col == 1'b1;

assign awready = aref_req == 1'b0 && (state == STATE_IDLE || (state == STATE_WRWAIT && same_ba_col == 1'b1)
                                                          || (state == STATE_WRITE && same_ba_col == 1'b1));
assign wready = state == STATE_WRITE;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= STATE_INIT;
        ref_cnt <= 8'd0;
        cmd <= NOP;
        addr <= 0;
        ba <= 0 ;
        init_col_addr <= 0;
        col_addr <= 0;
    end else begin
        case (state) 

            STATE_INIT:   if(init_end)   state <= STATE_IDLE;

            STATE_IDLE:   begin
                if(aref_req)   begin 
                    state <= STATE_AREF;
                    cmd <= NOP;
                    ref_cnt <= 8'd0;
                end
                else if(awvalid)    begin 
                    w_cnt <= 6'd0;
                    cmd <= ACT;
                    {ba, addr} <= awaddr[`BA_BITS+`ROW_BITS+`COL_BITS-1:`COL_BITS];
                    row_addr <= awaddr[`ROW_BITS+`COL_BITS-1:`COL_BITS];
                    init_col_addr <= awaddr[`COL_BITS-1:2];
                    state <= STATE_WRITE;
                end else 
                    cmd <= NOP;
            end

            STATE_AREF:   begin   
                ref_cnt <= ref_cnt + 8'd1;
                case(ref_cnt)
                    0:          begin cmd <= PRE; addr <= ALLPRE_ADDR;end
                    RPA:        cmd <= AREF;
                    RPA+RFC:    state <= STATE_IDLE;
                    default:    cmd <= NOP;
                endcase
            end

            // STATE_WRITE: begin
            //     // 暂时没有后续写请求    
            //     if (w_cnt > awlen + WL) begin
            //         state <= STATE_WRWAIT;
            //         wrwait_cnt <= 'd0;
            //         cmd <= NOP;
            //         w_cnt <= w_cnt + 1;
            //     end
                //下一次写请求到来，且在同一bank、row
                // 需要等到前面的 cmd 、wdata,等 都给到后续信号才响应 
                // else if(w_cnt > awlen) begin
                //     if(wr_to_wr) begin                
                //         w_cnt <= 'd0; 
                //         init_col_addr <= awaddr[`COL_BITS-1:2];
                //         state <= STATE_WRITE;
                //     end
                //     else w_cnt <= w_cnt + 1;
                // end
                // else begin
                //     if(w_cnt[0] == 1'b1)  begin
                //         cmd <= WRITE;
                //         // cmd <= w_cnt == 'd0 ? WRITE : NOP;
                //         addr <= {init_col_addr + (w_cnt >> 1), 2'b0};
                //     end
                //     else cmd <= NOP;
                //     w_cnt <= w_cnt + 1;
                // end 
            // end 

            STATE_WRITE: begin
                w_cnt <= w_cnt + 1;
                if(w_cnt == awlen + 1) state <= STATE_WRDATA;
                else if(wvalid) begin
                    if(w_cnt[0] == 1'b1) begin
                        cmd <= WRITE;
                        addr <= {init_col_addr + (w_cnt >> 1), 2'b0};
                    end else
                        cmd <= NOP;
                end
                bvalid <= w_cnt == awlen + 1;
            end

            // ------------------------------------------------------------------------------------------
            // 1、下一次写请求到来，且在同一bank、row, 需要等到前面的 cmd 、wdata,等 都给到，后续信号才响应 
            // 2、在写数据完全传输到总线上后，转为另一等待状态，
            // 3、这一等待状态可以接收更多其他请求
            // ------------------------------------------------------------------------------------------
            STATE_WRDATA: begin
                if(wr_to_wr) begin          
                    w_cnt <= 'd0; 
                    init_col_addr <= awaddr[`COL_BITS-1:2];
                    state <= STATE_WRITE;
                end else
                    w_cnt <= w_cnt + 1;
                if (w_cnt > awlen + WL) begin
                    state <= STATE_WRWAIT;
                    wrwait_cnt <= 'd0;
                end
            end

            // ------------------------------------------------------------------------------------------
            // 可以接受 不同行操作（读/写）、同行读、刷新操作等 
            // ------------------------------------------------------------------------------------------
            STATE_WRWAIT: begin
                if(wrwait_cnt < WR)
                    wrwait_cnt <= wrwait_cnt + 1'b1;
                // cmd <= NOP;
                //写请求到来，且同一bank,row,不需要写恢复
                if(wr_to_wr) begin
                    state <= STATE_WRITE;
                    w_cnt <= 'd0;
                    init_col_addr <= awaddr[`COL_BITS-1:2];
                end
                //读请求到来,同一～，需要写恢复
                //需要等待tWTR时间后
                // else if(wr_to_rd && wrwait_cnt >= 2) begin
                //     state <= STATE_READ;
                // end
                
                // 读/写请求不在同一bank/row、刷新请求到来，需要写恢复
                else if((awvalid == 1'b1 || aref_req == 1'b1 ) && (wrwait_cnt == WR)) begin
                    state <= STATE_PRE;
                    rp_cnt <= 'd0;
                    cmd <= PRE;
                    addr <= ALLPRE_ADDR;
                end
            end

            STATE_PRE: begin
                rp_cnt <= rp_cnt + 1;
                cmd <= NOP;
                if(rp_cnt >= `tRPA/`tCK) begin
                    state <= STATE_IDLE;
                end
            end

        endcase 
    end
end


// -------------------------------------------------------------------------------------
//   connect
// -------------------------------------------------------------------------------------
assign {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} = state == STATE_INIT ? init_cmd : cmd;
assign ddr2_ba = state == STATE_INIT ? init_ba : ba;
assign ddr2_addr = state == STATE_INIT ? init_addr : addr;


assign  ddr2_clk = clk;
assign  ddr2_clk_n = ~clk;
assign  ddr2_cke = init_cke;



ddr2_init ddr2_init_inst(
    .clk                        (clk),
    .rst_n                      (rst_n),
    .init_cke                   (init_cke),
    .init_ba                    (init_ba),
    .init_cmd                   (init_cmd),
    .init_addr                  (init_addr),
    .init_end                   (init_end)
);



endmodule
