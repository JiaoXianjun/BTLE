// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Core_v5.3 figure3.5 on page 2735

`timescale 1ns / 1ps
module scramble_core #
(
  parameter integer CHANNEL_NUMBER_BIT_WIDTH = 6
) (
  input wire clk,
  input wire rst,

  input  wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number, // load into lfsr (linear feedback shift register) upon channel_number_load==1
  input  wire channel_number_load,
  input  wire data_in,
  input  wire data_in_valid,
  output reg  data_out,
  output reg  data_out_valid
);

wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number_internal;

reg [CHANNEL_NUMBER_BIT_WIDTH : 0] lfsr;

assign channel_number_internal = (channel_number == 0? {CHANNEL_NUMBER_BIT_WIDTH{1'b1}} : channel_number); // in case no valid setting yet

always @ (posedge clk) begin
  if (rst) begin
    data_out <= 0;
    data_out_valid <= 0;
    // lfsr <= 0;
    lfsr[0] <= 1;
    // lfsr[CHANNEL_NUMBER_BIT_WIDTH : 1] <= channel_number_internal;
    lfsr[1] <= channel_number_internal[5];
    lfsr[2] <= channel_number_internal[4];
    lfsr[3] <= channel_number_internal[3];
    lfsr[4] <= channel_number_internal[2];
    lfsr[5] <= channel_number_internal[1];
    lfsr[6] <= channel_number_internal[0];
  end else begin
    if (channel_number_load) begin
      lfsr[0] <= 1;
      // lfsr[CHANNEL_NUMBER_BIT_WIDTH : 1] <= channel_number_internal;
      lfsr[1] <= channel_number_internal[5];
      lfsr[2] <= channel_number_internal[4];
      lfsr[3] <= channel_number_internal[3];
      lfsr[4] <= channel_number_internal[2];
      lfsr[5] <= channel_number_internal[1];
      lfsr[6] <= channel_number_internal[0];
    end else begin
      if (data_in_valid) begin
        lfsr[0] <= lfsr[6];
        lfsr[1] <= lfsr[0];
        lfsr[2] <= lfsr[1];
        lfsr[3] <= lfsr[2];
        lfsr[4] <= lfsr[3]^lfsr[6];
        lfsr[5] <= lfsr[4];
        lfsr[6] <= lfsr[5];

        data_out <= lfsr[6]^data_in;
        data_out_valid <= 1;
      end else begin
        data_out_valid <= 0;
      end
    end
  end
end

endmodule

