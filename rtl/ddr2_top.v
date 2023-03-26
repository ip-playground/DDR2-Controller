`include "rtl/define.v"
module ddr2_top(
    input                       ck,
    input                       rst_n,
    output      wire            ddr2_ck,
    output      wire            ddr2_ck_n,
    output      wire            ddr2_cke,
    output      wire            ddr2_cs_n,
    output      wire            ddr2_we_n,
    output      wire            ddr2_ras_n,
    output      wire            ddr2_cas_n,
    output      wire    [`BA_BITS-1:0]   ddr2_ba,
    output      wire    [`ADDR_BITS-1:0]  ddr2_addr
    // inout           [15:0]  ddr2_dq,
    // inout           [1:0]   ddr2_dqs,
    // inout           [1:0]   ddr2_dqs_n,
    // output                  ddr2_odt,   
);

//init
wire                init_end;
wire        [`BA_BITS-1:0]   init_ba;
wire        [`ADDR_BITS-1:0]  init_addr;
wire        [3:0]   init_cmd;
wire                init_cke;


assign  ddr2_ck = ck;
assign  ddr2_ck_n = ~ck;



assign  ddr2_cke = init_cke;

assign  {ddr2_cs_n,ddr2_ras_n,ddr2_cas_n,ddr2_we_n} = init_cmd;
assign  ddr2_ba = init_ba;
assign  ddr2_addr = init_addr;

ddr2_init ddr2_init_inst(
    .ck                         (ck),
    .rst_n                      (rst_n),
    .init_cke                   (init_cke),
    .init_ba                    (init_ba),
    .init_cmd                   (init_cmd),
    .init_addr                  (init_addr),
    .init_end                   (init_end)
);


endmodule
