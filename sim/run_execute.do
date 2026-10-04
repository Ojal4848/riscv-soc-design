quit -sim
vlib work
vlog -sv *.sv
vsim -voptargs=+acc work.tb_phase1
add wave -radix hex /tb_phase1/uut/core_inst/alu_inst/*
run 200ns
wave zoom full