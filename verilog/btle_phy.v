// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// iverilog -o btle_phy btle_phy.v btle_rx.v btle_rx_core_tb.v btle_rx_core.v gfsk_demodulation.v search_unique_bit_sequence.v scramble_core.v crc24_core.v serial_in_ram_out.v dpram.v btle_tx.v crc24.v scramble.v gfsk_modulation.v bit_repeat_upsample.v gauss_filter.v vco.v 

`timescale 1ns / 1ps
module btle_phy #
(
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
  input wire clk,
  input wire rst,

  // for tx
  input wire [3:0] tx_gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  input wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value,

  input wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address,
  input wire signed [(IQ_BIT_WIDTH-1) : 0] tx_cos_table_write_data,
  input wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address,
  input wire signed [(IQ_BIT_WIDTH-1) : 0] tx_sin_table_write_data,

  input wire [7:0]  tx_preamble,

  input wire [31:0] tx_access_address,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0] tx_crc_state_init_bit,
  input wire tx_crc_state_init_bit_load,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number,
  input wire tx_channel_number_load,

  input wire [7:0] tx_pdu_octet_mem_data,
  input wire [5:0] tx_pdu_octet_mem_addr,

  input wire tx_start,

  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_i_signal,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_q_signal,
  output wire tx_iq_valid,
  output wire tx_iq_valid_last,

  // for tx debug purpose
  output wire tx_phy_bit,
  output wire tx_phy_bit_valid,
  output wire tx_phy_bit_valid_last,

  output wire tx_bit_upsample,
  output wire tx_bit_upsample_valid,
  output wire tx_bit_upsample_valid_last,

  output wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_bit_upsample_gauss_filter,
  output wire tx_bit_upsample_gauss_filter_valid,
  output wire tx_bit_upsample_gauss_filter_valid_last,

  // for rx
  input wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit,

  input wire  signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_i_signal,
  input wire  signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_q_signal,
  input wire  rx_iq_valid,

  output wire  rx_hit_flag,
  output wire  rx_decode_run,
  output wire  rx_decode_end,
  output wire  rx_crc_ok,
  output wire  [2:0] rx_best_phase,
  output wire  [6:0] rx_payload_length,

  input  wire  [5:0] rx_pdu_octet_mem_addr,
  output wire  [7:0] rx_pdu_octet_mem_data
);

btle_tx # (
.CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH),
.CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
.SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL),
.GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
.NUM_TAP_GAUSS_FILTER(NUM_TAP_GAUSS_FILTER),
.VCO_BIT_WIDTH(VCO_BIT_WIDTH),
.SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
.IQ_BIT_WIDTH(IQ_BIT_WIDTH),
.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT(GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT)
) btle_tx_i (
  .clk(clk),
  .rst(rst),

  .gauss_filter_tap_index(tx_gauss_filter_tap_index),
  .gauss_filter_tap_value(tx_gauss_filter_tap_value),

  .cos_table_write_address(tx_cos_table_write_address),
  .cos_table_write_data(tx_cos_table_write_data),
  .sin_table_write_address(tx_sin_table_write_address),
  .sin_table_write_data(tx_sin_table_write_data),
  
  .preamble(tx_preamble),

  .access_address(tx_access_address),
  .crc_state_init_bit(tx_crc_state_init_bit),
  .crc_state_init_bit_load(tx_crc_state_init_bit_load),
  .channel_number(tx_channel_number),
  .channel_number_load(tx_channel_number_load),

  .pdu_octet_mem_data(tx_pdu_octet_mem_data),
  .pdu_octet_mem_addr(tx_pdu_octet_mem_addr),

  .tx_start(tx_start),

  .i(tx_i_signal),
  .q(tx_q_signal),
  .iq_valid(tx_iq_valid),
  .iq_valid_last(tx_iq_valid_last),

  // for debug purpose
  .phy_bit(tx_phy_bit),
  .phy_bit_valid(tx_phy_bit_valid),
  .phy_bit_valid_last(tx_phy_bit_valid_last),

  .bit_upsample(tx_bit_upsample),
  .bit_upsample_valid(tx_bit_upsample_valid),
  .bit_upsample_valid_last(tx_bit_upsample_valid_last),

  .bit_upsample_gauss_filter(tx_bit_upsample_gauss_filter),
  .bit_upsample_gauss_filter_valid(tx_bit_upsample_gauss_filter_valid),
  .bit_upsample_gauss_filter_valid_last(tx_bit_upsample_gauss_filter_valid_last)
);

btle_rx # (
  .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL),
  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH),
  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE),
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH)
) btle_rx_i (
  .clk(clk),
  .rst(rst),

  .unique_bit_sequence(rx_unique_bit_sequence),
  .channel_number(rx_channel_number),
  .crc_state_init_bit(rx_crc_state_init_bit),

  .i(rx_i_signal),
  .q(rx_q_signal),
  .iq_valid(rx_iq_valid),

  .hit_flag(rx_hit_flag),
  .decode_run(rx_decode_run),
  .decode_end(rx_decode_end),
  .crc_ok(rx_crc_ok),
  .best_phase(rx_best_phase),

  .payload_length(rx_payload_length),

  .pdu_octet_mem_data(rx_pdu_octet_mem_data),
  .pdu_octet_mem_addr(rx_pdu_octet_mem_addr)
);

endmodule

