// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Core_v5.3 section 3.1on page 2640
// The modulation index shall be between 0.45 and 0.55
// We implement 0.5

`timescale 1ns / 1ps
module vco #
(
  parameter VCO_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8
) (
  input wire clk,
  input wire rst,

  input  wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] cos_table_write_address,
  input  wire signed [(IQ_BIT_WIDTH-1) : 0] cos_table_write_data,
  input  wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] sin_table_write_address,
  input  wire signed [(IQ_BIT_WIDTH-1) : 0] sin_table_write_data,

  input wire signed [(VCO_BIT_WIDTH-1) : 0] voltage_signal,
  input wire voltage_signal_valid,
  input wire voltage_signal_valid_last,

  output wire signed [(IQ_BIT_WIDTH-1) : 0] cos_out,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] sin_out,
  output reg sin_cos_out_valid,
  output reg sin_cos_out_valid_last
);

reg signed [(VCO_BIT_WIDTH-1) : 0] integral_voltage_signal;

always @ (posedge clk) begin
  if (rst) begin
    sin_cos_out_valid <= 0;
    sin_cos_out_valid_last <= 0;

    integral_voltage_signal <= 0;
  end else begin
    sin_cos_out_valid <= voltage_signal_valid;
    sin_cos_out_valid_last <= voltage_signal_valid_last;

    if (voltage_signal_valid) begin
      integral_voltage_signal <= integral_voltage_signal + voltage_signal;
    end
  end
end

dpram # (
  .DATA_WIDTH(IQ_BIT_WIDTH),
  .ADDRESS_WIDTH(SIN_COS_ADDR_BIT_WIDTH)
) cos_table_dpram_i (
  .clk(clk),
  .rst(rst),

  .write_address(cos_table_write_address),
  .write_data(cos_table_write_data),
  .write_enable(1'b1),

  .read_address(integral_voltage_signal[(SIN_COS_ADDR_BIT_WIDTH-1) : 0]),
  .read_data(cos_out)
);

dpram # (
  .DATA_WIDTH(IQ_BIT_WIDTH),
  .ADDRESS_WIDTH(SIN_COS_ADDR_BIT_WIDTH)
) sin_table_dpram_i (
  .clk(clk),
  .rst(rst),

  .write_address(sin_table_write_address),
  .write_data(sin_table_write_data),
  .write_enable(1'b1),

  .read_address(integral_voltage_signal[(SIN_COS_ADDR_BIT_WIDTH-1) : 0]),
  .read_data(sin_out)
);

endmodule

