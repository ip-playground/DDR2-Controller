`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/28 20:20:20
// Design Name: 
// Module Name: tb_uart
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


// always #625 clk800m = ~clk800m;
always #5000 clk100m = ~clk100m;
wire    clk0;
wire    clk0_n;
wire    clk1;
wire    clk1_n;

wire init_end;

reg uart_rx;

reg [7:0] wr_mem_a[21:0];
reg [7:0] rd_mem_a[5:0];

initial begin
    wr_mem_a[0] = 8'h01;
    wr_mem_a[1] = 8'h00;
    wr_mem_a[2] = 8'h00;
    wr_mem_a[3] = 8'h00;
    wr_mem_a[4] = 8'h00;
    wr_mem_a[5] = 8'h11;
    wr_mem_a[6] = 8'h22;
    wr_mem_a[7] = 8'h33;
    wr_mem_a[8] = 8'h44;
    wr_mem_a[9] = 8'h55;
    wr_mem_a[10] = 8'h66;
    wr_mem_a[11] = 8'h77;
    wr_mem_a[12] = 8'h88;
    wr_mem_a[13] = 8'h99;
    wr_mem_a[14] = 8'haa;
    wr_mem_a[15] = 8'hbb;
    wr_mem_a[16] = 8'hcc;
    wr_mem_a[17] = 8'hdd;
    wr_mem_a[18] = 8'hee;
    wr_mem_a[19] = 8'h11;
    wr_mem_a[20] = 8'h22;
    wr_mem_a[21] = 8'hFF;
end

initial begin
    rd_mem_a[0] = 8'h02;
    rd_mem_a[1] = 8'h00;
    rd_mem_a[2] = 8'h00;
    rd_mem_a[3] = 8'h00;
    rd_mem_a[4] = 8'h00;
    rd_mem_a[5] = 8'hFF;
end

initial begin
    clk100m = 1;
    rst_n <= 0;
    uart_rx<= 1;
    #100000
    rst_n <= 1;
    #302000000
    rx_byte();
    #1000000
    rx_byte1();

end

task rx_byte();
    integer i;
    for(i=0;i<22;i=i+1)begin
        rx_bit(wr_mem_a[i]);
    end
endtask

task rx_byte1();
    integer i;
    for(i=0;i<6;i=i+1)begin
        rx_bit(rd_mem_a[i]);
    end
endtask

task rx_bit;
    input [7:0] data;
    
    integer i;
    for(i=0;i<10;i=i+1)
    begin
        case(i)
            0:uart_rx=1'b0;
            1:uart_rx=data[0];
            2:uart_rx=data[1];
            3:uart_rx=data[2];
            4:uart_rx=data[3];
            5:uart_rx=data[4];
            6:uart_rx=data[5];
            7:uart_rx=data[6];
            8:uart_rx=data[7];
            9:uart_rx=1'b1;
        endcase
        #560000;
    end
    
endtask



wire [7:0] uart_data;
wire uart_valid;
wire data_valid_out;
wire [7:0] data_out;
wire [25:0] address_out;
wire read_cmd_out;
wire write_cmd_out;
reg [7:0] data_in;
reg data_valid_in;

uart_rx uart_receiver (
    .clk(clk100m),
    .reset_n(rst_n),
    .rx(uart_rx),
    .data(uart_data),
    .valid(uart_valid)
);

uart_tx uart_sender (
    .clk(clk100m),
    .reset_n(rst_n),
    .tx_en(data_valid_in),
    .tx_data(data_in),
    .tx_out(uart_tx)
);

command_parser cmd_parser (
    .clk(clk100m),
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

reg [7:0] wr_data_array [15:0];
reg [3:0] wdata_cnt;
reg wr_collect_over;
reg wr_collect_over_next;
reg [3:0]   wr_collect_pipe;
reg wr_req;


always @(posedge clk100m) begin
    if(init_end == 1'b0) begin
        wdata_cnt <= 'd0;
    end
    else if(data_valid_out) begin
        wr_data_array[wdata_cnt] <= data_out;
        wdata_cnt <= wdata_cnt + 'd1;
    end
end

always @(posedge clk100m) begin
    if(init_end == 1'b0) 
        wr_collect_over <= 1'b0;
    else if(data_valid_out == 1'b1 && wdata_cnt == 'd15)
        wr_collect_over <= 1'b1;
    else 
        wr_collect_over <= 1'b0;
end

always @(posedge clk1) begin
    if(init_end == 1'b0)
        wr_collect_pipe <= 4'h0;
    else if(wr_trig)
        wr_collect_pipe <= 4'hf;
    else
        wr_collect_pipe <= {1'b0,wr_collect_pipe[3:1]};
end

always @(posedge clk1) begin
    if(init_end == 1'b0)
        wr_data <= 'd0;
    else if(wr_collect_pipe[0]) begin
        case(wr_collect_pipe)
            4'hf:wr_data <= {wr_data_array[2], wr_data_array[3], wr_data_array[0], wr_data_array[1]};
            4'h7:wr_data <= {wr_data_array[6], wr_data_array[7], wr_data_array[4], wr_data_array[5]};
            4'h3:wr_data <= {wr_data_array[10], wr_data_array[11], wr_data_array[8], wr_data_array[9]};
            4'h1:wr_data <= {wr_data_array[14], wr_data_array[15], wr_data_array[12], wr_data_array[13]};
        endcase
    end
end

always @(posedge clk1) begin
    if(init_end == 1'b0)
        wr_req <= 1'b0;
    else if(write_cmd_out & wr_collect_over & clk100m)
        wr_req <= 1'b1;
    else if(wr_req == 1'b1 && wr_trig == 1'b0)
        wr_req <= 1'b0;
end

always @(posedge clk1) begin
    if(init_end == 1'b0)
        wr_trig <= 1'b0;
    else if(wr_req == 1'b1 && wr_trig == 1'b0) 
        wr_trig <= 1'b1;
    else if(wr_ready == 1'b1 && wr_trig == 1'b1)
        wr_trig <= 1'b0;
end

always @(posedge clk1) begin
    if(init_end == 1'b0)
        wr_addr <= 'd0;
    else if(write_cmd_out & !clk100m)
        wr_addr <= address_out;
end

reg rd_req;
reg [7:0] rd_data_array [15:0];
reg [3:0] rd_collect_pipe;
reg rd_collect_over;
reg [4:0] rdata_cnt;
reg [13:0] rd_baud_cnt;
parameter BAUD_CNT_MAX  =   600;
reg work_en;

always @(posedge clk1) begin
    if(init_end == 1'b0)
        rd_req <= 1'b0;
    else if(read_cmd_out & clk100m)
        rd_req <= 1'b1;
    else if(rd_req == 1'b1 && rd_trig == 1'b0 )
        rd_req <= 1'b0;
end

always @(posedge clk1) begin
    if(init_end == 1'b0)
        rd_trig <= 1'b0;
    else if(rd_req == 1'b1 && rd_trig == 1'b0) 
        rd_trig <= 1'b1;
    else if(rd_ready == 1'b1 && rd_trig == 1'b1)
        rd_trig <= 1'b0;
end


always @(posedge clk1) begin
    if(init_end == 1'b0)
        rd_addr <= 'd0;
    else if(read_cmd_out & !clk100m)
        rd_addr <= address_out;
end

integer j;
always @(posedge clk1) begin
    if(init_end == 1'b0) begin
        rd_collect_pipe <= 'd0;
        for(j = 0; j < 16; j = j+1)
            rd_data_array[j] <= 'd0;
    end
    else if(rd_data_en & rd_collect_pipe[0]) begin
        case(rd_collect_pipe)
            4'hf:{rd_data_array[2], rd_data_array[3], rd_data_array[0], rd_data_array[1]} <= rd_data;
            4'h7:{rd_data_array[6], rd_data_array[7], rd_data_array[4], rd_data_array[5]} <= rd_data;
            4'h3:{rd_data_array[10], rd_data_array[11], rd_data_array[8], rd_data_array[9]}<= rd_data;
            4'h1:{rd_data_array[14], rd_data_array[15], rd_data_array[12],rd_data_array[13]}<= rd_data;
        endcase 
        rd_collect_pipe <= {1'b0,rd_collect_pipe[3:1]};
    end
    else if(rd_trig)
        rd_collect_pipe <= 4'hf;
end

always @(posedge clk1) begin
    if(init_end == 1'b0)
        rd_collect_over <= 1'b0;
    else if(rd_collect_pipe[0] & !rd_collect_pipe[2])
        rd_collect_over <=1'b1 ;
    else
        rd_collect_over <=1'b0;
end


always@(posedge clk100m )
    if(init_end == 1'b0)
        work_en <= 1'b0;
    else  if(rd_collect_over == 1'b1)
        work_en <= 1'b1;
    else    if((rdata_cnt == 4'd0) )
        work_en <= 1'b0;

always @(posedge clk100m) begin
    if(init_end == 1'b0)
        rd_baud_cnt <= 14'd0;
    else    if((work_en == 1'b0) || (rd_baud_cnt == BAUD_CNT_MAX - 1))
        rd_baud_cnt <= 14'd0;
    else    if(work_en == 1'b1)
        rd_baud_cnt <= rd_baud_cnt + 1'b1;
end

always @(posedge clk100m) begin
    if(init_end == 1'b0) begin;
        data_in <= 'd0;
        data_valid_in <= 1'b0;
    end
    else if(rdata_cnt > 0)begin
         if(rd_baud_cnt == 'd1)begin
            data_valid_in <= 1'b1;
            data_in <= rd_data_array[16-rdata_cnt];
        end else 
            data_valid_in <= 1'b0;
    end
end    


always @(posedge clk100m) begin
    if(init_end == 1'b0)
        rdata_cnt <= 'd0;
    else if(rd_collect_over)
        rdata_cnt <= 'd16; 
    else if(rd_baud_cnt == BAUD_CNT_MAX - 1)
        rdata_cnt <= rdata_cnt - 'd1;
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
