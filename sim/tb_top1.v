`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/05 17:14:03
// Design Name: 
// Module Name: tb_top1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/30 19:30:11
// Design Name: 
// Module Name: tb_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_top1();

parameter   BA_BITS     =   3;
parameter   ADDR_BITS   =   13; // Address Bits
parameter   ROW_BITS    =   13; // Number of Address bits
parameter   COL_BITS    =   10; // Number of Column bits
parameter   DM_BITS     =   2; // Number of Data Mask bits
parameter   DQ_BITS     =   16; // Number of Data bits
parameter   DQS_BITS    =   2;// Number of Dqs bits
parameter           ADDR_WIDTH  = ROW_BITS + COL_BITS + BA_BITS;
parameter           DATA_WIDTH  = DQ_BITS * 2;
parameter           DATA_LEVEL  = 2;
parameter   [7:0]   WBURST_LEN   = 8'd8;  
parameter   [7:0]   RBURST_LEN   = 8'd8;  



reg                        clk100m;
reg                        rst_n;

reg                         uart_rx;
wire                        uart_tx;

wire                         wr_over_led;
wire                         init_end_led;
wire                         rd_error_led;

wire                        ddr2_clk_p;
wire                        ddr2_clk_n;
wire                        ddr2_cke;
wire                        ddr2_cs_n;
wire                        ddr2_cas_n;
wire                        ddr2_ras_n;
wire                        ddr2_we_n;
wire       [BA_BITS-1:0]    ddr2_ba;
wire     [ADDR_BITS-1:0]    ddr2_addr;
wire       [DM_BITS-1:0]    ddr2_dqm;
wire       [DQ_BITS-1:0]    ddr2_dq;
wire      [DQS_BITS-1:0]    ddr2_dqs_p;
wire      [DQS_BITS-1:0]    ddr2_dqs_n;
wire                        ddr2_odt;

initial begin
    clk100m = 1;
    rst_n <= 0;
    #100000
    rst_n <= 1;
end

always #5000 clk100m = ~clk100m;

reg rd_error_1;
// always @(posedge clk1) begin
//     if(rd_error_led) 
//         $display("xxxxxxxxxxxxxx");
// end


top1 #(
    .BA_BITS     ( BA_BITS     ),    
    .ADDR_BITS   ( ADDR_BITS   ),
    .ROW_BITS    ( ROW_BITS    ),
    .COL_BITS    ( COL_BITS    ),
    .DM_BITS     ( DM_BITS     ),
    .DQ_BITS     ( DQ_BITS     ),
    .DQS_BITS    ( DQS_BITS    ),
    .wr_delay    ( 100),
    .rd_delay    ( 200)
)  top1_inst (
.sys_clk                (clk100m),
.sys_rst_n              (rst_n),
.wr_over_led            (wr_over_led),
.init_end_led           (init_end_led),
.rd_error_led           (rd_error_led),
.ddr2_clk_p             (ddr2_clk_p),
.ddr2_clk_n             (ddr2_clk_n),
.ddr2_cke               (ddr2_cke),
.ddr2_cs_n              (ddr2_cs_n),
.ddr2_cas_n             (ddr2_cas_n),
.ddr2_ras_n             (ddr2_ras_n),
.ddr2_we_n              (ddr2_we_n),
.ddr2_ba                (ddr2_ba),
.ddr2_addr              (ddr2_addr),
.ddr2_dqm               (ddr2_dqm),
.ddr2_dq                (ddr2_dq),
.ddr2_dqs_p             (ddr2_dqs_p),
.ddr2_dqs_n             (ddr2_dqs_n),
.ddr2_odt               (ddr2_odt)
);

ddr2 ddr2_inst(
    // .ck                         (ddr2_clk),
    .ck                         (ddr2_clk_p),
    .ck_n                       (ddr2_clk_n),
    .cke                        (ddr2_cke),
    .cs_n                       (ddr2_cs_n),
    .cas_n                      (ddr2_cas_n),
    .ras_n                      (ddr2_ras_n),
    .we_n                       (ddr2_we_n),
    .ba                         (ddr2_ba),
    .addr                       (ddr2_addr),
    .dq                         (ddr2_dq),
    .dm_rdqs                    (ddr2_dqm),
    // .dqs                        (ddr2_dqs),
    .dqs                        (ddr2_dqs_p),
    .dqs_n                      (ddr2_dqs_n),
    .rdqs_n                     (),
    .odt                        ()
);


endmodule

