quit -sim
vlib work
vlog -sv *.sv
vsim -voptargs=+acc work.tb_phase1
add wave -divider {AHB/AXI Signals}
add wave -radix hex /tb_phase1/uut/bridge_inst/*
run 2us
wave zoom full