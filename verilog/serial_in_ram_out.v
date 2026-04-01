// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

`timescale 1ns / 1ps
module serial_in_ram_out #
(
  parameter integer DATA_WIDTH = 8,
  parameter integer ADDRESS_WIDTH = 6
) (
  input wire clk,
  input wire rst,

  input  wire [(DATA_WIDTH-1) : 0] data_in,
  input  wire data_in_valid,

  input  wire clkb,
  input  wire [(ADDRESS_WIDTH-1) : 0] addr,
  output wire [(DATA_WIDTH-1) : 0] data
);

reg [(ADDRESS_WIDTH-1) : 0] addr_internal;

always @ (posedge clk) begin
  if (rst) begin
    addr_internal <= 0;
  end else begin
    if (data_in_valid) begin
      addr_internal <= addr_internal + 1;
    end
  end
end

sdpram_two_clk # (
  .DATA_WIDTH(DATA_WIDTH),
  .ADDRESS_WIDTH(ADDRESS_WIDTH)
) serial_in_ram_out_sdpram_two_clk_i (
  .clk(clk),
  .rst(rst),

  .write_address(addr_internal),
  .write_data(data_in),
  .write_enable(1'b1),

  .clkb(clkb),
  .read_address(addr),
  .read_data(data)
);

endmodule

