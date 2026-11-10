# Clock
set_property PACKAGE_PIN Y9 [get_ports {clk_100mhz}];
set_property IOSTANDARD LVCMOS33 [get_ports {clk_100mhz}];
create_clock -name clk_100mhz -period 20.0 [get_ports {clk_100mhz}];

# Buttons
set_property PACKAGE_PIN P16 [get_ports {rst_btn}];  # Center Button
set_property IOSTANDARD LVCMOS25 [get_ports {rst_btn}];
set_property PACKAGE_PIN R18 [get_ports {start_btn}]; # Right Button
set_property IOSTANDARD LVCMOS25 [get_ports {start_btn}];

# LEDs
set_property PACKAGE_PIN T22 [get_ports {led[0]}];
set_property PACKAGE_PIN T21 [get_ports {led[1]}];
set_property PACKAGE_PIN U22 [get_ports {led[2]}];
set_property PACKAGE_PIN U21 [get_ports {led[3]}];
set_property PACKAGE_PIN V22 [get_ports {led[4]}];
set_property PACKAGE_PIN W22 [get_ports {led[5]}];
set_property PACKAGE_PIN U19 [get_ports {led[6]}];
set_property PACKAGE_PIN U14 [get_ports {led[7]}];
set_property IOSTANDARD LVCMOS33 [get_ports -filter { NAME =~  "*led*" }];
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets rst_btn_IBUF]