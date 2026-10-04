################################################################################
# 1. PRIMARY SYSTEM CLOCK & RESET
# 66.67 MHz Target Clock (15 ns period) for RV32I Core & Peripherals
################################################################################
create_clock -period 15.000 -name sys_clk -waveform {0.000 7.500} [get_ports clk]

# Ignore timing path on asynchronous reset
set_false_path -from [get_ports rst_n]

################################################################################
# 2. PERIPHERAL INTERFACE TIMING (UART & I2C)
# Set false paths for slow asynchronous external peripheral pins to ensure
# setup/hold optimization focuses strictly on internal CPU core & bus matrix
################################################################################
# UART External Pins
set_false_path -to   [get_ports -quiet uart_tx]
set_false_path -from [get_ports -quiet uart_rx]

# I2C External Lines (SCL & SDA)
set_false_path -to   [get_ports -quiet i2c_scl]
set_false_path -from [get_ports -quiet i2c_scl]
set_false_path -to   [get_ports -quiet i2c_sda]
set_false_path -from [get_ports -quiet i2c_sda]