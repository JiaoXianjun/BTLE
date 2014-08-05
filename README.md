A BTLE (Bluetooth Low energy)/BT4.0 packet sender based on <a href="https://github.com/mossmann/hackrf">hackrf_transfer</a>

All link layer packet formats are supported. (Chapter 2&3, PartB, Volume 6, 
<a href="https://www.google.fi/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCAQFjAA&url=https%3A%2F%2Fwww.bluetooth.org%2Fdocman%2Fhandlers%2Fdownloaddoc.ashx%3Fdoc_id%3D229737&ei=ui3gU4GkC-up0AW4q4GwBw&usg=AFQjCNFY1IFeFAAWwimnoaWMsIRZQvPDSw&sig2=wTgMMxNPJ52NHclpsQ4XhQ&bvm=bv.72197243,d.d2k">Core_V4.0.pdf</a>   )

It can be used to transmit arbitrary pre-defined BTLE signal/packet sequence, such as iBeacon, <a href="http://processors.wiki.ti.com/index.php/BLE_sniffer_guide">Connection establishment procedure</a> in TI's website, or any other purpose you want (Together with TI's packet sniffer, you will have full abilities). See <a href="http://youtu.be/Y8ttV5AEb-g">video demo 1</a> (outside China) or <a href="http://v.youku.com/v_show/id_XNzUxMDIzNzAw.html">video demo 2</a> (inside China)

Build:

    cd host
    mkdir build
    cd build
    cmake ../
    make
    sudo make install  (or not install, just use btle_tx in hackrf-tools/src)

Usage method 1:

    btle_tx packet1 packet2 ... packetX ...  rN

Usage method 2:

    btle_tx packets.txt

In method 2, just thoe command line parameters (packet1 ... rN) in method 1 are written/grouped in a .txt file as input of btle_tx. One parameter one line. A line start with "#" is regarded as comment.

"packetX" is one string which describes one packet. All packets composes a sequence of packets.

"rN" means the sequence will be repeated for N times. If it is not specified, the sequence will only be sent once.

iBeacon example: (iBeacon principle: http://www.warski.org/blog/2014/01/how-ibeacons-work/ )

    ./btle_tx 37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100 r100

Above command sends one packet and repeats it 100 times with 100ms time space (If you have "Locate" app in your iPhone/iPad, it will show the iBeacon info.). The packet descriptor string:

    37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100

    37 -- channel 37 (one of BTLE Advertising channel 37 38 39)
    iBeacon -- packet format is for iBeacon. (Actually is ADV_IND format in Core_V4.0.pdf)
    AdvA -- Advertising address (MAC address) which is specified as 010203040506 (See Core_V4.0.pdf)
    UUID -- here we specify it as Estimote’s fixed UUID: B9407F30F5F8466EAFF925556B57FE6D
    Major -- major number of iBeacon format. (Here it is 0008)
    Minor -- minor number of iBeacon format. (Here it is 0009)
    Txpower -- transmit power parameter of iBeacon format (Here it is C5)
    Space -- How many millisecond whould be waited after this packet sent. (Here it is 100ms)

Connection establishment example: (See "Connection establishment" part of http://processors.wiki.ti.com/index.php/BLE_sniffer_guide )

    ./btle_tx 37-ADV_IND-TxAdd-0-RxAdd-0-AdvA-90D7EBB19299-AdvData-0201050702031802180418-Space-100  37-CONNECT_REQ-TxAdd-0-RxAdd-0-InitA-001830EA965F-AdvA-90D7EBB19299-AA-60850A1B-CRCInit-A77B22-WinSize-02-WinOffset-000F-Interval-0050-Latency-0000-Timeout-07D0-ChM-1FFFFFFFFF-Hop-9-SCA-5-Space-100 9-LL_DATA-AA-60850A1B-LLID-1-NESN-0-SN-0-MD-0-DATA-X-CRCInit-A77B22-Space-100
    
    Above simualtes a Connection establishment procedure between device 1 and device 2.
    the 1st packet -- device 1 sends ADV_IND packet in channel 37.
    the 2nd packet -- After device 2 which is in scanning state receives the ADV packet, device 2 sends CONNECT_REQ packet to request connection setup with device 1. In this request packet, there are device 2 MAC address (InitA), target MAC address (device 1 MAC address AdvA), Access address (AA), CRC initilization
-------------------------------------original README of hackrf-------------------------------------

This repository contains hardware designs and software for HackRF, a project to
produce a low cost, open source software radio platform.

![Jawbreaker](https://raw.github.com/mossmann/hackrf/master/doc/jawbreaker-fd0-145436.jpeg)

(photo by fd0 from https://github.com/fd0/jawbreaker-pictures)

principal author: Michael Ossmann <mike@ossmann.com>

http://greatscottgadgets.com/hackrf/
