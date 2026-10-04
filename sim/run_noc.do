quit -sim
vlib work
vlog -sv *.sv
vsim -voptargs=+acc work.tb_phase1
add wave -divider {NoC Signals}
add wave -radix hex /tb_phase1/noc_tx_flit /tb_phase1/noc_tx_valid /tb_phase1/noc_tx_ready
run 5us
wave zoom full