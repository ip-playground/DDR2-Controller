`timescale 1ps / 1ps

module master#(
    parameter           ADDR_WIDTH  = 26,
    parameter           DATA_WIDTH  = 32,
    parameter           DATA_LEVEL  = 2,
    parameter           COL_BITS    = 10, // Number of Column bits
    parameter   [7:0]   WBURST_LEN  = 8'd128,
    parameter   [7:0]   RBURST_LEN  = 8'd128 
)(
    input   wire                        rst_n,
    input   wire                        clk,
    input   wire                        init_end,

    input   wire                        usr_wr_en,
    input   wire    [DATA_WIDTH-1:0]    usr_wr_data,
    input   wire    [ADDR_WIDTH-1:0]    usr_wr_begin_addr,
    input   wire    [ADDR_WIDTH-1:0]    usr_wr_end_addr,

    input   wire                        usr_rd_en,
    output  wire    [DATA_WIDTH-1:0]    usr_rd_data,
    input   wire    [ADDR_WIDTH-1:0]    usr_rd_begin_addr,
    input   wire    [ADDR_WIDTH-1:0]    usr_rd_end_addr,

    output  wire                        axi_awvalid,
    input   wire                        axi_awready,
    output  wire     [ADDR_WIDTH-1:0]   axi_awaddr,
    output  wire     [           7:0]   axi_awlen,
    // output  wire     [           1:0]   axi_awsize,
    output  wire                        axi_wvalid,
    input   wire                        axi_wready,
    output  wire                        axi_wlast,
    output  wire     [DATA_WIDTH-1:0]   axi_wdata,
    input   wire                        axi_bvalid,
    output  wire                        axi_bready,

    output  wire                        axi_arvalid,
    input   wire                        axi_arready,
    output  wire    [ADDR_WIDTH-1:0]   axi_araddr,
    output  wire     [           7:0]   axi_arlen,
    // output  wire     [           1:0]   axi_arsize,
    input   wire                        axi_rvalid,
    output  wire                        axi_rready,
    input   wire                        axi_rlast,
    input   wire     [DATA_WIDTH-1:0]   axi_rdata
);


//写信号
wire                        axi_wr_data_en;
wire   [DATA_WIDTH-1:0]     axi_wr_data;
wire                        axi_wr_ready;
wire                        axi_wr_trig;
wire   [ADDR_WIDTH-1:0]     axi_wr_addr;
wire              [7:0]     axi_wr_burst_len;
wire                        axi_wr_done; 
reg                         wr_trig_reg          ;   
reg   [ADDR_WIDTH-1:0]      wr_addr_reg          ;

//读信号
wire                        axi_rd_data_en;
wire   [DATA_WIDTH-1:0]     axi_rd_data;
wire                        axi_rd_ready;
wire                        axi_rd_trig;
wire   [ADDR_WIDTH-1:0]     axi_rd_addr;
wire              [7:0]     axi_rd_burst_len;
wire                        axi_rd_done;    
reg                         rd_trig_reg          ;   
reg   [ADDR_WIDTH-1:0]      rd_addr_reg          ;


//写fifo所需信号
// wire                        wr_fifo_wr_clk        ;
// wire                        wr_fifo_rd_clk        ;
wire                        wr_fifo_clk           ;
wire    [DATA_WIDTH-1:0]    wr_fifo_din           ;
wire    [DATA_WIDTH-1:0]    wr_fifo_dout           ;
wire                        wr_fifo_wr_en         ;
wire                        wr_fifo_full          ;
wire                        wr_fifo_almost_full   ;
wire                        wr_fifo_empty         ;
wire                        wr_fifo_almost_empty  ;
// wire               [9:0]    wr_fifo_rd_data_count ;
// wire               [9:0]    wr_fifo_rd_data_count ;
wire              [10:0]    wr_fifo_data_count ;

//读fifo
wire                        rd_fifo_clk           ;
wire    [DATA_WIDTH-1:0]    rd_fifo_din           ;
wire    [DATA_WIDTH-1:0]    rd_fifo_dout           ;
wire                        rd_fifo_wr_en         ;
wire                        rd_fifo_rd_en         ;
wire                        rd_fifo_full          ;
wire                        rd_fifo_almost_full   ;
wire                        rd_fifo_empty         ;
wire                        rd_fifo_almost_empty  ;
wire              [10:0]    rd_fifo_data_count ;

// assign wr_fifo_wr_clk = usr_wr_clk;
// assign wr_fifo_rd_clk = clk;
assign wr_fifo_clk = clk;
assign wr_fifo_rst = !rst_n;
assign wr_fifo_din = usr_wr_data;
assign wr_fifo_wr_en = usr_wr_en;
assign wr_fifo_rd_en = axi_wr_data_en;
assign axi_wr_data = wr_fifo_dout;

assign rd_fifo_clk = clk;
assign rd_fifo_rst = !rst_n;
assign rd_fifo_wr_en = axi_rd_data_en;
assign rd_fifo_din = axi_rd_data;
assign rd_fifo_rd_en = usr_rd_en;
assign usr_rd_data = rd_fifo_dout;


assign axi_wr_burst_len = WBURST_LEN;
assign axi_wr_trig = wr_trig_reg;
assign axi_wr_addr = wr_addr_reg;


assign axi_rd_burst_len = RBURST_LEN;
assign axi_rd_trig = rd_trig_reg;
assign axi_rd_addr = rd_addr_reg;



/*根据写总线状态 和当前写fifo里是否有数据 生成wr_trig,*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_trig_reg <= 1'b0;
    else if((wr_fifo_data_count+'d2) >= WBURST_LEN && axi_wr_ready == 1'b1)
        wr_trig_reg <= 1'b1;
    else
        wr_trig_reg <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_addr_reg <= usr_wr_begin_addr;
    else if(axi_wr_done) begin
        if(wr_addr_reg >= usr_wr_end_addr - WBURST_LEN * 2) begin
            wr_addr_reg <= usr_wr_begin_addr;
        end
        else
            wr_addr_reg <= wr_addr_reg + WBURST_LEN*2;
    end
end

/*根据用户读请求、读总线状态 和当前写fifo里是否数据full 生成rd_trig,*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rd_trig_reg <= 1'b0;
    else if(usr_rd_en == 1'b1 && rd_fifo_data_count <= (2048 - RBURST_LEN) && axi_rd_ready)
        rd_trig_reg <= 1'b1;
    else 
        rd_trig_reg <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rd_addr_reg <= usr_rd_begin_addr;
    else if(axi_rd_done) begin
        if(rd_addr_reg >= usr_rd_end_addr - WBURST_LEN * 2) begin
            rd_addr_reg <= usr_rd_begin_addr;
        end
        else
            rd_addr_reg <= rd_addr_reg + RBURST_LEN*2;
    end
end

wr_fifo wr_fifo_inst (
    .clk                        (wr_fifo_clk),
    .srst                       (wr_fifo_rst),
    .din                        (wr_fifo_din),
    .wr_en                      (wr_fifo_wr_en),
    .dout                       (wr_fifo_dout),
    .rd_en                      (wr_fifo_rd_en),
    .almost_full                (wr_fifo_almost_full),    
    .empty                      (wr_fifo_empty),
    .almost_empty               (wr_fifo_almost_empty),
    .data_count                 (wr_fifo_data_count)
);

wr_fifo rd_fifo_inst (
    .clk                        (rd_fifo_clk),
    .srst                       (rd_fifo_rst),
    .din                        (rd_fifo_din),
    .wr_en                      (rd_fifo_wr_en),
    .dout                       (rd_fifo_dout),
    .rd_en                      (rd_fifo_rd_en),
    .almost_full                (rd_fifo_almost_full),    
    .empty                      (rd_fifo_empty),
    .almost_empty               (rd_fifo_almost_empty),
    .data_count                 (rd_fifo_data_count)
);


// fifo_ctrl_master  #(
//     .ADDR_WIDTH                 ( ADDR_WIDTH  ),
//     .DATA_WIDTH                 ( DATA_WIDTH  ),
//     .WBURST_LEN                 ( WBURST_LEN  ),
//     .RBURST_LEN                 ( RBURST_LEN  )
// )fifo_ctrl_master_inst(
//     .clk                        (clk),
//     .rst_n                      (rst_n),

//     .usr_wr_clk                (clk),
//     .usr_wr_rst_n              (rst_n),
//     .usr_wr_begin_addr          (usr_wr_begin_addr),
//     .usr_wr_end_addr            (usr_wr_end_addr),
//     .usr_wr_en                  (usr_wr_en),
//     .usr_wr_data                (usr_wr_data),

//     .wr_ready                   (axi_wr_ready),
//     .wr_trig                    (axi_wr_trig),
//     .wr_addr                    (axi_wr_addr),
//     .wr_burst_len               (axi_wr_burst_len),
//     .wr_fifo_rd_en              (axi_wr_data_en),
//     .wr_fifo_dout           (axi_wr_data),
//     .wr_done                    (axi_wr_done)
// );


axi_wr_master #(
    .ADDR_WIDTH     ( ADDR_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH     ),
    .DATA_LEVEL     ( DATA_LEVEL    ),
    .WBURST_LEN     ( WBURST_LEN  ),
    .RBURST_LEN     ( RBURST_LEN  )
) axi_wr_master_inst (
    .rst_n                       (rst_n),
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

    .wr_trig                    (axi_wr_trig),                    
    .wr_len                     (axi_wr_burst_len),
    .wr_data                    (axi_wr_data),
    .wr_data_en                 (axi_wr_data_en),
    .wr_addr                    (axi_wr_addr),
    .wr_ready                   (axi_wr_ready),
    .wr_done                    (axi_wr_done)
);

axi_rd_master #(
    .ADDR_WIDTH     ( ADDR_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH     ),
    .DATA_LEVEL     ( DATA_LEVEL    ),
    .WBURST_LEN     ( WBURST_LEN  ),
    .RBURST_LEN     ( RBURST_LEN  )
) axi_rd_master_inst (
    .rst_n                      (rst_n),
    .clk                        (clk),
    .init_end                   (init_end),

    .axi_arvalid                (axi_arvalid),
    .axi_arready                (axi_arready),
    .axi_araddr                 (axi_araddr),
    .axi_arlen                  (axi_arlen),
    .axi_rvalid                 (axi_rvalid),
    .axi_rready                 (axi_rready),
    .axi_rlast                  (axi_rlast),
    .axi_rdata                  (axi_rdata),

    .rd_trig                    (axi_rd_trig),                    
    .rd_len                     (axi_rd_burst_len),
    .rd_data                    (axi_rd_data),
    .rd_data_en                 (axi_rd_data_en),
    .rd_addr                    (axi_rd_addr),
    .rd_ready                   (axi_rd_ready),
    .rd_done                    (axi_rd_done)
);


endmodule
