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
`timescale 1ps / 1ps
`include "../rtl/define.v" 
module tb();

parameter           ADDR_WIDTH  = `ROW_BITS + `COL_BITS + `BA_BITS;
parameter           DATA_WIDTH  = `DQ_BITS * 2;
parameter           DATA_LEVEL  = 2;
parameter   [7:0]   WBURST_LEN   = 8'd8;  
parameter   [7:0]   RBURST_LEN   = 8'd8;  

wire                         ck;
reg                         ck800m;
wire                         rst_n;
reg                         rstn_async;

wire                        awvalid;
wire                        awready;
wire     [ADDR_WIDTH-1:0]    awaddr;
wire    [           7:0]    awlen;
wire                        wvalid;
wire                        wready;
wire                        wlast;
wire    [DATA_WIDTH-1:0]    wdata;
wire                        bvalid;
wire                        bready;

wire                        ddr2_ck;
wire                        ddr2_ck_n;
wire                        ddr2_cke;
wire                        ddr2_cs_n;
wire                        ddr2_cas_n;
wire                        ddr2_ras_n;
wire                        ddr2_we_n;
wire    [`BA_BITS-1:0]      ddr2_ba;
wire    [`ADDR_BITS-1:0]    ddr2_addr;
wire    [`DM_BITS-1:0]      ddr2_dqm;
wire    [`DQ_BITS-1:0]      ddr2_dq;
wire    [`DQS_BITS-1:0]     ddr2_dqs;
wire    [`DQS_BITS-1:0]     ddr2_dqs_n;


always #625 ck800m = ~ck800m;

reg w_trig;

initial begin
    ck800m <= 1'b1;
    rstn_async <= 1'b0;
    repeat(4) @(posedge ck800m);
    rstn_async <= 1'b1;
    #400000000;
    w_trig <= 1'b1;
    #15000;
    w_trig <= 1'b0;
    #150000;
    $finish(0);
end

initial begin
    $dumpfile("tb.fsdb");
    $dumpvars(0,tb);
end

axi_master #(
    .ADDR_WIDTH     ( ADDR_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH     ),
    .DATA_LEVEL     ( DATA_LEVEL    ),
    .WBURST_LEN     ( WBURST_LEN  ),
    .RBURST_LEN     ( RBURST_LEN  )
) axi_master_inst (
    .rstn                   (rst_n),
    .clk                    (ck),
    .w_trig                 (w_trig),
    .awvalid                (awvalid),
    .awready                (awready),
    .awaddr                 (awaddr),
    .awlen                  (awlen),
    .wvalid                 (wvalid),
    .wready                 (wready),
    .wlast                  (wlast),
    .wdata                  (wdata),
    .bvalid                 (bvalid),
    .bready                 (bready)
);

ddr2_ctrl ddr2_ctrl_inst (
    .ck                     (ck),
    .ck800m                 (ck800m),
    .rst_n                  (rst_n),
    .rstn_async             (rstn_async),
    .awvalid                (awvalid),
    .awready                (awready),
    .awaddr                 (awaddr),
    .awlen                  (awlen),
    .wvalid                 (wvalid),
    .wready                 (wready),
    .wlast                  (wlast),
    .wdata                  (wdata),
    .bvalid                 (bvalid),
    .bready                 (bready),
    .ddr2_ck                (ddr2_ck),
    .ddr2_ck_n              (ddr2_ck_n),
    .ddr2_cke               (ddr2_cke),
    .ddr2_cs_n              (ddr2_cs_n),
    .ddr2_cas_n             (ddr2_cas_n),
    .ddr2_ras_n             (ddr2_ras_n),
    .ddr2_we_n              (ddr2_we_n),
    .ddr2_ba                (ddr2_ba),
    .ddr2_addr              (ddr2_addr),
    .ddr2_dq                (ddr2_dq),
    .ddr2_dqm               (ddr2_dqm),
    .ddr2_dqs               (ddr2_dqs),
    .ddr2_dqs_n             (ddr2_dqs_n)
);

ddr2 ddr2_inst(
    .ck                     (ddr2_ck),
    .ck_n                   (ddr2_ck_n),
    .cke                    (ddr2_cke),
    .cs_n                   (ddr2_cs_n),
    .cas_n                  (ddr2_cas_n),
    .ras_n                  (ddr2_ras_n),
    .we_n                   (ddr2_we_n),
    .ba                     (ddr2_ba),
    .addr                   (ddr2_addr),
    .dq                     (ddr2_dq),
    .dm_rdqs                (ddr2_dqm),
    .dqs                    (ddr2_dqs),
    .dqs_n                  (ddr2_dqs_n),
    .rdqs_n                 (),
    .odt                    ()
);




endmodule
