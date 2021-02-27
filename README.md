BTLE
========

BTLE is a free and open-source Software Defined Radio Bluetooth Low Energy (BLE) software suite. 

It includes:
  * btle_rx - BLE sniffer. Besides sniff broadcasting/fixed channel, it can also track channel hopping of a communication link.
  * btle_tx - Universal BLE packet transmitter. Besides BLE standard, it supports also raw bit mode to generate arbitrary GFSK packet. In this way, you can test non-standard protocol or standard under discussion before chip in the market.

Features
---------------

 * PHY and upper layer are implemented in software (C language). Full Software Defined Radio Flexibility. 
 * BLE standard 1Mbps GFSK PHY.
 * All ADV and DATA channel link layer packet formats in Core_V4.0 (Chapter 2&3, PartB, Volume 6) are supported.
 * Sniffer is capable to parse and track channel hopping pattern automatically, not limited to broadcasting channel or fixed channel.

Hardware
--------

 * [HackRF](https://github.com/mossmann/hackrf)
 * [bladeRF](https://github.com/Nuand/bladeRF)
 * [compatible version of HackRF and bladeRF libraries](compatible_hackrf_bladerf_lib.txt)

Build and Quick test
------------------

Make sure your SDR hardware environment (driver/lib) has been setup correctly before run this project.

```
git clone https://github.com/JiaoXianjun/BTLE.git
cd BTLE/host
mkdir build
cd build
cmake ../                   (default. for HackRF)
cmake ../ -DUSE_BLADERF=1   (only for bladeRF)

make
./btle-tools/src/btle_rx
```
Above command sniffs on channel 37. You should see many packets on screen if you have BLE devices (phone/pad/laptop) around.
```
./btle-tools/src/btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-LOCAL_NAME09-SDR/Bluetooth/Low/Energy r500 
```
Above command transmits discovery packets on ADV channel. You should see a device with name "SDR/Bluetooth/Low/Energy" in another BLE sniffer App (such as LightBlue).

~~**MAY NOT BE NECESSARY**: To support fast/realtime sender and scanner/sniffer, I ever changed:~~

~~lib_device->transfer_count to 4~~

~~lib_device->buffer_size to 4096~~

~~in hackrf driver: hackrf.c. Maybe you should also do that change to your HackRF driver source code and re-compile, re-install~~

btle_rx usage
------------------
```    
btle_rx -c chan -g gain -a access_addr -k crc_init -v -r
```
```
-h --help
```
Print this help screen
```
-c --chan
```
Channel number. Default value 37 (one of ADV channels). Valid value 0~39 (all ADV and DATA channels).
```
-g --gain
```
VGA gain. default value 6. valid value 0~62. Gain should be tuned very carefully to ensure best performance under your circumstance. Suggest test from low gain, because high gain always causes severe distortion and get you nothing.
```
-l --lnaGain
```
LNA gain in dB. HACKRF lna default 32, valid 0~40, lna in max gain. bladeRF default is max rx gain 32dB (valid 0~40). Gain should be tuned very carefully to ensure best performance under your circumstance. 
```
-b --amp
```
Enable amp (HackRF). Default off.
```
-a --access
```
Access address. Default 8e89bed6 for ADV channel 37 38 39. You should specify correct value for data channel according to captured connection setup procedure.
```
-k --crcinit
```
Default 555555 for ADV channel. You should specify correct value for data channel according to captured connection setup procedure.
```
-v --verbose
```
Verbose mode. Print more information when there is error
```
-r --raw
```
Raw mode. After access addr is detected, print out following raw 42 bytes (without descrambling, parsing)
```        
-f --freq_hz (need argument)
```
This frequency (Hz) will override channel setting (In case someone want to work on freq other than BTLE. More general purpose).
```
-m --access_mask (need argument)
```
If a bit is 1 in this mask, corresponding bit in access address will be taken into packet existing decision (In case someone want a shorter/sparser unique word to do packet detection. More general purpose).```
-o --hop
```
This will turn on data channel tracking (frequency hopping) after link setup information is captured in ADV_CONNECT_REQ packet on ADV channel.
```
-s --filename
```
Store packets to pcap file.

btle_tx usage
------------------
```
btle_tx packet1 packet2 ... packetX ...  rN
```
or 
```
btle_tx packets.txt
```
packets.txt is a text file which has command line parameters (packet1 packet2 ... rN) text. One parameter one line. A line start with "#" is regarded as comment. See [packets.txt example](host/btle-tools/src/packets.txt)
```
packetX 
```
is one string which describes one packet. All packets compose a packets sequence.
```
rN
```
means the sequence will be repeated for N times. If it is not specified, the sequence will only be sent once.

packetX string format
```    
channel_number-packet_type-field-value-field-value-...-Space-value
```
Each descriptor string starts with BTLE channel number (0~39), then followed by packet_type (RAW/iBeacon/ADV_IND/ADV_DIRECT_IND/etc. See all format examples [**AT THE END: Appendix**](#appendix-packet-descriptor-examples-of-btle_tx-for-all-formats) ), then followed by field-value pair which is packet_type specific, at last there is Space-value pair (optional) where the value specifies how many millisecond will be waited after this packet sent.

**DO NOT** use space character " " in a command line packet descriptor. You CAN use space in the txt file packet descriptor.

**DO NOT** use "-" inside each field. "-" is magic character which is used to separate different fields in packet descriptor. 


* **btle_tx example: [Discovery packets](host/btle-tools/src/packets_discovery.txt)**

Open LightBlue APP (or other BLE sniffer) in your iPhone/device before this command:
```
./btle-tools/src/btle_tx ../btle-tools/src/packets_discovery.txt
```
You will see a device named as "SDR Bluetooth Low Energy" in your LightBlue APP.

Corresponding Command line:
```
./btle-tools/src/btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-LOCAL_NAME09-SDR/Bluetooth/Low/Energy r40
``` 
Note: space " " is replaced by "/" because space " " is not supported in command line.


* **btle_tx example: [Connection establishment](doc/TI-BLE-INTRODUCTION.pdf)**
```
btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-1      37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-1     9-LL_DATA-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-DATA-XX-CRCInit-A77B22-Space-1
```
Above simulates a Connection establishment procedure between device 1 and device 2. Corresponding descriptor file [BTLE/host/btle-tools/src/packets.txt](host/btle-tools/src/packets.txt).

The 1st packet -- device 1 sends ADV_IND packet in channel 37.

The 2nd packet -- After device 2 (in scanning state) receives the ADV packet from device 1, device 2 sends CONNECT_REQ packet to request connection setup with device 1. In this request packet, there are device 2 MAC address (InitA), target MAC address (device 1 MAC address AdvA), Access address (AA) which will be used by device 1 in following packet sending in data channel, CRC initialization value for following device 1 sending packet, Hopping channel information (ChM and Hop) for data channel used by device 1, etc.

The 3rd packet -- device 1 send an empty Link layer data PDU in channel 9 (decided by hopping scheme) according to those connection request information received from device 2. ("XX" after field "DATA" means there is no data for this field )

Time space between packets are 1s (1000ms). Tune TI's packet sniffer to channel 37, then above establishment procedure will be captured.


* **btle_tx example: [iBeacon](doc/ibeacon.pdf)**
```
./btle-tools/src/btle_tx 37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100     r100
```
Above command sends iBeacon packet and repeats it 100 times with 100ms time space. Corresponding descriptor file [BTLE/host/btle-tools/src/packets_ibeacon.txt](host/btle-tools/src/packets_ibeacon.txt). You can use a BLE sniffer dongle to see the packet.

The packet descriptor string:
```
37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100
```
```
37
```
channel 37 (one of BTLE Advertising channel 37 38 39)
```
iBeacon
```
packet format key word which means iBeacon format. (Actually it is ADV_IND format in Core_V4.0.pdf)
```
AdvA
```
Advertising address (MAC address) which is set as 010203040506 (See Core_V4.0.pdf)
```
UUID
```
here we specify it as Estimote’s fixed UUID: B9407F30F5F8466EAFF925556B57FE6D
```
Major
```
major number of iBeacon format. (Here it is 0008)
```
Minor
```
minor number of iBeacon format. (Here it is 0009)
```
Txpower
```
transmit power parameter of iBeacon format (Here it is C5)
```
Space
```
How many millisecond will be waited after this packet sent. (Here it is 100ms)
 
Demos
------------------

See a comparison with TI's packet sniffer here: [http://sdr-x.github.io/BTLE-SNIFFER/](http://sdr-x.github.io/BTLE-SNIFFER/)

See <a href="https://youtu.be/9LDPhOF2yyw">btle_rx video demo</a> or <a href="https://vimeo.com/144574631">btle_rx video demo</a> (in China) and <a href="http://youtu.be/Y8ttV5AEb-g">btle_tx video demo 1</a> or <a href="http://v.youku.com/v_show/id_XNzUxMDIzNzAw.html">btle_tx video demo 2</a> (in China)

# Appendix: Packet descriptor examples of btle_tx for all formats
------------------

RAW packets: (All bits will be sent to GFSK modulator directly)
```
37-RAW-aad6be898e8dc3ce338c4cb1207730144f9474e0e15eedb378c3bc
```
ADVERTISING CHANNEL packets (channel 37 for example):
```
37-IBEACON-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5
37-ADV_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
37-ADV_DIRECT_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-InitA-0708090A0B0C
37-ADV_NONCONN_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
37-ADV_SCAN_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
37-SCAN_REQ-TxAdd-1-RxAdd-0-ScanA-010203040506-AdvA-0708090A0B0C
37-SCAN_RSP-TxAdd-1-RxAdd-0-AdvA-010203040506-ScanRspData-00112233445566778899AABBCCDDEEFF
37-CONNECT_REQ-TxAdd-1-RxAdd-0-InitA-010203040506-AdvA-0708090A0B0C-AA-01020304-CRCInit-050607-WinSize-08-WinOffset-090A-Interval-0B0C-Latency-0D0E-Timeout-0F00-ChM-0102030405-Hop-3-SCA-4
```
DATA CHANNEL packets (channel 9 for example):
```
9-LL_DATA-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-DATA-XX-CRCInit-A77B22
9-LL_CONNECTION_UPDATE_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-WinSize-02-WinOffset-0e0F-Interval-0450-Latency-0607-Timeout-07D0-Instant-eeff-CRCInit-A77B22
9-LL_CHANNEL_MAP_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-ChM-1FFFFFFFFF-Instant-0201-CRCInit-A77B22
9-LL_TERMINATE_IND-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-ErrorCode-12-CRCInit-A77B22
9-LL_ENC_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-Rand-0102030405060708-EDIV-090A-SKDm-0102030405060708-IVm-090A0B0C-CRCInit-A77B22
9-LL_ENC_RSP-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-SKDs-0102030405060708-IVs-01020304-CRCInit-A77B22
9-LL_START_ENC_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-CRCInit-A77B22
9-LL_START_ENC_RSP-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-CRCInit-A77B22
9-LL_UNKNOWN_RSP-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-UnknownType-01-CRCInit-A77B22
9-LL_FEATURE_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-FeatureSet-0102030405060708-CRCInit-A77B22
9-LL_FEATURE_RSP-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-FeatureSet-0102030405060708-CRCInit-A77B22
9-LL_PAUSE_ENC_REQ-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-CRCInit-A77B22
9-LL_PAUSE_ENC_RSP-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-CRCInit-A77B22
9-LL_VERSION_IND-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-VersNr-01-CompId-0203-SubVersNr-0405-CRCInit-A77B22
9-LL_REJECT_IND-AA-60850A1B-LLID-3-NESN-0-SN-0-MD-0-ErrorCode-00-CRCInit-A77B22
```
Discovery packets: (which can show any name or services in scanner APP, such as LightBlue):
```
37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-FLAGS-02-LOCAL_NAME09-CA-TXPOWER-03-SERVICE03-180D1810-SERVICE_DATA-180D40-MANUF_DATA-0001FF-CONN_INTERVAL-0006 (-SERVICE_SOLI14-1811)

FLAGS: 0x01 LE Limited Discoverable Mode; 0x02 LE General Discoverable Mode
SERVICE:
0x02 16-bit Service UUIDs More 16-bit UUIDs available
0x03 16-bit Service UUIDs Complete list of 16-bit UUIDs available
0x04 32-bit Service UUIDs More 3a2-bit UUIDs available
0x05 32-bit Service UUIDs Complete list of 32-bit UUIDs available
0x06 128-bit Service UUIDs More 128-bit UUIDs available
0x07 128-bit Service UUIDs Complete list of 128-bit UUIDs available
```
