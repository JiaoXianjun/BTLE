// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Based on Xilinx UG901 2025-06-11
// https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Simple-Dual-Port-Block-RAM-with-Single-Clock-Verilog
// Simple Dual-Port Block RAM with Single Clock (Verilog)

`timescale 1ns / 1ps
module sdpram_one_clk #
(
  parameter integer DATA_WIDTH = 8,
  parameter integer ADDRESS_WIDTH = 11
) (
  input wire clk,
  input wire rst,

  input wire [ADDRESS_WIDTH-1:0] write_address,
  input wire [DATA_WIDTH-1:0] write_data,
  input wire write_enable,

  input wire [ADDRESS_WIDTH-1:0] read_address,
  output reg [DATA_WIDTH-1:0] read_data
);

reg [DATA_WIDTH-1:0] memory [((1<<ADDRESS_WIDTH)-1):0];

always @ (posedge clk) begin
  if (write_enable) begin
    memory[write_address] <= write_data;
  end
end

always @ (posedge clk) begin
  read_data <= memory[read_address];
end

endmodule
