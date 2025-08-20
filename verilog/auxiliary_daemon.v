// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

`define KEEP_FOR_DBG (*mark_debug="true",DONT_TOUCH="TRUE"*)

`timescale 1ns / 1ps
module auxiliary_daemon #
(
  parameter RF_IQ_BIT_WIDTH = 64,
  parameter RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4),

  parameter IQ_BIT_WIDTH = 8,

  parameter GFSK_DEMODULATION_BIT_WIDTH = 16
) (
  input bb_clk, // bb 16MHz clock
  input bb_rst,

  input wire signed [(RF_I_OR_Q_BIT_WIDTH-1) : 0] rx_i_signal, // bb 16MHz clock
  input wire signed [(RF_I_OR_Q_BIT_WIDTH-1) : 0] rx_q_signal,
  input wire rx_iq_valid,
  input wire [7:0] bb_gpio,

  output wire [RF_I_OR_Q_BIT_WIDTH : 0] i_abs_add_q_abs,
  output wire agc_lock_change
);

reg [(RF_I_OR_Q_BIT_WIDTH-1) : 0] i_abs;
reg [(RF_I_OR_Q_BIT_WIDTH-1) : 0] q_abs;

`KEEP_FOR_DBG reg bb_gpio_msb_delay;

assign i_abs_add_q_abs = i_abs + q_abs;

assign agc_lock_change = (bb_gpio_msb_delay != bb_gpio[7]);

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

endmodule

