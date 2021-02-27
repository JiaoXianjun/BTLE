./btle_tx welcom_packets_discovery.txt

copy above command generated IQ_sample_for_matlab.txt into variable "c" of gen_float32_bin_for_usrp_replay.m.

run .m script in matlab or octave

replay above script generated btle_ch37_iq_float32_welcom_msg.bin in replay_for_btle_4Msps.grc.

Install LightBlue in your iPhone or other similar things of Android, and open the App.

You will see a welcome message "SDR Bluetooth LE welcome u!" on your phone.
