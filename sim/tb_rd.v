`timescale 1ps / 1ps
module tb_rd();
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

wire                       clk;
wire                       clk2;
reg                        clk100m;
reg                        rst_n;

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
// wire                        ddr2_clk_n;
wire                        ddr2_cke;
wire                        ddr2_cs_n;
wire                        ddr2_cas_n;
wire                        ddr2_ras_n;
wire                        ddr2_we_n;
wire      [BA_BITS-1:0]    ddr2_ba;
wire    [ADDR_BITS-1:0]    ddr2_addr;
wire      [DM_BITS-1:0]    ddr2_dqm;
wire      [DQ_BITS-1:0]    ddr2_dq;
wire     [DQS_BITS-1:0]    ddr2_dqs;
// wire     [DQS_BITS-1:0]    ddr2_dqs_n;

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

assign wr_len = 'd64;
assign rd_len = 'd32;
localparam wr_delay = 'd100;
localparam rd_delay = 'd150;


integer cnt;        
integer cnt_rd;        

// always #625 clk800m = ~clk800m;
always #5000 clk100m = ~clk100m;
wire    clk0;
wire    clk0_n;
wire    clk1;
wire    clk1_n;

wire init_end;

initial begin
    // clk800m <= 1'b1;
    clk100m <= 1'b1;
    rst_n <= 1'b0;
    // init_end_rd <= 1'b0;
    repeat(4) @(posedge clk100m);
    rst_n <= 1'b1;
    // init_end <= 1'b0;
    // init_end_rd <= 1'b1;
    // #2500000;
    // $finish(0);
end

// initial begin
//     $dumpfile("tb_rd.fsdb");
//     $dumpvars(0,tb_rd);
// end

reg wr_over;

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
    //有写结束
    else if(cnt == wr_delay && wr_over == 1'b0) 

    //一直写
    // else if(cnt == wr_delay) 
        wr_trig <= 1'b1;
    else if(wr_trig == 1'b1 && wr_ready == 1'b1)
        wr_trig <= 1'b0;
end

// always @(posedge clk) begin
always @(posedge clk1) begin
    if(init_end == 1'b0) begin
        wr_data <= 'h1200;
        wr_addr <= 'd0;
    end else begin
        //累加写
        if(wr_data_en)
            wr_data <= wr_data + 'd1;
        if(wr_done)
            wr_addr <= wr_addr + wr_len + wr_len;

        //循环写
        // if(wr_addr[COL_BITS]) begin
        //     wr_addr <= 'd0;
        //     wr_data <= 'd1;
        // end
        // else begin
        //     if(wr_data_en)
        //         wr_data <= wr_data + 'd1;
        //     if(wr_done)
        //         wr_addr <= wr_addr + wr_len + wr_len;
        // end
    end

end

//单独写
// always @(posedge clk) begin
//     if(!rst_n)
//         rd_trig <= 1'b0;
//         rd_addr <= 'd0;
// end

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

// always @(posedge clk) begin
always @(posedge clk1) begin
    if(wr_over == 1'b0)
        rd_trig <= 1'b0;
    else if(cnt_rd == rd_delay) 
        rd_trig <= 1'b1;
    else if(rd_trig == 1'b1 && rd_ready == 1'b1)
        rd_trig <= 1'b0;
end

// always @(posedge clk) begin
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


wire locked;
// clk_wiz_0 instance_name(
//     // Clock out ports
//     .clk_out1(clk),     // output clk_out1
//     .clk_out2(clk2),     // output clk_out2
//     // Status and control signals
//     .reset(!rst_n), // input reset
//     .locked(locked),       // output locked
//    // Clock in ports
//     .clk_in1(clk100m)
// );      // input clk_in1

// clk_wiz_1 clk_wiz_1_inst(
//     // Clock out ports
//     .clk_out1(clk0),     // output clk_out1
//     .clk_out2(clk0_n),     // output clk_out2
//     .clk_out3(clk1_n),     // output clk_out3
//     .clk_out4(clk1),     // output clk_out4
//     // Status and control signals
//     .reset(!rst_n), // input reset
//     .locked(locked),       // output locked
//    // Clock in ports
//     .clk_in1(clk100m)
// );      // input clk_in1
clk_wiz_1 clk_wiz_1_inst(
    // Clock out ports
    .clk_out1(clk1),     // output clk_out1
    .clk_out2(clk1_n),     // output clk_out2
    .clk_out3(clk0_n),     // output clk_out3
    .clk_out4(clk0),     // output clk_out4
    // Status and control signals
    .reset(!rst_n), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk100m)
);      // input clk_in1

wire [DQS_BITS-1:0] ddr2_dqs_p;
wire [DQS_BITS-1:0] ddr2_dqs_n;
wire  ddr2_clk_p;
wire  ddr2_clk_n;
// assign ddr2_clk = clk1;
// assign ddr2_clk_n = ~clk1;
// assign ddr2_clk = clk0;
// assign ddr2_clk_n = ~clk0;
// assign ddr2_dqs_n = ~ddr2_dqs;

axi_rd_master #(
    .ADDR_WIDTH     ( ADDR_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH     ),
    .DATA_LEVEL     ( DATA_LEVEL    ),
    .WBURST_LEN     ( WBURST_LEN  ),
    .RBURST_LEN     ( RBURST_LEN  )
) axi_rd_master_inst (
    .rst_n                       (rst_n),
    // .clk                        (clk),
    .clk                        (clk1),
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

ddr2_ctrl ddr2_ctrl_inst (
    .clk1                       (clk1),
    .clk1_n                     (clk1_n),
    .clk0_n                     (clk0_n),
    .clk0                     (clk0),
    // .clk                        (clk),
    // .clk2                       (clk2),
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
    // .ddr2_dqs                   (ddr2_dqs),
    .ddr2_dqs_p                   (ddr2_dqs_p),
    .ddr2_dqs_n                 (ddr2_dqs_n)
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
