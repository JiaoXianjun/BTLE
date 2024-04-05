// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Input phy_bit rate 1M, output phy_bit rate 8M
// clk speed 16M

`timescale 1ns / 1ps
module bit_repeat_upsample #
(
  parameter SAMPLE_PER_SYMBOL = 8
) (
  input wire clk,
  input wire rst,

  input wire phy_bit,
  input wire bit_valid,
  input wire bit_valid_last,

  output reg  bit_upsample,
  output wire bit_upsample_valid,
  output wire bit_upsample_valid_last
);

reg [14:0] bit_valid_delay;
reg [14:0] bit_valid_last_delay;
wire bit_valid_wide;
wire bit_valid_last_wide;
reg bit_upsample_valid_internal;
reg [2:0] bit_upsample_count;
reg first_bit_valid_encountered;

assign bit_valid_wide = (|bit_valid_delay);
assign bit_valid_last_wide = (|bit_valid_last_delay);

assign bit_upsample_valid = (bit_upsample_valid_internal & bit_valid_wide);
assign bit_upsample_valid_last = ((bit_upsample_count==0) & bit_valid_last_wide);

always @ (posedge clk) begin
  if (rst) begin
    bit_valid_delay <= 0;
    bit_valid_last_delay <= 0;
    bit_upsample <= 0;
    bit_upsample_valid_internal <= 0;
    bit_upsample_count <= 0;

    first_bit_valid_encountered <= 0;
  end else begin
    bit_valid_delay[0]  <= bit_valid;
    bit_valid_delay[14:1]  <= bit_valid_delay[13:0];
    // bit_valid_delay[1]  <= bit_valid_delay[0];
    // bit_valid_delay[2]  <= bit_valid_delay[1];
    // bit_valid_delay[3]  <= bit_valid_delay[2];
    // bit_valid_delay[4]  <= bit_valid_delay[3];
    // bit_valid_delay[5]  <= bit_valid_delay[4];
    // bit_valid_delay[6]  <= bit_valid_delay[5];
    // bit_valid_delay[7]  <= bit_valid_delay[6];
    // bit_valid_delay[8]  <= bit_valid_delay[7];
    // bit_valid_delay[9]  <= bit_valid_delay[8];
    // bit_valid_delay[10] <= bit_valid_delay[9];
    // bit_valid_delay[11] <= bit_valid_delay[10];
    // bit_valid_delay[12] <= bit_valid_delay[11];
    // bit_valid_delay[13] <= bit_valid_delay[12];
    // bit_valid_delay[14] <= bit_valid_delay[13];

    bit_valid_last_delay[0]  <= bit_valid_last;
    bit_valid_last_delay[14:1]  <= bit_valid_last_delay[13:0];

    if (bit_valid) begin
      bit_upsample <= phy_bit;
    end
    bit_upsample_valid_internal <= (~bit_upsample_valid_internal);

    first_bit_valid_encountered <= (bit_valid? 1 : first_bit_valid_encountered);
    if (first_bit_valid_encountered == 0) begin
      bit_upsample_count <= 1;
    end else begin
      bit_upsample_count <= (bit_upsample_valid_internal == 0? (bit_upsample_count + 1) : bit_upsample_count);
    end
  end
end

endmodule

