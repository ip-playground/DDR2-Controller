`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/28 15:41:55
// Design Name: 
// Module Name: command_parser
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


module command_parser (
    input wire clk,
    input wire reset_n,
    input wire [7:0] data_in,
    input wire valid_in,
    output reg [25:0] address,
    output reg [7:0] data,
    output reg data_valid,
    output reg read_cmd,
    output reg write_cmd
);

reg [4:0] byte_counter;
reg [1:0] cmd_type;
reg [6:0] data_counter;

reg [1:0] state;
parameter IDLE = 2'b00, ADDRESS = 2'b01, DATA = 2'b10, LAST = 2'b11;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= IDLE; 
        byte_counter <= 0;
        cmd_type <= 2'b00;
        read_cmd <= 0;
        write_cmd <= 0;
        data_valid <= 0;
    end else begin
        case (state)
            IDLE: begin
                read_cmd <= 1'b0;
                if (valid_in) begin
                    if (data_in != 8'hFF) begin
                        cmd_type <= data_in[1:0];
                        byte_counter <= 1;
                        state <= ADDRESS;
                    end
                end
            end
            ADDRESS: begin
                if(valid_in) begin
                    case (byte_counter)
                        1: address[7:0] <= data_in;
                        2: address[15:8] <= data_in;
                        3: address[23:16] <= data_in;
                        4: address[25:24] <= data_in[1:0];
                        // 4: address[31:24] <= data_in;
                    endcase
                    byte_counter <= byte_counter + 1;
                end
                else if(byte_counter == 'd5) begin
                    state <= DATA;
                    byte_counter <= 'd1;
                end
                
            end 
            DATA: begin
                if (valid_in) begin
                    if (data_in != 8'hFF) begin
                        data <= data_in;
                        data_valid <= 1;
                        if (cmd_type == 2'b01) write_cmd <= 1;
                    end else begin
                        state <= IDLE;
                    end
                    if (cmd_type == 2'b10) begin
                        read_cmd <= 1;
                    end
                end else begin
                    data_valid <= 0;
                    read_cmd <= 0;
                    write_cmd <= 0;
                end
            end
        endcase
    end
end

endmodule
