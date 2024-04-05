// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// iverilog -o btle_controller_wrapper btle_controller_wrapper.v btle_controller.v btle_ll.v uart_frame_rx.v uart_frame_tx.v rx_clk_gen.v tx_clk_gen.v btle_phy.v btle_rx.v btle_rx_core.v gfsk_demodulation.v search_unique_bit_sequence.v scramble_core.v crc24_core.v serial_in_ram_out.v dpram.v btle_tx.v crc24.v scramble.v gfsk_modulation.v bit_repeat_upsample.v gauss_filter.v vco.v

`timescale 1ns / 1ps
module btle_controller_wrapper #
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

  input  wire baremetal_phy_intf_mode, //currently 1 for external access. should be 0 in the future to let btle_ll control phy
  output wire [31:0] fake_pins
);

  // ====baremetal phy interface. should be via uart in the future====
  // for phy tx
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [3:0] ext_tx_gauss_filter_tap_index; // only need to set 0~8, 9~16 will be mirror of 0~7
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] ext_tx_gauss_filter_tap_value;

(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ext_tx_cos_table_write_address;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg signed [(IQ_BIT_WIDTH-1) : 0] ext_tx_cos_table_write_data;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] ext_tx_sin_table_write_address;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg signed [(IQ_BIT_WIDTH-1) : 0] ext_tx_sin_table_write_data;

(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [7:0]  ext_tx_preamble;

(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [31:0] ext_tx_access_address;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [(CRC_STATE_BIT_WIDTH-1) : 0] ext_tx_crc_state_init_bit;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg ext_tx_crc_state_init_bit_load;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ext_tx_channel_number;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg ext_tx_channel_number_load;

(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [7:0] ext_tx_pdu_octet_mem_data;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [5:0] ext_tx_pdu_octet_mem_addr;

(*mark_debug="true",DONT_TOUCH="TRUE"*) reg ext_tx_start;

  // for phy tx debug purpose
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_phy_bit;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_phy_bit_valid;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_phy_bit_valid_last;

(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_bit_upsample;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_bit_upsample_valid;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_bit_upsample_valid_last;

(*mark_debug="true",DONT_TOUCH="TRUE"*) wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] ext_tx_bit_upsample_gauss_filter;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_bit_upsample_gauss_filter_valid;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire ext_tx_bit_upsample_gauss_filter_valid_last;

  // for phy rx
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  ext_rx_unique_bit_sequence;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] ext_rx_channel_number;
(*mark_debug="true",DONT_TOUCH="TRUE"*) reg [(CRC_STATE_BIT_WIDTH-1) : 0]      ext_rx_crc_state_init_bit;

(*mark_debug="true",DONT_TOUCH="TRUE"*) wire  rx_hit_flag;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire  rx_decode_run;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire  rx_decode_end;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire  rx_crc_ok;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire  [2:0] rx_best_phase;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire  [6:0] rx_payload_length;

(*mark_debug="true",DONT_TOUCH="TRUE"*) reg  [5:0] ext_rx_pdu_octet_mem_addr;
(*mark_debug="true",DONT_TOUCH="TRUE"*) wire  [7:0] rx_pdu_octet_mem_data;

//fake outputs
assign fake_pins = rx_pdu_octet_mem_data+rx_payload_length+rx_best_phase+rx_crc_ok+rx_decode_end+rx_decode_run+rx_hit_flag+
                   ext_tx_bit_upsample_gauss_filter_valid_last+ext_tx_bit_upsample_gauss_filter_valid+ext_tx_bit_upsample_gauss_filter+
                   ext_tx_bit_upsample_valid_last+ext_tx_bit_upsample_valid+ext_tx_bit_upsample+
                   ext_tx_phy_bit_valid_last+ext_tx_phy_bit_valid+ext_tx_phy_bit;

//fake driver
always @ (posedge clk) begin
  if (rst) begin
    ext_tx_gauss_filter_tap_index <= 0;
    ext_tx_gauss_filter_tap_value <= 0;

    ext_tx_cos_table_write_address <= 0;
    ext_tx_cos_table_write_data <= 0;
    ext_tx_sin_table_write_address <= 0;
    ext_tx_sin_table_write_data <= 0;

    ext_tx_preamble <= 0;

    ext_tx_access_address <= 0;
    ext_tx_crc_state_init_bit <= 0;
    ext_tx_crc_state_init_bit_load <= 0;
    ext_tx_channel_number <= 0;
    ext_tx_channel_number_load <= 0;

    ext_tx_pdu_octet_mem_data <= 0;
    ext_tx_pdu_octet_mem_addr <= 0;

    ext_tx_start <= 0;

    ext_rx_unique_bit_sequence <= 0;
    ext_rx_channel_number <= 0;
    ext_rx_crc_state_init_bit <= 0;

    ext_rx_pdu_octet_mem_addr <= 0;
  end else begin
    ext_tx_gauss_filter_tap_index <= ext_tx_gauss_filter_tap_index + 1;
    ext_tx_gauss_filter_tap_value <= ext_tx_gauss_filter_tap_value + 1;

    ext_tx_cos_table_write_address <= ext_tx_cos_table_write_address + 1;
    ext_tx_cos_table_write_data <= ext_tx_cos_table_write_data + 1;
    ext_tx_sin_table_write_address <= ext_tx_sin_table_write_address + 1;
    ext_tx_sin_table_write_data <= ext_tx_sin_table_write_data + 1;

    ext_tx_preamble <= ext_tx_preamble + 1;

    ext_tx_access_address <= ext_tx_access_address + 1;
    ext_tx_crc_state_init_bit <= ext_tx_crc_state_init_bit + 1;
    ext_tx_crc_state_init_bit_load <= ext_tx_crc_state_init_bit_load + 1;
    ext_tx_channel_number <= ext_tx_channel_number + 1;
    ext_tx_channel_number_load <= ext_tx_channel_number_load + 1;

    ext_tx_pdu_octet_mem_data <= ext_tx_pdu_octet_mem_data + 1;
    ext_tx_pdu_octet_mem_addr <= ext_tx_pdu_octet_mem_addr + 1;

    ext_tx_start <= ext_tx_start + 1;

    ext_rx_unique_bit_sequence <= ext_rx_unique_bit_sequence + 1;
    ext_rx_channel_number <= ext_rx_channel_number + 1;
    ext_rx_crc_state_init_bit <= ext_rx_crc_state_init_bit + 1;

    ext_rx_pdu_octet_mem_addr <= ext_rx_pdu_octet_mem_addr + 1;
  end
end

btle_controller #
(
  .CLK_FREQUENCE(CLK_FREQUENCE),
  .BAUD_RATE(BAUD_RATE),
  .PARITY(PARITY),
  .FRAME_WD(FRAME_WD),

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
) btle_controller_i (
  .clk(clk),
  .rst(rst),

    // ============================to host: UART HCI=========================
  .uart_rx(uart_rx),
  .uart_tx(uart_tx),

    // =========================to zero-IF RF transceiver====================
  .tx_i_signal(tx_i_signal),
  .tx_q_signal(tx_q_signal),
  .tx_iq_valid(tx_iq_valid),
  .tx_iq_valid_last(tx_iq_valid_last),

  .rx_i_signal(rx_i_signal),
  .rx_q_signal(rx_q_signal),
  .rx_iq_valid(rx_iq_valid),

    // ====baremetal phy interface. should be via uart in the future====
  .baremetal_phy_intf_mode(baremetal_phy_intf_mode), //currently 1 for external access. should be 0 in the future to let btle_ll control phy
    // for phy tx
  .ext_tx_gauss_filter_tap_index(ext_tx_gauss_filter_tap_index), // only need to set 0~8, 9~16 will be mirror of 0~7
  .ext_tx_gauss_filter_tap_value(ext_tx_gauss_filter_tap_value),

  .ext_tx_cos_table_write_address(ext_tx_cos_table_write_address),
  .ext_tx_cos_table_write_data(ext_tx_cos_table_write_data),
  .ext_tx_sin_table_write_address(ext_tx_sin_table_write_address),
  .ext_tx_sin_table_write_data(ext_tx_sin_table_write_data),

  .ext_tx_preamble(ext_tx_preamble),

  .ext_tx_access_address(ext_tx_access_address),
  .ext_tx_crc_state_init_bit(ext_tx_crc_state_init_bit),
  .ext_tx_crc_state_init_bit_load(ext_tx_crc_state_init_bit_load),
  .ext_tx_channel_number(ext_tx_channel_number),
  .ext_tx_channel_number_load(ext_tx_channel_number_load),

  .ext_tx_pdu_octet_mem_data(ext_tx_pdu_octet_mem_data),
  .ext_tx_pdu_octet_mem_addr(ext_tx_pdu_octet_mem_addr),

  .ext_tx_start(ext_tx_start),

    // for phy tx debug purpose
  .ext_tx_phy_bit(ext_tx_phy_bit),
  .ext_tx_phy_bit_valid(ext_tx_phy_bit_valid),
  .ext_tx_phy_bit_valid_last(ext_tx_phy_bit_valid_last),

  .ext_tx_bit_upsample(ext_tx_bit_upsample),
  .ext_tx_bit_upsample_valid(ext_tx_bit_upsample_valid),
  .ext_tx_bit_upsample_valid_last(ext_tx_bit_upsample_valid_last),

  .ext_tx_bit_upsample_gauss_filter(ext_tx_bit_upsample_gauss_filter),
  .ext_tx_bit_upsample_gauss_filter_valid(ext_tx_bit_upsample_gauss_filter_valid),
  .ext_tx_bit_upsample_gauss_filter_valid_last(ext_tx_bit_upsample_gauss_filter_valid_last),

    // for phy rx
  .ext_rx_unique_bit_sequence(ext_rx_unique_bit_sequence),
  .ext_rx_channel_number(ext_rx_channel_number),
  .ext_rx_crc_state_init_bit(ext_rx_crc_state_init_bit),

  .ext_rx_hit_flag(rx_hit_flag),
  .ext_rx_decode_run(rx_decode_run),
  .ext_rx_decode_end(rx_decode_end),
  .ext_rx_crc_ok(rx_crc_ok),
  .ext_rx_best_phase(rx_best_phase),
  .ext_rx_payload_length(rx_payload_length),

  .ext_rx_pdu_octet_mem_addr(ext_rx_pdu_octet_mem_addr),
  .ext_rx_pdu_octet_mem_data(rx_pdu_octet_mem_data)
);

endmodule

