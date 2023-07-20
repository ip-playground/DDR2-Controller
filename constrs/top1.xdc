create_clock -period 10.000 [get_ports sys_clk]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports uart_tx]


set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports init_end_led]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports wr_over_led]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports rd_error_led]

set_property INTERNAL_VREF 0.9 [get_iobanks 34]

set_property -dict {PACKAGE_PIN R7 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[0]}]
set_property -dict {PACKAGE_PIN V6 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[1]}]
set_property -dict {PACKAGE_PIN R8 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[2]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[3]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[4]}]
set_property -dict {PACKAGE_PIN R6 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[5]}]
set_property -dict {PACKAGE_PIN U6 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[6]}]
set_property -dict {PACKAGE_PIN R5 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[7]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[8]}]
set_property -dict {PACKAGE_PIN U3 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[9]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[10]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[11]}]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[12]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[13]}]
set_property -dict {PACKAGE_PIN V1 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[14]}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD SSTL18_II} [get_ports {ddr2_dq[15]}]

set_property -dict {PACKAGE_PIN T6 IOSTANDARD SSTL18_II} [get_ports {ddr2_dqm[0]}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD SSTL18_II} [get_ports {ddr2_dqm[1]}]


set_property -dict {PACKAGE_PIN U9 IOSTANDARD DIFF_SSTL18_II} [get_ports {ddr2_dqs_p[0]}]
set_property -dict {PACKAGE_PIN V9 IOSTANDARD DIFF_SSTL18_II} [get_ports {ddr2_dqs_n[0]}]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD DIFF_SSTL18_II} [get_ports {ddr2_dqs_p[1]}]
set_property -dict {PACKAGE_PIN V2 IOSTANDARD DIFF_SSTL18_II} [get_ports {ddr2_dqs_n[1]}]

# set_property -dict {PACKAGE_PIN K3 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[13]}]
set_property -dict {PACKAGE_PIN N6 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[12]}]
set_property -dict {PACKAGE_PIN K5 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[11]}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[10]}]
set_property -dict {PACKAGE_PIN N5 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[9]}]
set_property -dict {PACKAGE_PIN L4 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[8]}]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[7]}]
set_property -dict {PACKAGE_PIN M2 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[6]}]
set_property -dict {PACKAGE_PIN P5 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[5]}]
set_property -dict {PACKAGE_PIN L3 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[4]}]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[3]}]
set_property -dict {PACKAGE_PIN M6 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[2]}]
set_property -dict {PACKAGE_PIN P4 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[1]}]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD SSTL18_II} [get_ports {ddr2_addr[0]}]


set_property -dict {PACKAGE_PIN R1 IOSTANDARD SSTL18_II} [get_ports {ddr2_ba[2]}]
set_property -dict {PACKAGE_PIN P3 IOSTANDARD SSTL18_II} [get_ports {ddr2_ba[1]}]
set_property -dict {PACKAGE_PIN P2 IOSTANDARD SSTL18_II} [get_ports {ddr2_ba[0]}]

set_property -dict {PACKAGE_PIN L6 IOSTANDARD DIFF_SSTL18_II} [get_ports ddr2_clk_p]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD DIFF_SSTL18_II} [get_ports ddr2_clk_n]

set_property -dict {PACKAGE_PIN N4 IOSTANDARD SSTL18_II} [get_ports ddr2_ras_n]
set_property -dict {PACKAGE_PIN L1 IOSTANDARD SSTL18_II} [get_ports ddr2_cas_n]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD SSTL18_II} [get_ports ddr2_we_n]
set_property -dict {PACKAGE_PIN K6 IOSTANDARD SSTL18_II} [get_ports ddr2_cs_n]

set_property -dict {PACKAGE_PIN M1 IOSTANDARD SSTL18_II} [get_ports ddr2_cke]
set_property -dict {PACKAGE_PIN M3 IOSTANDARD SSTL18_II} [get_ports ddr2_odt]


# create_generated_clock -name clk_p -source [get_pins {ddr2_ctrl_inst/ODDR_inst/C}] -divide_by 1  [get_ports ddr2_clk_p]
# create_generated_clock -name clk_p -source [get_pins {ddr2_ctrl/ODDR_inst/C}] -divide_by 1  [get_ports ddr2_clk_p]


# set fwclk        clk_p;     # forwarded clock name (generated using create_generated_clock at output clock port)        
# set tsu_r        1.000;            # destination device setup time requirement for rising edge
# set thd_r        0.000;            # destination device hold time requirement for rising edge
# set tsu_f        0.000;            # destination device setup time requirement for falling edge
# set thd_f        1.000;            # destination device hold time requirement for falling edge
# set trce_dly_max 0.100;            # maximum board trace delay
# set trce_dly_min 0.100;            # minimum board trace delay
# set output_ports_dqs  {ddr2_dqs_p ddr2_dqs_n};   # list of output ports

# # Output Delay Constraints
# set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_r] [get_ports $output_ports_dqs];
# set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_r] [get_ports $output_ports_dqs];
# set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_f] [get_ports $output_ports_dqs] -clock_fall -add_delay;
# set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_f] [get_ports $output_ports_dqs] -clock_fall -add_delay;



# create_generated_clock -name ddr2_dqs_0 -source [get_pins {ddr2_ctrl_inst/OBUFDS_inst_dqs/I}] -divide_by 1  [get_ports ddr2_dqs_p[0]]

# # set fwclk        clk_p;     # forwarded clock name (generated using create_generated_clock at output clock port)        
# set fwclk        ddr2_dqs_0;     # forwarded clock name (generated using create_generated_clock at output clock port)        
# set tsu_r        0.050;            # destination device setup time requirement for rising edge
# set thd_r        0.150;            # destination device hold time requirement for rising edge
# set tsu_f        0.050;            # destination device setup time requirement for falling edge
# set thd_f        0.150;            # destination device hold time requirement for falling edge
# set trce_dly_max 0.100;            # maximum board trace delay
# set trce_dly_min 0.100;            # minimum board trace delay
# set dq_dqm  {
#     ddr2_dq[0] 
#     ddr2_dq[1]
#     ddr2_dq[2]
#     ddr2_dq[3]
#     ddr2_dq[4]
#     ddr2_dq[5]
#     ddr2_dq[6]    
#     ddr2_dq[7]
#     ddr2_dqm[0]    

# };   # list of output ports

# # Output Delay Constraints


# set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_r] [get_ports $dq_dqm];
# set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_r] [get_ports $dq_dqm];
# set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu_f] [get_ports $dq_dqm] -clock_fall -add_delay;
# set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd_f] [get_ports $dq_dqm] -clock_fall -add_delay;

