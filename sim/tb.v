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

reg                         ck;
reg                         rst_n;
wire                        ddr2_ck;
wire                        ddr2_ck_n;
wire                        ddr2_cke;
wire                        ddr2_cs_n;
wire                        ddr2_cas_n;
wire                        ddr2_ras_n;
wire                        ddr2_we_n;
wire    [`BA_BITS-1:0]      ddr2_ba;
wire    [`ADDR_BITS-1:0]    ddr2_addr;
wire    [1:0]               ddr2_dqm;
wire    [15:0]              ddr2_dq;

always #2500 ck = ~ck;

initial begin
    ck <= 1'b1;
    rst_n <= 1'b0;
    repeat(4) @(posedge ck);
    rst_n <= 1'b1;
    #400000000;
end


ddr2_top ddr2_top_inst (
    .ck                     (ck),
    .rst_n                  (rst_n),
    .ddr2_ck                (ddr2_ck),
    .ddr2_ck_n              (ddr2_ck_n),
    .ddr2_cke               (ddr2_cke),
    .ddr2_cs_n              (ddr2_cs_n),
    .ddr2_cas_n             (ddr2_cas_n),
    .ddr2_ras_n             (ddr2_ras_n),
    .ddr2_we_n              (ddr2_we_n),
    .ddr2_ba                (ddr2_ba),
    .ddr2_addr              (ddr2_addr)
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
    .dq                     (),
    .dqs                    (),
    .dqs_n                  (),
    .rdqs_n                 (),
    .dm_rdqs                (),
    .odt                    ()
);




endmodule
