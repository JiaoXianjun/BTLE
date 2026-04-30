// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// for rx, the IQ signal and valid are from ad9361 rf 8MHz clock domain, the bb internal processing is in 16MHz clock domain
// for tx, the IQ signal and valid are from bb 16MHz clock domain, they go to ad9361 rf 8MHz clock domain

`timescale 1ns / 1ps
module clock_domain_conversion_iq #
(
  parameter integer RF_IQ_BIT_WIDTH = 64,
  parameter integer RF_I_OR_Q_BIT_WIDTH = (RF_IQ_BIT_WIDTH/4),

  parameter integer IQ_BIT_WIDTH = 8,

  parameter integer GFSK_DEMODULATION_BIT_WIDTH = 16
) (
  input rf_clk, // ad9361 8MHz rf clock
  input rf_rst,

  input bb_clk, // bb 16MHz clock
  input bb_rst,

  // rx path
  input wire [7:0]                     rf_gpio,
  input wire [(RF_IQ_BIT_WIDTH-1) : 0] rx_iq_signal_ext, // ad9361 8MHz rf clock
  input wire                           rx_iq_valid_ext,

  output reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_i_signal, // bb 16MHz clock
  output reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_q_signal,
  output reg rx_iq_valid,
  output reg [7:0] bb_gpio,

  // tx path
  input wire signed [(IQ_BIT_WIDTH-1) : 0] tx_i_signal, // bb 16MHz clock
  input wire signed [(IQ_BIT_WIDTH-1) : 0] tx_q_signal,
  input wire tx_iq_valid,
  input wire tx_iq_valid_last,

  output reg [(RF_IQ_BIT_WIDTH-1) : 0] tx_iq_signal_ext, // ad9361 8MHz rf clock
  output reg                           tx_iq_valid_ext,
  output reg                           tx_iq_valid_last_ext
);

// rx path
always @ (posedge bb_clk) begin
  if (bb_rst) begin
    rx_i_signal <= 0;
    rx_q_signal <= 0;
    rx_iq_valid <= 0;
    bb_gpio     <= 0;
  end else begin
    rx_i_signal <= rx_iq_signal_ext[(RF_I_OR_Q_BIT_WIDTH-1)   : 0                  ];
    rx_q_signal <= rx_iq_signal_ext[(2*RF_I_OR_Q_BIT_WIDTH-1) : RF_I_OR_Q_BIT_WIDTH];
    rx_iq_valid <= (~rx_iq_valid); // rx_iq_valid_ext is always 1 (under 8MHz clk). we need valid every other 16MHz clk to get 8MHz valid under 16MHz (8Msps rate is half of 16MHz clk)
    bb_gpio     <= rf_gpio;
  end
end

// tx path
always @ (posedge rf_clk) begin
  if (rf_rst) begin
    tx_iq_signal_ext <= 0;
    tx_iq_valid_ext <= 0;
    tx_iq_valid_last_ext <= 0;
  end else begin
    tx_iq_signal_ext[(RF_I_OR_Q_BIT_WIDTH-1)   : 0                   ]    <= {{(RF_I_OR_Q_BIT_WIDTH-IQ_BIT_WIDTH){tx_i_signal[IQ_BIT_WIDTH-1]}}, tx_i_signal};
    tx_iq_signal_ext[(2*RF_I_OR_Q_BIT_WIDTH-1) : RF_I_OR_Q_BIT_WIDTH ]    <= {{(RF_I_OR_Q_BIT_WIDTH-IQ_BIT_WIDTH){tx_q_signal[IQ_BIT_WIDTH-1]}}, tx_q_signal};
    tx_iq_signal_ext[(RF_IQ_BIT_WIDTH-1)       : (2*RF_I_OR_Q_BIT_WIDTH)] <= 0;
    tx_iq_valid_ext <= tx_iq_valid;
    tx_iq_valid_last_ext <= tx_iq_valid_last;
  end
end

endmodule

