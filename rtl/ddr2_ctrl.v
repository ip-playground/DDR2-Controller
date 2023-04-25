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
    output reg                                             ck,
    output   reg                                           rst_n,
    input   wire                                            ck800m,
    input   wire                                            rstn_async,

    input   wire                                        awvalid,
    output  wire                                         awready,
    input   wire    [`BA_BITS+`ROW_BITS+`COL_BITS-1:0]  awaddr,
    input   wire                                 [7:0]  awlen,
    input   wire                                        wvalid,
    output  wire                                         wready,
    input   wire                                        wlast,
    input   wire                      [`DQ_BITS*2-1:0]  wdata,
    output  reg                                        bvalid,
    input   wire                                        bready,
    
    output  wire                                        ddr2_ck,
    output  wire                                        ddr2_ck_n,
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
//   clock and reset 
// ----------------------------------// -------------------------------------------------------------------------------------
// generate reset sync with drv_clk
// -------------------------------------------------------------------------------------
reg       rstn_clk   ;
reg [2:0] rstn_clk_l ;
always @ (posedge ck800m or negedge rstn_async)
    if(~rstn_async)
        {rstn_clk, rstn_clk_l} <= 'd0;
    else
        {rstn_clk, rstn_clk_l} <= {rstn_clk_l, 1'b1};

// -------------------------------------------------------------------------------------
// generate reset sync with clk
// -------------------------------------------------------------------------------------
reg       rstn_aclk   ;
reg [2:0] rstn_aclk_l ;
always @ (posedge ck or negedge rstn_async)
    if(~rstn_async)
        {rstn_aclk, rstn_aclk_l} <= 'd0;
    else
        {rstn_aclk, rstn_aclk_l} <= {rstn_aclk_l, 1'b1};

// -------------------------------------------------------------------------------------
//   generate clocks
// -------------------------------------------------------------------------------------
reg ck2;
always @ (posedge ck800m or negedge rstn_clk)
    if(~rstn_clk)
        {ck,ck2} <= 2'b00;
    else
        {ck,ck2} <= {ck,ck2} + 2'b01;

// -------------------------------------------------------------------------------------
//   generate user reset
// -------------------------------------------------------------------------------------
always @ (posedge ck or negedge rstn_aclk)
    if(~rstn_aclk)
        rst_n <= 1'b0;
    else
        rst_n <= 1'b1;


//state
localparam  STATE_INIT      =   5'b0_0001;
localparam  STATE_IDLE      =   5'b0_0011;
localparam  STATE_AREF      =   5'b0_0010;

localparam  STATE_WRACT     =   5'b0_0111;
localparam  STATE_WRITE     =   5'b0_0110;

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
wire                            init_end;
wire        [`BA_BITS-1:0]      init_ba;
wire        [`ADDR_BITS-1:0]    init_addr;
wire        [3:0]               init_cmd;
wire                            init_cke;
// -------------------------------------------------------------------------------------
//   aref
// -------------------------------------------------------------------------------------
reg                             aref_req;
integer                         cnt_tREFI;

localparam  DELAY_tREFI     =   `tREFI/`tCK;
localparam  RPA             =   `tRPA/`tCK;
localparam  RFC             =   `tRFC/`tCK;
localparam  ALLPRE_ADDR     =   `ADDR_BITS'b0_0100_0000_0000;


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
    else if(state == STATE_IDLE && aref_req == 1'b1) 
        aref_req <= 1'b0;
    else if(cnt_tREFI >= DELAY_tREFI) 
        aref_req <= 1'b1;   
end
// -------------------------------------------------------------------------------------
//   write
// -------------------------------------------------------------------------------------

assign awready = state == STATE_IDLE && aref_req == 1'b0;
assign wready = state == STATE_WRITE;

reg         [`COL_BITS-1:0]     init_col_addr;
reg         [`COL_BITS-1:0]     col_addr;
reg                   [5:0]     w_cnt;

reg        [`DQ_BITS*2-1:0]     wdata_1;
reg        [`DQ_BITS*2-1:0]     wdata_2;
reg        [`DQ_BITS*2-1:0]     wdata_3;
reg          [`DQ_BITS-1:0]     wdata_h;
reg          [`DQ_BITS-1:0]     wdata_l;

reg                   [3:0]     cmd_1;
reg                   [3:0]     cmd_2;
reg                   [3:0]     cmd_3;
reg                   [3:0]     cmd_4;

wire                            ddr2_w_burst_01; 
reg                             ddr2_w_burst_23;


reg          [`DQ_BITS-1:0]     dq_pre;
reg          [`DQ_BITS-1:0]     dq;
reg                             dqs_pre;
reg                             dqs;
reg                             dqm_pre;
reg                             dqm;

localparam  AL              =   `tRCD/`tCK - 1;
localparam  WL              =   AL + `CL - 1;    
localparam  WR              =   `tWR/`tCK;

always @(posedge ck) begin
  if(!rst_n) begin
    wdata_1 <= 'd0;
    wdata_2 <= 'd0;
    wdata_3 <= 'd0;
  end else begin
    wdata_1 <= wdata;
    wdata_2 <= wdata_1;
    wdata_3 <= wdata_2;
  end
end

always @(posedge ck) begin
  {wdata_h, wdata_l} <= wdata_3;
end

always @(posedge ck) begin
  cmd_1 <= cmd;
  cmd_2 <= cmd_1;
  cmd_3 <= cmd_2;
  cmd_4 <= cmd_3;
end

assign ddr2_w_burst_01 = cmd_4  == WRITE;
always @(posedge ck) begin
  ddr2_w_burst_23 <= ddr2_w_burst_01;
end

always @(posedge ck2) begin
  if(ddr2_w_burst_01 || ddr2_w_burst_23) begin
    dq_pre <= ck ? wdata_l : wdata_h;
    dqm_pre <= 0;
    dqs_pre <= ck;
    end else begin
    dq_pre <= 'dz;
    dqm_pre <= 'dz;
    dqs_pre <= 'dz;
  end
end


//delay
always @(posedge ck2) begin
  if(!rst_n) begin
    dq <= 'dz;
    dqm <= 'dz;
    dqs <= 'dz;
  end
  else begin
    dq <= dq_pre;
    dqm <= dqm_pre;
    dqs <= dqs_pre;
  end
end

assign ddr2_dq = dq;
assign ddr2_dqs = dqs;
assign ddr2_dqs_n = !dqs;
assign ddr2_dqm = dqm;
    
// -------------------------------------------------------------------------------------
//   state diagram
// -------------------------------------------------------------------------------------

reg         [`ADDR_BITS-1:0]    addr;
reg         [`BA_BITS-1:0]      ba;
reg         [7:0]               cnt;
reg [1:0] mark;

always @(posedge ck or negedge rst_n) begin
    if(!rst_n) begin
        state <= STATE_INIT;
        cnt <= 8'd0;
        cmd <= NOP;
        addr <= 0;
        ba <= 0 ;
        init_col_addr <= 0;
        col_addr <= 0;
        mark <= 0;

    end else begin
        case (state) 

            STATE_INIT:   if(init_end)   state <= STATE_IDLE;

            STATE_IDLE:   begin
                
                cnt <= 8'd0;

                if(aref_req)   begin 
                    state <= STATE_AREF;
                    cmd <= NOP;
                  end
                else if(awvalid)    begin 
                w_cnt <= 6'd0;
                cmd <= ACT;
                {ba, addr} <= awaddr[`BA_BITS+`ROW_BITS+`COL_BITS-1:`COL_BITS];
                init_col_addr <= awaddr[`COL_BITS-1:0];
                state <= STATE_WRITE;
                end else 
                    cmd <= NOP;
            end

            STATE_AREF:   begin   
                cnt <= cnt + 8'd1;
                case(cnt)
                    0:          begin cmd <= PRE; addr <= ALLPRE_ADDR;end
                    RPA:        cmd <= AREF;
                    RPA+RFC:    state <= STATE_IDLE;
                    default:    cmd <= NOP;
                endcase
            end

            STATE_WRACT:    begin
                bvalid <= 1'b0;
            end

            STATE_WRITE:    begin
                //暂时将其突发设为4,设死
                if(w_cnt == awlen + WL + WR - 1 + `tRPA/`tCK) begin
                    state <= STATE_IDLE;
                    mark <= 2'b11; 
                    bvalid <= 1'b1;
                  end
                else if(w_cnt == awlen + WL + WR - 1) begin
                    cmd <= PRE;
                    addr <= ALLPRE_ADDR;
                    mark <= 2'b10;  
                end else if((w_cnt < awlen)&&(w_cnt[0]==1'b0)) begin
                    cmd <= WRITE;
                    addr <= {init_col_addr + w_cnt >>1,2'b0};
										$display("===============addr=%d===========", addr);
                    mark <= 2'b01;
                end else cmd <= NOP;    
                w_cnt <= w_cnt + 1;
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


assign  ddr2_ck = ck;
assign  ddr2_ck_n = ~ck;
assign  ddr2_cke = init_cke;


// reg [12:0] addr;
// reg [3:0]   cmd;
// reg [2:0]   ba;

// always @(*) begin
//     if (addr != ddr2_addr)
//         $display("?????");
// end



// always @(posedge ck) begin
//     case(state)
//         INIT:   begin
//             {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} <= init_cmd;
//             ddr2_ba <= init_ba;
//             ddr2_addr <= init_addr;
//         end
//         AREF:   begin
//             {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} <= aref_cmd;
//             // ddr2_ba = aref_ba;
//             ddr2_addr <= aref_addr;
//         end
//         default:   begin
//             {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} <= init_cmd;
//             ddr2_ba <= init_ba;
//             ddr2_addr <= init_addr;
//         end
//     endcase
// end


// always @(posedge ck or negedge rst_n) begin
//     if(!rst_n)
//         aref_en <= 'd0;
//     else if(state == IDLE && aref_req == 1'b1)
//         aref_en <= 'd1;
//     else
//         aref_en <= 'd0;
// end


ddr2_init ddr2_init_inst(
    .ck                         (ck),
    .rst_n                      (rst_n),
    .init_cke                   (init_cke),
    .init_ba                    (init_ba),
    .init_cmd                   (init_cmd),
    .init_addr                  (init_addr),
    .init_end                   (init_end)
);

// ddr2_ref ddr2_ref_inst(
//     .ck                         (ck),
//     .rst_n                      (rst_n),
//     .init_end                   (init_end),
//     .aref_req                   (aref_req),
//     .aref_en                    (aref_en),
//     // .aref_ba                    (aref_ba),
//     .aref_cmd                   (aref_cmd),
//     .aref_addr                  (aref_addr),
//     .aref_end                   (aref_end)
// );


endmodule
