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
module tb_wr_aref();
parameter   BA_BITS     =   3;
parameter   ADDR_BITS   =   14; // Address Bits
parameter   ROW_BITS    =   14; // Number of Address bits
parameter   COL_BITS    =   10; // Number of Column bits
parameter   DM_BITS     =   1; // Number of Data Mask bits
parameter   DQ_BITS     =   8; // Number of Data bits
parameter   DQS_BITS    =   1;// Number of Dqs bits
parameter           ADDR_WIDTH  = ROW_BITS + COL_BITS + BA_BITS;
parameter           DATA_WIDTH  = DQ_BITS * 2;
parameter           DATA_LEVEL  = 2;
parameter   [7:0]   WBURST_LEN   = 8'd8;  
parameter   [7:0]   RBURST_LEN   = 8'd8;  

wire                        clk;
reg                         clk800m;
wire                        rst_n;
reg                         rstn_async;

wire                        axi_awvalid;
wire                        axi_awready;
wire     [ADDR_WIDTH-1:0]   axi_awaddr;
wire     [           7:0]   axi_awlen;
wire                        axi_wvalid;
wire                        axi_wready;
wire                        axi_wlast;
wire    [DATA_WIDTH-1:0]    axi_wdata;
wire                        axi_bvalid;
wire                        axi_bready;

wire                        axi_arvalid;
wire                        axi_arready;
wire     [ADDR_WIDTH-1:0]   axi_araddr;
wire     [           7:0]   axi_arlen;
wire                        axi_rvalid;
wire                        axi_rready;
wire                        axi_rlast;
wire    [DATA_WIDTH-1:0]    axi_rdata;

wire                        ddr2_clk;
wire                        ddr2_clk_n;
wire                        ddr2_cke;
wire                        ddr2_cs_n;
wire                        ddr2_cas_n;
wire                        ddr2_ras_n;
wire                        ddr2_we_n;
wire      [BA_BITS-1:0]     ddr2_ba;
wire    [ADDR_BITS-1:0]     ddr2_addr;
wire      [DM_BITS-1:0]     ddr2_dqm;
wire      [DQ_BITS-1:0]     ddr2_dq;
wire     [DQS_BITS-1:0]     ddr2_dqs;
wire     [DQS_BITS-1:0]     ddr2_dqs_n;

reg                         wr_trig;
wire                [7:0]   wr_len;
reg      [DATA_WIDTH-1:0]   wr_data;
wire                        wr_data_en;
reg      [ADDR_WIDTH-1:0]   wr_addr;
wire                        wr_ready;
wire                        wr_done;

assign wr_len = 'd72;

reg                         op_start;       
integer cnt;              

always #625 clk800m = ~clk800m;

wire init_end;

initial begin
    clk800m <= 1'b1;
    rstn_async <= 1'b0;
    op_start <= 1'b0;
    repeat(4) @(posedge clk800m);
    rstn_async <= 1'b1;
    #305000000;
    op_start <= 1'b1;
    #6000000;
    $finish(0);
end

initial begin
    $dumpfile("tb_wr_aref.fsdb");
    $dumpvars(0,tb_wr_aref);
end
localparam wr_delay = 'd100;
always @(posedge clk) begin
    if(op_start == 1'b0)
        cnt <= 'd0;
    else if(cnt == wr_delay) begin
        cnt <= 'd0;
    end else 
        cnt <= cnt + 'd1;
end

always @(posedge clk) begin
    if(op_start == 1'b0)
        wr_trig <= 1'b0;
    else if(cnt == wr_delay) 
        wr_trig <= 1'b1;
    else if(wr_trig == 1'b1 && wr_ready == 1'b1)
        wr_trig <= 1'b0;
end

always @(posedge clk) begin
    if(op_start == 1'b0) begin
        wr_data <= 'd1;
        wr_addr <= 'd0;
    end else begin
        if(wr_data_en)
            wr_data <= wr_data + 'd1;
        if(wr_done)
            wr_addr <= wr_addr + wr_len + wr_len;
    end

end


axi_wr_master #(
    .ADDR_WIDTH     ( ADDR_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH     ),
    .DATA_LEVEL     ( DATA_LEVEL    ),
    .WBURST_LEN     ( WBURST_LEN  ),
    .RBURST_LEN     ( RBURST_LEN  )
) axi_wr_master_inst (
    .rstn                       (rst_n),
    .clk                        (clk),
    .init_end                   (init_end),

    .axi_awvalid                (axi_awvalid),
    .axi_awready                (axi_awready),
    .axi_awaddr                 (axi_awaddr),
    .axi_awlen                  (axi_awlen),
    .axi_wvalid                 (axi_wvalid),
    .axi_wready                 (axi_wready),
    .axi_wlast                  (axi_wlast),
    .axi_wdata                  (axi_wdata),
    .axi_bvalid                 (axi_bvalid),
    .axi_bready                 (axi_bready),

    .wr_trig                    (wr_trig),                    
    .wr_len                     (wr_len),
    .wr_data                    (wr_data),
    .wr_data_en                 (wr_data_en),
    .wr_addr                    (wr_addr),
    .wr_ready                   (wr_ready),
    .wr_done                    (wr_done)
);

ddr2_ctrl ddr2_ctrl_inst (
    .clk                        (clk),
    .clk800m                    (clk800m),
    .rst_n                      (rst_n),
    .rstn_async                 (rstn_async),
    .init_end                   (init_end),
    .axi_awvalid                (axi_awvalid),
    .axi_awready                (axi_awready),
    .axi_awaddr                 (axi_awaddr),
    .axi_awlen                  (axi_awlen),
    .axi_wvalid                 (axi_wvalid),
    .axi_wready                 (axi_wready),
    .axi_wlast                  (axi_wlast),
    .axi_wdata                  (axi_wdata),
    .axi_bvalid                 (axi_bvalid),
    .axi_bready                 (axi_bready),
    .axi_arvalid                (axi_arvalid),
    .axi_arready                (axi_arready),
    .axi_araddr                 (axi_araddr),
    .axi_arlen                  (axi_arlen),
    .axi_rvalid                 (axi_rvalid),
    .axi_rready                 (axi_rready),
    .axi_rlast                  (axi_rlast),
    .axi_rdata                  (axi_rdata),
    .ddr2_clk                   (ddr2_clk),
    .ddr2_clk_n                 (ddr2_clk_n),
    .ddr2_cke                   (ddr2_cke),
    .ddr2_cs_n                  (ddr2_cs_n),
    .ddr2_cas_n                 (ddr2_cas_n),
    .ddr2_ras_n                 (ddr2_ras_n),
    .ddr2_we_n                  (ddr2_we_n),
    .ddr2_ba                    (ddr2_ba),
    .ddr2_addr                  (ddr2_addr),
    .ddr2_dq                    (ddr2_dq),
    .ddr2_dqm                   (ddr2_dqm),
    .ddr2_dqs                   (ddr2_dqs),
    .ddr2_dqs_n                 (ddr2_dqs_n)
);  
    
ddr2 ddr2_inst( 
    .ck                         (ddr2_clk),
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
    .dqs                        (ddr2_dqs),
    .dqs_n                      (ddr2_dqs_n),
    .rdqs_n                     (),
    .odt                        ()
);  




endmodule
