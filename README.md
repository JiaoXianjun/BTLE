A BTLE (Bluetooth Low energy)/BT4.0 packet sender based on <a href="https://github.com/mossmann/hackrf">hackrf_transfer</a>

All link layer packet formats are supported. (Chapter 2&3, PartB, Volume 6, 
<a href="https://www.google.fi/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCAQFjAA&url=https%3A%2F%2Fwww.bluetooth.org%2Fdocman%2Fhandlers%2Fdownloaddoc.ashx%3Fdoc_id%3D229737&ei=ui3gU4GkC-up0AW4q4GwBw&usg=AFQjCNFY1IFeFAAWwimnoaWMsIRZQvPDSw&sig2=wTgMMxNPJ52NHclpsQ4XhQ&bvm=bv.72197243,d.d2k">Core_V4.0.pdf</a>   )

It can be used to transmit arbitrary BTLE signal/packet sequence, such as iBeacon, <a href="http://processors.wiki.ti.com/index.php/BLE_sniffer_guide">Connection establishment procedure</a> in TI's website, or any other purpose you want. See <a href="http://youtu.be/Y8ttV5AEb-g">video demo 1</a> (outside China) or <a href="http://v.youku.com/v_show/id_XNzUxMDIzNzAw.html">video demo 2</a> (inside China)

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

iBeacon examples:

    ./btle_tx 37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100 r10

Above command sends one packet and repeats it 10 times. The packet descriptor string:

    37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100

    37 -- channel 37 (one of BTLE Advertising channel 37 38 39)
    iBeacon -- packet format is for iBeacon. (Actually is ADV_IND format in Core_V4.0.pdf)
    AdvA -- Advertising address which is defined in Core_V4.0.pdf

-------------------------------------original README of hackrf-------------------------------------

This repository contains hardware designs and software for HackRF, a project to
produce a low cost, open source software radio platform.

![Jawbreaker](https://raw.github.com/mossmann/hackrf/master/doc/jawbreaker-fd0-145436.jpeg)

(photo by fd0 from https://github.com/fd0/jawbreaker-pictures)

principal author: Michael Ossmann <mike@ossmann.com>

http://greatscottgadgets.com/hackrf/
