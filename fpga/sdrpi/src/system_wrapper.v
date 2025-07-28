// Xianjun jiao. putaoshu@msn.com
// based on Xilinx Vivado auto generated script. add necessary modifications.
// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.

`timescale 1 ps / 1 ps

module system_wrapper
   (CLK125M_OUT,
    ENET1_GMII_RX_CLK_0,
    ENET1_GMII_TX_CLK_0,
    GMII_ETHERNET_1_0_col,
    GMII_ETHERNET_1_0_crs,
    GMII_ETHERNET_1_0_rx_dv,
    GMII_ETHERNET_1_0_rx_er,
    GMII_ETHERNET_1_0_rxd,
    GMII_ETHERNET_1_0_tx_en,
    GMII_ETHERNET_1_0_tx_er,
    GMII_ETHERNET_1_0_txd,
    MDIO_ETHERNET_1_0_mdc,
    MDIO_ETHERNET_1_0_mdio_io,
    ddr_addr,
    ddr_ba,
    ddr_cas_n,
    ddr_ck_n,
    ddr_ck_p,
    ddr_cke,
    ddr_cs_n,
    ddr_dm,
    ddr_dq,
    ddr_dqs_n,
    ddr_dqs_p,
    ddr_odt,
    ddr_ras_n,
    ddr_reset_n,
    ddr_we_n,
    enable,
    fixed_io_ddr_vrn,
    fixed_io_ddr_vrp,
    fixed_io_mio,
    fixed_io_ps_clk,
    fixed_io_ps_porb,
    fixed_io_ps_srstb,
    gp_in_0,
    gp_out_0,
    gpio_i,
    gpio_o,
    gpio_status,
    gpio_t,
    gps_pps,
    iic_main_scl_io,
    iic_main_sda_io,
    otg_vbusoc,
    rx_clk_in_n,
    rx_clk_in_p,
    rx_data_in_n,
    rx_data_in_p,
    rx_frame_in_n,
    rx_frame_in_p,
    spi0_clk_i,
    spi0_clk_o,
    spi0_csn_0_o,
    spi0_csn_1_o,
    spi0_csn_2_o,
    spi0_csn_i,
    spi0_sdi_i,
    spi0_sdo_i,
    spi0_sdo_o,
    spi1_clk_i,
    spi1_clk_o,
    spi1_csn_0_o,
    spi1_csn_1_o,
    spi1_csn_2_o,
    spi1_csn_i,
    spi1_sdi_i,
    spi1_sdo_i,
    spi1_sdo_o,
    tdd_sync_i,
    tdd_sync_o,
    tdd_sync_t,
    tx_clk_out_n,
    tx_clk_out_p,
    tx_data_out_n,
    tx_data_out_p,
    tx_frame_out_n,
    tx_frame_out_p,
    txnrx,
    up_enable,
    up_txnrx);
  output CLK125M_OUT;
  input ENET1_GMII_RX_CLK_0;
  input ENET1_GMII_TX_CLK_0;
  input GMII_ETHERNET_1_0_col;
  input GMII_ETHERNET_1_0_crs;
  input GMII_ETHERNET_1_0_rx_dv;
  input GMII_ETHERNET_1_0_rx_er;
  input [7:0]GMII_ETHERNET_1_0_rxd;
  output [0:0]GMII_ETHERNET_1_0_tx_en;
  output [0:0]GMII_ETHERNET_1_0_tx_er;
  output [7:0]GMII_ETHERNET_1_0_txd;
  output MDIO_ETHERNET_1_0_mdc;
  inout MDIO_ETHERNET_1_0_mdio_io;
  inout [14:0]ddr_addr;
  inout [2:0]ddr_ba;
  inout ddr_cas_n;
  inout ddr_ck_n;
  inout ddr_ck_p;
  inout ddr_cke;
  inout ddr_cs_n;
  inout [3:0]ddr_dm;
  inout [31:0]ddr_dq;
  inout [3:0]ddr_dqs_n;
  inout [3:0]ddr_dqs_p;
  inout ddr_odt;
  inout ddr_ras_n;
  inout ddr_reset_n;
  inout ddr_we_n;
  output enable;
  inout fixed_io_ddr_vrn;
  inout fixed_io_ddr_vrp;
  inout [53:0]fixed_io_mio;
  inout fixed_io_ps_clk;
  inout fixed_io_ps_porb;
  inout fixed_io_ps_srstb;
  input [31:0]gp_in_0;
  output [31:0]gp_out_0;
  input [63:0]gpio_i;
  output [63:0]gpio_o;
  input [7:0]gpio_status;
  output [63:0]gpio_t;
  input gps_pps;
  inout iic_main_scl_io;
  inout iic_main_sda_io;
  input otg_vbusoc;
  input rx_clk_in_n;
  input rx_clk_in_p;
  input [5:0]rx_data_in_n;
  input [5:0]rx_data_in_p;
  input rx_frame_in_n;
  input rx_frame_in_p;
  input spi0_clk_i;
  output spi0_clk_o;
  output spi0_csn_0_o;
  output spi0_csn_1_o;
  output spi0_csn_2_o;
  input spi0_csn_i;
  input spi0_sdi_i;
  input spi0_sdo_i;
  output spi0_sdo_o;
  input spi1_clk_i;
  output spi1_clk_o;
  output spi1_csn_0_o;
  output spi1_csn_1_o;
  output spi1_csn_2_o;
  input spi1_csn_i;
  input spi1_sdi_i;
  input spi1_sdo_i;
  output spi1_sdo_o;
  input tdd_sync_i;
  output tdd_sync_o;
  output tdd_sync_t;
  output tx_clk_out_n;
  output tx_clk_out_p;
  output [5:0]tx_data_out_n;
  output [5:0]tx_data_out_p;
  output tx_frame_out_n;
  output tx_frame_out_p;
  output txnrx;
  input up_enable;
  input up_txnrx;

  wire CLK125M_OUT;
  wire ENET1_GMII_RX_CLK_0;
  wire ENET1_GMII_TX_CLK_0;
  wire GMII_ETHERNET_1_0_col;
  wire GMII_ETHERNET_1_0_crs;
  wire GMII_ETHERNET_1_0_rx_dv;
  wire GMII_ETHERNET_1_0_rx_er;
  wire [7:0]GMII_ETHERNET_1_0_rxd;
  wire [0:0]GMII_ETHERNET_1_0_tx_en;
  wire [0:0]GMII_ETHERNET_1_0_tx_er;
  wire [7:0]GMII_ETHERNET_1_0_txd;
  wire MDIO_ETHERNET_1_0_mdc;
  wire MDIO_ETHERNET_1_0_mdio_i;
  wire MDIO_ETHERNET_1_0_mdio_io;
  wire MDIO_ETHERNET_1_0_mdio_o;
  wire MDIO_ETHERNET_1_0_mdio_t;
  wire [14:0]ddr_addr;
  wire [2:0]ddr_ba;
  wire ddr_cas_n;
  wire ddr_ck_n;
  wire ddr_ck_p;
  wire ddr_cke;
  wire ddr_cs_n;
  wire [3:0]ddr_dm;
  wire [31:0]ddr_dq;
  wire [3:0]ddr_dqs_n;
  wire [3:0]ddr_dqs_p;
  wire ddr_odt;
  wire ddr_ras_n;
  wire ddr_reset_n;
  wire ddr_we_n;
  wire enable;
  wire fixed_io_ddr_vrn;
  wire fixed_io_ddr_vrp;
  wire [53:0]fixed_io_mio;
  wire fixed_io_ps_clk;
  wire fixed_io_ps_porb;
  wire fixed_io_ps_srstb;
  wire [31:0]gp_in_0;
  wire [31:0]gp_out_0;
  wire [63:0]gpio_i;
  wire [63:0]gpio_o;
  wire [7:0]gpio_status;
  wire [63:0]gpio_t;
  wire gps_pps;
  wire iic_main_scl_i;
  wire iic_main_scl_io;
  wire iic_main_scl_o;
  wire iic_main_scl_t;
  wire iic_main_sda_i;
  wire iic_main_sda_io;
  wire iic_main_sda_o;
  wire iic_main_sda_t;
  wire otg_vbusoc;
  wire rx_clk_in_n;
  wire rx_clk_in_p;
  wire [5:0]rx_data_in_n;
  wire [5:0]rx_data_in_p;
  wire rx_frame_in_n;
  wire rx_frame_in_p;
  wire spi0_clk_i;
  wire spi0_clk_o;
  wire spi0_csn_0_o;
  wire spi0_csn_1_o;
  wire spi0_csn_2_o;
  wire spi0_csn_i;
  wire spi0_sdi_i;
  wire spi0_sdo_i;
  wire spi0_sdo_o;
  wire spi1_clk_i;
  wire spi1_clk_o;
  wire spi1_csn_0_o;
  wire spi1_csn_1_o;
  wire spi1_csn_2_o;
  wire spi1_csn_i;
  wire spi1_sdi_i;
  wire spi1_sdo_i;
  wire spi1_sdo_o;
  wire tdd_sync_i;
  wire tdd_sync_o;
  wire tdd_sync_t;
  wire tx_clk_out_n;
  wire tx_clk_out_p;
  wire [5:0]tx_data_out_n;
  wire [5:0]tx_data_out_p;
  wire tx_frame_out_n;
  wire tx_frame_out_p;
  wire txnrx;
  wire up_enable;
  wire up_txnrx;

  IOBUF MDIO_ETHERNET_1_0_mdio_iobuf
       (.I(MDIO_ETHERNET_1_0_mdio_o),
        .IO(MDIO_ETHERNET_1_0_mdio_io),
        .O(MDIO_ETHERNET_1_0_mdio_i),
        .T(MDIO_ETHERNET_1_0_mdio_t));
  IOBUF iic_main_scl_iobuf
       (.I(iic_main_scl_o),
        .IO(iic_main_scl_io),
        .O(iic_main_scl_i),
        .T(iic_main_scl_t));
  IOBUF iic_main_sda_iobuf
       (.I(iic_main_sda_o),
        .IO(iic_main_sda_io),
        .O(iic_main_sda_i),
        .T(iic_main_sda_t));
  system system_i
       (.CLK125M_OUT(CLK125M_OUT),
        .ENET1_GMII_RX_CLK_0(ENET1_GMII_RX_CLK_0),
        .ENET1_GMII_TX_CLK_0(ENET1_GMII_TX_CLK_0),
        .GMII_ETHERNET_1_0_col(GMII_ETHERNET_1_0_col),
        .GMII_ETHERNET_1_0_crs(GMII_ETHERNET_1_0_crs),
        .GMII_ETHERNET_1_0_rx_dv(GMII_ETHERNET_1_0_rx_dv),
        .GMII_ETHERNET_1_0_rx_er(GMII_ETHERNET_1_0_rx_er),
        .GMII_ETHERNET_1_0_rxd(GMII_ETHERNET_1_0_rxd),
        .GMII_ETHERNET_1_0_tx_en(GMII_ETHERNET_1_0_tx_en),
        .GMII_ETHERNET_1_0_tx_er(GMII_ETHERNET_1_0_tx_er),
        .GMII_ETHERNET_1_0_txd(GMII_ETHERNET_1_0_txd),
        .MDIO_ETHERNET_1_0_mdc(MDIO_ETHERNET_1_0_mdc),
        .MDIO_ETHERNET_1_0_mdio_i(MDIO_ETHERNET_1_0_mdio_i),
        .MDIO_ETHERNET_1_0_mdio_o(MDIO_ETHERNET_1_0_mdio_o),
        .MDIO_ETHERNET_1_0_mdio_t(MDIO_ETHERNET_1_0_mdio_t),
        .ddr_addr(ddr_addr),
        .ddr_ba(ddr_ba),
        .ddr_cas_n(ddr_cas_n),
        .ddr_ck_n(ddr_ck_n),
        .ddr_ck_p(ddr_ck_p),
        .ddr_cke(ddr_cke),
        .ddr_cs_n(ddr_cs_n),
        .ddr_dm(ddr_dm),
        .ddr_dq(ddr_dq),
        .ddr_dqs_n(ddr_dqs_n),
        .ddr_dqs_p(ddr_dqs_p),
        .ddr_odt(ddr_odt),
        .ddr_ras_n(ddr_ras_n),
        .ddr_reset_n(ddr_reset_n),
        .ddr_we_n(ddr_we_n),
        .enable(enable),
        .fixed_io_ddr_vrn(fixed_io_ddr_vrn),
        .fixed_io_ddr_vrp(fixed_io_ddr_vrp),
        .fixed_io_mio(fixed_io_mio),
        .fixed_io_ps_clk(fixed_io_ps_clk),
        .fixed_io_ps_porb(fixed_io_ps_porb),
        .fixed_io_ps_srstb(fixed_io_ps_srstb),
        .gp_in_0(gp_in_0),
        .gp_out_0(gp_out_0),
        .gpio_i(gpio_i),
        .gpio_o(gpio_o),
        .gpio_status(gpio_status),
        .gpio_t(gpio_t),
        .gps_pps(gps_pps),
        .iic_main_scl_i(iic_main_scl_i),
        .iic_main_scl_o(iic_main_scl_o),
        .iic_main_scl_t(iic_main_scl_t),
        .iic_main_sda_i(iic_main_sda_i),
        .iic_main_sda_o(iic_main_sda_o),
        .iic_main_sda_t(iic_main_sda_t),
        .otg_vbusoc(otg_vbusoc),
        .rx_clk_in_n(rx_clk_in_n),
        .rx_clk_in_p(rx_clk_in_p),
        .rx_data_in_n(rx_data_in_n),
        .rx_data_in_p(rx_data_in_p),
        .rx_frame_in_n(rx_frame_in_n),
        .rx_frame_in_p(rx_frame_in_p),
        .spi0_clk_i(spi0_clk_i),
        .spi0_clk_o(spi0_clk_o),
        .spi0_csn_0_o(spi0_csn_0_o),
        .spi0_csn_1_o(spi0_csn_1_o),
        .spi0_csn_2_o(spi0_csn_2_o),
        .spi0_csn_i(spi0_csn_i),
        .spi0_sdi_i(spi0_sdi_i),
        .spi0_sdo_i(spi0_sdo_i),
        .spi0_sdo_o(spi0_sdo_o),
        .spi1_clk_i(spi1_clk_i),
        .spi1_clk_o(spi1_clk_o),
        .spi1_csn_0_o(spi1_csn_0_o),
        .spi1_csn_1_o(spi1_csn_1_o),
        .spi1_csn_2_o(spi1_csn_2_o),
        .spi1_csn_i(spi1_csn_i),
        .spi1_sdi_i(spi1_sdi_i),
        .spi1_sdo_i(spi1_sdo_i),
        .spi1_sdo_o(spi1_sdo_o),
        .tdd_sync_i(tdd_sync_i),
        .tdd_sync_o(tdd_sync_o),
        .tdd_sync_t(tdd_sync_t),
        .tx_clk_out_n(tx_clk_out_n),
        .tx_clk_out_p(tx_clk_out_p),
        .tx_data_out_n(tx_data_out_n),
        .tx_data_out_p(tx_data_out_p),
        .tx_frame_out_n(tx_frame_out_n),
        .tx_frame_out_p(tx_frame_out_p),
        .txnrx(txnrx),
        .up_enable(up_enable),
        .up_txnrx(up_txnrx));
endmodule
