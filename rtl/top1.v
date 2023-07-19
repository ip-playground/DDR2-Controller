`timescale 1ps / 1ps
// `define WRITE_ONLY


module top1 #(
    parameter   BA_BITS     =   3,
    parameter   ADDR_BITS   =   13, // Address Bits
    parameter   ROW_BITS    =   13, // Number of Address bits
    parameter   COL_BITS    =   10, // Number of Column bits
    parameter   DM_BITS     =   2, // Number of Data Mask bits
    parameter   DQ_BITS     =   16, // Number of Data bits
    parameter   DQS_BITS    =   2,// Number of Dqs bits
    parameter           ADDR_WIDTH  = ROW_BITS + COL_BITS + BA_BITS,
    parameter           DATA_WIDTH  = DQ_BITS * 2,
    parameter           DATA_LEVEL  = 2,
    parameter   [7:0]   WBURST_LEN   = 8'd8,
    parameter   [7:0]   RBURST_LEN   = 8'd8,
    parameter   wr_delay    =   2000,
    parameter   rd_delay    =   2000
)
(
    input                         sys_clk,
    input                         sys_rst_n,
    // output                          led,
    output                          wr_over_led,
    output                          init_end_led,
    output                          rd_error_led,

    output                         ddr2_clk_p,
    output                         ddr2_clk_n,
    output                         ddr2_cke,
    output                         ddr2_cs_n,
    output                         ddr2_cas_n,
    output                         ddr2_ras_n,
    output                         ddr2_we_n,
    output        [BA_BITS-1:0]    ddr2_ba,
    output      [ADDR_BITS-1:0]    ddr2_addr,
    inout         [DM_BITS-1:0]    ddr2_dqm,
    inout         [DQ_BITS-1:0]    ddr2_dq,
    inout        [DQS_BITS-1:0]    ddr2_dqs_p,
    inout        [DQS_BITS-1:0]    ddr2_dqs_n,
    output                         ddr2_odt
     
);



wire                       clk;
wire                       clk100m;
wire                       rst_n;

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



reg                         wr_trig;
wire                [7:0]   wr_len;
reg      [DATA_WIDTH-1:0]   wr_data;
wire                        wr_data_en;
reg      [ADDR_WIDTH-1:0]   wr_addr;
wire                        wr_ready;
wire                        wr_done;

reg                         rd_trig;
wire                [7:0]   rd_len;
wire      [DATA_WIDTH-1:0]  rd_data;
reg      [DATA_WIDTH-1:0]   rd_data_accept;
wire                        rd_data_en;
reg      [ADDR_WIDTH-1:0]   rd_addr;
wire                        rd_ready;   
wire                        rd_done;




assign clk100m = sys_clk;
assign rst_n = sys_rst_n;

assign wr_len = 'd32;
assign rd_len = 'd32;

integer cnt;        
integer cnt_rd;        

wire init_end;
reg wr_over;
wire rd_error;

assign init_end_led = init_end;
assign wr_over_led = wr_over;
assign rd_error_led = rd_error;

wire    clk0;
wire    clk2;
wire    clk1;
wire    clk1_n;
wire    locked;


always @(posedge clk1) begin
    if(init_end == 1'b0)
        cnt <= 'd0;
    else if(cnt == wr_delay) begin
        cnt <= 'd0;
    end else 
        cnt <= cnt + 'd1;
end

// always @(posedge clk) begin
always @(posedge clk1) begin
    if(init_end == 1'b0)
        wr_trig <= 1'b0;
    `ifdef WRITE_ONLY
    //一直写
    else if(cnt == wr_delay) 
    `else
    //有写结束
    else if(cnt == wr_delay && wr_over == 1'b0) 
    `endif
        wr_trig <= 1'b1;
    else if(wr_trig == 1'b1 && wr_ready == 1'b1)
        wr_trig <= 1'b0;
end


// always @(posedge clk) begin
always @(posedge clk1) begin
    if(init_end == 1'b0) begin
        wr_data <= 'h1;
        wr_addr <= 'd0;
    end else begin
        `ifdef WRITE_ONLY
        //循环写
        if(wr_addr[COL_BITS]) begin
            wr_addr <= 'd0;
            wr_data <= 'd1;
        end
        else begin
            if(wr_data_en)
                wr_data <= wr_data + 'd1;
            if(wr_done)
                wr_addr <= wr_addr + wr_len + wr_len;
        end
        `else
        //累加写
        if(wr_data_en)
            wr_data <= wr_data + 'd1;
        if(wr_done)
            wr_addr <= wr_addr + wr_len + wr_len;
        `endif
    end

end

`ifdef WRITE_ONLY
//单独写
always @(posedge clk) begin
    if(!rst_n)
        rd_trig <= 1'b0;
        rd_addr <= 'd0;
end
`else
//下面为读请求信号产生过程
always @(posedge clk1) begin
    if(!rst_n) 
        wr_over <= 1'b0;
    else if(wr_addr[COL_BITS])
        wr_over <= 1'b1;
end
always @(posedge clk1) begin
    if(wr_over == 1'b0)
        cnt_rd <= 'd0;
    else if(cnt_rd == rd_delay) begin
        cnt_rd <= 'd0;
    end else 
        cnt_rd <= cnt_rd + 'd1;
end

always @(posedge clk1) begin
    if(wr_over == 1'b0)
        rd_trig <= 1'b0;
    else if(cnt_rd == rd_delay) 
        rd_trig <= 1'b1;
    else if(rd_trig == 1'b1 && rd_ready == 1'b1)
        rd_trig <= 1'b0;
end

always @(posedge clk1) begin
    if(wr_over == 1'b0) begin
        rd_addr <= 'd0;
    end else begin
        if(rd_data_en)
            rd_data_accept <= rd_data;
        if(rd_addr[COL_BITS])
            rd_addr <= 'd0;
        else 
        if(rd_done)
            rd_addr <= rd_addr + rd_len + rd_len;
    end
end
`endif
wire clk1_rd;
   BUFG BUFG_inst_rd (
      .O(clk1_rd), // 1-bit output: Clock output
      .I(clk1)  // 1-bit input: Clock input
   );
wire clk1_ctrl;
   BUFG BUFG_inst_0 (
      .O(clk1_ctrl), // 1-bit output: Clock output
      .I(clk1)  // 1-bit input: Clock input
   );
wire clk1_ctrl_n;
   BUFG BUFG_inst_1 (
      .O(clk1_ctrl_n), // 1-bit output: Clock output
      .I(clk1_n)  // 1-bit input: Clock input
   );


clk_wiz_1 clk_wiz_1_inst(
    // Clock out ports
    .clk_out1(clk1),     // output clk_out1  主时钟
    .clk_out2(clk1_n),     // output clk_out2
    .clk_out3(clk2),     // output clk_out3   写数据用
    // .clk_out5(clk2),     // output clk_out5
    // Status and control signals
    .reset(!rst_n), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk100m)
);      // input clk_in1


axi_rd_master #(
    .ADDR_WIDTH     ( ADDR_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH     ),
    .DATA_LEVEL     ( DATA_LEVEL    ),
    .WBURST_LEN     ( WBURST_LEN  ),
    .RBURST_LEN     ( RBURST_LEN  )
) axi_rd_master_inst (
    .rst_n                       (rst_n),
    .clk                        (clk1),
    // .clk                        (clk1_rd),
    // .led                        (led),
    .rd_error                   (rd_error),
    .init_end                   (init_end),

    .axi_arvalid                (axi_arvalid),
    .axi_arready                (axi_arready),
    .axi_araddr                 (axi_araddr),
    .axi_arlen                  (axi_arlen),
    .axi_rvalid                 (axi_rvalid),
    .axi_rready                 (axi_rready),
    .axi_rlast                  (axi_rlast),
    .axi_rdata                  (axi_rdata),

    .rd_trig                    (rd_trig),                    
    .rd_len                     (rd_len),
    .rd_data                    (rd_data),
    .rd_data_en                 (rd_data_en),
    .rd_addr                    (rd_addr),
    .rd_ready                   (rd_ready),
    .rd_done                    (rd_done)
);


axi_wr_master #(
    .ADDR_WIDTH     ( ADDR_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH     ),
    .DATA_LEVEL     ( DATA_LEVEL    ),
    .WBURST_LEN     ( WBURST_LEN  ),
    .RBURST_LEN     ( RBURST_LEN  )
) axi_wr_master_inst (
    .rst_n                       (rst_n),
    // .clk                        (clk),
    .clk                        (clk1),
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

ddr2_ctrl #(
    .BA_BITS     ( BA_BITS     ),    
    .ADDR_BITS   ( ADDR_BITS   ),
    .ROW_BITS    ( ROW_BITS    ),
    .COL_BITS    ( COL_BITS    ),
    .DM_BITS     ( DM_BITS     ),
    .DQ_BITS     ( DQ_BITS     ),
    .DQS_BITS    ( DQS_BITS    )
)  ddr2_ctrl_inst (
    // .clk                        (clk),
    .clk0                        (clk0),
    .clk2                     (clk2),
    // .clk1                       (clk1),
    // .clk1_n                     (clk1_n),
    .clk1                       (clk1_ctrl),
    .clk1_n                     (clk1_ctrl_n),
    // .clk2                       (clk2),
    // .ddr2_dqs_in                (ddr2_dqs_in),
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
    // .axi_rdata_next_r           (axi_rdata_next_r),
    .ddr2_clk_p                   (ddr2_clk_p),
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
    .ddr2_dqs_p                   (ddr2_dqs_p),
    .ddr2_dqs_n                 (ddr2_dqs_n),
    .ddr2_odt                   (ddr2_odt)
);  





endmodule