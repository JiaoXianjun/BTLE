// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// btle_controller = btle_ll (link layer) + btle_phy (phy: btle_tx and btle_rx)

// iverilog -o btle_controller btle_controller.v clock_domain_conversion_iq.v ./btle_ll/hw/fpga/btle_ll_stub.v btle_phy.v btle_rx.v btle_rx_core.v gfsk_demodulation.v search_unique_bit_sequence.v scramble_core.v crc24_core.v serial_in_ram_out.v sdpram_two_clk.v sdpram_one_clk.v btle_tx.v crc24.v scramble.v gfsk_modulation.v bit_repeat_upsample.v gauss_filter.v vco.v

`define KEEP_FOR_DBG (*mark_debug="true",DONT_TOUCH="TRUE"*)

`timescale 1ns / 1ps
module btle_controller #
(
  // Width of S_AXI data bus
  parameter integer C_S00_AXI_DATA_WIDTH  = 32,
  // Width of S_AXI address bus
  parameter integer C_S00_AXI_ADDR_WIDTH  = 8,

  // parameter	CLK_FREQUENCE	= 16_000_000,	//hz
  parameter	CLK_FREQUENCE	= 100_000_000,	//hz
  parameter BAUD_RATE		= 115200		,		  //9600、19200 、38400 、57600 、115200、230400、460800、921600
  parameter PARITY			= "NONE"	,		  //"NONE","EVEN","ODD"
  parameter FRAME_WD		= 8,					    //if PARITY="NONE",it can be 5~9;else 5~8

  parameter RF_IQ_BIT_WIDTH = 64,
  parameter RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4),

  parameter CRC_STATE_BIT_WIDTH = 24,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter SAMPLE_PER_SYMBOL = 8,
  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter NUM_TAP_GAUSS_FILTER = 17,
  parameter VCO_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8,
  parameter GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1,

  parameter GFSK_DEMODULATION_BIT_WIDTH = 16,
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32
) (
  input  wire rf_clk,
  input  wire rf_rst,

  input  wire bb_clk,
  input  wire bb_rst,

  // ===============Auxiliary Signals================
  `KEEP_FOR_DBG input  wire [7:0] gpio,
  `KEEP_FOR_DBG output wire [15:0] ll_gpio,
  output wire ll_itrpt0,
  output wire ll_itrpt1,
  output wire ll_itrpt2,
  output wire ll_itrpt3,
  output wire ll_itrpt4,
  output wire ll_itrpt5,
  output wire ll_itrpt6,
  output wire ll_itrpt7,

  // ============================to host: UART HCI=========================
  input  wire uart_rx,
  output wire uart_tx,

  // =========================to zero-IF RF transceiver====================
  `KEEP_FOR_DBG input wire [7:0]         rf_gpio,
  `KEEP_FOR_DBG output wire [(RF_IQ_BIT_WIDTH-1) : 0]  tx_iq_signal_ext,
  `KEEP_FOR_DBG output wire                            tx_iq_valid_ext,
  `KEEP_FOR_DBG output wire                            tx_iq_valid_last_ext,

  `KEEP_FOR_DBG input  wire  [(RF_IQ_BIT_WIDTH-1) : 0] rx_iq_signal_ext,
  `KEEP_FOR_DBG input  wire                            rx_iq_valid_ext,

  // Ports of Axi Slave Bus Interface
  input  wire s00_axi_aclk,
  input  wire s00_axi_aresetn,
  input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
  input  wire [2 : 0] s00_axi_awprot,
  input  wire s00_axi_awvalid,
  output wire s00_axi_awready,
  input  wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
  input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
  input  wire s00_axi_wvalid,
  output wire s00_axi_wready,
  output wire [1 : 0] s00_axi_bresp,
  output wire s00_axi_bvalid,
  input  wire s00_axi_bready,
  input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
  input  wire [2 : 0] s00_axi_arprot,
  input  wire s00_axi_arvalid,
  output wire s00_axi_arready,
  output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
  output wire [1 : 0] s00_axi_rresp,
  output wire s00_axi_rvalid,
  input  wire s00_axi_rready,

  // ====baremetal phy interface. should be via uart in the future====
  input wire baremetal_phy_intf_mode, //currently 1 for external access. should be 0 in the future to let btle_ll control phy

  // for phy tx
  input wire [3:0]                                   ext_tx_gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  input wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] ext_tx_gauss_filter_tap_value,

  input wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]   ext_tx_cos_table_write_address,
  input wire signed [(IQ_BIT_WIDTH-1) : 0]      ext_tx_cos_table_write_data,
  input wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0]   ext_tx_sin_table_write_address,
  input wire signed [(IQ_BIT_WIDTH-1) : 0]      ext_tx_sin_table_write_data,

  input wire [7:0]                              ext_tx_preamble,

  input wire [31:0]                             ext_tx_access_address,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0]      ext_tx_crc_state_init_bit,
  input wire                                    ext_tx_crc_state_init_bit_load,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ext_tx_channel_number,
  input wire                                    ext_tx_channel_number_load,

  input wire [7:0]                              ext_tx_pdu_octet_mem_data,
  input wire [5:0]                              ext_tx_pdu_octet_mem_addr,

  input wire                                    ext_tx_start,

  // for phy tx debug purpose
  output wire ext_tx_phy_bit,
  output wire ext_tx_phy_bit_valid,
  output wire ext_tx_phy_bit_valid_last,

  output wire ext_tx_bit_upsample,
  output wire ext_tx_bit_upsample_valid,
  output wire ext_tx_bit_upsample_valid_last,

  output wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] ext_tx_bit_upsample_gauss_filter,
  output wire ext_tx_bit_upsample_gauss_filter_valid,
  output wire ext_tx_bit_upsample_gauss_filter_valid_last,

  // for phy rx
  input wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  ext_rx_unique_bit_sequence,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ext_rx_channel_number,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0]      ext_rx_crc_state_init_bit,

  `KEEP_FOR_DBG output wire        ext_rx_hit_flag,
  `KEEP_FOR_DBG output wire        ext_rx_decode_run,
  `KEEP_FOR_DBG output wire        ext_rx_decode_end,
  `KEEP_FOR_DBG output wire        ext_rx_crc_ok,
  `KEEP_FOR_DBG output wire  [2:0] ext_rx_best_phase,
  `KEEP_FOR_DBG output wire  [6:0] ext_rx_payload_length,

  input  wire  [5:0] ext_rx_pdu_octet_mem_addr,
  `KEEP_FOR_DBG output wire  [7:0] ext_rx_pdu_octet_mem_data
);

// =================intermediate IQ defines===================
wire signed [(IQ_BIT_WIDTH-1) : 0]                tx_i_signal;
wire signed [(IQ_BIT_WIDTH-1) : 0]                tx_q_signal;
wire                                              tx_iq_valid;
wire                                              tx_iq_valid_last;

`KEEP_FOR_DBG wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_i_signal;
`KEEP_FOR_DBG wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_q_signal;
`KEEP_FOR_DBG wire                                              rx_iq_valid;
`KEEP_FOR_DBG wire [7:0]                                        bb_gpio;
`KEEP_FOR_DBG wire [RF_I_OR_Q_BIT_WIDTH : 0]                    i_abs_add_q_abs;
`KEEP_FOR_DBG wire                                              agc_lock_change;
`KEEP_FOR_DBG wire                                              agc_lock_state;
`KEEP_FOR_DBG wire [6:0]                                        rf_gain;

// =================link layer and auxiliary==================
// `KEEP_FOR_DBG wire [15:0] ll_reg_gpio;

wire slv_reg_rden;
wire [4:0] axi_araddr_core;

`KEEP_FOR_DBG wire slv_reg_wren;
`KEEP_FOR_DBG wire [4:0] axi_awaddr_core;

// =================link layer to phy tx======================
wire [3:0] ll_tx_gauss_filter_tap_index;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] ll_tx_gauss_filter_tap_value;

wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ll_tx_cos_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0]    ll_tx_cos_table_write_data;
wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ll_tx_sin_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0]    ll_tx_sin_table_write_data;

wire [7:0]  ll_tx_preamble;

wire [31:0] ll_tx_access_address;
wire [(CRC_STATE_BIT_WIDTH-1) : 0]      ll_tx_crc_state_init_bit;
wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ll_tx_channel_number;

wire [7:0] ll_tx_pdu_octet_mem_data;
wire [5:0] ll_tx_pdu_octet_mem_addr;
wire ll_tx_start;

// ===========================phy tx=========================
wire [3:0] tx_gauss_filter_tap_index;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value;

wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0]    tx_cos_table_write_data;
wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0]    tx_sin_table_write_data;

wire [7:0]  tx_preamble;

wire [31:0] tx_access_address;
wire [(CRC_STATE_BIT_WIDTH-1) : 0] tx_crc_state_init_bit;
wire tx_crc_state_init_bit_load;
wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number;
wire tx_channel_number_load;

wire [7:0] tx_pdu_octet_mem_data;
wire [5:0] tx_pdu_octet_mem_addr;
wire tx_start;

// ==============link layer to phy rx=======================
wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  ll_rx_unique_bit_sequence;
wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ll_rx_channel_number;
wire [(CRC_STATE_BIT_WIDTH-1) : 0]      ll_rx_crc_state_init_bit;

wire  [5:0] ll_rx_pdu_octet_mem_addr;

// =======================phy rx============================
`KEEP_FOR_DBG wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence;
`KEEP_FOR_DBG wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number;
`KEEP_FOR_DBG wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit;

`KEEP_FOR_DBG wire  [5:0] rx_pdu_octet_mem_addr;

// =======switch between external baremetal phy control and link layer phy control========
// phy tx
assign tx_gauss_filter_tap_index = (baremetal_phy_intf_mode? ext_tx_gauss_filter_tap_index : ll_tx_gauss_filter_tap_index);
assign tx_gauss_filter_tap_value = (baremetal_phy_intf_mode? ext_tx_gauss_filter_tap_value : ll_tx_gauss_filter_tap_value);

assign tx_cos_table_write_address = (baremetal_phy_intf_mode? ext_tx_cos_table_write_address : ll_tx_cos_table_write_address);
assign tx_cos_table_write_data = (baremetal_phy_intf_mode? ext_tx_cos_table_write_data : ll_tx_cos_table_write_data);
assign tx_sin_table_write_address = (baremetal_phy_intf_mode? ext_tx_sin_table_write_address : ll_tx_sin_table_write_address);
assign tx_sin_table_write_data = (baremetal_phy_intf_mode? ext_tx_sin_table_write_data : ll_tx_sin_table_write_data);

assign tx_preamble = (baremetal_phy_intf_mode? ext_tx_preamble : ll_tx_preamble);

assign tx_access_address = (baremetal_phy_intf_mode? ext_tx_access_address : ll_tx_access_address);
assign tx_crc_state_init_bit = (baremetal_phy_intf_mode? ext_tx_crc_state_init_bit : ll_tx_crc_state_init_bit);
assign tx_crc_state_init_bit_load = (baremetal_phy_intf_mode? ext_tx_crc_state_init_bit_load : ll_tx_start);
assign tx_channel_number = (baremetal_phy_intf_mode? ext_tx_channel_number : ll_tx_channel_number);
assign tx_channel_number_load = (baremetal_phy_intf_mode? ext_tx_channel_number_load : ll_tx_start);

assign tx_pdu_octet_mem_data = (baremetal_phy_intf_mode? ext_tx_pdu_octet_mem_data : ll_tx_pdu_octet_mem_data);
assign tx_pdu_octet_mem_addr = (baremetal_phy_intf_mode? ext_tx_pdu_octet_mem_addr : ll_tx_pdu_octet_mem_addr);
assign tx_start = (baremetal_phy_intf_mode? ext_tx_start : ll_tx_start);

// phy rx
assign rx_unique_bit_sequence = (baremetal_phy_intf_mode? ext_rx_unique_bit_sequence : ll_rx_unique_bit_sequence);
assign rx_channel_number = (baremetal_phy_intf_mode? ext_rx_channel_number : ll_rx_channel_number);
assign rx_crc_state_init_bit = (baremetal_phy_intf_mode? ext_rx_crc_state_init_bit : ll_rx_crc_state_init_bit);

assign rx_pdu_octet_mem_addr = (baremetal_phy_intf_mode? ext_rx_pdu_octet_mem_addr : ll_rx_pdu_octet_mem_addr);

clock_domain_conversion_iq #
(
  .RF_IQ_BIT_WIDTH(RF_IQ_BIT_WIDTH),
  .RF_I_OR_Q_BIT_WIDTH(RF_I_OR_Q_BIT_WIDTH),

  .IQ_BIT_WIDTH(IQ_BIT_WIDTH),

  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH)
) clock_domain_conversion_iq_i (
  .rf_clk(rf_clk), // ad9361 8MHz rf clock
  .rf_rst(rf_rst),

  .bb_clk(bb_clk), // bb 16MHz clock
  .bb_rst(bb_rst),

  // rx path
  .rf_gpio(rf_gpio),
  .rx_iq_signal_ext(rx_iq_signal_ext),
  .rx_iq_valid_ext(rx_iq_valid_ext),

  .rx_i_signal(rx_i_signal),
  .rx_q_signal(rx_q_signal),
  .rx_iq_valid(rx_iq_valid),
  .bb_gpio(bb_gpio),

  // tx path
  .tx_i_signal(tx_i_signal),
  .tx_q_signal(tx_q_signal),
  .tx_iq_valid(tx_iq_valid),
  .tx_iq_valid_last(tx_iq_valid_last),

  .tx_iq_signal_ext(tx_iq_signal_ext),
  .tx_iq_valid_ext(tx_iq_valid_ext),
  .tx_iq_valid_last_ext(tx_iq_valid_last_ext)
);

auxiliary_daemon #
(
  .RF_IQ_BIT_WIDTH(RF_IQ_BIT_WIDTH),
  .RF_I_OR_Q_BIT_WIDTH(RF_I_OR_Q_BIT_WIDTH),

  .IQ_BIT_WIDTH(IQ_BIT_WIDTH),

  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH)
) auxiliary_daemon_i (
  .bb_clk(bb_clk), // bb 16MHz clock
  .bb_rst(bb_rst),

  .rx_i_signal(rx_i_signal), // bb 16MHz clock
  .rx_q_signal(rx_q_signal),
  .rx_iq_valid(rx_iq_valid),
  .bb_gpio(bb_gpio),

  .i_abs_add_q_abs(i_abs_add_q_abs),
  .agc_lock_change(agc_lock_change),
  .agc_lock_state(agc_lock_state),
  .rf_gain(rf_gain)
);

btle_ll btle_ll_i (
  .bb_clk(bb_clk),
  .bb_rst(bb_rst),

  .ref_1pps(gpio[0]),

  // ====to host: UART HCI====
  .uart_rx(uart_rx),
  .uart_tx(uart_tx),

  // ====to phy tx====
  .tx_gauss_filter_tap_index (ll_tx_gauss_filter_tap_index), // only need to set 0~8, 9~16 will be mirror of 0~7
  .tx_gauss_filter_tap_value (ll_tx_gauss_filter_tap_value),

  .tx_cos_table_write_address(ll_tx_cos_table_write_address),
  .tx_cos_table_write_data   (ll_tx_cos_table_write_data),
  .tx_sin_table_write_address(ll_tx_sin_table_write_address),
  .tx_sin_table_write_data   (ll_tx_sin_table_write_data),

  .tx_preamble(ll_tx_preamble),

  .tx_access_address    (ll_tx_access_address),
  .tx_crc_state_init_bit(ll_tx_crc_state_init_bit),
  .tx_channel_number    (ll_tx_channel_number),

  .tx_pdu_octet_mem_data(ll_tx_pdu_octet_mem_data),
  .tx_pdu_octet_mem_addr(ll_tx_pdu_octet_mem_addr),
  .tx_start             (ll_tx_start),
  .tx_iq_valid_last     (tx_iq_valid_last),

  // ====to phy rx====
  .rx_unique_bit_sequence(ll_rx_unique_bit_sequence),
  .rx_channel_number     (ll_rx_channel_number),
  .rx_crc_state_init_bit (ll_rx_crc_state_init_bit),

  .rx_hit_flag      (ext_rx_hit_flag),
  .rx_decode_run    (ext_rx_decode_run),
  .rx_decode_end    (ext_rx_decode_end),
  .rx_crc_ok        (ext_rx_crc_ok),
  .rx_payload_length(ext_rx_payload_length),

  .rx_pdu_octet_mem_addr(ll_rx_pdu_octet_mem_addr),
  .rx_pdu_octet_mem_data(ext_rx_pdu_octet_mem_data),

  // ===============Auxiliary Signals================
  .ll_gpio(ll_gpio),
  .ll_itrpt0(ll_itrpt0),
  .ll_itrpt1(ll_itrpt1),
  .ll_itrpt2(ll_itrpt2),
  .ll_itrpt3(ll_itrpt3),
  .ll_itrpt4(ll_itrpt4),
  .ll_itrpt5(ll_itrpt5),
  .ll_itrpt6(ll_itrpt6),
  .ll_itrpt7(ll_itrpt7),

  .rx_i_signal(rx_i_signal),
  .rx_q_signal(rx_q_signal),
  .rx_iq_valid(rx_iq_valid),

  .i_abs_add_q_abs(i_abs_add_q_abs),
  .agc_lock_change(agc_lock_change),
  .agc_lock_state(agc_lock_state),
  .rf_gain(rf_gain),

  // Ports of Axi Slave Bus Interface
  .slv_reg_rden(slv_reg_rden),
  .axi_araddr_core(axi_araddr_core),
  .slv_reg_wren(slv_reg_wren),
  .axi_awaddr_core(axi_awaddr_core),

  .axi_aclk(s00_axi_aclk),
  .axi_aresetn(s00_axi_aresetn),
  .axi_awaddr(s00_axi_awaddr),
  .axi_awprot(s00_axi_awprot),
  .axi_awvalid(s00_axi_awvalid),
  .axi_awready(s00_axi_awready),
  .axi_wdata(s00_axi_wdata),
  .axi_wstrb(s00_axi_wstrb),
  .axi_wvalid(s00_axi_wvalid),
  .axi_wready(s00_axi_wready),
  .axi_bresp(s00_axi_bresp),
  .axi_bvalid(s00_axi_bvalid),
  .axi_bready(s00_axi_bready),
  .axi_araddr(s00_axi_araddr),
  .axi_arprot(s00_axi_arprot),
  .axi_arvalid(s00_axi_arvalid),
  .axi_arready(s00_axi_arready),
  .axi_rdata(s00_axi_rdata),
  .axi_rresp(s00_axi_rresp),
  .axi_rvalid(s00_axi_rvalid),
  .axi_rready(s00_axi_rready)
);

btle_phy #
(
  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH),
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
  .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL),
  .GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
  .NUM_TAP_GAUSS_FILTER(NUM_TAP_GAUSS_FILTER),
  .VCO_BIT_WIDTH(VCO_BIT_WIDTH),
  .SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
  .IQ_BIT_WIDTH(IQ_BIT_WIDTH),
  .GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT(GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT),

  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH),
  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE)
) btle_phy_i (
  .clk(bb_clk),
  .rst(bb_rst),

  .clkb(s00_axi_aclk),

  .tx_gauss_filter_tap_index(tx_gauss_filter_tap_index),
  .tx_gauss_filter_tap_value(tx_gauss_filter_tap_value),

  .tx_cos_table_write_address(tx_cos_table_write_address),
  .tx_cos_table_write_data(tx_cos_table_write_data),
  .tx_sin_table_write_address(tx_sin_table_write_address),
  .tx_sin_table_write_data(tx_sin_table_write_data),

  .tx_preamble(tx_preamble),

  .tx_access_address(tx_access_address),
  .tx_crc_state_init_bit(tx_crc_state_init_bit),
  .tx_crc_state_init_bit_load(tx_crc_state_init_bit_load),
  .tx_channel_number(tx_channel_number),
  .tx_channel_number_load(tx_channel_number_load),

  .tx_pdu_octet_mem_data(tx_pdu_octet_mem_data),
  .tx_pdu_octet_mem_addr(tx_pdu_octet_mem_addr),

  .tx_start(tx_start),

  .tx_i_signal(tx_i_signal),
  .tx_q_signal(tx_q_signal),
  .tx_iq_valid(tx_iq_valid),
  .tx_iq_valid_last(tx_iq_valid_last),

  // for phy tx debug purpose
  .tx_phy_bit(ext_tx_phy_bit),
  .tx_phy_bit_valid(ext_tx_phy_bit_valid),
  .tx_phy_bit_valid_last(ext_tx_phy_bit_valid_last),

  .tx_bit_upsample(ext_tx_bit_upsample),
  .tx_bit_upsample_valid(ext_tx_bit_upsample_valid),
  .tx_bit_upsample_valid_last(ext_tx_bit_upsample_valid_last),

  .tx_bit_upsample_gauss_filter(ext_tx_bit_upsample_gauss_filter),
  .tx_bit_upsample_gauss_filter_valid(ext_tx_bit_upsample_gauss_filter_valid),
  .tx_bit_upsample_gauss_filter_valid_last(ext_tx_bit_upsample_gauss_filter_valid_last),

  // for rx
  .rx_unique_bit_sequence(rx_unique_bit_sequence),
  .rx_channel_number(rx_channel_number),
  .rx_crc_state_init_bit(rx_crc_state_init_bit),

  .rx_i_signal(rx_i_signal),
  .rx_q_signal(rx_q_signal),
  .rx_iq_valid(rx_iq_valid),

  .rx_hit_flag(ext_rx_hit_flag),
  .rx_decode_run(ext_rx_decode_run),
  .rx_decode_end(ext_rx_decode_end),
  .rx_crc_ok(ext_rx_crc_ok),
  .rx_best_phase(ext_rx_best_phase),
  .rx_payload_length(ext_rx_payload_length),

  .rx_pdu_octet_mem_addr(rx_pdu_octet_mem_addr),
  .rx_pdu_octet_mem_data(ext_rx_pdu_octet_mem_data)
);

endmodule
