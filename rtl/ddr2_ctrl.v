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
    input                               ck,
    input                               rst_n,
    output  wire                        ddr2_ck,
    output  wire                        ddr2_ck_n,
    output  wire                        ddr2_cke,
    output  wire                        ddr2_cs_n,
    output  wire                        ddr2_we_n,
    output  wire                        ddr2_ras_n,
    output  wire                        ddr2_cas_n,
    output  wire    [`BA_BITS-1:0]      ddr2_ba,
    output  wire    [`ADDR_BITS-1:0]    ddr2_addr
    // inout           [15:0]  ddr2_dq,
    // inout           [1:0]   ddr2_dqs,
    // inout           [1:0]   ddr2_dqs_n,
    // output                  ddr2_odt,   
);

//state
localparam  STATE_INIT      =   5'b0_0001;
localparam  STATE_IDLE      =   5'b0_0010;
localparam  STATE_AREF      =   5'b0_0100;
localparam  STATE_WRITE     =   5'b0_1000;
localparam  STATE_READ      =   5'b1_0000;

reg         [4:0]               state;//暂时写为5位


//cmd
localparam  NOP             =   4'b0111;
localparam  PRE             =   4'b0010;
localparam  AREF            =   4'b0001;


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
//   state diagram
// -------------------------------------------------------------------------------------

reg         [`ADDR_BITS-1:0]    addr;
reg         [3:0]               cmd;
reg         [`BA_BITS-1:0]      ba;
reg         [7:0]               cnt ;

always @(posedge ck or negedge rst_n) begin
    if(!rst_n) begin
        state <= STATE_INIT;
        cnt <= 8'd0;
        cmd <= NOP;
        addr <= 0;
        ba <= 0 ;

    end else begin
        case (state) 

            STATE_INIT:   if(init_end)   state <= STATE_IDLE;

            STATE_IDLE:   begin
                cmd <= NOP;
                cnt <= 8'd0;
                if(aref_req)    state <= STATE_AREF;
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
