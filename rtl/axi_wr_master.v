/*
 *******************************************************************************
 *  Filename    :   axi_wr_master.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *
 *******************************************************************************
 */
module axi_wr_master #(
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

    input   wire                        wr_trig,
    input   wire                [7:0]   wr_len,
    input   wire     [DATA_WIDTH-1:0]   wr_data,
    output  wire                       wr_data_en,
    input   wire     [ADDR_WIDTH-1:0]   wr_addr,
    output  wire                        wr_ready,
    output  wire                        wr_done,

    //AXI总线
    // output  wire                [3:0]   axi_awid, 
    output  reg                         axi_awvalid,
    input   wire                        axi_awready,
    output  reg      [ADDR_WIDTH-1:0]   axi_awaddr,
    output  reg      [           7:0]   axi_awlen,
    // output  wire     [           1:0]   axi_awsize,
    output  reg                         axi_wvalid,
    input   wire                        axi_wready,
    output  wire                        axi_wlast,
    output  wire     [DATA_WIDTH-1:0]   axi_wdata,
    input   wire                        axi_bvalid,
    output  wire                        axi_bready


);


reg     [2:0]   state_w;
reg     [7:0]   wr_data_cnt;
//state_w
parameter   IDLE    = 3'b000;
parameter   START   = 3'b001;
parameter   AW      = 3'b011;
parameter   W       = 3'b010;   
parameter   B       = 3'b110;
parameter   DONE    = 3'b100;

assign wr_ready = state_w == IDLE ? 1'b1 : 1'b0;
assign wr_done = state_w == DONE ? 1'b1 : 1'b0;
// assign wr_data_en = axi_wvalid && axi_wready;

//暂时只有一个主机
// assign axi_awid = 4'b1111;

//当前总线数据宽度16位,两个字节
// assign axi_awsize = 2'b01;
//默认地址递增
//assign awburst = 2'b01;
assign axi_wdata = wr_data;
assign axi_wlast = wr_data_cnt == 'd0 ? 1'b1 : 1'b0;
assign axi_bready = state_w == B ? 1'b1 : 1'b0;


always @(posedge clk) begin
    if(!rst_n) begin
        state_w <= IDLE;
        axi_awvalid <= 1'b0;
        axi_wvalid <= 1'b0;
        axi_awaddr <= 'd0;
        axi_awlen <= 'd0;
    end else begin
        case(state_w) 
            IDLE:begin
                if(wr_trig) begin
                    // state_w <= AW;
                    state_w <= START;
                    axi_awvalid <= 1'b1;
                    axi_awaddr <= wr_addr;
                    wr_data_cnt <= 'd1;
                    axi_awlen <= wr_len;
                end
            end
            START:
                state_w <= AW;
            AW:begin
                if(axi_awready) begin
                    state_w <= W;
                    axi_awvalid <= 1'b0;
                    axi_wvalid <= 1'b1;                    
                    wr_data_cnt <= wr_len - 'd1;
                end
            end

            W:begin
                if(axi_wready) begin
                    if(wr_data_cnt == 8'd0) begin
                        state_w <= B;
                        axi_wvalid <= 1'b0;
                    end else
                        wr_data_cnt <= wr_data_cnt - 'd1;
                end
            end
            B:begin
                if(axi_bvalid) 
                    state_w <= DONE;
            end

            DONE:
                state_w <= IDLE;
            default:
                state_w <= IDLE;
        endcase
    end

end

reg [7:0]pre_cnt;
reg wr_data_en_reg;
always @(posedge clk) begin
    if(!rst_n) begin
        pre_cnt <= 'd0;
        wr_data_en_reg <= 1'b0;
    end 
    else  begin
        if(state_w == START && axi_awready == 1'b1) begin
            pre_cnt <= wr_len - 'd1;
            wr_data_en_reg <= 1'b1;
        end 
        else if(pre_cnt > 'd0) 
            pre_cnt <= pre_cnt - 'd1;
        else 
            wr_data_en_reg <= 1'b0;
    end
end
assign wr_data_en = wr_data_en_reg;
// assign wr_data_en = axi_wready & axi_wvalid;


endmodule
