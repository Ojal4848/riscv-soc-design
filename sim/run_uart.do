quit -sim
vlib work
vlog -sv *.sv
vsim -voptargs=+acc work.tb_phase1
add wave -divider {UART Signals}
add wave -radix hex /tb_phase1/uut/uart_inst/*
add wave /tb_phase1/uart_tx
run 10us
wave zoom full