quit -sim

if {[file exists work]} { vdel -lib work -all }

vlib work

vlog -sv {*}[glob C:/Users/admin/Desktop/rv32i_soc_project/rv32i_soc/rv32i_soc.srcs/sim_1/new/*.sv] {*}[glob C:/Users/admin/Desktop/rv32i_soc_project/rv32i_soc/rv32i_soc.srcs/sources_1/new/*.sv]

vsim -voptargs=+acc work.tb_phase1

do wave.do

run 500ns

wave zoom full