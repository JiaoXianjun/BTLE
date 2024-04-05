// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Core_v5.3 section 3.1on page 2640
// BT = 0.5

`timescale 1ns / 1ps
module gauss_filter #
(
  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter NUM_TAP_GAUSS_FILTER = 17
) (
  input wire clk,
  input wire rst,

  input wire [3:0] tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  input wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap_value,

  input wire bit_upsample,
  input wire bit_upsample_valid,
  input wire bit_upsample_valid_last,
  
  output reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] bit_upsample_gauss_filter,
  output reg bit_upsample_gauss_filter_valid,
  output reg bit_upsample_gauss_filter_valid_last
);

reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap0;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap1;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap2;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap3;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap4;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap5;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap6;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap7;
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap8;

reg [(NUM_TAP_GAUSS_FILTER-2) : 0] bit_upsample_store;

wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap0_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap1_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap2_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap3_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap4_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap5_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap6_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap7_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap8_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap9_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap10_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap11_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap12_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap13_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap14_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap15_mult;
wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap16_mult;

assign tap0_mult  = (bit_upsample         ? gauss_filter_tap0:(-gauss_filter_tap0));
assign tap1_mult  = (bit_upsample_store[0]? gauss_filter_tap1:(-gauss_filter_tap1));
assign tap2_mult  = (bit_upsample_store[1]? gauss_filter_tap2:(-gauss_filter_tap2));
assign tap3_mult  = (bit_upsample_store[2]? gauss_filter_tap3:(-gauss_filter_tap3));
assign tap4_mult  = (bit_upsample_store[3]? gauss_filter_tap4:(-gauss_filter_tap4));
assign tap5_mult  = (bit_upsample_store[4]? gauss_filter_tap5:(-gauss_filter_tap5));
assign tap6_mult  = (bit_upsample_store[5]? gauss_filter_tap6:(-gauss_filter_tap6));
assign tap7_mult  = (bit_upsample_store[6]? gauss_filter_tap7:(-gauss_filter_tap7));
assign tap8_mult  = (bit_upsample_store[7]? gauss_filter_tap8:(-gauss_filter_tap8));
assign tap9_mult  = (bit_upsample_store[8]? gauss_filter_tap7:(-gauss_filter_tap7));
assign tap10_mult = (bit_upsample_store[9]? gauss_filter_tap6:(-gauss_filter_tap6));
assign tap11_mult = (bit_upsample_store[10]?gauss_filter_tap5:(-gauss_filter_tap5));
assign tap12_mult = (bit_upsample_store[11]?gauss_filter_tap4:(-gauss_filter_tap4));
assign tap13_mult = (bit_upsample_store[12]?gauss_filter_tap3:(-gauss_filter_tap3));
assign tap14_mult = (bit_upsample_store[13]?gauss_filter_tap2:(-gauss_filter_tap2));
assign tap15_mult = (bit_upsample_store[14]?gauss_filter_tap1:(-gauss_filter_tap1));
assign tap16_mult = (bit_upsample_store[15]?gauss_filter_tap0:(-gauss_filter_tap0));

// Populate input tap index and value to internal taps
always @ (posedge clk) begin
  if (rst) begin
    gauss_filter_tap0 <= 0;
    gauss_filter_tap1 <= 0;
    gauss_filter_tap2 <= 0;
    gauss_filter_tap3 <= 0;
    gauss_filter_tap4 <= 0;
    gauss_filter_tap5 <= 0;
    gauss_filter_tap6 <= 0;
    gauss_filter_tap7 <= 0;
    gauss_filter_tap8 <= 0;
  end else begin
    case(tap_index)
      0: begin gauss_filter_tap0 <= tap_value; end
      1: begin gauss_filter_tap1 <= tap_value; end
      2: begin gauss_filter_tap2 <= tap_value; end
      3: begin gauss_filter_tap3 <= tap_value; end
      4: begin gauss_filter_tap4 <= tap_value; end
      5: begin gauss_filter_tap5 <= tap_value; end
      6: begin gauss_filter_tap6 <= tap_value; end
      7: begin gauss_filter_tap7 <= tap_value; end
      8: begin gauss_filter_tap8 <= tap_value; end
    endcase
  end
end


always @ (posedge clk) begin
  if (rst) begin
    bit_upsample_gauss_filter <= 0;
    bit_upsample_gauss_filter_valid <= 0;
    bit_upsample_gauss_filter_valid_last <= 0;
    bit_upsample_store <= 0;
  end else begin
    bit_upsample_gauss_filter_valid <= bit_upsample_valid;
    bit_upsample_gauss_filter_valid_last <= bit_upsample_valid_last;
    if (bit_upsample_valid) begin
      bit_upsample_store[(NUM_TAP_GAUSS_FILTER-2) : 1] <= bit_upsample_store[(NUM_TAP_GAUSS_FILTER-3) : 0];
      bit_upsample_store[0] <= bit_upsample;

      bit_upsample_gauss_filter <= (tap0_mult+tap1_mult+tap2_mult+tap3_mult+tap4_mult+tap5_mult+tap6_mult+tap7_mult+tap8_mult+tap9_mult+tap10_mult+tap11_mult+tap12_mult+tap13_mult+tap14_mult+tap15_mult+tap16_mult);
    end 
  end
end

endmodule
