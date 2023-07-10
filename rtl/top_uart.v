`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/28 16:22:50
// Design Name: 
// Module Name: top_uart
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
module top_uart #(
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
    parameter   [7:0]   RBURST_LEN   = 8'd8
)
(
    input                         sys_clk,
    input                         sys_rst_n,

    input                           uart_rx,
    output                          uart_tx,
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
wire                       clk2;
wire                       clk100m;
wire                       rst_n;

wire init_end;
reg wr_over;
wire rd_error;

assign init_end_led = init_end;
assign wr_over_led = wr_over;
assign rd_error_led = rd_error;

assign clk100m = sys_clk;
assign rst_n = sys_rst_n;


wire    clk0;
wire    clk0_n;
wire    clk1;
wire    clk1_n;
wire    locked;

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
// reg      [DATA_WIDTH-1:0]   wr_data;
wire     [DATA_WIDTH-1:0]   wr_data;
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
// wire      [ADDR_WIDTH-1:0]   rd_addr;
wire                        rd_ready;   
wire                        rd_done;



wire [7:0] uart_data;
wire uart_valid;
wire data_valid_out;
wire [7:0] data_out;
wire [25:0] address_out;
wire read_cmd_out;
wire write_cmd_out;
reg [7:0] data_in;
reg data_valid_in;

wire uart_clk_buf;
wire uart_clk;
// ODDR #(
//    .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
//    .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
//    .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
// ) ODDR_uart_buf (
//    .Q(uart_clk_buf),   // 1-bit DDR output
//    .C(clk100m),   // 1-bit clock input
//    .CE(1'b1), // 1-bit clock enable input
//    .D1(1'b1), // 1-bit data input (positive edge)
//    .D2(1'b0), // 1-bit data input (negative edge)
//    .R(R),   // 1-bit reset
//    .S(1'b0)    // 1-bit set
// );

// OBUF OBUF_uart(.I(uart_clk_buf),.O(uart_clk));
OBUF OBUF_uart(.I(clk100m),.O(uart_clk));

uart_rx uart_receiver (
    .clk(uart_clk),
    .reset_n(rst_n),
    .rx(uart_rx),
    .data(uart_data),
    .valid(uart_valid)
);

uart_tx uart_sender (
    .clk(uart_clk),
    .reset_n(rst_n),
    .tx_en(data_valid_in),
    .tx_data(data_in),
    .tx_out(uart_tx)
);

command_parser cmd_parser (
    .clk(uart_clk),
    .reset_n(rst_n),
    .data_in(uart_data),
    .valid_in(uart_valid),
    .address(address_out),
    .data(data_out),
    .data_valid(data_valid_out),
    .read_cmd(read_cmd_out),
    .write_cmd(write_cmd_out)
);

assign wr_len = 'd4;
assign rd_len = 'd4;
// assign wr_addr = address_out;
reg wfifo_rd_en;
// wire wfifo_rd_en;
wire [31:0]wfifo_dout;  
wire [5 : 0] wfifo_rd_data_count;
wire [7 : 0] wfifo_wr_data_count;
wire empty;
wire almost_empty;



fifo_generator_0 wfifo (
  .rst(!rst_n),                      // input wire rst
  .wr_clk(clk100m),                // input wire wr_clk
  .rd_clk(clk1),                // input wire rd_clk
  .din(data_out),                      // input wire [7 : 0] din
  .wr_en(data_valid_out),                  // input wire wr_en
  .rd_en(wr_data_en),                  // input wire rd_en

  .dout(wfifo_dout),                    // output wire [31 : 0] dout
  .full(),                    // output wire full
  .almost_full(),      // output wire almost_full
  .empty(empty),                  // output wire empty
  .almost_empty(almost_empty),    // output wire almost_empty
  
  .rd_data_count(wfifo_rd_data_count),  // output wire [5 : 0] rd_data_count
  .wr_data_count(wfifo_wr_data_count),  // output wire [7 : 0] wr_data_count
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy()      // output wire rd_rst_busy
);

reg wfifo_wr_over;
always @(posedge clk100m) begin
    if(!rst_n)
        wfifo_wr_over <= 1'b0;
    else if(wfifo_wr_data_count == (wr_len << 2))
        wfifo_wr_over <= 1'b1;
    else
        wfifo_wr_over <= 1'b0;
end


always @(posedge clk1) begin
    if(!rst_n)
        wfifo_rd_en <= 'd0;
    // else if(wfifo_wr_data_count == (wr_len << 2) && (wr_data_en == 1'b1))
    else if( (wr_data_en == 1'b1))
        wfifo_rd_en <= 1'b1;
    else 
        wfifo_rd_en <= 1'b0;       
end


reg wfifo_wr_over_0;
reg wfifo_wr_over_1;
reg wr_req_0;
reg wr_req_1;
reg wr_req;

always @(posedge clk1) begin
    if(!rst_n) begin
        wfifo_wr_over_0 <= 1'b0;
        wfifo_wr_over_1 <= 1'b0;
    end else begin
        wfifo_wr_over_0 <= wfifo_wr_over;
        wfifo_wr_over_1 <= wfifo_wr_over_0;
    end
end


always @(posedge clk1) begin
    if(~rst_n)
        wr_req_0 <= 1'b0;
    // else if(wfifo_wr_data_count == (wr_len << 2)) begin
    else if(wfifo_wr_over_1 == 1'b1) begin
        wr_req_0 <= 1'b1;
    end else 
        wr_req_0 <= 1'b0;
end

always @(posedge clk1) begin
    if(~rst_n)
        wr_req_1 <= 1'b0;
    else
        wr_req_1 <= wr_req_0;
end

always @(posedge clk1) begin
    if(~rst_n)
        wr_req <= 1'b0;
    else if(wr_req_0 & (~wr_req_1))
        wr_req <= 1'b1;
    else if(wr_req == 1'b1 && wr_trig == 1'b0)
        wr_req <= 1'b0;
end

always @(posedge clk1) begin
    if(~rst_n)
        wr_trig <= 1'b0;
    else if(wr_req == 1'b1 && wr_trig == 1'b0) 
        wr_trig <= 1'b1;
    else if(wr_ready == 1'b1 && wr_trig == 1'b1)
        wr_trig <= 1'b0;
end

assign wr_data =  wfifo_dout ;

reg [25:0]wr_addr_0;
reg [25:0]wr_addr_1;

always @(posedge clk1) begin
    if(~rst_n) begin
        wr_addr_0 <= 'd0;
        wr_addr_1 <= 'd0;
    end else begin
        wr_addr_0 <= address_out;
        wr_addr_1 <= wr_addr_0;
    end
end

always @(posedge clk1) begin
    if(~rst_n)
        wr_addr <= 'd0;
    else
        wr_addr <= wr_addr_0;
end

ila_1 ila_top (
    .clk(clk1),
    .probe0(wr_data[15:0]),
    .probe1(wr_data_en)
);


reg rd_req;
wire [7:0] rfifo_dout;
wire rfifo_empty;  
reg [4:0] rdata_cnt;
reg [13:0] rd_baud_cnt;
parameter BAUD_CNT_MAX  =   550;
// parameter BAUD_CNT_MAX  =   52070;
reg rfifo_rd_work_en;
wire rfifo_rd_en;
wire [5:0] rfifo_wr_data_count;

assign rfifo_rd_en = rd_baud_cnt == BAUD_CNT_MAX/2;

fifo_generator_1 rfifo (
  .rst(!rst_n),                      // input wire rst
  .wr_clk(clk1),                // input wire wr_clk
  .rd_clk(clk100m),                // input wire rd_clk
  .din(rd_data),                      // input wire [31 : 0] din
  .wr_en(rd_data_en),                  // input wire wr_en

  .rd_en(rfifo_rd_en),                  // input wire rd_en
  .dout(rfifo_dout),                    // output wire [7 : 0] dout

  .full(),                    // output wire full
  .empty(rfifo_empty),                  // output wire empty
  .rd_data_count(),  // output wire [7 : 0] rd_data_count
  .wr_data_count(rfifo_wr_data_count),  // output wire [5 : 0] wr_data_count
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy()      // output wire rd_rst_busy
);

always @(posedge clk1) begin
    if(~rst_n)
        rd_req <= 1'b0;
    else if(read_cmd_out & clk100m)
        rd_req <= 1'b1;
    else if(rd_req == 1'b1 && rd_trig == 1'b0 )
        rd_req <= 1'b0;
end

always @(posedge clk1) begin
    if(~rst_n)
        rd_trig <= 1'b0;
    else if(rd_req == 1'b1 && rd_trig == 1'b0) 
        rd_trig <= 1'b1;
    else if(rd_ready == 1'b1 && rd_trig == 1'b1)
        rd_trig <= 1'b0;
end

// reg [25:0]rd_addr_0;
// reg [25:0]rd_addr_1;

// always @(posedge clk1) begin
//     if(~rst_n) begin
//         rd_addr_0 <= 'd0;
//         rd_addr_1 <= 'd0;
//     end else begin
//         rd_addr_0 <= address_out;
//         rd_addr_1 <= rd_addr_0;
//     end
// end

// always @(posedge clk1) begin
//     if(~rst_n)
//         rd_addr <= 'd0;
//     else
//         rd_addr <= rd_addr_1;
// end
always @(posedge clk1) begin
    if(~rst_n)
        rd_addr <= 'd0;
    else
        rd_addr <= address_out;
end
// assign rd_addr = address_out;


always@(posedge clk100m )
    if(~rst_n)
        rfifo_rd_work_en <= 1'b0;
    else  if(~rfifo_empty)
        rfifo_rd_work_en <= 1'b1;
    else    if((rdata_cnt == 4'd0) )
        rfifo_rd_work_en <= 1'b0;

always @(posedge clk100m) begin
    if(~rst_n)
        rd_baud_cnt <= 14'd0;
    else    if((rfifo_rd_work_en == 1'b0) || (rd_baud_cnt == BAUD_CNT_MAX - 1))
        rd_baud_cnt <= 14'd0;
    else    if(rfifo_rd_work_en == 1'b1)
        rd_baud_cnt <= rd_baud_cnt + 1'b1;
end

always @(posedge clk100m) begin
    if(~rst_n) begin;
        data_in <= 'd0;
        data_valid_in <= 1'b0;
    end
    else if(rdata_cnt > 0)begin
         if(rd_baud_cnt == BAUD_CNT_MAX - 2)begin
            data_valid_in <= 1'b1;
            data_in <= rfifo_dout;
        end else 
            data_valid_in <= 1'b0;
    end
end    


always @(posedge clk100m) begin
    if(~rst_n)
        rdata_cnt <= 'd0;
    else if(~rfifo_empty && (rdata_cnt == 'd0))
        rdata_cnt <= (rd_len << 2); 
    else if(rd_baud_cnt == BAUD_CNT_MAX - 1)
        rdata_cnt <= rdata_cnt - 'd1;
end






clk_wiz_1 clk_wiz_1_inst(
    // Clock out ports
    .clk_out1(clk1),     // output clk_out1  主时钟
    .clk_out2(clk1_n),     // output clk_out2
    .clk_out3(clk0_n),     // output clk_out3   写数据用
    .clk_out4(clk0),     // output clk_out4
    // .clk_out5(clk2),     // output clk_out5
    // Status and control signals
    .reset(!rst_n), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk100m)
);      // input clk_in1


// (* DONT_TOUCH = "true" *)wire [31:0] axi_rdata_next_r;
// reg [31:0] axi_rdata_next_r_1;
// always @(posedge clk1) begin
//     if(!rst_n)
//         axi_rdata_next_r_1 <= 'd0;
//     else
//         axi_rdata_next_r_1 <= axi_rdata_next_r;
// end
// ila_1 ila_1_inst (
// 	.clk(clk1), // input wire clk


// 	.probe0(axi_rdata_next_r_1[16:8]) // input wire [8:0] probe0
// );






// wire [DQS_BITS-1 : 0] ddr2_dqs_in;


// reg [9:0]axi_addr;
// always @(posedge clk1) begin
//     if(!rst_n)
//         axi_addr <= 'd0;
//     else
//         axi_addr <= axi_araddr[9:0];
// end

// ila_0 your_instance_name (
// 	// .clk(clk2), // input wire clk
// 	.clk(clk1), // input wire clk


// 	// .probe0(state), // input wire [4:0]  probe0  
// 	.probe0(16'd0), // input wire [15:0]  probe0  
// 	.probe1(axi_addr), // input wire [9:0]  probe1
//     .probe2(rd_error)
//     // .probe3({2'b00})
// );



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
    .clk0_n                     (clk0_n),
    .clk1                       (clk1),
    .clk1_n                     (clk1_n),
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

