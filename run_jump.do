quit -sim
vlib work
vlog -sv *.sv
vsim -voptargs=+acc work.tb_phase1
add wave -radix hex /tb_phase1/uut/core_inst/pc
run 500ns
wave zoom full