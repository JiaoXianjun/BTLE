// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// btle_controller = btle_ll (link layer) + btle_phy (phy: btle_tx and btle_rx)

// iverilog -o btle_controller btle_controller.v btle_ll.v uart_frame_rx.v uart_frame_tx.v rx_clk_gen.v tx_clk_gen.v btle_phy.v btle_rx.v btle_rx_core.v gfsk_demodulation.v search_unique_bit_sequence.v scramble_core.v crc24_core.v serial_in_ram_out.v dpram.v btle_tx.v crc24.v scramble.v gfsk_modulation.v bit_repeat_upsample.v gauss_filter.v vco.v

`timescale 1ns / 1ps
module btle_controller #
(
	parameter	CLK_FREQUENCE	= 16_000_000,	//hz
  parameter BAUD_RATE		= 115200		,		  //9600、19200 、38400 、57600 、115200、230400、460800、921600
  parameter PARITY			= "NONE"	,		  //"NONE","EVEN","ODD"
  parameter FRAME_WD		= 8,					    //if PARITY="NONE",it can be 5~9;else 5~8

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
  input clk,
  input rst,

  // ============================to host: UART HCI=========================
  input  uart_rx,
  output uart_tx,

  // =========================to zero-IF RF transceiver====================
  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_i_signal,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_q_signal,
  output wire tx_iq_valid,
  output wire tx_iq_valid_last,

  input wire  signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_i_signal,
  input wire  signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_q_signal,
  input wire  rx_iq_valid,

  // ====baremetal phy interface. should be via uart in the future====
  input wire baremetal_phy_intf_mode, //currently 1 for external access. should be 0 in the future to let btle_ll control phy
  // for phy tx
  input wire [3:0] ext_tx_gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  input wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] ext_tx_gauss_filter_tap_value,

  input wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ext_tx_cos_table_write_address,
  input wire signed [(IQ_BIT_WIDTH-1) : 0] ext_tx_cos_table_write_data,
  input wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ext_tx_sin_table_write_address,
  input wire signed [(IQ_BIT_WIDTH-1) : 0] ext_tx_sin_table_write_data,

  input wire [7:0]  ext_tx_preamble,

  input wire [31:0] ext_tx_access_address,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0] ext_tx_crc_state_init_bit,
  input wire ext_tx_crc_state_init_bit_load,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ext_tx_channel_number,
  input wire ext_tx_channel_number_load,

  input wire [7:0] ext_tx_pdu_octet_mem_data,
  input wire [5:0] ext_tx_pdu_octet_mem_addr,

  input wire ext_tx_start,

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

  output wire  ext_rx_hit_flag,
  output wire  ext_rx_decode_run,
  output wire  ext_rx_decode_end,
  output wire  ext_rx_crc_ok,
  output wire  [2:0] ext_rx_best_phase,
  output wire  [6:0] ext_rx_payload_length,

  input  wire  [5:0] ext_rx_pdu_octet_mem_addr,
  output wire  [7:0] ext_rx_pdu_octet_mem_data
);

// =================link layer to phy tx======================
wire [3:0] ll_tx_gauss_filter_tap_index;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] ll_tx_gauss_filter_tap_value;

wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ll_tx_cos_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0] ll_tx_cos_table_write_data;
wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ll_tx_sin_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0] ll_tx_sin_table_write_data;

wire [7:0]  ll_tx_preamble;

wire [31:0] ll_tx_access_address;
wire [(CRC_STATE_BIT_WIDTH-1) : 0] ll_tx_crc_state_init_bit;
wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ll_tx_channel_number;

wire [7:0] ll_tx_pdu_octet_mem_data;
wire [5:0] ll_tx_pdu_octet_mem_addr;
wire ll_tx_start;

// ===========================phy tx=========================
wire [3:0] tx_gauss_filter_tap_index;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value;

wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0] tx_cos_table_write_data;
wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address;
wire signed [(IQ_BIT_WIDTH-1) : 0] tx_sin_table_write_data;

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
wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence;
wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number;
wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit;

wire  [5:0] rx_pdu_octet_mem_addr;

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

btle_ll # (
  .CLK_FREQUENCE(CLK_FREQUENCE),
  .BAUD_RATE(BAUD_RATE),
  .PARITY(PARITY),
  .FRAME_WD(FRAME_WD),

  .GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
  .SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
  .IQ_BIT_WIDTH(IQ_BIT_WIDTH),
  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH),
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),

  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE)
) btle_ll_i (
  .clk(clk),
  .rst(rst),

  // ====to host: UART HCI====
  .uart_rx(uart_rx),
  .uart_tx(uart_tx),

  // ====to phy tx====
  .tx_gauss_filter_tap_index(ll_tx_gauss_filter_tap_index), // only need to set 0~8, 9~16 will be mirror of 0~7
  .tx_gauss_filter_tap_value(ll_tx_gauss_filter_tap_value),

  .tx_cos_table_write_address(ll_tx_cos_table_write_address),
  .tx_cos_table_write_data(ll_tx_cos_table_write_data),
  .tx_sin_table_write_address(ll_tx_sin_table_write_address),
  .tx_sin_table_write_data(ll_tx_sin_table_write_data),

  .tx_preamble(ll_tx_preamble),

  .tx_access_address(ll_tx_access_address),
  .tx_crc_state_init_bit(ll_tx_crc_state_init_bit),
  .tx_channel_number(ll_tx_channel_number),

  .tx_pdu_octet_mem_data(ll_tx_pdu_octet_mem_data),
  .tx_pdu_octet_mem_addr(ll_tx_pdu_octet_mem_addr),
  .tx_start(ll_tx_start),
  .tx_iq_valid_last(tx_iq_valid_last),

  // ====to phy rx====
  .rx_unique_bit_sequence(ll_rx_unique_bit_sequence),
  .rx_channel_number(ll_rx_channel_number),
  .rx_crc_state_init_bit(ll_rx_crc_state_init_bit),

  .rx_hit_flag(ext_rx_hit_flag),
  .rx_decode_run(ext_rx_decode_run),
  .rx_decode_end(ext_rx_decode_end),
  .rx_crc_ok(ext_rx_crc_ok),
  .rx_payload_length(ext_rx_payload_length),

  .rx_pdu_octet_mem_addr(ll_rx_pdu_octet_mem_addr),
  .rx_pdu_octet_mem_data(ext_rx_pdu_octet_mem_data)
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
  .clk(clk),
  .rst(rst),

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

