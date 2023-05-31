`timescale 1ps / 1ps
module fifo_ctrl_master
#(
    parameter           ADDR_WIDTH  = 26,
    parameter           DATA_WIDTH  = 32,
    parameter   [7:0]   WBURST_LEN  = 8'd128,
    parameter   [7:0]   RBURST_LEN  = 8'd128 

)
(
    input   wire                        clk             ,
    input   wire                        rst_n           ,
    
    //用户数据 写入写fifo 信号
    input   wire                        usr_wr_clk     ,
    input   wire                        usr_wr_rst_n   ,
    input   wire    [ADDR_WIDTH-1:0]    usr_wr_begin_addr,
    input   wire    [ADDR_WIDTH-1:0]    usr_wr_end_addr ,
    input   wire                        usr_wr_en   ,   //写fifo 写使能
    input   wire    [DATA_WIDTH-1:0]    usr_wr_data ,

    //axi_wr
    input   wire                        wr_fifo_rd_en   ,
    output  wire   [DATA_WIDTH-1:0]     wr_fifo_dout,
    input   wire                        wr_ready,           //总线 写通道空闲
    output  wire                        wr_trig         ,   //写突发触发信号
    output  wire   [ADDR_WIDTH-1:0]     wr_addr         ,
    output  wire              [7:0]     wr_burst_len    ,
    input   wire                        wr_done  
);

//寄存器
reg                         wr_trig_reg          ;   
reg   [ADDR_WIDTH-1:0]      wr_addr_reg          ;

//写fifo所需信号
// wire                        wr_fifo_wr_clk        ;
// wire                        wr_fifo_rd_clk        ;
wire                        wr_fifo_clk           ;
wire    [DATA_WIDTH-1:0]    wr_fifo_din           ;
wire                        wr_fifo_wr_en         ;
wire                        wr_fifo_full          ;
wire                        wr_fifo_almost_full   ;
wire                        wr_fifo_empty         ;
wire                        wr_fifo_almost_empty  ;
// wire               [9:0]    wr_fifo_rd_data_count ;
// wire               [9:0]    wr_fifo_rd_data_count ;
wire              [10:0]    wr_fifo_data_count ;

// assign wr_fifo_wr_clk = usr_wr_clk;
// assign wr_fifo_rd_clk = clk;
assign wr_fifo_clk = clk;
assign wr_fifo_rst = !usr_wr_rst_n;
assign wr_fifo_din = usr_wr_data;
assign wr_fifo_wr_en = usr_wr_en;

assign wr_burst_len = WBURST_LEN;
assign wr_trig = wr_trig_reg;
assign wr_addr = wr_addr_reg;

/*根据wr_ready 和当前写fifo里是否有数据 生成wr_trig,*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_trig_reg <= 1'b0;
    else if((wr_fifo_data_count+'d2) >= WBURST_LEN && wr_ready == 1'b1)
        wr_trig_reg <= 1'b1;
    else
        wr_trig_reg <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_addr_reg <= usr_wr_begin_addr;
    else if(wr_done) begin
        if(wr_addr_reg >= usr_wr_end_addr - WBURST_LEN * 2)
            wr_addr_reg <= usr_wr_begin_addr;
        else
            wr_addr_reg <= wr_addr_reg + WBURST_LEN*2;
    end
end






wr_fifo wr_fifo_inst (
    .clk                        (wr_fifo_clk),
    .srst                        (wr_fifo_rst),
    .din                        (wr_fifo_din),
    .wr_en                      (wr_fifo_wr_en),
    .dout                       (wr_fifo_dout),
    .rd_en                      (wr_fifo_rd_en),
    .almost_full                (wr_fifo_almost_full),    
    .empty                      (wr_fifo_empty),
    .almost_empty               (wr_fifo_almost_empty),
    .data_count                 (wr_fifo_data_count)
);





endmodule
