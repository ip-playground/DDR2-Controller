/*
 *******************************************************************************
 *  Filename    :   ddr2_init.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *  Created     :   3/20/2023
 *
 *******************************************************************************
 */
`include "/home/caoshiyang/ddr2/DDR2-Controller/rtl/define.v"
module ddr2_init(
    input                               ck,
    input                               rst_n,
    output  reg                         init_cke,
    output  reg     [`BA_BITS-1:0]      init_ba,
    output  reg     [3:0]               init_cmd,
    output  reg     [`ADDR_BITS-1:0]    init_addr,
    output  wire                        init_end
);

//=============================================================================\
// ****************** Define Parameter and Internal Signals *****************
//=============================================================================\
localparam          DELAY_300US =   `INIT_DELAY_300US/`tCK;
localparam          DELAY_500NS =   `INIT_DELAY_500NS/`tCK;
localparam          NOP         =   4'b0111;
localparam          PRE         =   4'b0010;
localparam          AREF        =   4'b0001;
localparam          LM          =   4'b0000;

//以下为init在等待500ns之后的操作
localparam          PRE1        =   0;
localparam          LM1         =   PRE1 + `tRPA/`tCK;
localparam          LM2         =   LM1 + `tMRD;
localparam          LM3         =   LM2 + `tMRD;
localparam          LM4         =   LM3 + `tMRD;
localparam          PRE2        =   LM4 + `tMRD;
localparam          AREF1       =   PRE2 + `tRPA/`tCK;
localparam          AREF2       =   AREF1 + `tRFC/`tCK;
localparam          LM5         =   AREF2 + `tRFC/`tCK;
localparam          LM6         =   LM5 + `tMRD;
localparam          LM7         =   LM6 + `tMRD;
localparam          PRE3        =   LM7 + `tMRD;


integer             cnt_300us;
integer             cnt_500ns;
integer             cnt_cmd;
wire                flag_end_300us; 
wire                flag_end_500ns;
reg                 init_cke_p;

always @(posedge ck or negedge rst_n) begin
    if(!rst_n)
        cnt_300us <= 0;
    else if(flag_end_300us == 1'b0)
        cnt_300us <= cnt_300us + 1;
    
end
assign flag_end_300us = cnt_300us >= DELAY_300US ? 1'b1 : 1'b0;


//cke这块暂时不知道后续怎么处理，此处仅是对于镁光手册的波形实现
always @(posedge ck or negedge rst_n) begin
    if(!rst_n) begin
        init_cke <= 1'b0;
        init_cke_p <= 1'b0;
    end
    else if(flag_end_300us) begin
        init_cke_p <= 1'b1;
        init_cke <= init_cke_p;

    end
end


//需要在前面300us过后，也即等待时钟稳定后
always @(posedge ck or negedge rst_n) begin
    if(!rst_n)
        cnt_500ns <= 0;
    else if(flag_end_300us == 1'b1 && flag_end_500ns == 1'b0)
        cnt_500ns <= cnt_500ns + 1;
end

assign  flag_end_500ns = cnt_500ns >= DELAY_500NS ? 1'b1 : 1'b0;

always @(posedge ck or negedge rst_n) begin
    if(!rst_n)
        cnt_cmd <= 1'b0;
    else if(flag_end_500ns == 1'b1 && init_end == 1'b0)
        cnt_cmd <= cnt_cmd + 1;
end

always @(posedge ck or negedge rst_n) begin
    if(!rst_n) begin
        init_cmd <= NOP;
        init_addr <= 0;
        init_ba <= 0;
    end
    else if(flag_end_500ns) begin
        case(cnt_cmd)
            PRE1:   begin init_cmd <= PRE;  init_addr <= `ADDR_BITS'b00_0100_0000_0000;     end
            LM1:    begin init_cmd <= LM;   init_addr <= `ADDR_BITS'b00_0000_0000_0000; init_ba <= 3'b010;   end
            LM2:    begin init_cmd <= LM;   init_addr <= `ADDR_BITS'b00_0000_0000_0000; init_ba <= 3'b011;   end
            LM3:    begin init_cmd <= LM;   init_addr <= `ADDR_BITS'b00_0000_0000_0000; init_ba <= 3'b001;   end
            LM4:    begin init_cmd <= LM;   init_addr <= `ADDR_BITS'b00_1011_0110_0010; init_ba <= 3'b000;   end
            PRE2:   begin init_cmd <= PRE;  init_addr <= `ADDR_BITS'b00_0100_0000_0000;     end
            AREF1:   begin init_cmd <= AREF;  end
            AREF2:   begin init_cmd <= AREF;  end
            //MR默认设置：WR=3,CL=3,突发：顺序，长度4 ;
            LM5:    begin init_cmd <= LM;   init_addr <= `ADDR_BITS'b00_0100_0011_0010; init_ba <= 3'b000;   end
            LM6:    begin init_cmd <= LM;   init_addr <= `ADDR_BITS'b00_0011_1000_0000; init_ba <= 3'b001;   end
            // EMR1 暂时这么设置，AL = 2(POST CAS)  
            LM7:    begin init_cmd <= LM;   init_addr <= `ADDR_BITS'b00_0000_0001_0000; init_ba <= 3'b001;   end
            PRE3:   begin init_cmd <= PRE;  init_addr <= `ADDR_BITS'b00_0100_0000_0000;     end
            default: init_cmd <= NOP;
        endcase
    end
end

assign init_end = cnt_cmd > PRE3+1 ? 1'b1 : 1'b0;

endmodule
