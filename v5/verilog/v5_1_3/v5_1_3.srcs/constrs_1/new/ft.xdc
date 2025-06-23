set_property PACKAGE_PIN D4 [get_ports {ft_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_clk}]
# ft_clk => 100000000Hz
create_clock -period 10.0 -name ft_clk_12 -waveform {0.000 5.0} [get_ports ft_clk]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks ft_clk_12]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clock -of_objects [get_ports ft_clk]]

set_property PACKAGE_PIN N6 [get_ports {ft_wakeup}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_wakeup}]

set_property PACKAGE_PIN M6 [get_ports {ft_reset}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_reset}]

set_property PACKAGE_PIN L2 [get_ports {ft_rxf}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_rxf}]

set_property PACKAGE_PIN L3 [get_ports {ft_txe}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_txe}]

set_property PACKAGE_PIN P9 [get_ports {ft_oe}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_oe}]

set_property PACKAGE_PIN N9 [get_ports {ft_rd}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_rd}]

set_property PACKAGE_PIN J1 [get_ports {ft_wr}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_wr}]

set_property PACKAGE_PIN H1 [get_ports {ft_be[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_be[0]}]

set_property PACKAGE_PIN K3 [get_ports {ft_be[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_be[1]}]

set_property PACKAGE_PIN K2 [get_ports {ft_be[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_be[2]}]

set_property PACKAGE_PIN K1 [get_ports {ft_be[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_be[3]}]

set_property PACKAGE_PIN T8 [get_ports {ft_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[0]}]

set_property PACKAGE_PIN T7 [get_ports {ft_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[1]}]

set_property PACKAGE_PIN T10 [get_ports {ft_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[2]}]

set_property PACKAGE_PIN T9 [get_ports {ft_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[3]}]

set_property PACKAGE_PIN T5 [get_ports {ft_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[4]}]

set_property PACKAGE_PIN R5 [get_ports {ft_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[5]}]

set_property PACKAGE_PIN T12 [get_ports {ft_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[6]}]

set_property PACKAGE_PIN R12 [get_ports {ft_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[7]}]

set_property PACKAGE_PIN R7 [get_ports {ft_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[8]}]

set_property PACKAGE_PIN R6 [get_ports {ft_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[9]}]

set_property PACKAGE_PIN T13 [get_ports {ft_data[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[10]}]

set_property PACKAGE_PIN R13 [get_ports {ft_data[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[11]}]

set_property PACKAGE_PIN R8 [get_ports {ft_data[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[12]}]

set_property PACKAGE_PIN P8 [get_ports {ft_data[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[13]}]

set_property PACKAGE_PIN T15 [get_ports {ft_data[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[14]}]

set_property PACKAGE_PIN T14 [get_ports {ft_data[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[15]}]

set_property PACKAGE_PIN C4 [get_ports {ft_data[16]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[16]}]

set_property PACKAGE_PIN E3 [get_ports {ft_data[17]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[17]}]

set_property PACKAGE_PIN D3 [get_ports {ft_data[18]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[18]}]

set_property PACKAGE_PIN G2 [get_ports {ft_data[19]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[19]}]

set_property PACKAGE_PIN G1 [get_ports {ft_data[20]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[20]}]

set_property PACKAGE_PIN J5 [get_ports {ft_data[21]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[21]}]

set_property PACKAGE_PIN J4 [get_ports {ft_data[22]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[22]}]

set_property PACKAGE_PIN G5 [get_ports {ft_data[23]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[23]}]

set_property PACKAGE_PIN G4 [get_ports {ft_data[24]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[24]}]

set_property PACKAGE_PIN H5 [get_ports {ft_data[25]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[25]}]

set_property PACKAGE_PIN H4 [get_ports {ft_data[26]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[26]}]

set_property PACKAGE_PIN F2 [get_ports {ft_data[27]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[27]}]

set_property PACKAGE_PIN E1 [get_ports {ft_data[28]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[28]}]

set_property PACKAGE_PIN J3 [get_ports {ft_data[29]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[29]}]

set_property PACKAGE_PIN H3 [get_ports {ft_data[30]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[30]}]

set_property PACKAGE_PIN H2 [get_ports {ft_data[31]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[31]}]

# # ft_clk => 100000000Hz
# create_clock -period 10.0 -name ft_clk_0 -waveform {0.000 5.000} [get_ports ft_clk]
# set_property PACKAGE_PIN F5 [get_ports {ft_clk}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_clk}]
# set_property PACKAGE_PIN F3 [get_ports {ft_rxf}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_rxf}]
# set_property PACKAGE_PIN F4 [get_ports {ft_txe}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_txe}]
# set_property PACKAGE_PIN B7 [get_ports {ft_data[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[0]}]
# set_property PACKAGE_PIN A7 [get_ports {ft_data[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[1]}]
# set_property PACKAGE_PIN B6 [get_ports {ft_data[2]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[2]}]
# set_property PACKAGE_PIN B5 [get_ports {ft_data[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[3]}]
# set_property PACKAGE_PIN C3 [get_ports {ft_data[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[4]}]
# set_property PACKAGE_PIN C2 [get_ports {ft_data[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[5]}]
# set_property PACKAGE_PIN R6 [get_ports {ft_data[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[6]}]
# set_property PACKAGE_PIN R7 [get_ports {ft_data[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[7]}]
# set_property PACKAGE_PIN C7 [get_ports {ft_data[8]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[8]}]
# set_property PACKAGE_PIN C6 [get_ports {ft_data[9]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[9]}]
# set_property PACKAGE_PIN R12 [get_ports {ft_data[10]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[10]}]
# set_property PACKAGE_PIN T12 [get_ports {ft_data[11]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[11]}]
# set_property PACKAGE_PIN T9 [get_ports {ft_data[12]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[12]}]
# set_property PACKAGE_PIN T10 [get_ports {ft_data[13]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[13]}]
# set_property PACKAGE_PIN B4 [get_ports {ft_data[14]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[14]}]
# set_property PACKAGE_PIN A3 [get_ports {ft_data[15]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[15]}]
# set_property PACKAGE_PIN G2 [get_ports {ft_be[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_be[0]}]
# set_property PACKAGE_PIN G1 [get_ports {ft_be[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_be[1]}]
# set_property PACKAGE_PIN D3 [get_ports {ft_rd}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_rd}]
# set_property PACKAGE_PIN E3 [get_ports {ft_wr}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_wr}]
# set_property PACKAGE_PIN E5 [get_ports {ft_oe}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ft_oe}]
# # set_clock_groups -group [get_clocks -include_generated_clocks clk_0] \
# #   -group [get_clocks -include_generated_clocks ft_clk_0] -asynchronous
# set_clock_groups -async -group [get_clocks -include_generated_clocks ft_clk_0]

# set_input_delay -clock [get_clocks ft_clk_0] -min -add_delay 0.000 [get_ports ft_rxf]
# set_input_delay -clock [get_clocks ft_clk_0] -max -add_delay 0.001 [get_ports ft_rxf]
# set_input_delay -clock [get_clocks ft_clk_0] -min -add_delay 0.000 [get_ports ft_txe]
# set_input_delay -clock [get_clocks ft_clk_0] -max -add_delay 0.001 [get_ports ft_txe]
# set_output_delay -clock [get_clocks ft_clk_0] -min -add_delay 0.000 [get_ports {ft_data[*]}]
# set_output_delay -clock [get_clocks ft_clk_0] -max -add_delay 0.001 [get_ports {ft_data[*]}]
# set_false_path -to [get_ports {ft_data[*]}]
# set_output_delay -clock [get_clocks ft_clk_0] -min -add_delay 0.000 [get_ports {ft_be[*]}]
# set_output_delay -clock [get_clocks ft_clk_0] -max -add_delay 0.001 [get_ports {ft_be[*]}]
# set_false_path -to [get_ports {ft_be[*]}]
# set_output_delay -clock [get_clocks ft_clk_0] -min -add_delay 0.000 [get_ports {ft_oe}]
# set_output_delay -clock [get_clocks ft_clk_0] -max -add_delay 0.001 [get_ports {ft_oe}]
# set_false_path -to [get_ports {ft_oe}]
# set_output_delay -clock [get_clocks ft_clk_0] -min -add_delay 0.000 [get_ports {ft_rd}]
# set_output_delay -clock [get_clocks ft_clk_0] -max -add_delay 0.001 [get_ports {ft_rd}]
# set_false_path -to [get_ports {ft_rd}]
# set_output_delay -clock [get_clocks ft_clk_0] -min -add_delay 0.000 [get_ports {ft_wr}]
# set_output_delay -clock [get_clocks ft_clk_0] -max -add_delay 0.001 [get_ports {ft_wr}]
# set_false_path -to [get_ports {ft_wr}]