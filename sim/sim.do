vlib work

vlog "./tb.v"
vlog "./ddr2.v"
vlog "../rtl/*.v"

vsim -voptargs=+acc work.tb

view wave
view structure
view signals

add wave -divider {ddr2_ctrl}
add wave tb/ddr2_ctrl_inst/*


run 310000ns