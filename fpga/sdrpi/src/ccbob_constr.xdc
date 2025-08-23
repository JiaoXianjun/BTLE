
# ports connect to P1 in sdrpi board.

#   // gpio_bd[0]  -> P1.gpio1
#   // gpio_bd[1]  -> P1.gpio2
#   // gpio_bd[2]  -> P1.gpio3
#   // ......
#   // gpio_bd[24] -> P1.gpio25
#   // gpio_bd[25] -> P1.gpio26




set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[0]}]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[1]}]
set_property -dict {PACKAGE_PIN W10 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[2]}]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[3]}]
set_property -dict {PACKAGE_PIN U9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[4]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[5]}]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[6]}]
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[7]}]
set_property -dict {PACKAGE_PIN V6 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[8]}]
set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[9]}]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[10]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[11]}]
set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[12]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[13]}]
set_property -dict {PACKAGE_PIN U10 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[14]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[15]}]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[16]}]
set_property -dict {PACKAGE_PIN Y6 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[17]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[18]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[19]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[20]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[21]}]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[22]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[23]}]
set_property -dict {PACKAGE_PIN W8 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[24]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS25} [get_ports {gpio_bd[25]}]







