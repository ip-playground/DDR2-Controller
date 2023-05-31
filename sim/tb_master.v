`timescale 1ps / 1ps

module tb_master();

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
parameter   [7:0]   WBURST_LEN   = 8'd128;  
parameter   [7:0]   RBURST_LEN   = 8'd128;  
parameter   MEM_SIZE    =   1024;

wire                        clk;
wire                        clk2;
reg                         clk100m;
reg                         rst_n;

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

wire                        usr_wr_en;
wire   [DATA_WIDTH-1:0]     usr_wr_data;
wire   [ADDR_WIDTH-1:0]     usr_wr_begin_addr;
wire   [ADDR_WIDTH-1:0]     usr_wr_end_addr;

wire                        usr_rd_en;
wire   [DATA_WIDTH-1:0]     usr_rd_data; 
wire   [ADDR_WIDTH-1:0]     usr_rd_begin_addr;
wire   [ADDR_WIDTH-1:0]     usr_rd_end_addr;

assign usr_wr_begin_addr = 'd0;
assign usr_wr_end_addr = usr_wr_begin_addr + MEM_SIZE * 2;

assign usr_rd_begin_addr = 'd0;
assign usr_rd_end_addr = usr_rd_begin_addr + MEM_SIZE * 2;

always #5000 clk100m = ~clk100m;

wire init_end;

initial begin
    clk100m <= 1'b1;
    rst_n <= 1'b0;
    repeat(4) @(posedge clk100m);
    rst_n <= 1'b1;
    #305000000;
    #5500000;
    // $finish(0);
end

wire locked;
clk_wiz_0 instance_name(
    // Clock out ports
    .clk_out1(clk),     // output clk_out1
    .clk_out2(clk2),     // output clk_out2
    // Status and control signals
    .reset(!rst_n), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk100m)
);      // input clk_in1

generate_data #(
    .DATA_WIDTH                 ( DATA_WIDTH  ),
    .MEM_SIZE                   (MEM_SIZE)
)generate_data_inst (
    .sys_clk                    (clk),
    .sys_rst_n                  (rst_n),
    .init_end                   (init_end),
    .wr_en                      (usr_wr_en),
    .wr_data                    (usr_wr_data),
    .rd_en                      (usr_rd_en),
    .rd_data                    (usr_rd_data)
);

master #(
    .ADDR_WIDTH                 ( ADDR_WIDTH  ),
    .DATA_WIDTH                 ( DATA_WIDTH  ),
    .DATA_LEVEL                 ( DATA_LEVEL  ),
    .WBURST_LEN                 ( WBURST_LEN  ),
    .RBURST_LEN                 ( RBURST_LEN  )
)master_inst(
    .clk                        (clk),
    .rst_n                      (rst_n),
    .init_end                   (init_end),

    .usr_wr_en                  (usr_wr_en),
    .usr_wr_data                (usr_wr_data),
    .usr_wr_begin_addr          (usr_wr_begin_addr),
    .usr_wr_end_addr            (usr_wr_end_addr),

    .usr_rd_en                  (usr_rd_en),
    .usr_rd_data                (usr_rd_data),
    .usr_rd_begin_addr          (usr_rd_begin_addr),
    .usr_rd_end_addr            (usr_rd_end_addr),

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
    .axi_rdata                  (axi_rdata)

);


ddr2_ctrl #(
    .BA_BITS                    (BA_BITS),
    .ADDR_BITS                  (ADDR_BITS),
    .ROW_BITS                   (ROW_BITS),
    .COL_BITS                   (COL_BITS),
    .DM_BITS                    (DM_BITS),
    .DQ_BITS                    (DQ_BITS),   
    .DQS_BITS                   (DQS_BITS)
)ddr2_ctrl_inst(
    .clk                        (clk),
    .clk2                       (clk2),
    .rst_n                      (rst_n),
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
