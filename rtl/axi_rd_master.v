/*
 *******************************************************************************
 *  Filename    :   axi_rd_master.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *
 *******************************************************************************
 */
module axi_rd_master #(
    parameter           ADDR_WIDTH  = 26,
    parameter           DATA_WIDTH  = 32,
    parameter           DATA_LEVEL  = 2,
    parameter           COL_BITS    = 10, // Number of Column bits
    parameter   [7:0]   WBURST_LEN  = 8'd8,
    parameter   [7:0]   RBURST_LEN  = 8'd8 
)(
    input   wire                        rst_n,
    input   wire                        clk,
    input   wire                        init_end,
    output  wire                        rd_error,

    input   wire                        rd_trig,
    input   wire                [7:0]   rd_len,
    output  wire     [DATA_WIDTH-1:0]   rd_data,
    output  wire                        rd_data_en,
    input   wire     [ADDR_WIDTH-1:0]   rd_addr,
    output  wire                        rd_ready,
    output  wire                        rd_done,

    //AXI总线
    // output  wire                [3:0]   axi_arid, 
    output  reg                         axi_arvalid,
    input   wire                        axi_arready,
    output  reg     [ADDR_WIDTH-1:0]   axi_araddr,
    output  reg      [           7:0]   axi_arlen,
    // output  wire     [           1:0]   axi_arsize,
    input   wire                        axi_rvalid,
    output  reg                         axi_rready,
    input   wire                        axi_rlast,
    input   wire     [DATA_WIDTH-1:0]   axi_rdata
    // output  reg                         led


);


reg     [2:0]   state_r;
reg     [7:0]   rd_data_cnt;
//state_r
parameter   IDLE    = 3'b000;
parameter   START    = 3'b001;
parameter   ARD      = 3'b011;
parameter   RD       = 3'b010;   
parameter   B       = 3'b110;
parameter   DONE    = 3'b100;

assign rd_ready = state_r == IDLE ? 1'b1 : 1'b0;
assign rd_done = state_r == DONE ? 1'b1 : 1'b0;
reg [7:0]   r_cnt;


//暂时只有一个主机
// assign axi_arid = 4'b1111;

// assign axi_arlen = rd_len;
//当前总线数据宽度16位,两个字节
// assign axi_arsize = 2'b01;
//默认地址递增
//assign arburst = 2'b01;


always @(posedge clk) begin
    if(!rst_n) begin
        state_r <= IDLE;
        axi_arvalid <= 1'b0;
        axi_arlen <= 'd0;
        axi_araddr <= 'd0;
    end else begin
        case(state_r) 
            IDLE:begin
                if(rd_trig) begin
                    state_r <= START;
                    axi_arvalid <= 1'b1;
                    axi_araddr <= rd_addr;
                    axi_arlen <= rd_len;
                end
            end
            START:begin
                state_r <= ARD;
            end
            ARD:begin
                if(axi_arready) begin
                    // axi_arlen <= rd_len;
                    state_r <= RD;
                    axi_arvalid <= 1'b0;
                    axi_rready <= 1'b1;
                    rd_data_cnt <= rd_len - 1;
                    r_cnt <= 'd0;
                end
            end
            RD:begin
                if(axi_rvalid) begin
                    if(rd_data_cnt == 8'd0) begin
                        axi_rready <= 1'b0;
                        state_r <= DONE;
                    end else begin
                        rd_data_cnt <= rd_data_cnt - 'd1;
                        r_cnt <= r_cnt + 'd1;
                    end
                end
            end
            DONE:
                state_r <= IDLE;
            default:
                state_r <= IDLE;
        endcase
    end
end


reg     [DATA_WIDTH-1:0]   diff_data_1;
reg     [DATA_WIDTH-1:0]   diff_data_2;
reg     [DATA_WIDTH-1:0]   diff_data_3;
reg                         rd_error_reg;
assign rd_error = rd_error_reg;

reg axi_rvalid_1;
reg axi_rvalid_2;
reg     [DATA_WIDTH-1:0]    axi_rdata_1;
reg     [DATA_WIDTH-1:0]   axi_rdata_2;
always @(posedge clk) begin
    if(!rst_n) begin
        axi_rvalid_1 <= 1'b0;
        axi_rvalid_2 <= 1'b0;
        axi_rdata_1 <= 'd0;
        axi_rdata_2 <= 'd0;
    end
    else begin
        axi_rvalid_1 <= axi_rvalid; 
        axi_rvalid_2 <= axi_rvalid_1;
        axi_rdata_1 <= axi_rdata;
        axi_rdata_2 <= axi_rdata_1;
    end
end


assign rd_data_en = axi_rvalid_1 ;
assign rd_data = axi_rdata_1;

// assign rd_data_en = axi_rvalid ;
// assign rd_data = axi_rdata;



always @(posedge clk) begin
    if(!rst_n) begin
        diff_data_1 <= 'd0;
    end
    // else if(axi_rvalid_1) begin
    else begin
        diff_data_1 <= (axi_araddr>>1) + r_cnt + 'd1;
    end 
    // else begin
    //     diff_data_1 <= 'd0;
    // end
end


always @(posedge clk) begin
    if(!rst_n) begin
        diff_data_2 <= 'd0;
    end
    else  begin
        diff_data_2 <= diff_data_1;
    end 
end


always @(posedge clk) begin
    if(!rst_n)
        rd_error_reg <= 1'b0;
    else if( axi_rvalid_2 == 1'b1 && diff_data_2 != axi_rdata_2 ) begin
    // else if( axi_rvalid_1 == 1'b1 && diff_data_1 != axi_rdata_1 ) begin
        rd_error_reg <= 1'b1;
    end
    // else 
    //     rd_error_reg <= 1'b0;
end


ila_rd your_instance_name (
	.clk(clk), // input wire clk

	.probe0(diff_data_1[15:0]), // input wire [15:0]  probe0  
	// .probe0(diff_data_2[15:0]), // input wire [15:0]  probe0  
	// .probe0(16'd0), // input wire [15:0]  probe0  
	.probe1(axi_rdata_1[15:0]), // input wire [15:0]  probe1 
	// .probe1(axi_rdata_2[15:0]), // input wire [15:0]  probe1 
	// .probe1(16'd0), // input wire [15:0]  probe1 
	.probe2(axi_rvalid_1) // input wire [0:0]  probe2
);



endmodule