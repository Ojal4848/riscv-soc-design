quit -sim
vlib work
vlog -sv *.sv
vsim -voptargs=+acc work.tb_phase1
add wave -divider {I2C Serial Bus}
add wave -radix hex /tb_phase1/uut/i2c_inst/*
run 200ns
wave zoom full