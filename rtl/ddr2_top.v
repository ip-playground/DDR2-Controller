/*
 *******************************************************************************
 *  Filename    :   ddr2_init.v
 *
 *  Author      :   caosy      <1960552705@qq.com>
 * 
 *  Version     :   1.0.0
 *
 *  Created     :   3/22/2023
 *
 *******************************************************************************
 */
`include "define.v"
module ddr2_top(
    input                               ck,
    input                               rst_n,
    output  wire                        ddr2_ck,
    output  wire                        ddr2_ck_n,
    output  wire                        ddr2_cke,
    output  reg                        ddr2_cs_n,
    output  reg                        ddr2_we_n,
    output  reg                        ddr2_ras_n,
    output  reg                        ddr2_cas_n,
    output  reg    [`BA_BITS-1:0]      ddr2_ba,
    output  reg    [`ADDR_BITS-1:0]    ddr2_addr
    // inout           [15:0]  ddr2_dq,
    // inout           [1:0]   ddr2_dqs,
    // inout           [1:0]   ddr2_dqs_n,
    // output                  ddr2_odt,   
);

localparam  INIT            =       5'b0_0001;
localparam  IDLE            =       5'b0_0010;
localparam  AREF            =       5'b0_0100;
localparam  WRITE           =       5'b0_1000;
localparam  READ            =       5'b1_0000;


//arbit
reg         [4:0]               state;//暂时写为5位

//init
wire                            init_end;
wire        [`BA_BITS-1:0]      init_ba;
wire        [`ADDR_BITS-1:0]    init_addr;
wire        [3:0]               init_cmd;
wire                            init_cke;

//aref
wire                            aref_req;
reg                             aref_en;
wire        [`ADDR_BITS-1:0]    aref_addr;
wire        [3:0]               aref_cmd;
wire                            aref_end;



//arbit
always @(posedge ck or negedge rst_n) begin
    if(!rst_n)
        state <= INIT;
    else begin
        case (state) 
            INIT:   begin
                if(init_end)
                    state <= IDLE;
                else
                    state <= INIT;
            end
            IDLE:   begin
                if(aref_en)
                    state <= AREF;
                else
                    state <= IDLE;
            end
            AREF:   begin
                if(aref_end)
                    state <= IDLE;
                else
                    state <= AREF;
            end
            default:state <= INIT;
        endcase 
    end
end

// reg [12:0] addr;
// reg [3:0]   cmd;
// reg [2:0]   ba;

// always @(*) begin
//     if (addr != ddr2_addr)
//         $display("?????");
// end



always @(posedge ck) begin
    case(state)
        INIT:   begin
            {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} <= init_cmd;
            ddr2_ba <= init_ba;
            ddr2_addr <= init_addr;
        end
        AREF:   begin
            {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} <= aref_cmd;
            // ddr2_ba = aref_ba;
            ddr2_addr <= aref_addr;
        end
        default:   begin
            {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} <= init_cmd;
            ddr2_ba <= init_ba;
            ddr2_addr <= init_addr;
        end
    endcase
end


// assign {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} = state == AREF ? aref_cmd : init_cmd;
// assign ddr2_ba = init_ba;
// assign ddr2_addr = state == AREF ? aref_addr : init_addr;



always @(posedge ck or negedge rst_n) begin
    if(!rst_n)
        aref_en <= 'd0;
    else if(state == IDLE && aref_req == 1'b1)
        aref_en <= 'd1;
    else
        aref_en <= 'd0;
end

assign  ddr2_ck = ck;
assign  ddr2_ck_n = ~ck;
assign  ddr2_cke = init_cke;


ddr2_init ddr2_init_inst(
    .ck                         (ck),
    .rst_n                      (rst_n),
    .init_cke                   (init_cke),
    .init_ba                    (init_ba),
    .init_cmd                   (init_cmd),
    .init_addr                  (init_addr),
    .init_end                   (init_end)
);

ddr2_ref ddr2_ref_inst(
    .ck                         (ck),
    .rst_n                      (rst_n),
    .init_end                   (init_end),
    .aref_req                   (aref_req),
    .aref_en                    (aref_en),
    // .aref_ba                    (aref_ba),
    .aref_cmd                   (aref_cmd),
    .aref_addr                  (aref_addr),
    .aref_end                   (aref_end)
);


endmodule
