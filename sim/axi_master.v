    /*
 *******************************************************************************
 *  Filename    :   axi_master.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *
 *******************************************************************************
 */
`include "../rtl/define.v" 

module axi_master #(
    parameter           ADDR_WIDTH  = `ROW_BITS + `COL_BITS + `BA_BITS,
    parameter           DATA_WIDTH  = `DQ_BITS * 2,
    parameter           DATA_LEVEL  = 2,
    parameter   [7:0]   WBURST_LEN   = 8'd7,
    parameter   [7:0]   RBURST_LEN   = 8'd7 
)(
    input   wire                        rstn,
    input   wire                        clk,
    input   wire                        w_trig,
    output  wire                        awvalid,
    input   wire                        awready,
    output  reg     [ADDR_WIDTH-1:0]    awaddr,
    output  wire    [           7:0]    awlen,
    output  wire                        wvalid,
    input   wire                        wready,
    output  wire                        wlast,
    output  reg     [DATA_WIDTH-1:0]    wdata,
    input   wire                        bvalid,
    output  wire                        bready

);


//state
parameter   INIT    = 3'b000;
parameter   AW      = 3'b001;
parameter   W       = 3'b010;   
parameter   B       = 3'b011;
reg     [2:0]   state;

//initial  awaddr = 'd0;

reg     [3:0]   w_cnt;

assign awvalid = state == AW;
assign awlen   = WBURST_LEN;
assign wlast   = w_cnt == awlen;
assign wvalid  = state == W;
assign bready  = 1'b1;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
       awaddr <= 'd0;
       w_cnt <= 'd0;
       state <= INIT;
    end else begin
        case(state)
            INIT:begin
                if(w_trig)
                    state <= AW;
            end
            AW:  if(awready)begin
                   state <= W;
                   w_cnt <= 8'd0;
            end
            W:begin
                if(wlast)
                  state <= B;
                if(wready) begin
                  w_cnt <= w_cnt + 1;
                  wdata <= w_cnt;
                end
            end
            B:begin
              if (bvalid) 
                state <= AW;
            end
        endcase

    end
end


endmodule
