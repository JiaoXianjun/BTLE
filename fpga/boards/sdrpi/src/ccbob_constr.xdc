 
# ports connect to P1 in sdrpi board. 
       
#   // gpio_bd[0]  -> P1.gpio1
#   // gpio_bd[1]  -> P1.gpio2
#   // gpio_bd[2]  -> P1.gpio3
#   // ......
#   // gpio_bd[24] -> P1.gpio25
#   // gpio_bd[25] -> P1.gpio26
    
 
   
   
set_property  -dict { PACKAGE_PIN    g14    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[0]]  
set_property  -dict { PACKAGE_PIN    v10    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[1]]  
set_property  -dict { PACKAGE_PIN    w10    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[2]]  
set_property  -dict { PACKAGE_PIN    y9     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[3]]  
set_property  -dict { PACKAGE_PIN    u9     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[4]]  
set_property  -dict { PACKAGE_PIN    v8     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[5]]  
set_property  -dict { PACKAGE_PIN    y7     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[6]]  
set_property  -dict { PACKAGE_PIN    y13    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[7]]  
set_property  -dict { PACKAGE_PIN    v6     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[8]]  
set_property  -dict { PACKAGE_PIN    y12    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[9]]  
set_property  -dict { PACKAGE_PIN    w11    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[10]] 
set_property  -dict { PACKAGE_PIN    t9     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[11]] 
set_property  -dict { PACKAGE_PIN    w9     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[12]] 
set_property  -dict { PACKAGE_PIN    v7     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[13]] 
set_property  -dict { PACKAGE_PIN    u10    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[14]] 
set_property  -dict { PACKAGE_PIN    v11    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[15]] 
set_property  -dict { PACKAGE_PIN    y8     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[16]] 
set_property  -dict { PACKAGE_PIN    y6     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[17]] 
set_property  -dict { PACKAGE_PIN    u8     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[18]] 
set_property  -dict { PACKAGE_PIN    w6     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[19]] 
set_property  -dict { PACKAGE_PIN    u5     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[20]] 
set_property  -dict { PACKAGE_PIN    t5     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[21]] 
set_property  -dict { PACKAGE_PIN    y11    IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[22]] 
set_property  -dict { PACKAGE_PIN    u7     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[23]] 
set_property  -dict { PACKAGE_PIN    w8     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[24]] 
set_property  -dict { PACKAGE_PIN    v5     IOSTANDARD  LVCMOS25 }  [get_ports  gpio_bd[25]]  


