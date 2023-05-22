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
`include "../rtl/define.v"
module ddr2_ctrl #(
    parameter   BA_BITS     =   3,
    parameter   ADDR_BITS   =   14, // Address Bits
    parameter   ROW_BITS    =   14, // Number of Address bits
    parameter   COL_BITS    =   10, // Number of Column bits
    parameter   DM_BITS     =   1, // Number of Data Mask bits
    parameter   DQ_BITS     =   8, // Number of Data bits
    parameter   DQS_BITS    =   1 // Number of Dqs bits
)
(
    output  reg                                         clk,
    output  reg                                         rst_n,
    input   wire                                        clk800m,
    input   wire                                        rstn_async,
    output  wire                                        init_end,

    input   wire                                        axi_awvalid,
    output  wire                                        axi_awready,
    input   wire       [BA_BITS+ROW_BITS+COL_BITS-1:0]  axi_awaddr,
    input   wire                                 [7:0]  axi_awlen,
    input   wire                                        axi_wvalid,
    output  wire                                        axi_wready,
    input   wire                                        axi_wlast,
    input   wire                      [DQ_BITS*2-1:0]   axi_wdata,
    output  wire                                         axi_bvalid,
    input   wire                                        axi_bready,

    input   wire                                        axi_arvalid,
    output  wire                                        axi_arready,
    input   wire       [BA_BITS+ROW_BITS+COL_BITS-1:0]  axi_araddr, 
    input   wire                                [ 7:0]  axi_arlen,
    output  wire                                        axi_rvalid,
    input   wire                                        axi_rready,
    output  wire                                        axi_rlast,
    output  reg                       [DQ_BITS*2-1:0]   axi_rdata,

    output  wire                                        ddr2_clk,
    output  wire                                        ddr2_clk_n,
    output  wire                                        ddr2_cke,
    output  wire                                        ddr2_cs_n,
    output  wire                                        ddr2_we_n,
    output  wire                                        ddr2_ras_n,
    output  wire                                        ddr2_cas_n,
    output  wire                         [BA_BITS-1:0]  ddr2_ba,
    output  wire                       [ADDR_BITS-1:0]  ddr2_addr,
    inout                                [DQ_BITS-1:0]  ddr2_dq,
    inout                                [DM_BITS-1:0]  ddr2_dqm,
    inout                               [DQS_BITS-1:0]  ddr2_dqs,
    inout                               [DQS_BITS-1:0]  ddr2_dqs_n
   // output                  ddr2_odt   
);
parameter   tCK     =   5;      
parameter   tRPA    =   15;             // PRECHARGE ALL period             
parameter   tRFC    =   130;            // REFRESH to ACTIVATE or to REFRESH interval 原本应该是127.5，为了方便整除改为130,下同
parameter   tREFI   =   7800;           // Average periodic refresh
parameter   tRCD    =   15;             // ACTIVATE-to-READ or WRITE delay   12.5
parameter   tRRD    =   7.5;            // ACTIVATE-to ACTIVATE delay different bank
parameter   tRC     =   55;             // ACTIVATE-toACTIVATE delay,same bank
// parameter   tFAW    =   35;          
parameter   CL      =   3;              // CAS latency 速率400                  
parameter   BL      =   4;              // busrt length
parameter   tWR     =   15;             // WRITE recovery
parameter   tWTR     =  10;             // Internal WRITE-to-READ delay  7.5
parameter   tRTP    =   10;             // Internal READ-to-PRECHARGE delay 7.5

// -------------------------------------------------------------------------------------
//   clock and reset 
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

// -------------------------------------------------------------------------------------
//   state
// -------------------------------------------------------------------------------------
localparam  STATE_INIT      =   5'b0_0000;
localparam  STATE_IDLE      =   5'b0_0001;
localparam  STATE_AREF      =   5'b0_0011;
localparam  STATE_PRE       =   5'b0_0010;
localparam  STATE_ACT       =   5'b1_1101;

localparam  STATE_WRITE     =   5'b0_0101;
localparam  STATE_WROVER    =   5'b0_1001;
localparam  STATE_WRWAIT    =   5'b0_0111;
localparam  STATE_WRTORD    =   5'b0_0110;
localparam  STATE_WRTOPRE   =   5'b0_0100;
localparam  STATE_RETURNWR  =   5'b1_1001;  
localparam  STATE_WRTOAREF  =   5'b1_0101;

localparam  STATE_RETURNRD  =   5'b1_1110;  
localparam  STATE_RDTOAREF  =   5'b1_1111;
localparam  STATE_READ      =   5'b0_1100;  //c
// localparam  STATE_RDOVER    =   5'b0_1101;  //d 
localparam  STATE_RDWAIT    =   5'b0_1111;
localparam  STATE_RDTOPRE   =   5'b0_1110;  //e


// -------------------------------------------------------------------------------------
//   cmd
// -------------------------------------------------------------------------------------
localparam  NOP             =   4'b0111;
localparam  PRE             =   4'b0010;
localparam  AREF            =   4'b0001;
localparam  WRITE           =   4'b0100;
localparam  READ            =   4'b0101;
localparam  ACT             =   4'b0011;

// -------------------------------------------------------------------------------------
//   param
// -------------------------------------------------------------------------------------
localparam  DELAY_tREFI     =   tREFI/tCK;
localparam  RPA             =   tRPA/tCK;
localparam  RFC             =   tRFC/tCK;
localparam  ALLPRE_ADDR     =   (ADDR_BITS)'('b0_0100_0000_0000);           
localparam  AL              =   tRCD/tCK - 2;
localparam  WL              =   AL + CL - 1;    
localparam  RL              =   AL + CL;    
localparam  WR              =   tWR/tCK;
localparam  WTR             =   tWTR/tCK;
localparam  RTP             =   tRTP/tCK;
localparam  RTP1            = RTP < 'd2 ? 'd2 : RTP;
localparam  Delay_RD_TO_PRE = AL +  BL/2 - 'd2 + RTP1;

/*设置中断读/写操作转去刷新操作的阈值，
* 此处为还有8个及以上个周期的数据待传输的情况下，需要转去刷新，
* 否则当前操作完成再转去刷新*/
localparam  Threshold       =   'd8;  


reg                 [4:0]       state;
reg                 [3:0]       cmd;

wire        [BA_BITS-1:0]       init_ba;
wire      [ADDR_BITS-1:0]       init_addr;
wire                [3:0]       init_cmd;
wire                            init_cke;

reg                 [7:0]       wr_cnt;
reg                 [7:0]       rd_cnt;
reg                 [7:0]       ref_cnt;
reg                 [3:0]       act_cnt;
reg                 [3:0]       rp_cnt;
reg                 [3:0]       to_aref_cnt;
reg                [11:0]       refi_cnt;

// -------------------------------------------------------------------------------------
//   aref
// -------------------------------------------------------------------------------------
reg                             aref_req;
wire                            wr_to_aref_en;
wire                            rd_to_aref_en;
reg                  [7:0]      wr_cnt_history;
reg                  [1:0]      wr_or_rd_to_aref;
wire                            pre_wr_to_aref;
wire                            pre_rd_to_aref;

/*  允许打断读/写操作   */
assign wr_to_aref_en = state == STATE_WRITE && wr_cnt < axi_awlen - Threshold && wr_cnt[0] == 1'b0;
assign rd_to_aref_en = state == STATE_READ && rd_cnt < axi_arlen - Threshold && rd_cnt[0] == 1'b0;

assign pre_wr_to_aref = aref_req == 1'b1 &&  wr_to_aref_en;
assign pre_rd_to_aref = aref_req == 1'b1 && rd_to_aref_en;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        refi_cnt <= 'd0;
    else if( refi_cnt >= DELAY_tREFI) 
        refi_cnt <= 'd0;        
    else if(init_end)
        refi_cnt <= refi_cnt + 'd1;
end

/*  每隔7.8us请求一次刷新，被允许后置低 */
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        aref_req <= 1'b0;
    else if((state == STATE_IDLE || wr_to_aref_en || rd_to_aref_en)  && aref_req == 1'b1) 
        aref_req <= 1'b0;
    else if(refi_cnt >= DELAY_tREFI) 
        aref_req <= 1'b1;   
end

// -------------------------------------------------------------------------------------
//   write
// -------------------------------------------------------------------------------------

reg                 [WL:0]      wr_pipe;


reg        [DQ_BITS*2-1:0]      axi_wdata_1;
reg        [DQ_BITS*2-1:0]      axi_wdata_2;
reg          [DQ_BITS-1:0]      axi_wdata_h;
reg          [DQ_BITS-1:0]      axi_wdata_l;


reg          [DQ_BITS-1:0]      dq_pre;
reg          [DQ_BITS-1:0]      dq;
wire         [DQS_BITS-1:0]     dqs;
wire         [DQS_BITS-1:0]     dqs_n;
reg           [DM_BITS-1:0]     dqm_pre;
reg           [DM_BITS-1:0]     dqm;

/*  利用pipe记录前几个周期写的状态，由于，dq数据出现在总线上跟对应的写命令有延迟（WL) */
always @(posedge clk) begin
    if(!rst_n)
        wr_pipe <= 'd0;
    else if(state == STATE_WRITE && wr_cnt > 'd0)
        wr_pipe <= {wr_pipe[WL-'d1:0],1'b1};
    else
        wr_pipe <= {wr_pipe[WL-'d1:0], 1'b0};
end

always @(posedge clk) begin
    if(!rst_n) 
        axi_wdata_1 <= 'd0;
    else if(state == STATE_WRITE) 
        axi_wdata_1 <= axi_wdata;
end

always @(posedge clk) begin
    if(!rst_n) begin
        axi_wdata_2 <= 'd0;
        {axi_wdata_h, axi_wdata_l} <= 'd0;
    end else begin
        axi_wdata_2 <= axi_wdata_1;
        {axi_wdata_h, axi_wdata_l} <= axi_wdata_2;
    end
end

always @(posedge clk2) begin
  if(wr_pipe[WL-1]) begin
    dq_pre <= clk ? axi_wdata_l : axi_wdata_h;
    dqm_pre <= 'd0;
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

assign dqs = wr_pipe[WL] | wr_pipe[WL-1] ? {DQS_BITS{clk}} : 'dz;
assign dqs_n = wr_pipe[WL] | wr_pipe[WL-1] ? {DQS_BITS{!clk}} : 'dz;
assign ddr2_dq = dq;
assign ddr2_dqs = dqs;
assign ddr2_dqs_n = dqs_n;
assign ddr2_dqm = dqm;

// -------------------------------------------------------------------------------------
//   read
// -------------------------------------------------------------------------------------
reg             [RL+'d1:0]      rd_pipe;
reg          [DQ_BITS-1:0]      axi_rdata_l;
reg        [DQ_BITS*2-1:0]      pre_axi_rdata;


always @(posedge clk) begin
    if(!rst_n)
        rd_pipe <= 'd0;
    else if(state == STATE_READ && rd_cnt > 'd0)
        rd_pipe <= {rd_pipe[RL:0],1'b1};
    else
        rd_pipe <= {rd_pipe[RL:0], 1'b0};
end

always @(posedge clk2) begin
    if(rd_pipe[RL])begin
        axi_rdata_l <= ddr2_dq;
        pre_axi_rdata <= {ddr2_dq,axi_rdata_l};
    end
end

always @(posedge clk) begin
    if(rd_pipe[RL])
        axi_rdata <= pre_axi_rdata;
end

// -------------------------------------------------------------------------------------
//   state diagram
// -------------------------------------------------------------------------------------

reg         [ADDR_BITS-1:0]     addr;
reg           [BA_BITS-1:0]     ba;
reg          [COL_BITS-3:0]     init_col_addr;
reg          [ROW_BITS-1:0]     row_addr;
reg                             wr_en;
wire                            same_to_wr;
wire                            same_to_rd;
wire                            same_ba_col_w;
wire                            same_ba_col_r;

assign same_ba_col_w = (ba == axi_awaddr[BA_BITS + ROW_BITS+COL_BITS-1:COL_BITS + ROW_BITS])
                     && (row_addr == axi_awaddr[ROW_BITS+COL_BITS-1:COL_BITS]);
assign same_ba_col_r = (ba == axi_araddr[BA_BITS + ROW_BITS+COL_BITS-1:COL_BITS + ROW_BITS])
                     && (row_addr == axi_araddr[ROW_BITS+COL_BITS-1:COL_BITS]);

assign same_to_wr = aref_req == 1'b0 && axi_awvalid == 1'b1 && same_ba_col_w == 1'b1;
assign same_to_rd = aref_req == 1'b0 && axi_arvalid == 1'b1 && same_ba_col_r == 1'b1;

assign axi_awready = aref_req == 1'b0 && (state == STATE_IDLE || (state == STATE_WRWAIT && same_ba_col_w == 1'b1)
                                                          || (state == STATE_RDWAIT && same_ba_col_w == 1'b1));

assign axi_wready = wr_cnt >= 'd1 && wr_cnt <= axi_awlen;

assign axi_bvalid = wr_cnt > axi_awlen + WL ? 1'b1 : 1'b0;

assign axi_arready = aref_req == 1'b0 && !axi_awvalid && ((state == STATE_IDLE ) || (state == STATE_WRWAIT && same_ba_col_r == 1'b1)
                                                                            || (state == STATE_RDWAIT && same_ba_col_r == 1'b1)) ;

assign axi_rvalid = rd_pipe[RL + 'd1];   


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= STATE_INIT;
        ref_cnt <= 8'd0;
        cmd <= NOP;
        addr <= 0;
        ba <= 0 ;
        row_addr <= 'd0;
        init_col_addr <= 0;
        wr_or_rd_to_aref <= 2'b00;
        act_cnt <= WL + 'd2;
        // axi_awready_1 <= 1'b0;
    end else begin
        case (state) 
            STATE_INIT:   
                if(init_end) begin
                    state <= STATE_IDLE;
                end

            STATE_IDLE:   begin
                if(aref_req) begin 
                    state <= STATE_AREF;
                    cmd <= NOP;
                    ref_cnt <= 8'd0;
                end
                else if(axi_awvalid) begin 
                    act_cnt <= 'd0;    
                    wr_en <= 1'b1;  
                    cmd <= ACT;
                    {ba, addr} <= axi_awaddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                    row_addr <= axi_awaddr[ROW_BITS+COL_BITS-1:COL_BITS];
                    init_col_addr <= axi_awaddr[COL_BITS-1:2];
                    state <= STATE_ACT;
                end 
                else if(axi_arvalid) begin
                    act_cnt <= 'd0;
                    wr_en <= 1'b0;
                    cmd <= ACT;
                    {ba, addr} <= axi_araddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                    row_addr <= axi_araddr[ROW_BITS+COL_BITS-1:COL_BITS];
                    init_col_addr <= axi_araddr[COL_BITS-1:2];
                    state <= STATE_ACT;
                end
                else 
                    cmd <= NOP;
            end
    
            STATE_AREF:   begin   
                ref_cnt <= ref_cnt + 'd1;
                case(ref_cnt)
                    0:          begin cmd <= PRE; addr <= ALLPRE_ADDR;end
                    RPA:        cmd <= AREF;
                    RPA+RFC:begin  
                        if(wr_or_rd_to_aref == 2'b00) 
                            state <= STATE_IDLE;
                        else if(wr_or_rd_to_aref == 2'b01) begin  
                            cmd <= ACT;
                            {ba, addr} <= axi_awaddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                            row_addr <= axi_awaddr[ROW_BITS+COL_BITS-1:COL_BITS];
                            init_col_addr <= axi_awaddr[COL_BITS-1:2];
                            state <= STATE_RETURNWR;
                            act_cnt <= 'd0;
                        end else begin
                            cmd <= ACT;
                            {ba, addr} <= axi_araddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                            row_addr <= axi_araddr[ROW_BITS+COL_BITS-1:COL_BITS];
                            init_col_addr <= axi_araddr[COL_BITS-1:2];
                            state <= STATE_RETURNRD;
                            act_cnt <= 'd0;
                        end
                    end
                    default:    cmd <= NOP;
                endcase
            end

            STATE_ACT: begin
                act_cnt <= act_cnt + 'd1;
                if(act_cnt == 'd0 ) begin
                    if(wr_en) begin
                        state <= STATE_WRITE;
                        wr_cnt <= 'd0;
                    end else begin
                        state <= STATE_READ;
                        rd_cnt <= 'd0;
                    end
                end 
                cmd <= NOP;
            end

            STATE_WRITE: begin 

                // if(act_cnt < WL + 'd2)
                //     act_cnt <= act_cnt + 'd1;
                // ------------------------------------------------------------------------------------------
                // 当写数据突发长度较长，在写数据时，数据刷新请求到来，需要先保存当前状态，再去执行刷新，然后再回来
                // ------------------------------------------------------------------------------------------
               
                wr_cnt <= wr_cnt + 'd1;
                if(axi_wlast)begin
                    state <= STATE_WROVER;  
                    cmd <= NOP;
                end
                else if(pre_wr_to_aref) begin
                    wr_cnt_history <= wr_cnt+1;
                    wr_cnt <= axi_awlen + 1;
                    state <= STATE_WRTOAREF;
                    to_aref_cnt <= 'd0;
                    wr_or_rd_to_aref <= 2'b01;
                end 
                else if(axi_wvalid ) begin
                    if(wr_cnt[0] == 1'b0) begin
                        cmd <= WRITE;
                        addr <= {init_col_addr + (wr_cnt >> 1), 2'b0};
                    end else
                        cmd <= NOP;
                end 
           end

            STATE_WRTOAREF:begin
                if(to_aref_cnt < WL + WR)
                    to_aref_cnt <= to_aref_cnt + 'd1;
                else begin
                    state <= STATE_AREF;
                    ref_cnt <= 'd0;
                end
            end

            STATE_RETURNWR:begin
                act_cnt <= act_cnt + 'd1;
                if(act_cnt == 'd1) begin
                    cmd <= WRITE;
                    state <= STATE_WRITE;
                    wr_cnt <= wr_cnt_history;
                    wr_or_rd_to_aref <= 2'b00;
                    addr <= {init_col_addr + ((wr_cnt_history-'d1) >> 1), 2'b0};
                end else 
                    cmd <= NOP;
            end
            // ------------------------------------------------------------------------------------------
            // 1、下一次写请求到来，且在同一bank、row, 需要等到前面的 cmd 、axi_wdata,等 都给到，后续信号才响应 
            // 2、在写数据完全传输到总线上后，转为另一等待状态，
            // 3、这一等待状态可以接收其他请求
            // ------------------------------------------------------------------------------------------

            STATE_WROVER: begin
                wr_cnt <= wr_cnt + 'd1;
                if (wr_cnt == axi_awlen + WL) 
                    state <= STATE_WRWAIT;

            end

            STATE_WRWAIT: begin
                if(wr_cnt < axi_awlen + WL + WR + 1)
                    wr_cnt <= wr_cnt + 1'b1;
                // cmd <= NOP;
                //写请求到来，且同一bank,row,不需要写恢复
                if(same_to_wr) begin
                        state <= STATE_WRITE;
                        wr_cnt <= 'd0;
                        init_col_addr <= axi_awaddr[COL_BITS-1:2];

                end
                //读请求到来,同一～，需要写恢复
                //需要等待tWTR时间后
                else if(same_to_rd) begin
                    state <= STATE_WRTORD;
                end
                // 读/写请求不在同一bank/row、刷新请求到来，需要写恢复
                else if(axi_awvalid == 1'b1 || aref_req == 1'b1 || axi_arvalid == 1'b1) begin
                    state <= STATE_WRTOPRE;
                end
            end
            
            STATE_WRTORD:begin
                wr_cnt <= wr_cnt + 1;
                if(wr_cnt >= axi_awlen + WL + WTR)  begin
                    rd_cnt <= 'd0;
                    init_col_addr <= axi_araddr[COL_BITS-1:2];
                    state <= STATE_READ;
                end
            end
            
            STATE_WRTOPRE: begin
                wr_cnt <= wr_cnt + 1;
                if(wr_cnt >= axi_awlen + WL + WR) begin
                    state <= STATE_PRE;
                    rp_cnt <= 'd0;
                    cmd <= PRE;         
                    addr <= ALLPRE_ADDR;
                end
            end

            STATE_PRE: begin
                rp_cnt <= rp_cnt + 1;
                cmd <= NOP;
                if(rp_cnt >= tRPA/tCK) begin
                    state <= STATE_IDLE;
                end
            end
            
            STATE_READ: begin
                rd_cnt <= rd_cnt + 1;
                // ------------------------------------------------------------------------------------------
                // 当读数据突发长度较长，在读数据时，数据刷新请求到来，需要先保存当前状态，再去执行刷新。。。
                // ------------------------------------------------------------------------------------------
                if(rd_cnt == axi_arlen) 
                    state <= STATE_RDWAIT;
                else if(pre_rd_to_aref) begin
                    state <= STATE_RDTOAREF;
                    to_aref_cnt <= 'd0;
                    wr_or_rd_to_aref <= 2'b10;
                end 
                else if(axi_rready) begin 
                    if(rd_cnt[0] == 1'b0) begin
                        cmd <= READ;
                        addr <= {init_col_addr + (rd_cnt >> 1), 2'b0};
                    end else
                        cmd <= NOP;
                end
            end

            STATE_RDTOAREF:begin
                if(to_aref_cnt < Delay_RD_TO_PRE)
                    to_aref_cnt <= to_aref_cnt + 'd1;
                else begin
                    state <= STATE_AREF;
                    ref_cnt <= 'd0;
                end
            end

            STATE_RETURNRD:begin
                act_cnt <= act_cnt + 'd1;
                if(act_cnt == 'd1) begin
                    cmd <= READ;
                    state <= STATE_READ;
                    wr_or_rd_to_aref <= 2'b00;
                    addr <= {init_col_addr + ((rd_cnt) >> 1), 2'b0};
                    // addr <= {init_col_addr + ((wr_cnt-'d1) >> 1), 2'b0};
                end else 
                    cmd <= NOP;
            end

            // STATE_RDOVER:begin
            //     rd_cnt <= rd_cnt + 1;
            //     if(rd_cnt == axi_arlen + RL + 'd2)
            //         state <= STATE_RDWAIT;
            // end

            STATE_RDWAIT: begin
                if(rd_cnt < axi_arlen + Delay_RD_TO_PRE)
                    rd_cnt <= rd_cnt + 1;
                if(same_to_wr) begin
                    wr_cnt <= 'd0;
                    init_col_addr <= axi_awaddr[COL_BITS-1:2];
                    state <= STATE_WRITE;
                end 
                else if(same_to_rd) begin
                    rd_cnt <= 'd0;
                    init_col_addr <= axi_araddr[COL_BITS-1:2];
                    state <= STATE_READ;
                end 
                else if(axi_arvalid == 1'b1 || axi_awvalid == 1'b1 || aref_req == 1'b1) begin
                    state <= STATE_RDTOPRE;
                end
             end

             STATE_RDTOPRE: begin
                rd_cnt <= rd_cnt + 1;
                if(rd_cnt >= axi_arlen + Delay_RD_TO_PRE) begin
                    state <= STATE_PRE;
                    rp_cnt <= 'd0;
                    cmd <= PRE;
                    addr <= ALLPRE_ADDR;
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
