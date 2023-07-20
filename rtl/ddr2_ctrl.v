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
`define FPGA
module ddr2_ctrl #(
    parameter   BA_BITS     =   3,
    parameter   ADDR_BITS   =   13, // Address Bits
    parameter   ROW_BITS    =   13, // Number of Address bits
    parameter   COL_BITS    =   10, // Number of Column bits
    parameter   DM_BITS     =   2, // Number of Data Mask bits
    parameter   DQ_BITS     =   16, // Number of Data bits
    parameter   DQS_BITS    =   2 // Number of Dqs bits
)
(
    // output  reg                                         clk,
    // output  reg                                         rst_n,
    // input   wire                                        clk800m,
    input                                               clk2,
    input                                               clk0,
    input                                               clk1,
    input                                               clk1_n,
    // input               [DQS_BITS-1 : 0]                                ddr2_dqs_in,
    // input                                               clk,
    // input                                               clk2,
    input                                               rst_n,
    // input   wire                                        rstn_async,
    output  wire                                        init_end,

    input   wire                                        axi_awvalid,
    // output  wire                                        axi_awready,
    output  reg                                        axi_awready,
    input   wire       [BA_BITS+ROW_BITS+COL_BITS-1:0]  axi_awaddr,
    input   wire                                 [7:0]  axi_awlen,
    input   wire                                        axi_wvalid,
    // output  wire                                        axi_wready,
    output  reg                                        axi_wready,
    input   wire                                        axi_wlast,
    input   wire                      [DQ_BITS*2-1:0]   axi_wdata,
    output  wire                                         axi_bvalid,
    input   wire                                        axi_bready,

    input   wire                                        axi_arvalid,
    // output  wire                                        axi_arready,
    output  reg                                       axi_arready,
    input   wire       [BA_BITS+ROW_BITS+COL_BITS-1:0]  axi_araddr, 
    input   wire                                [ 7:0]  axi_arlen,
    // output  wire                                        axi_rvalid,
    output  reg                                        axi_rvalid,
    input   wire                                        axi_rready,
    output  wire                                        axi_rlast,
    // output  reg                       [DQ_BITS*2-1:0]   axi_rdata,
    output  wire                       [DQ_BITS*2-1:0]   axi_rdata,
    // output  reg [DQ_BITS*2-1:0] axi_rdata_next_r,

    output  wire                                        ddr2_clk_p,
    output  wire                                        ddr2_clk_n,
    output  wire                                        ddr2_cke,
    output  wire                                        ddr2_odt,
    output  wire                                        ddr2_cs_n,
    output  wire                                        ddr2_we_n,
    output  wire                                        ddr2_ras_n,
    output  wire                                        ddr2_cas_n,
    output  wire                         [BA_BITS-1:0]  ddr2_ba,
    output  wire                       [ADDR_BITS-1:0]  ddr2_addr,
    inout                                [DQ_BITS-1:0]  ddr2_dq,
    inout                                [DM_BITS-1:0]  ddr2_dqm,
    inout                               [DQS_BITS-1:0]  ddr2_dqs_p,
    inout                               [DQS_BITS-1:0]  ddr2_dqs_n
   // output                  ddr2_odt   
);
parameter   tCK     =   5;      
parameter   tRPA    =   20;             // PRECHARGE ALL period    17.5         
parameter   tRFC    =   130;            // REFRESH to ACTIVATE or to REFRESH interval 原本应该是127.5，为了方便整除改为130,下同
parameter   tREFI   =   7800;           // Average periodic refresh
parameter   tRCD    =   15;             // ACTIVATE-to-READ or WRITE delay
parameter   tRRD    =   10;            // ACTIVATE-to ACTIVATE delay different bank
parameter   tRC     =   55;             // ACTIVATE-toACTIVATE delay,same bank
// parameter   tFAW    =   35;          
parameter   CL      =   3;              // CAS latency 速率400                  
parameter   BL      =   4;              // busrt length
parameter   tWR     =   15;             // WRITE recovery
parameter   tWTR     =  10;             // Internal WRITE-to-READ delay  7.5
parameter   tRTP    =   10;             // Internal READ-to-PRECHARGE delay 7.5


// -------------------------------------------------------------------------------------
//   state
// -------------------------------------------------------------------------------------


localparam  STATE_INIT      =   5'b0_0000; //0
localparam  STATE_IDLE      =   5'b0_0001;  //1
localparam  STATE_ACT       =   5'b0_0101;  //5
localparam  STATE_AREF      =   5'b0_0011;  //3
localparam  STATE_AREFOVER  =   5'b0_1010; //a
localparam  STATE_PRE       =   5'b0_1001;  //9

localparam  STATE_READ      =   5'b0_1101;  //d
localparam  STATE_RDWAIT    =   5'b0_1111;  //f
localparam  STATE_RDTORD    =   5'b0_1110;  //e
localparam  STATE_RDTOPRE   =   5'b0_1011;  //b
localparam  STATE_RDTOAREF0 =   5'b0_0110;  //6
localparam  STATE_RDTOAREF  =   5'b0_0111;  //7
localparam  STATE_RETURNRD  =   5'b0_1100;  //c


localparam  STATE_WRITE     =   5'b1_0101;  //15
localparam  STATE_WROVER    =   5'b1_0001;
localparam  STATE_WRWAIT    =   5'b1_1111;
localparam  STATE_TOWR      =   5'b1_1001;
localparam  STATE_WRTORD    =   5'b1_1101;
localparam  STATE_WRTOPRE   =   5'b1_1000;

localparam  STATE_WRTOAREF0 =   5'b1_0111;
localparam  STATE_WRTOAREF  =   5'b1_0011;
localparam  STATE_RETURNWR  =   5'b1_1010;  

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
// localparam  ALLPRE_ADDR     =   (ADDR_BITS)'('b0_0100_0000_0000);           
localparam  ALLPRE_ADDR     =   13'b0_0100_0000_0000;           
localparam  AL              =   tRCD/tCK - 1; //2
localparam  WL              =   AL + CL - 1;    //4
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
reg                 [3:0]       rp_cnt;
reg                 [3:0]       to_aref_cnt;
reg                [11:0]       refi_cnt;

// -------------------------------------------------------------------------------------
//   aref
// -------------------------------------------------------------------------------------
reg                             aref_req;
reg                  [7:0]      wr_cnt_history;
reg                  [1:0]      wr_or_rd_to_aref;

reg                             aref_req_over;



always @(posedge clk1 or negedge rst_n) begin
// always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        refi_cnt <= 'd0;
    else if( refi_cnt >= DELAY_tREFI) 
        refi_cnt <= 'd0;        
    else if(init_end)
        refi_cnt <= refi_cnt + 'd1;
end

/*  每隔7.8us请求一次刷新，被允许后置低 */
always @(posedge clk1 or negedge rst_n) begin
// always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        aref_req <= 1'b0;
    else if((state == STATE_IDLE || aref_req_over )  && aref_req == 1'b1) 
        aref_req <= 1'b0;
    else if(refi_cnt >= DELAY_tREFI) 
        aref_req <= 1'b1;   
end

// -------------------------------------------------------------------------------------
//   write
// -------------------------------------------------------------------------------------

// reg                 [WL:0]      wr_pipe;
reg                 [WL+1:0]      wr_pipe;


reg        [DQ_BITS*2-1:0]      axi_wdata_1;
reg        [DQ_BITS*2-1:0]      axi_wdata_2;
reg        [DQ_BITS*2-1:0]      axi_wdata_3;
reg        [DQ_BITS*2-1:0]      axi_wdata_4;
reg        [DQ_BITS*2-1:0]      axi_wdata_5;


wire          [DQ_BITS-1:0]      dq;
reg          [DM_BITS-1:0]      dqm;
reg          [7:0]              wr_len;

always @(posedge clk1) begin
    if(!rst_n)
        wr_len <= 'd0;
    else 
        wr_len <= axi_awlen;
end

/*  利用pipe记录前几个周期写的状态，由于，dq数据出现在总线上跟对应的写命令有延迟（WL) */
always @(posedge clk1) begin
    if(!rst_n)
        wr_pipe <= 'd0;
    else if(state == STATE_WRITE && wr_cnt > 'd0)
        // wr_pipe <= {wr_pipe[WL-'d1:0],1'b1};
        wr_pipe <= {wr_pipe[WL:0],1'b1};
    else
        // wr_pipe <= {wr_pipe[WL-'d1:0], 1'b0};
        wr_pipe <= {wr_pipe[WL:0], 1'b0};
end


always @(posedge clk1) begin
// always @(posedge clk2) begin
    if(!rst_n) begin
        axi_wdata_1 <= 'd0;
    end
    // else if(state == STATE_WRITE) begin
    else  begin
        axi_wdata_1 <= axi_wdata;
    end 
end

always @(posedge clk2) begin
    if(!rst_n) begin
        axi_wdata_2 <= 'd0;
        axi_wdata_3 <= 'd0;
        axi_wdata_4 <= 'd0;
        axi_wdata_5 <= 'd0;
    end
    else  begin
        axi_wdata_2 <= axi_wdata_1;
        axi_wdata_3 <= axi_wdata_2;
        axi_wdata_4 <= axi_wdata_3;
        axi_wdata_5 <= axi_wdata_4;
    end
end

reg [WL:0]wr_pipe_0;
reg [WL:0]wr_pipe_1;

always @(posedge clk2) begin
    if(!rst_n) begin
        wr_pipe_0 <= 'd0;
        wr_pipe_1 <= 'd0;
    end
    else  begin
        wr_pipe_0 <= wr_pipe;
        wr_pipe_1 <= wr_pipe_0;
    end
end


`ifdef FPGA
assign dq = clk2 ?   axi_wdata_5[15:0] : axi_wdata_5[31:16];
`else
assign dq = clk2 ?   axi_wdata_4[15:0] : axi_wdata_4[31:16];
`endif

always @(posedge clk2) begin
    if(!rst_n) begin
        dqm <= 'dz;
    end
    `ifdef FPGA
    else if(wr_pipe_0[WL-2])
    `else
    else if(wr_pipe_0[WL-3])
    `endif
        dqm <= 2'b00;
    else
        dqm <= 'dz;
end


reg dq_valid ;
always @(posedge clk2) begin
    if(!rst_n)
        dq_valid <= 1'b0;
    `ifdef FPGA
    else if(wr_pipe_0[WL-2] | wr_pipe_0[WL-3])
    `else
    else if(wr_pipe_0[WL-3] | wr_pipe_0[WL-4])
    `endif
        dq_valid <= 1'b1;
    else    
        dq_valid <= 1'b0;
end

wire [DQS_BITS-1:0] ddr2_dqs;
assign ddr2_dqm = dqm;
assign ddr2_dqs = dq_valid ? {clk1,clk1} : 'dz;
assign ddr2_dq = dq_valid ? dq : 'dz;
// assign ddr2_dqs = wr_pipe_0[WL-3] | wr_pipe_0[WL-4] ? {clk1,clk1} : 'dz;
// assign ddr2_dq = wr_pipe_0[WL-3] | wr_pipe_0[WL-4] ? dq : 'dz;
// assign ddr2_dqs = wr_pipe[WL-2] | wr_pipe[WL-1] ? {2{clk0}} : 'dz;
// assign ddr2_dq = wr_pipe[WL-2] | wr_pipe[WL-1] ? dq : 'dz;


// wire [DQS_BITS-1:0] ddr2_dqs;
// assign ddr2_dqs = wr_pipe[WL-2] | wr_pipe[WL-1] ? {2{clk1}} : 'dz;
// assign ddr2_dq = wr_pipe[WL] | wr_pipe[WL-1] ? dq : 'dz;


// -------------------------------------------------------------------------------------
//   read
// -------------------------------------------------------------------------------------
// reg             [RL+'d1:0]      rd_pipe;
reg             [RL+'d2:0]      rd_pipe;
reg          [DQ_BITS-1:0]      axi_rdata_low;
reg          [DQ_BITS-1:0]      axi_rdata_h;
reg        [DQ_BITS*2-1:0]      pre_axi_rdata;
reg          [7:0]              rd_len;
reg         [DQ_BITS-1:0]       ddr2_dq_1;

always @(posedge clk1) begin
    if(!rst_n)
        rd_len <= 'd0;
    else 
        rd_len <= axi_arlen;
end

always @(posedge clk1) begin
    if(!rst_n)
        rd_pipe <= 'd0;
    else if(state == STATE_READ && rd_cnt > 'd0)
        // rd_pipe <= {rd_pipe[RL:0],1'b1};
        rd_pipe <= {rd_pipe[RL+1:0],1'b1};
    else
        // rd_pipe <= {rd_pipe[RL:0], 1'b0};
        rd_pipe <= {rd_pipe[RL+1:0], 1'b0};
end


always @(posedge clk1_n) begin
    if(!rst_n) begin
        axi_rdata_low <= 'd0;
        ddr2_dq_1 <= 'd0;
    end
    `ifdef FPGA
    else if(rd_pipe[RL+1]) begin
        axi_rdata_low <= ddr2_dq;
        ddr2_dq_1 <= axi_rdata_low;
    end
    `else
    else if(rd_pipe[RL-1] ) begin
        axi_rdata_low <= ddr2_dq;
        ddr2_dq_1 <= axi_rdata_low;
    end
    `endif
    // else 
    //     axi_rdata_low <= 'd0;
end


reg [DQ_BITS*2-1:0] axi_rdata_pre;
always @(posedge clk1) begin
    `ifdef FPGA 
    if(rd_pipe[RL+1])
    `else
    if( rd_pipe[RL-1]) 
    `endif
        // axi_rdata <= {ddr2_dq, axi_rdata_low};
        axi_rdata_pre <= {ddr2_dq, axi_rdata_low};
    else
        axi_rdata_pre <= 'd0;
end




// -------------------------------------------------------------------------------------
//   state diagram
// -------------------------------------------------------------------------------------

reg         [ADDR_BITS-1:0]     addr;
reg           [BA_BITS-1:0]     ba;
reg          [COL_BITS-3:0]     init_col_addr;
reg          [ROW_BITS-1:0]     row_addr;
reg                             wr_en;
// wire                            same_to_wr;
// wire                            same_to_rd;
reg                            same_to_wr;
reg                            same_to_rd;
wire                            same_ba_col_w;
wire                            same_ba_col_r;
reg                             op_req;

assign same_ba_col_w = (ba == axi_awaddr[BA_BITS + ROW_BITS+COL_BITS-1:COL_BITS + ROW_BITS])
                     && (row_addr == axi_awaddr[ROW_BITS+COL_BITS-1:COL_BITS]);
assign same_ba_col_r = (ba == axi_araddr[BA_BITS + ROW_BITS+COL_BITS-1:COL_BITS + ROW_BITS])
                     && (row_addr == axi_araddr[ROW_BITS+COL_BITS-1:COL_BITS]);

// assign same_to_wr = aref_req == 1'b0 && axi_awvalid == 1'b1 && same_ba_col_w == 1'b1;
// assign same_to_rd = aref_req == 1'b0 && axi_arvalid == 1'b1 && same_ba_col_r == 1'b1;
always @(posedge clk1) begin
    if(!rst_n) begin
        same_to_wr <= 1'b0;
        same_to_rd <= 1'b0;
    end else if(~aref_req)begin
        same_to_wr <= axi_awvalid == 1'b1 && same_ba_col_w == 1'b1;
        same_to_rd <= axi_arvalid == 1'b1 && same_ba_col_r == 1'b1;
    end else begin
        same_to_wr <= 1'b0;
        same_to_rd <= 1'b0;        
    end
end

always @(posedge clk1) begin
    if(!rst_n) 
        op_req <= 1'b0;
    else 
        op_req <= axi_arvalid | axi_awvalid | aref_req;
end

// assign axi_awready = aref_req == 1'b0 && (state == STATE_IDLE || (state == STATE_WRWAIT && same_ba_col_w == 1'b1)
//                                                           || (state == STATE_RDWAIT && same_ba_col_w == 1'b1));
always @(posedge clk1) begin
    if(!rst_n) begin
        axi_awready <= 1'b0;
    end else if(~aref_req)begin
        // if(state == STATE_IDLE)
        //     axi_awready <= 1'b1;
        // else if(same_ba_col_w)
        //     axi_awready <= &state[2:0];
        // else 
        //     axi_awready <= 1'b0;
        axi_awready <= state == STATE_IDLE || (same_ba_col_w & (&state[3:0]));
    end else begin
        axi_awready <= 1'b0;   
    end
end


// assign axi_arready = aref_req == 1'b0 && !axi_awvalid && ((state == STATE_IDLE ) || (state == STATE_WRWAIT && same_ba_col_r == 1'b1)
//                                                                             || (state == STATE_RDWAIT && same_ba_col_r == 1'b1)) ;

always @(posedge clk1) begin
    if(!rst_n) begin
        axi_arready <= 1'b0;
    end else if(~aref_req & (~axi_awvalid))begin
        axi_arready <= state == STATE_IDLE || (same_ba_col_r & (&state[3:0]));
    end else begin
        axi_arready <= 1'b0;   
    end
end                                                                          

// assign axi_wready = wr_cnt >= 'd1 && wr_cnt <= wr_len;
always @(posedge clk1) begin
    if(!rst_n)
        axi_wready <= 1'b0;
    else if( (wr_cnt >= 'd0 && wr_cnt < wr_len))
        axi_wready <= 1'b1;
    else if(state == STATE_ACT && wr_en == 1'b1)
        axi_wready <= 1'b1;
    else 
        axi_wready <= 1'b0;
end

assign axi_bvalid = wr_cnt > wr_len + WL ? 1'b1 : 1'b0;

reg axi_rvalid_0; 
always @(posedge clk1) begin
    if(!rst_n)
        axi_rvalid_0 <= 1'b0;
    `ifdef FPGA
    else if(rd_pipe[RL+1])
    `else
    else if(rd_pipe[RL-1])
    `endif
        axi_rvalid_0 <= 1'b1;
    else 
        axi_rvalid_0 <= 1'b0;
end

always @(posedge clk1) begin
    if(!rst_n)
        axi_rvalid <= 1'b0;
    else
        axi_rvalid <= axi_rvalid_0;
end



always @(posedge clk1 or negedge rst_n) begin
    if(!rst_n) begin
        state <= STATE_INIT;
        ref_cnt <= 8'd0;
        cmd <= NOP;
        addr <= 0;
        ba <= 0 ;
        row_addr <= 'd0;
        init_col_addr <= 0;
        wr_or_rd_to_aref <= 2'b00;
        wr_cnt <= 'd0;
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
                    wr_en <= 1'b1;  
                    cmd <= ACT;
                    {ba, addr} <= axi_awaddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                    row_addr <= axi_awaddr[ROW_BITS+COL_BITS-1:COL_BITS];
                    init_col_addr <= axi_awaddr[COL_BITS-1:2];
                    state <= STATE_ACT;
                end 
                else if(axi_arvalid) begin
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
                        state <= STATE_AREFOVER;
                    end
                    default:    cmd <= NOP;
                endcase
            end

            STATE_AREFOVER:begin
                if(wr_or_rd_to_aref == 2'b00) 
                    state <= STATE_IDLE;
                else if(wr_or_rd_to_aref == 2'b01) begin  
                    cmd <= ACT;
                    {ba, addr} <= axi_awaddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                    row_addr <= axi_awaddr[ROW_BITS+COL_BITS-1:COL_BITS];
                    init_col_addr <= axi_awaddr[COL_BITS-1:2];
                    state <= STATE_RETURNWR;
                end else begin
                    cmd <= ACT;
                    {ba, addr} <= axi_araddr[BA_BITS+ROW_BITS+COL_BITS-1:COL_BITS];
                    row_addr <= axi_araddr[ROW_BITS+COL_BITS-1:COL_BITS];
                    init_col_addr <= axi_araddr[COL_BITS-1:2];
                    state <= STATE_RETURNRD;
                end                
            end

            STATE_ACT: begin
                    if(wr_en) begin
                        state <= STATE_WRITE;
                        // wr_cnt <= 'd0;
                        wr_cnt <= 'd1;
                        cmd <= WRITE;
                        addr <= {init_col_addr, 2'b0};

                    end else begin
                        state <= STATE_READ;
                        // rd_cnt <= 'd0;
                        rd_cnt <= 'd1;
                        cmd <= READ;
                        addr <= {init_col_addr, 2'b0};
                    end
                // end 
            end

            STATE_WRITE: begin 
                // ------------------------------------------------------------------------------------------
                // 当写数据突发长度较长，在写数据时，数据刷新请求到来，需要先保存当前状态，再去执行刷新，然后再回来
                // ------------------------------------------------------------------------------------------
                if(axi_wvalid)
                    wr_cnt <= wr_cnt + 'd1;
                if(axi_wlast)begin
                    state <= STATE_WROVER;  
                    cmd <= NOP;
                end
                else if(wr_cnt[0] == 1'b0) begin
                    // if(aref_req & (wr_cnt < wr_len - Threshold )) begin
                    if(aref_req ) begin
                        wr_cnt_history <= wr_cnt+1;
                        wr_cnt <= wr_len + 1;
                        state <= STATE_WRTOAREF0;
                        // to_aref_cnt <= 'd0;
                        // wr_or_rd_to_aref <= 2'b01;
                        // aref_req_over <= 1'b1;
                    end 
                    else if(axi_wvalid ) begin
                        cmd <= WRITE;
                        addr <= {init_col_addr + (wr_cnt >> 1), 2'b0};
                    end 
                end
                else
                    cmd <= NOP;
           end

            STATE_WRTOAREF0:begin
                to_aref_cnt <= 'd0;
                wr_or_rd_to_aref <= 2'b01;
                aref_req_over <= 1'b1;
                state <= STATE_WRTOAREF;
            end


            STATE_WRTOAREF:begin
                aref_req_over <= 1'b0;
                if(to_aref_cnt < WL + WR)
                    to_aref_cnt <= to_aref_cnt + 'd1;
                else begin
                    state <= STATE_AREF;
                    ref_cnt <= 'd0;
                end
            end

            STATE_RETURNWR:begin
                    cmd <= WRITE;
                    state <= STATE_WRITE;
                    wr_cnt <= wr_cnt_history;
                    wr_or_rd_to_aref <= 2'b00;
                    addr <= {init_col_addr + ((wr_cnt_history-'d1) >> 1), 2'b0};
                // end else 
                //     cmd <= NOP;
            end
            // ------------------------------------------------------------------------------------------
            // 1、下一次写请求到来，且在同一bank、row, 需要等到前面的 cmd 、axi_wdata,等 都给到，后续信号才响应 
            // 2、在写数据完全传输到总线上后，转为另一等待状态，
            // 3、这一等待状态可以接收其他请求
            // ------------------------------------------------------------------------------------------

            STATE_WROVER: begin
                wr_cnt <= wr_cnt + 'd1;
                if (wr_cnt == wr_len + WL) 
                    state <= STATE_WRWAIT;

            end

            STATE_WRWAIT: begin
                if(wr_cnt < wr_len + WL + WR + 1)
                    wr_cnt <= wr_cnt + 1'b1;
                //写请求到来，且同一bank,row,不需要写恢复
                if(same_to_wr) begin
                        // state <= STATE_WRITE;
                        // wr_cnt <= 'd0;
                        // init_col_addr <= axi_awaddr[COL_BITS-1:2];
                    state <= STATE_TOWR;
                end
                //读请求到来,同一～，需要写恢复
                //需要等待tWTR时间后
                else if(same_to_rd) begin
                    state <= STATE_WRTORD;
                end
                // 读/写请求不在同一bank/row、刷新请求到来，需要写恢复
                // else if(axi_awvalid | aref_req | axi_arvalid) begin
                else if(op_req) begin
                    state <= STATE_WRTOPRE;
                end
            end
            
            STATE_TOWR:begin
                state <= STATE_WRITE;
                wr_cnt <= 'd0;
                init_col_addr <= axi_awaddr[COL_BITS-1:2];          
            end
            STATE_WRTORD:begin
                wr_cnt <= wr_cnt + 1;
                if(wr_cnt >= wr_len + WL + WTR)  begin
                    rd_cnt <= 'd0;
                    init_col_addr <= axi_araddr[COL_BITS-1:2];
                    state <= STATE_READ;
                end
            end
            
            STATE_WRTOPRE: begin
                wr_cnt <= wr_cnt + 1;
                if(wr_cnt >= wr_len + WL + WR) begin
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
                
                // ------------------------------------------------------------------------------------------
                // 当读数据突发长度较长，在读数据时，数据刷新请求到来，需要先保存当前状态，再去执行刷新。。。
                // ------------------------------------------------------------------------------------------
                rd_cnt <= rd_cnt + 1;
                if(rd_cnt == rd_len) begin
                    state <= STATE_RDWAIT;
                    cmd <= NOP;
                end
                else if(rd_cnt[0] == 1'b0) begin
                    // if(aref_req & (rd_cnt < rd_len - Threshold)) begin
                    if(aref_req ) begin
                        // state <= STATE_RDTOAREF;
                        // cmd <= NOP;
                        state <= STATE_RDTOAREF0;
                        // to_aref_cnt <= 'd0;
                        // wr_or_rd_to_aref <= 2'b10;     
                        // aref_req_over <= 1'b1;
                    end  
                    else if(axi_rready)  begin
                        cmd <= READ;
                        addr <= {init_col_addr + (rd_cnt >> 1), 2'b0};         
                    end
                end else 
                    cmd <= NOP;
            end
            STATE_RDTOAREF0:begin
                to_aref_cnt <= 'd0;
                wr_or_rd_to_aref <= 2'b10;     
                aref_req_over <= 1'b1; 
                state <= STATE_RDTOAREF;
            end

            STATE_RDTOAREF:begin
                aref_req_over <= 1'b0;
                if(to_aref_cnt < Delay_RD_TO_PRE)
                    to_aref_cnt <= to_aref_cnt + 'd1;
                else begin
                    ref_cnt <= 'd0;
                    state <= STATE_AREF;
                end
            end

            STATE_RETURNRD:begin
                cmd <= READ;
                state <= STATE_READ;
                wr_or_rd_to_aref <= 2'b00;
                addr <= {init_col_addr + ((rd_cnt) >> 1), 2'b0};
            end

            STATE_RDWAIT: begin
                if(rd_cnt < rd_len + Delay_RD_TO_PRE)
                    rd_cnt <= rd_cnt + 1;
                if(same_to_wr) begin
                    state <= STATE_TOWR;
                end 
                else if(same_to_rd) begin
                    state <= STATE_RDTORD;
                end 
                // else if(axi_arvalid | axi_awvalid | aref_req) begin
                else if(op_req) begin
                    state <= STATE_RDTOPRE;
                end
             end

             STATE_RDTORD: begin
                rd_cnt <= 'd0;
                init_col_addr <= axi_araddr[COL_BITS-1:2];
                state <= STATE_READ;                
             end

             STATE_RDTOPRE: begin
                rd_cnt <= rd_cnt + 1;
                if(rd_cnt >= rd_len + Delay_RD_TO_PRE) begin
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
assign  ddr2_cke = init_cke;



/*用于处理传输给外部器件用的 clk */
wire clk1_buf;
ODDR #(
   .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
   .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
   .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
) ODDR_inst (
   .Q(clk1_buf),   // 1-bit DDR output
   .C(clk1),   // 1-bit clock input
   .CE(1'b1), // 1-bit clock enable input
   .D1(1'b1), // 1-bit data input (positive edge)
   .D2(1'b0), // 1-bit data input (negative edge)
   .R(R),   // 1-bit reset
   .S(1'b0)    // 1-bit set
);

/*生成差分信号的原语*/

`ifdef FPGA
OBUFDS #(
   .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
   .SLEW("SLOW")           // Specify the output slew rate
) OBUFDS_inst_clk (
   .O(ddr2_clk_p),     // Diff_p output (connect directly to top-level port)
   .OB(ddr2_clk_n),   // Diff_n output (connect directly to top-level port)
   .I(clk1_buf)      // Buffer input
);
`else
OBUFDS #(
   .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
   .SLEW("SLOW")           // Specify the output slew rate
) OBUFDS_inst_clk (
   .O(ddr2_clk_p),     // Diff_p output (connect directly to top-level port)
   .OB(ddr2_clk_n),   // Diff_n output (connect directly to top-level port)
   .I(clk1)      // Buffer input
);
`endif



OBUFDS #(
   .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
   .SLEW("SLOW")           // Specify the output slew rate
) OBUFDS_inst_dqs (
   .O(ddr2_dqs_p[0]),     // Diff_p output (connect directly to top-level port)
   .OB(ddr2_dqs_n[0]),   // Diff_n output (connect directly to top-level port)
   .I(ddr2_dqs[0])      // Buffer input
);
OBUFDS #(
   .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
   .SLEW("SLOW")           // Specify the output slew rate
) OBUFDS_inst_dqs1 (
   .O(ddr2_dqs_p[1]),     // Diff_p output (connect directly to top-level port)
   .OB(ddr2_dqs_n[1]),   // Diff_n output (connect directly to top-level port)
   .I(ddr2_dqs[1])      // Buffer input
);




ddr2_init ddr2_init_inst(
    // .clk                        (clk),
    .clk                        (clk1),
    .rst_n                      (rst_n),
    .init_cke                   (init_cke),
    .init_ba                    (init_ba),
    .init_cmd                   (init_cmd),
    .init_addr                  (init_addr),
    .ddr2_odt                   (ddr2_odt),
    .init_end                   (init_end)
);

/*使用 ila */

reg [9:0]axi_addr;
always @(posedge clk1) begin
    if(!rst_n)
        axi_addr <= 'd0;
    else
        axi_addr <= axi_araddr[9:0];
end


reg [DQ_BITS*2-1:0] axi_rdata_reg;
assign axi_rdata = axi_rdata_reg;
always @(posedge clk1) begin
    if(!rst_n) 
        axi_rdata_reg <= 'd0;
    else
        axi_rdata_reg <= axi_rdata_pre;
end


reg [DQ_BITS*2-1:0]  axi_rdata_1;
always @(posedge clk1) begin
    if(!rst_n)
        axi_rdata_1 <= 'd0;
    else 
        axi_rdata_1 <= axi_rdata;
end




ila_0 your_instance_name (
	// .clk(clk2), // input wire clk
	.clk(clk1), // input wire clk


	// .probe0(state), // input wire [4:0]  probe0  
	// .probe0(axi_rdata_reg), // input wire [15:0]  probe0  
	.probe0(16'd0), // input wire [15:0]  probe0  
	// .probe1(16'd0),// input wire [15:0]  probe1
	// .probe1(ddr2_dq_1),// input wire [15:0]  probe1
	.probe1(dq[15:0]),// input wire [15:0]  probe1
    .probe2(cmd)
);

endmodule


