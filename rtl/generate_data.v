`timescale 1ns / 1ps
/*
 *******************************************************************************
 *  Filename    :   generate_data.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 *
 *  Version     :   1.0.0
 *
 *  Created     :   5/23/2023
 *
 *******************************************************************************
 */


module generate_data #(
    parameter           DATA_WIDTH  = 32,
    parameter           MEM_SIZE    = 4096
)
(
    input   wire                        sys_clk,
    input   wire                        sys_rst_n,
    input   wire                        init_end,
    output  reg                         wr_en,
    output  reg    [DATA_WIDTH-1:0]     wr_data,
    // output  reg                         rd_start,
    output  reg                         rd_en,
    input   wire   [DATA_WIDTH-1:0]     rd_data

    // input   wire                        rd_data_ready
);

// parameter CNT_WIDTH = $clog2(MEM_SIZE);
// reg [CNT_WIDTH:0] wr_cnt;
reg                 wr_over;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)  begin
        rd_en <= 1'b0;
        // rd_start <= 1'b0;
    end
    else if(wr_over == 1'b1 ) begin
        rd_en <= 1'b1;
        // rd_start <= 1'b1;
    end
    else 
        rd_en <= 1'b0;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n ) begin
        wr_en <= 1'b0;
        wr_data <= 'd0;
        wr_over <= 1'b0;
    end else if(init_end)begin
        if(wr_data <= MEM_SIZE) begin
            wr_en <= 1'b1;
            wr_data <= wr_data + 'd1;
            // wr_data <= wr_data + 'd1; 
        end else begin
            wr_en <= 1'b0;
            wr_over <= 1'b1;
            // wr_cnt <= wr_cnt + 'd1;
        end
    end
end

endmodule
