// ***************************************************************************
// Xianjun jiao. putaoshu@msn.com
// based on Analog Devices HDL reference design. add necessary modules/modifications.
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  inout   [14:0]  ddr_addr,
  inout   [ 2:0]  ddr_ba,
  inout           ddr_cas_n,
  inout           ddr_ck_n,
  inout           ddr_ck_p,
  inout           ddr_cke,
  inout           ddr_cs_n,
  inout   [ 3:0]  ddr_dm,
  inout   [31:0]  ddr_dq,
  inout   [ 3:0]  ddr_dqs_n,
  inout   [ 3:0]  ddr_dqs_p,
  inout           ddr_odt,
  inout           ddr_ras_n,
  inout           ddr_reset_n,
  inout           ddr_we_n,

  inout           fixed_io_ddr_vrn,
  inout           fixed_io_ddr_vrp,
  inout   [53:0]  fixed_io_mio,
  inout           fixed_io_ps_clk,
  inout           fixed_io_ps_porb,
  inout           fixed_io_ps_srstb,

  inout           iic_scl,
  inout           iic_sda,

  inout   [10:0]  gpio_bd,

  input           rx_clk_in_p,
  input           rx_clk_in_n,
  input           rx_frame_in_p,
  input           rx_frame_in_n,
  input   [ 5:0]  rx_data_in_p,
  input   [ 5:0]  rx_data_in_n,
  output          tx_clk_out_p,
  output          tx_clk_out_n,
  output          tx_frame_out_p,
  output          tx_frame_out_n,
  output  [ 5:0]  tx_data_out_p,
  output  [ 5:0]  tx_data_out_n,

  output          enable,
  output          txnrx,
  input           clkout_in,
  output          clkout_out,

  inout           gpio_clksel,
  inout           gpio_resetb,
  inout           gpio_sync,
  inout           gpio_en_agc,
  inout   [ 3:0]  gpio_ctl,
  input   [ 7:0]  gpio_status,

  output          spi_csn,
  output          spi_clk,
  output          spi_mosi,
  input           spi_miso,
  
  output          rx1_band_sel_h,
  output          rx1_band_sel_l,
  output          tx1_band_sel_h,
  output          tx1_band_sel_l,
  output          rx2_band_sel_h,
  output          rx2_band_sel_l,
  output          tx2_band_sel_h,
  output          tx2_band_sel_l

  );


	// internal signals

	wire    [31:0]  gp_out_s;
	wire    [31:0]  gp_in_s;
	wire    [63:0]  gpio_i;
	wire    [63:0]  gpio_o;
	wire    [63:0]  gpio_t;
	wire    [7:0]   gpio_status_dummy;
	wire    [27:0]  gp_out;
	wire    [27:0]  gp_in;
	wire            rx1_band_sel_h;
	wire            rx1_band_sel_l;
	wire            tx1_band_sel_l;
	wire            tx1_band_sel_h;
	wire            rx2_band_sel_l;
	wire            rx2_band_sel_h;
	wire            tx2_band_sel_l;
	wire            tx2_band_sel_h;

	// assignments
	assign clkout_out = clkout_in;
	assign gp_out[27:0] = gp_out_s[27:0];
	assign gp_in_s[31:28] = gp_out_s[31:28];
	assign gp_in_s[27: 0] = gp_in[27:0];

	// the RF switch is fixed at the higher frequency range,
	// which means the RF switch pass only frequency at 3G~6G,
	// this could be improved by add RF swicth control in the 
	// devicetree, so that, the RF switch can chage with the 
	// lo frequency;
    assign rx1_band_sel_h = 1'b1;
    assign rx1_band_sel_l = 1'b0;
    assign tx1_band_sel_h = 1'b1;
    assign tx1_band_sel_l = 1'b0;
    assign rx2_band_sel_h = 1'b1;
    assign rx2_band_sel_l = 1'b0;
    assign tx2_band_sel_h = 1'b1;
    assign tx2_band_sel_l = 1'b0;

  // board gpio - 31-0

  assign gpio_i[31:11] = gpio_o[31:11];

  ad_iobuf #(.DATA_WIDTH(11)) i_iobuf_bd (
    .dio_t (gpio_t[10:0]),
    .dio_i (gpio_o[10:0]),
    .dio_o (gpio_i[10:0]),
    .dio_p (gpio_bd));

  // ad9361 gpio - 63-32

  assign gpio_i[63:52] = gpio_o[63:52];
  assign gpio_i[50:47] = gpio_o[50:47];

  ad_iobuf #(.DATA_WIDTH(16)) i_iobuf (
    .dio_t ({gpio_t[51], gpio_t[46:32]}),
    .dio_i ({gpio_o[51], gpio_o[46:32]}),
    .dio_o ({gpio_i[51], gpio_i[46:32]}),
    .dio_p ({ gpio_clksel,        // 51:51
              gpio_resetb,        // 46:46
              gpio_sync,          // 45:45
              gpio_en_agc,        // 44:44
              gpio_ctl,           // 43:40
              gpio_status_dummy}));     // 39:32

  // instantiations

  system_wrapper i_system_wrapper (
    .ddr_addr (ddr_addr),
    .ddr_ba (ddr_ba),
    .ddr_cas_n (ddr_cas_n),
    .ddr_ck_n (ddr_ck_n),
    .ddr_ck_p (ddr_ck_p),
    .ddr_cke (ddr_cke),
    .ddr_cs_n (ddr_cs_n),
    .ddr_dm (ddr_dm),
    .ddr_dq (ddr_dq),
    .ddr_dqs_n (ddr_dqs_n),
    .ddr_dqs_p (ddr_dqs_p),
    .ddr_odt (ddr_odt),
    .ddr_ras_n (ddr_ras_n),
    .ddr_reset_n (ddr_reset_n),
    .ddr_we_n (ddr_we_n),
    .enable (enable),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    .gp_in_0 (gp_in_s[31:0]),
    .gp_out_0 (gp_out_s[31:0]),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_status(gpio_status),
    .gpio_t (gpio_t),
    .gps_pps (1'b0),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),
    .otg_vbusoc (1'b0),
    .rx_clk_in_n (rx_clk_in_n),
    .rx_clk_in_p (rx_clk_in_p),
    .rx_data_in_n (rx_data_in_n),
    .rx_data_in_p (rx_data_in_p),
    .rx_frame_in_n (rx_frame_in_n),
    .rx_frame_in_p (rx_frame_in_p),
    .spi0_clk_i (1'b0),
    .spi0_clk_o (spi_clk),
    .spi0_csn_0_o (spi_csn),
    .spi0_csn_1_o (),
    .spi0_csn_2_o (),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (spi_miso),
    .spi0_sdo_i (1'b0),
    .spi0_sdo_o (spi_mosi),
    .spi1_clk_i (1'b0),
    .spi1_clk_o (),
    .spi1_csn_0_o (),
    .spi1_csn_1_o (),
    .spi1_csn_2_o (),
    .spi1_csn_i (1'b1),
    .spi1_sdi_i (1'b0),
    .spi1_sdo_i (1'b0),
    .spi1_sdo_o (),
    .tdd_sync_i (1'b0),
    .tdd_sync_o (),
    .tdd_sync_t (),
    .tx_clk_out_n (tx_clk_out_n),
    .tx_clk_out_p (tx_clk_out_p),
    .tx_data_out_n (tx_data_out_n),
    .tx_data_out_p (tx_data_out_p),
    .tx_frame_out_n (tx_frame_out_n),
    .tx_frame_out_p (tx_frame_out_p),
    .txnrx (txnrx),
    .up_enable (gpio_o[47]),
    .up_txnrx (gpio_o[48]));

endmodule

// ***************************************************************************
// ***************************************************************************
