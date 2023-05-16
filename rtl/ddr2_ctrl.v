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

    input   wire                                        awvalid,
    output  wire                                        awready,
    input   wire       [BA_BITS+ROW_BITS+COL_BITS-1:0]  awaddr,
    input   wire                                 [7:0]  awlen,
    input   wire                                        wvalid,
    output  wire                                         wready,
    input   wire                                        wlast,
    input   wire                      [DQ_BITS*2-1:0]   wdata,
    output  reg                                         bvalid,
    input   wire                                        bready,

    input   wire                                        arvalid,
    output  wire                                        arready,
    input   wire       [BA_BITS+ROW_BITS+COL_BITS-1:0]  araddr, 
    input   wire                                [ 7:0]  arlen,
    output  wire                                        rvalid,
    input   wire                                        rready,
    output  wire                                        rlast,
    output  reg                       [DQ_BITS*2-1:0]  rdata,

    output  wire                                        ddr2_clk,
    output  wire                                        ddr2_clk_n,
    output  wire                                        ddr2_cke,
    output  wire                                        ddr2_cs_n,
    output  wire                                        ddr2_we_n,
    output  wire                                        ddr2_ras_n,
    output  wire                                        ddr2_cas_n,
    output  wire                         [BA_BITS-1:0]  ddr2_ba,
    output  wire                       [ADDR_BITS-1:0]  ddr2_addr,
    inout                                        [7:0]  ddr2_dq,
    inout                                               ddr2_dqm,
    inout                                               ddr2_dqs,
    inout                                               ddr2_dqs_n
   // output                  ddr2_odt   
);
parameter   tCK     =   5;               
parameter   tRPA    =   15;             
parameter   tRFC    =   130;          //原本应该是127.5，为了方便整除改为130
//ref模块
parameter   tREFI   =   7800;
//Active
parameter   tRCD    =   15;      //12.5
parameter   tRRD    =   7.5;
parameter   tRC     =   55;
parameter   tFAW    =   35;
//Write
parameter   CL      =   3;       //速率400                  
parameter   BL      =   4;
parameter   tWR     =   15;
parameter   tWTR     =  10;     //7.5
//Read
parameter   tRTP    =   10; //7.5

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


//state
localparam  STATE_INIT      =   5'b0_0000;
localparam  STATE_IDLE0     =   5'b1_0000;
localparam  STATE_IDLE      =   5'b0_0001;
localparam  STATE_ACT       =   5'b1_0001;
localparam  STATE_AREF      =   5'b0_0010;
localparam  STATE_PRE       =   5'b0_0011;

localparam  STATE_WRITE     =   5'b0_0111;
localparam  STATE_WDATA     =   5'b0_0101;
localparam  STATE_WRTORD    =   5'b0_0100;
localparam  STATE_WRWAIT    =   5'b0_0110;
localparam  STATE_WRTOPRE   =   5'b0_1010;

localparam  STATE_READ      =   5'b0_1111;
localparam  STATE_RDWAIT     =   5'b0_1101;
localparam  STATE_RDTOPRE   =   5'b0_1110;


reg         [4:0]               state;//暂时写为5位
reg         [3:0]               cmd;


//cmd
localparam  NOP             =   4'b0111;
localparam  PRE             =   4'b0010;
localparam  AREF            =   4'b0001;
localparam  WRITE           =   4'b0100;
localparam  READ            =   4'b0101;
localparam  ACT             =   4'b0011;


// -------------------------------------------------------------------------------------
//   init
// -------------------------------------------------------------------------------------
// wire                            init_end; 
wire        [BA_BITS-1:0]       init_ba;
wire        [ADDR_BITS-1:0]     init_addr;
wire        [3:0]               init_cmd;
wire                            init_cke;
// -------------------------------------------------------------------------------------
//   aref
// -------------------------------------------------------------------------------------

localparam  DELAY_tREFI     =   tREFI/tCK;
localparam  RPA             =   tRPA/tCK;
localparam  RFC             =   tRFC/tCK;
localparam  ALLPRE_ADDR     =   (ADDR_BITS)'('b0_0100_0000_0000);

reg                             aref_req;
integer                         cnt_tREFI;
reg         [7:0]               ref_cnt;

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
localparam  AL              =   tRCD/tCK - 2;
localparam  WL              =   AL + CL - 1;    
localparam  RL              =   AL + CL;    
localparam  WR              =   tWR/tCK;
localparam  WTR             =   tWTR/tCK;

reg         [COL_BITS-3:0]     init_col_addr;
reg                  [5:0]     w_cnt;
reg                  [5:0]     wrwait_cnt;
reg                  [5:0]     rp_cnt;

reg        [DQ_BITS*2-1:0]     wdata_1;
reg        [DQ_BITS*2-1:0]     wdata_2;
reg        [DQ_BITS*2-1:0]     wdata_3;
reg          [DQ_BITS-1:0]     wdata_h;
reg          [DQ_BITS-1:0]     wdata_l;


reg          [DQ_BITS-1:0]     dq_pre;
reg          [DQ_BITS-1:0]     dq;
wire                           dqs;
wire                           dqs_n;
reg                            dqm_pre;
reg                            dqm;
reg                  [5:0]     wr_data_after_cmd;


always @(posedge clk) begin
    if(!rst_n) begin
    wdata_1 <= 'd0;
    wdata_2 <= 'd0;
    wdata_3 <= 'd0;
  end else if(state == STATE_WRITE || state == STATE_WRWAIT) begin
  // end else begin
    wdata_1 <= wdata;
    wdata_2 <= wdata_1;
    wdata_3 <= wdata_2;
  end
end

always @(posedge clk) begin
  {wdata_h, wdata_l} <= wdata_2;
end

always @(posedge clk) begin
  if(!rst_n) wr_data_after_cmd <= 'd9;
  else if(w_cnt == WL) wr_data_after_cmd <= 'd0;
  else if(wr_data_after_cmd < 'd9) wr_data_after_cmd <= wr_data_after_cmd + 'd1;
end

always @(posedge clk2) begin
  if(wr_data_after_cmd >= 'd0 && wr_data_after_cmd <= 'd7) begin
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

// -------------------------------------------------------------------------------------
//   read
// -------------------------------------------------------------------------------------
localparam  RTP     =   tRTP/tCK;

reg                   [5:0]     r_cnt;
reg                   [5:0]     rdwait_cnt;
reg                   [3:0]     rd_data_after_cmd;
reg          [DQ_BITS-1:0]     rdata_l;
reg          [DQ_BITS-1:0]     pre_rdata;

assign rvalid = rd_data_after_cmd >= 'd1 && rd_data_after_cmd <= 'd8;   
assign rlast  = rd_data_after_cmd == 'd8;
always @(posedge clk) begin
  if(!rst_n) rd_data_after_cmd <= 'd9;
  else if(r_cnt == RL + 'd1) rd_data_after_cmd <= 'd0;
  else if(rd_data_after_cmd < 'd9) rd_data_after_cmd <= rd_data_after_cmd + 'd1;
end

always @(posedge clk2) begin
    if(rd_data_after_cmd >= 'd0 && rd_data_after_cmd <= 'd8) begin
        rdata_l <= ddr2_dq;
        pre_rdata <= {ddr2_dq,rdata_l};
    end
end


always @(posedge clk) begin
    if(rd_data_after_cmd >= 'd0 && rd_data_after_cmd <= 'd7) begin
        rdata <= pre_rdata;
    end
end
assign dqs = wr_data_after_cmd >= 'd0 && wr_data_after_cmd <= 'd8 ? clk : 'dz;
assign dqs_n = wr_data_after_cmd >= 'd0 && wr_data_after_cmd <= 'd8 ? !clk : 'dz;
assign ddr2_dq = dq;
assign ddr2_dqs = dqs;
assign ddr2_dqs_n = dqs_n;
assign ddr2_dqm = dqm;
    
// -------------------------------------------------------------------------------------
//   state diagram
// -------------------------------------------------------------------------------------

reg          [ADDR_BITS-1:0]    addr;
reg          [BA_BITS-1:0]      ba;
reg          [ROW_BITS-1:0]     row_addr;
reg                             rd_or_wr;
wire                            same_to_wr;
wire                            same_to_rd;
wire                            same_ba_col_w;
wire                            same_ba_col_r;

assign same_ba_col_w = (ba == awaddr[BA_BITS + ROW_BITS+COL_BITS-1:COL_BITS + ROW_BITS])
                     && (row_addr == awaddr[ROW_BITS+COL_BITS-1:COL_BITS]);
assign same_ba_col_r = (ba == araddr[BA_BITS + ROW_BITS+COL_BITS-1:COL_BITS + ROW_BITS])
                     && (row_addr == araddr[ROW_BITS+COL_BITS-1:COL_BITS]);

assign same_to_wr = aref_req == 1'b0 && awvalid == 1'b1 && same_ba_col_w == 1'b1;
assign same_to_rd = aref_req == 1'b0 && arvalid == 1'b1 && same_ba_col_r == 1'b1;

assign awready = aref_req == 1'b0 && (state == STATE_IDLE || (state == STATE_WRWAIT && same_ba_col_w == 1'b1)
                                                          || (state == STATE_RDWAIT && same_ba_col_w == 1'b1));
// reg awready_1;
// assign awready = aref_req == 1'b0 && (state == STATE_IDLE || (awready_1 == 1'b1 && same_ba_col_w == 1'b1));
assign wready = w_cnt >= 'd1 && w_cnt <= awlen;
// reg arready_1;
// assign arready =  aref_req == 1'b0 && (state == STATE_IDLE || (arready_1 == 1'b1 && same_ba_col_r == 1'b1));
assign arready = aref_req == 1'b0 && !awvalid && ((state == STATE_IDLE ) || (state == STATE_WRWAIT && same_ba_col_r == 1'b1)
                                                                            || (state == STATE_RDWAIT && same_ba_col_r == 1'b1)) ;


reg         wr_en;
reg [1:0]   act_cnt;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= STATE_INIT;
        ref_cnt <= 8'd0;
        cmd <= NOP;
        addr <= 0;
        ba <= 0 ;
        row_addr <= 'd0;
        init_col_addr <= 0;
        // awready_1 <= 1'b0;
    end else begin
        case (state) 
            STATE_INIT:   
                if(init_end) begin
                    state <= STATE_IDLE;
                end
            // STATE_IDLE0: begin
            //     state <= STATE_IDLE;
                // awready_1 <= 1'b1;
                // arready <= 1'b1; 
            //  end
            STATE_IDLE:   begin
                if(aref_req) begin 
                    state <= STATE_AREF;
                    cmd <= NOP;
                    ref_cnt <= 8'd0;
                    // awready_1 <= 1'b0;
                    // arready_1 <= 1'b0;
                end
                else if(awvalid) begin 
                    // awready_1 <= 1'b0;
                    // arready_1 <= 1'b0;
                    act_cnt <= 6'd0;    
                    wr_en <= 1'b1;  
                    cmd <= ACT;
                    {ba, addr} <= awaddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                    row_addr <= awaddr[ROW_BITS+COL_BITS-1:COL_BITS];
                    init_col_addr <= awaddr[COL_BITS-1:2];
                    // state <= STATE_WRITE; 
                    state <= STATE_ACT;
                end 
                else if(arvalid) begin
                    // awready_1 <= 1'b0;
                    // arready_1 <= 1'b0;
                    act_cnt <= 6'd0;
                    wr_en <= 1'b0;
                    cmd <= ACT;
                    {ba, addr} <= araddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                    row_addr <= araddr[ROW_BITS+COL_BITS-1:COL_BITS];
                    init_col_addr <= araddr[COL_BITS-1:2];
                    state <= STATE_ACT;
                end
                else 
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

            STATE_ACT: begin
                act_cnt <= act_cnt + 'd1;
                if(act_cnt == 'd0 ) begin
                    if(wr_en) begin
                        state <= STATE_WRITE;
                        w_cnt <= 'd0;
                        // cmd <= WRITE;
                        // addr <= {init_col_addr, 2'b0};   
                    end else begin
                        state <= STATE_READ;
                        r_cnt <= 'd0;
                        // cmd <= READ;
                        // addr <= {init_col_addr, 2'b0};
                    end
                end 
                cmd <= NOP;
            end

            STATE_WRITE: begin 
                // w_cnt <= w_cnt + 1;
                // if(w_cnt == awlen ) begin
                //     state <= STATE_WRWAIT;   
                //     bvalid <= 1'b1;
                //     // awready_1 <= 1'b1;
                //     cmd <= NOP;
                // end
                // else if(wvalid) begin
                //     if(w_cnt[0] == 1'b0) begin
                //         cmd <= WRITE;
                //         addr <= {init_col_addr + (w_cnt >> 1), 2'b0};
                //     end else
                //         cmd <= NOP;
                // end
                w_cnt <= w_cnt + 'd1;
                if(wvalid ) begin
                    if(w_cnt[0] == 1'b0) begin
                        cmd <= WRITE;
                        addr <= {init_col_addr + (w_cnt >> 1), 2'b0};
                    end else
                        cmd <= NOP;
                end 
                if(wlast)begin
                    state <= STATE_WRWAIT;  
                    bvalid <= 1'b1;
                    // awready_1 <= 1'b1;
                    cmd <= NOP;
                end
                // bvalid <= w_cnt == awlen + 1;
                // ------------------------------------------------------------------------------------------
                // TODO1:当写数据突发长度较长，在写数据时，数据刷新请求到来，需要先保存当前状态，再去执行刷新，然后再回来
                // ------------------------------------------------------------------------------------------
                
            end

            // ------------------------------------------------------------------------------------------
            // 1、下一次写请求到来，且在同一bank、row, 需要等到前面的 cmd 、wdata,等 都给到，后续信号才响应 
            // 2、在写数据完全传输到总线上后，转为另一等待状态，
            // 3、这一等待状态可以接收更多其他请求
            // ------------------------------------------------------------------------------------------
            // STATE_WDATA: begin
            //     if(same_to_wr) begin          
            //         awready_1 <= 1'b0;
            //         w_cnt <= 'd0; 
            //         init_col_addr <= awaddr[COL_BITS-1:2];
            //         state <= STATE_WRITE;                        
            //         cmd <= WRITE;
            //         addr <= {awaddr[COL_BITS-1:2], 2'b0};  
            //     end 
            //     else begin
            //         w_cnt <= w_cnt + 1;
            //         if (w_cnt > awlen + WL - 1) begin
            //             state <= STATE_WRWAIT;
            //             wrwait_cnt <= 'd0;
            //             //读写优先级，同时到来写优先，但是读先来就先读
            //             rd_or_wr <= 1'b0;
            //         end
            //     end
            // end

            // ------------------------------------------------------------------------------------------
            // 下一次写请求到来，且在同一bank、row, 需要等到前面的 cmd 、wdata,等 都给到，后续信号才响应
            // 还可以接受 不同行操作（读/写）、同行读、刷新操作等 ，需要等待写恢复时间。。。
            // ------------------------------------------------------------------------------------------
            STATE_WRWAIT: begin
                if(w_cnt < awlen + WL + WR + 1)
                    w_cnt <= w_cnt + 1'b1;
                // cmd <= NOP;
                //写请求到来，且同一bank,row,不需要写恢复
                if(same_to_wr) begin
                    // if(rd_or_wr == 1'b0) begins  
                        state <= STATE_WRITE;
                        w_cnt <= 'd0;
                        init_col_addr <= awaddr[COL_BITS-1:2];
                        // awready_1 <= 1'b0;
                        // cmd <= WRITE;
                        // addr <= {awaddr[COL_BITS-1:2], 2'b0};  
                    // end
                end
                //读请求到来,同一～，需要写恢复
                //需要等待tWTR时间后
                else if(same_to_rd) begin
                    // rd_or_wr <= 1'b1;
                    // if (wrwait_cnt >= 2) begin
                    //     r_cnt <= 'd2;
                    //     init_col_addr <= araddr[COL_BITS-1:2];
                    //     addr <= {araddr[COL_BITS-1:2], 2'b0};
                    //     cmd <= READ;
                    //     state <= STATE_READ;
                    // end
                    state <= STATE_WRTORD;
                    // awready_1 <= 1'b0;
                end
                
                // 读/写请求不在同一bank/row、刷新请求到来，需要写恢复
                else if(awvalid == 1'b1 || aref_req == 1'b1 || arvalid == 1'b1) begin
                    // state <= STATE_PRE;
                    // rp_cnt <= 'd0;
                    // cmd <= PRE;
                    // addr <= ALLPRE_ADDR;
                    state <= STATE_WRTOPRE;
                    // awready_1 <= 1'b0;      
                end
            end
            
            STATE_WRTORD:begin
                w_cnt <= w_cnt + 1;
                if(w_cnt >= awlen + WL + WTR)  begin
                    r_cnt <= 'd0;
                    init_col_addr <= araddr[COL_BITS-1:2];
                    // addr <= {araddr[COL_BITS-1:2], 2'b0};
                    // cmd <= READ;
                    state <= STATE_READ;
                end
            end
            
            STATE_WRTOPRE: begin
                w_cnt <= w_cnt + 1;
                if(w_cnt == awlen + WL + WR) begin
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
                r_cnt <= r_cnt + 1;

                if(r_cnt == arlen) begin 
                    state <= STATE_RDWAIT;
                    cmd <= NOP;
                end
                // else if(rready) begin
                else if(rready) begin 
                    if(r_cnt[0] == 1'b0) begin
                        cmd <= READ;
                        addr <= {init_col_addr + (r_cnt >> 1), 2'b0};
                    end else
                        cmd <= NOP;
                end
            end

            STATE_RDWAIT: begin
                if(r_cnt < arlen + RL + RTP)
                    r_cnt <= r_cnt + 1;
                if(same_to_rd) begin
                    r_cnt <= 'd0;
                    init_col_addr <= araddr[COL_BITS-1:2];
                    state <= STATE_READ;
                end 
                else if(same_to_wr) begin
                    w_cnt <= 'd0;
                    init_col_addr <= awaddr[COL_BITS-1:2];
                    // addr <= {araddr[COL_BITS-1:2], 2'b0};
                    // cmd <= WRITE;
                    state <= STATE_WRITE;
                end 
                else if(arvalid == 1'b1 || awvalid == 1'b1 || aref_req == 1'b1) begin
                    state <= STATE_RDTOPRE;
                end
             end

             STATE_RDTOPRE: begin
                r_cnt <= r_cnt + 1;
                if(r_cnt >= arlen + RL ) begin
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
