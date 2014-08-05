A BTLE (Bluetooth Low energy)/BT4.0 packet sender based on <a href="https://github.com/mossmann/hackrf">hackrf_transfer</a>

All link layer packet formats are supported. (Chapter 2&3, PartB, Volume 6, 
<a href="https://www.google.fi/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCAQFjAA&url=https%3A%2F%2Fwww.bluetooth.org%2Fdocman%2Fhandlers%2Fdownloaddoc.ashx%3Fdoc_id%3D229737&ei=ui3gU4GkC-up0AW4q4GwBw&usg=AFQjCNFY1IFeFAAWwimnoaWMsIRZQvPDSw&sig2=wTgMMxNPJ52NHclpsQ4XhQ&bvm=bv.72197243,d.d2k">Core_V4.0.pdf</a>   )

It can be used to transmit arbitrary BTLE signal/packet, such as iBeacon, <a href="http://processors.wiki.ti.com/index.php/BLE_sniffer_guide">Connection establishment procedure</a> in TI's website, or any other purpose you want. See video demo <a href="http://youtu.be/Y8ttV5AEb-g">1</a> (outside China) or <a href="http://v.youku.com/v_show/id_XNzUxMDIzNzAw.html">2</a> (inside China)

usage:

way 1:  btle_tx packet1 packet2 packet3 ... packetM rN

way 2:  btle_tx packets.txt



-------------------------------------original README of hackrf-------------------------------------

This repository contains hardware designs and software for HackRF, a project to
produce a low cost, open source software radio platform.

![Jawbreaker](https://raw.github.com/mossmann/hackrf/master/doc/jawbreaker-fd0-145436.jpeg)

(photo by fd0 from https://github.com/fd0/jawbreaker-pictures)

principal author: Michael Ossmann <mike@ossmann.com>

http://greatscottgadgets.com/hackrf/
