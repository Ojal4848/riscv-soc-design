onerror {resume}
quietly WaveActivateNextPane {} 0

# -----------------------------------------------------------------------------
# 1. System Clocks & Reset
# -----------------------------------------------------------------------------
add wave -noupdate -divider {System Clocks & Reset}
add wave -noupdate -label {Clock}           /tb_phase1/clk
add wave -noupdate -label {Reset (Active L)} /tb_phase1/rst_n

# -----------------------------------------------------------------------------
# 2. CPU Core & Execution State
# -----------------------------------------------------------------------------
add wave -noupdate -divider {CPU Core & Execution State}
add wave -noupdate -radix hexadecimal -label {Program Counter (PC)} /tb_phase1/uut/core_inst/pc
add wave -noupdate -radix hexadecimal -label {Fetched Instruction} /tb_phase1/uut/core_inst/if_id_instr
add wave -noupdate -radix hexadecimal -label {ALU Result}         /tb_phase1/uut/core_inst/alu_result
add wave -noupdate -label {Register File WE}                       /tb_phase1/uut/core_inst/rf_we

# -----------------------------------------------------------------------------
# 3. Register File Array
# -----------------------------------------------------------------------------
add wave -noupdate -divider {Register File Array}
add wave -noupdate -radix hexadecimal -label {Regs [0:31]}        /tb_phase1/uut/core_inst/regfile_inst/registers

# -----------------------------------------------------------------------------
# 4. ITCM / DTCM RAM Memory Interface
# -----------------------------------------------------------------------------
add wave -noupdate -divider {ITCM / DTCM RAM Memory}
add wave -noupdate -radix hexadecimal -label {ITCM Addr}          /tb_phase1/uut/itcm_ram/itcm_addr
add wave -noupdate -radix hexadecimal -label {ITCM Read Data}     /tb_phase1/uut/itcm_ram/itcm_rdata
add wave -noupdate -label {DTCM Write Enable}                      /tb_phase1/uut/itcm_ram/dtcm_we
add wave -noupdate -radix hexadecimal -label {DTCM Write Addr}    /tb_phase1/uut/itcm_ram/dtcm_addr
add wave -noupdate -radix hexadecimal -label {DTCM Write Data}    /tb_phase1/uut/itcm_ram/dtcm_wdata

# -----------------------------------------------------------------------------
# 5. AXI-to-AHB Bus Bridge & Conversion Interface
# -----------------------------------------------------------------------------
add wave -noupdate -divider {AXI-to-AHB Bus Bridge (Conversion)}
add wave -noupdate -radix hexadecimal -label {AXI AWADDR}        /tb_phase1/uut/bridge_inst/s_axi_awaddr
add wave -noupdate -label {AXI AWVALID}                            /tb_phase1/uut/bridge_inst/s_axi_awvalid
add wave -noupdate -radix hexadecimal -label {AXI WDATA}         /tb_phase1/uut/bridge_inst/s_axi_wdata
add wave -noupdate -label {AXI WVALID}                             /tb_phase1/uut/bridge_inst/s_axi_wvalid
add wave -noupdate -radix hexadecimal -label {AHB HADDR (Converted)} /tb_phase1/uut/ahb_haddr
add wave -noupdate -radix hexadecimal -label {AHB HWDATA (Converted)} /tb_phase1/uut/ahb_hwdata
add wave -noupdate -label {AHB HWRITE (Converted)}                 /tb_phase1/uut/ahb_hwrite
add wave -noupdate -label {AHB HREADY}                             /tb_phase1/uut/ahb_hready

# -----------------------------------------------------------------------------
# 6. External Peripherals (UART & NoC)
# -----------------------------------------------------------------------------
add wave -noupdate -divider {External Peripherals & NoC}
add wave -noupdate -label {UART TX Pin (Serial Output)}            /tb_phase1/uut/uart_tx
add wave -noupdate -label {NoC TX Valid}                           /tb_phase1/uut/noc_tx_valid
add wave -noupdate -radix hexadecimal -label {NoC TX Flit (35-bit)} /tb_phase1/uut/noc_tx_flit

# -----------------------------------------------------------------------------
# Waveform Window Configuration
# -----------------------------------------------------------------------------
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 240
configure wave -valuecolwidth 120
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
update

# Set view range to 100 microseconds to observe full UART serial transmission
WaveRestoreZoom {0 ns} {100 us}