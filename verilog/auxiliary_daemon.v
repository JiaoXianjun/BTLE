// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

`define KEEP_FOR_DBG (*mark_debug="true",DONT_TOUCH="TRUE"*)

`timescale 1ns / 1ps
module auxiliary_daemon #
(
  parameter integer RF_IQ_BIT_WIDTH = 64,
  parameter integer RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4),

  parameter integer IQ_BIT_WIDTH = 8,

  parameter integer GFSK_DEMODULATION_BIT_WIDTH = 16,
  
  parameter integer BRAM_DEPTH = 32768,
  parameter integer BRAM_ADDR_WIDTH = $clog2(BRAM_DEPTH),
  parameter integer BRAM_DATA_WIDTH = (2*RF_I_OR_Q_BIT_WIDTH),
  parameter integer BRAM_ADDR_WIDTH_IN_BYTE = $clog2(BRAM_DEPTH*BRAM_DATA_WIDTH/8)
) (
  input bb_clk, // bb 16MHz clock
  input bb_rst,

  input wire signed [(RF_I_OR_Q_BIT_WIDTH-1) : 0] rx_i_signal, // bb 16MHz clock
  input wire signed [(RF_I_OR_Q_BIT_WIDTH-1) : 0] rx_q_signal,
  input wire rx_iq_valid,
  input wire [7:0] bb_gpio,

  output wire [RF_I_OR_Q_BIT_WIDTH : 0] i_abs_add_q_abs,
  output wire agc_lock_change,
  output wire agc_lock_state,
  output wire [6:0] rf_gain,

  // bram related
  `KEEP_FOR_DBG output reg  [BRAM_ADDR_WIDTH-1 : 0] bram_addr_b,
  `KEEP_FOR_DBG input  wire [BRAM_ADDR_WIDTH_IN_BYTE-1 : 0] bram_addr_a,
  input  wire bram_clk_a,
  input  wire [BRAM_DATA_WIDTH-1 : 0] bram_wrdata_a,
  `KEEP_FOR_DBG output wire [BRAM_DATA_WIDTH-1 : 0] bram_rddata_a,
  input  wire bram_en_a,
  input  wire bram_rst_a,
  input  wire bram_we_a
);

reg [(RF_I_OR_Q_BIT_WIDTH-1) : 0] i_abs;
reg [(RF_I_OR_Q_BIT_WIDTH-1) : 0] q_abs;

`KEEP_FOR_DBG reg bb_gpio_msb_delay;

assign i_abs_add_q_abs = i_abs + q_abs;

assign agc_lock_change = (bb_gpio_msb_delay != bb_gpio[7]);
assign agc_lock_state = bb_gpio[7];
assign rf_gain = bb_gpio[6:0];

// some misc signals
always @ (posedge bb_clk) begin
  if (bb_rst) begin
    i_abs <= 0;
    q_abs <= 0;

    bb_gpio_msb_delay <= 0;
  end else begin
    i_abs <= ( (rx_i_signal[RF_I_OR_Q_BIT_WIDTH-1]==1'd1)? (-rx_i_signal) : rx_i_signal );
    q_abs <= ( (rx_q_signal[RF_I_OR_Q_BIT_WIDTH-1]==1'd1)? (-rx_q_signal) : rx_q_signal );

    bb_gpio_msb_delay <= bb_gpio[7];
  end
end

// bram related
always @ (posedge bb_clk) begin
  if (bb_rst) begin
    bram_addr_b <= 0;
  end else begin
    if (rx_iq_valid) begin
      bram_addr_b <= bram_addr_b + 1;
    end
  end
end

sdpram_two_clk_xilinx #
(
  .DATA_WIDTH(BRAM_DATA_WIDTH),
  .ADDRESS_WIDTH(BRAM_ADDR_WIDTH)
) sdpram_two_clk_auxiliary_daemon_i (
  .clk(bb_clk),
  .rst(bb_rst),

  .write_address(bram_addr_b),
  .write_data({rx_q_signal, rx_i_signal}),
  .write_enable(1'd1),

  .clkb(bram_clk_a),
  .rstb(bram_rst_a),
  .read_address(bram_addr_a[(BRAM_ADDR_WIDTH_IN_BYTE-1) : $clog2(BRAM_DATA_WIDTH/8)]),
  .read_data(bram_rddata_a)
);

endmodule
