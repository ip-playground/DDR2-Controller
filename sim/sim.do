vlib work

vlog "./tb.v"
vlog "./ddr2.v"
vlog "../rtl/*.v"

vsim -voptargs=+acc work.tb

view wave
view structure
view signals

add wave -divider {ddr2_top}
add wave tb/ddr2_top_inst/*


run 300900ns