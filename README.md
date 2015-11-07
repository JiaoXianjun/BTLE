
A BTLE (Bluetooth Low energy)/BT4.0 radio packet sniffer/scanner and sender ( build based on <a href="https://github.com/mossmann/hackrf">hackrf</a> and <a href="https://github.com/Nuand/bladeRF">bladeRF</a> ) . Also see my tech blog: http://sdr-x.github.io

==========================================================================

# News (See complete introduction section after news section):

## Nov. 2015: BTLE packet sniffer/scanner btle_rx works! Support HACKRF currently. Usage:
    
    btle_rx -c chan -g gain -a access_addr -k crc_init -v

chan: Channel number. Default value 37 (one of ADV chan). Valid value 0~39 (all ADV and DATA chan).

gain: VGA gain. default value 6. valid value 0~62. LNA has been set to maximum 40dB internally. Gain should be tuned very carefully to ensure best performance under your circumstance. Suggest test from low gain, because high gain always causes severe distortion and get you nothing.

access_addr: Access address. Default 8e89bed6 for ADV channel 37 38 39.

crc_init: Default 555555 for ADV channel. You should specify correct value for data channel according to captured connection setup procedure.

-v: verbose mode

**ATTENTION**: To support fast/realtime sender and scanner/sniffer, I have changed:

    lib_device->transfer_count to 4
    lib_device->buffer_size to 4096 

in hackrf driver: hackrf.c. You should also do that change to your driver source code and re-compile, re-install as instructed in <a href="https://github.com/mossmann/hackrf">hackrf</a>

See a comparison with TI's packet sniffer here: [http://sdr-x.github.io/BTLE-SNIFFER/](http://sdr-x.github.io/BTLE-SNIFFER/)

## Sep. 2015: Fixed-point version. Add new packet type: discovery. Open LightBlue APP in your iPhone/device, then:

    btle_tx packets_discovery.txt
    (packets_discovery.txt is under host/btle-tools/src)

You will see a device named as "CA1308 11950 22.626 113.823 8" in your LightBlue APP.

**DO NOT** use space character " " in a command line packet descriptor. You CAN use space in the txt file packet descriptor like above. Command line of above example:

    btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-LOCAL_NAME09-CA1308/11950/22.626/113.823/8 r40
    
"btle_tx 37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-LOCAL_NAME09-CA1308 11950 22.626 113.823 8 r40" in command line will get ERROR!

"-" is magic character which is used to separate different fields in packet descriptor. DO NOT use "-" inside each field.

## Aug. 2014: Fix packet loss bug. And, add <a href="https://github.com/Nuand/bladeRF">bladeRF</a> support:

    cmake ../ -DUSE_BLADERF=1  (without -DUSE_BLADERF=1 means HACKRF will be used by default)
    
(Don't forget removing all files in build directory before above command!)

==========================================================================

# Introduction

All ADV and DATA channel link layer packet formats are supported. (Chapter 2&3, PartB, Volume 6, 
<a href="https://www.google.fi/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCAQFjAA&url=https%3A%2F%2Fwww.bluetooth.org%2Fdocman%2Fhandlers%2Fdownloaddoc.ashx%3Fdoc_id%3D229737&ei=ui3gU4GkC-up0AW4q4GwBw&usg=AFQjCNFY1IFeFAAWwimnoaWMsIRZQvPDSw&sig2=wTgMMxNPJ52NHclpsQ4XhQ&bvm=bv.72197243,d.d2k">Core_V4.0.pdf</a>   )

btle_tx transmits arbitrary pre-defined BTLE signal/packet sequence, such as raw bits to GFSK modulator, iBeacon packet, <a href="http://processors.wiki.ti.com/index.php/BLE_sniffer_guide">Connection establishment procedure packet</a> in TI's website, or any other packets you want. 

btle_rx sniffs/scans BTLE packets in the air, just like TI'S packet sniffer.

See <a href="https://youtu.be/9LDPhOF2yyw">btle_rx video demo</a> (youtube) or <a href="https://vimeo.com/144574631">btle_rx video demo</a> (in China) and <a href="http://youtu.be/Y8ttV5AEb-g">btle_tx video demo 1</a> (outside China) or <a href="http://v.youku.com/v_show/id_XNzUxMDIzNzAw.html">btle_tx video demo 2</a> (inside China)

# 1. Build:

    cd host
    mkdir build
    cd build
    cmake ../      (without -DUSE_BLADERF=1 means HACKRF will be used by default)
    make
    sudo make install  (or not install, just use btle_tx in btle-tools/src)

# 2. btle_tx usage

Usage method 1:

    btle_tx packet1 packet2 ... packetX ...  rN

Usage method 2:

    btle_tx packets.txt

In method 2, just those command line parameters (packet1 ... rN) in method 1 are written/grouped in a .txt file as input of btle_tx tool. One parameter one line. A line start with "#" is regarded as comment. See packets.txt example in btle-tools/src.

"packetX" is one string which describes one packet. All packets compose a packets sequence.

"rN" means the sequence will be repeated for N times. If it is not specified, the sequence will only be sent once.

## Format of packet descriptor "packetX"
    
    channel_number-packet_type-field-value-field-value-...-Space-value

Each descriptor string starts with BTLE channel number (0~39), then followed by packet_type (RAW/iBeacon/ADV_IND/ADV_DIRECT_IND/etc. See all format examples at the end), then followed by field-value pair which is packet_type specific, at last there is Space-value pair (optional) where the value specifies how many millisecond will be waited after this packet sent.

### a). iBeacon example: (iBeacon principle: http://www.warski.org/blog/2014/01/how-ibeacons-work/ )

    btle_tx     37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100     r100

Above command sends iBeacon packet and repeats it 100 times with 100ms time space (If you have "Locate" app in your iPhone/iPad, it will detect the packet and show the iBeacon info.). The packet descriptor string:

    37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100

37 -- channel 37 (one of BTLE Advertising channel 37 38 39)

iBeacon -- packet format key word which means iBeacon format. (Actually it is ADV_IND format in Core_V4.0.pdf)

AdvA -- Advertising address (MAC address) which is set as 010203040506 (See Core_V4.0.pdf)

UUID -- here we specify it as Estimote’s fixed UUID: B9407F30F5F8466EAFF925556B57FE6D

Major -- major number of iBeacon format. (Here it is 0008)

Minor -- minor number of iBeacon format. (Here it is 0009)

Txpower -- transmit power parameter of iBeacon format (Here it is C5)

Space -- How many millisecond will be waited after this packet sent. (Here it is 100ms)

### b). Connection establishment example: (See "Connection establishment" part of http://processors.wiki.ti.com/index.php/BLE_sniffer_guide )

    btle_tx     37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-1      37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-1     9-LL_DATA-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-DATA-XX-CRCInit-A77B22-Space-1
    
Above simualtes a Connection establishment procedure between device 1 and device 2.

The 1st packet -- device 1 sends ADV_IND packet in channel 37.

The 2nd packet -- After device 2 (in scanning state) receives the ADV packet from device 1, device 2 sends CONNECT_REQ packet to request connection setup with device 1. In this request packet, there are device 2 MAC address (InitA), target MAC address (device 1 MAC address AdvA), Access address (AA) which will be used by device 1 in following packet sending in data channel, CRC initilization value for following device 1 sending packet, Hopping channel information (ChM and Hop) for data channel used by device 1, etc.

The 3rd packet -- device 1 send an empty Link layer data PDU in channel 9 (decided by hopping scheme) according to those connection request information received from device 2. ("XX" after field "DATA" means there is no data for this field )

Time space between packets are 1s (1000ms). Tune TI's packet sniffer to channel 37, then above establishment procedure will be captured.

### c). Discovery packets example: (which can show any name or services in receiver/scanner, such as LightBlue):

Open LightBlue APP in your iPhone/device, then:

    btle_tx packets_discovery.txt
    (packets_discovery.txt is under host/btle-tools/src)

You will see a device named as "CA1308 11950 22.626 113.823 8" in your LightBlue APP.

# 3. btle_rx Usage
    
    btle_rx -c chan -g gain -a access_addr -k crc_init -v

chan: Channel number. Default value 37 (one of ADV chan). Valid value 0~39 (all ADV and DATA chan).

gain: VGA gain. default value 6. valid value 0~62. LNA has been set to maximum 40dB internally. Gain should be tuned very carefully to ensure best performance under your circumstance. Suggest test from low gain, because high gain always causes severe distortion and get you nothing.

access_addr: Access address. Default 8e89bed6 for ADV channel 37 38 39.

crc_init: Default 555555 for ADV channel. You should specify correct value for data channel according to captured connection setup procedure.

-v: verbose mode

# Appendix: Packet descriptor examples of btle_tx for all formats:

RAW packets: (All bits will be sent to GFSK modulator directly)

    37-RAW-aad6be898e8dc3ce338c4cb1207730144f9474e0e15eedb378c3bc

ADVERTISING CHANNEL packets:

    37-IBEACON-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5
    37-ADV_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
    37-ADV_DIRECT_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-InitA-0708090A0B0C
    37-ADV_NONCONN_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
    37-ADV_SCAN_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-00112233445566778899AABBCCDDEEFF
    37-SCAN_REQ-TxAdd-1-RxAdd-0-ScanA-010203040506-AdvA-0708090A0B0C
    37-SCAN_RSP-TxAdd-1-RxAdd-0-AdvA-010203040506-ScanRspData-00112233445566778899AABBCCDDEEFF
    37-CONNECT_REQ-TxAdd-1-RxAdd-0-InitA-010203040506-AdvA-0708090A0B0C-AA-01020304-CRCInit-050607-WinSize-08-WinOffset-090A-Interval-0B0C-Latency-0D0E-Timeout-0F00-ChM-0102030405-Hop-3-SCA-4

DATA CHANNEL packets:

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

Discovery packets: (which can show any name or services in receiver/scanner, such as LightBlue):

    37-DISCOVERY-TxAdd-1-RxAdd-0-AdvA-010203040506-FLAGS-02-LOCAL_NAME09-CA-TXPOWER-03-SERVICE03-180D1810-SERVICE_DATA-180D40-MANUF_DATA-0001FF-CONN_INTERVAL-0006 (-SERVICE_SOLI14-1811)
   
    FLAGS: 0x01 LE Limited Discoverable Mode; 0x02 LE General Discoverable Mode
    SERVICE:
    0x02 16-bit Service UUIDs More 16-bit UUIDs available
    0x03 16-bit Service UUIDs Complete list of 16-bit UUIDs available
    0x04 32-bit Service UUIDs More 3a2-bit UUIDs available
    0x05 32-bit Service UUIDs Complete list of 32-bit UUIDs available
    0x06 128-bit Service UUIDs More 128-bit UUIDs available
    0x07 128-bit Service UUIDs Complete list of 128-bit UUIDs available
    
-------------------------------------original README of hackrf-------------------------------------

This repository contains hardware designs and software for HackRF, a project to
produce a low cost, open source software radio platform.

![Jawbreaker](https://raw.github.com/mossmann/hackrf/master/doc/jawbreaker-fd0-145436.jpeg)

(photo by fd0 from https://github.com/fd0/jawbreaker-pictures)

principal author: Michael Ossmann <mike@ossmann.com>

http://greatscottgadgets.com/hackrf/

-------------------------------------original README of bladeRF-------------------------------------

# bladeRF Source #
This repository contains all the source code required to program and interact with a bladeRF platform, including firmware for the Cypress FX3 USB controller, HDL for the Altera Cyclone IV FPGA, and C code for the host side libraries, drivers, and utilities.
The source is organized as follows:


| Directory         | Description                                                                                       |
| ----------------- |:--------------------------------------------------------------------------------------------------|
| [firmware_common] | Source and header files common between firmware and host software                                 |
| [fx3_firmware]    | Firmware for the Cypress FX3 USB controller                                                       |
| [hdl]             | All HDL code associated with the Cyclone IV FPGA                                                  |
| [host]            | Host-side libraries, drivers, utilities and samples                                               |


## Quick Start ##
1. Clone this repository via: ```git clone https://github.com/Nuand/bladeRF.git```
2. Fetch the latest pre-built bladeRF [FPGA image]. See the README.md in the [hdl] directory for more information.
3. Fetch the latest pre-built bladeRF [firmware image]. See the README.md in the [fx3_firmware] directory for more information.
4. Follow the instructions in the [host] directory to build and install libbladeRF and the bladeRF-cli utility.
5. Attach the bladeRF board to your fastest USB port.
6. You should now be able to see your device in the list output via ```bladeRF-cli -p```
7. You can view additional information about the device via ```bladeRF-cli -e info -e version```.
8. If any warnings indicate that a firmware update is needed, run:```bladeRF-cli -f <firmware_file>```. 
 - If you ever find the device booting into the FX3 bootloader (e.g., if you unplug the device in the middle of a firmware upgrade), see the ```recovery``` command in bladeRF-cli for additional details.
9. See the overview of the [bladeRF-cli] for more information about loading the FPGA and using the command line interface tool

For more information, see the [bladeRF wiki].

## Build Variables ##

Below are global options to choose which parts of the bladeRF project should
be built from the top level.  Please see the [fx3_firmware] and [host]
subdirectories for more specific options.

| Option                            | Description
| --------------------------------- |:--------------------------------------------------------------------------|
| -DENABLE_FX3_BUILD=\<ON/OFF\>     | Enables building the FX3 firmware. Default: OFF                           |                                   |
| -DENABLE_HOST_BUILD=\<ON/OFF\>    | Enables building the host library and utilities overall. Default: ON      |

[firmware_common]: ./firmware_common (Host-Firmware common files)
[fx3_firmware]: ./fx3_firmware (FX3 Firmware)
[hdl]: ./hdl (HDL)
[host]: ./host (Host)
[FPGA image]: https://www.nuand.com/fpga.php (Pre-built FPGA images)
[firmware image]: https://www.nuand.com/fx3.php (Pre-built firmware binaries)
[bladeRF-cli]: ./host/utilities/bladeRF-cli (bladeRF Command Line Interface)
[bladeRF wiki]: https://github.com/nuand/bladeRF/wiki (bladeRF wiki)

