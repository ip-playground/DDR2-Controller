`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/30 19:30:11
// Design Name: 
// Module Name: tb_top
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


module tb_top();

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

reg                        clk100m;
reg                        rst_n;

reg                         uart_rx;
wire                        uart_tx;

wire                         wr_over_led;
wire                         init_end_led;
wire                         rd_error_led;

wire                        ddr2_clk_p;
wire                        ddr2_clk_n;
wire                        ddr2_cke;
wire                        ddr2_cs_n;
wire                        ddr2_cas_n;
wire                        ddr2_ras_n;
wire                        ddr2_we_n;
wire       [BA_BITS-1:0]    ddr2_ba;
wire     [ADDR_BITS-1:0]    ddr2_addr;
wire       [DM_BITS-1:0]    ddr2_dqm;
wire       [DQ_BITS-1:0]    ddr2_dq;
wire      [DQS_BITS-1:0]    ddr2_dqs_p;
wire      [DQS_BITS-1:0]    ddr2_dqs_n;
wire                        ddr2_odt;

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

always #5000 clk100m = ~clk100m;

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

top_uart top_uart_inst (
.sys_clk                (clk100m),
.sys_rst_n              (rst_n),
.uart_rx                (uart_rx),
.uart_tx                (uart_tx),
.wr_over_led            (wr_over_led),
.init_end_led           (init_end_led),
.rd_error_led           (rd_error_led),
.ddr2_clk_p             (ddr2_clk_p),
.ddr2_clk_n             (ddr2_clk_n),
.ddr2_cke               (ddr2_cke),
.ddr2_cs_n              (ddr2_cs_n),
.ddr2_cas_n             (ddr2_cas_n),
.ddr2_ras_n             (ddr2_ras_n),
.ddr2_we_n              (ddr2_we_n),
.ddr2_ba                (ddr2_ba),
.ddr2_addr              (ddr2_addr),
.ddr2_dqm               (ddr2_dqm),
.ddr2_dq                (ddr2_dq),
.ddr2_dqs_p             (ddr2_dqs_p),
.ddr2_dqs_n             (ddr2_dqs_n),
.ddr2_odt               (ddr2_odt)
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
