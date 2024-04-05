// Author: Kenneth Wilke <kenneth.wilke@gmail.com>, Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: ISC License

// Dual-ported parameterized RAM module
// Based on https://github.com/KennethWilke/sv-dpram/blob/master/dpram.sv

// ISC License

// Copyright (c) 2023, Kenneth Wilke <kenneth.wilke@gmail.com>
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.

`timescale 1ns / 1ps
module dpram #
(
  parameter DATA_WIDTH = 8,
  parameter ADDRESS_WIDTH = 11
) (
  input wire clk,
  input wire rst,

  input wire [ADDRESS_WIDTH-1:0] write_address,
  input wire [DATA_WIDTH-1:0] write_data,
  input wire write_enable,

  input wire [ADDRESS_WIDTH-1:0] read_address,
  output wire [DATA_WIDTH-1:0] read_data
);

reg [DATA_WIDTH-1:0] memory [0:(1<<ADDRESS_WIDTH)-1];
integer i;

assign read_data = memory[read_address];

always @ (posedge clk) begin
  if (rst) begin
    // memory <= 0;
    // // for(i=0; i<(1<<ADDRESS_WIDTH); i=i+1)
    // //   memory[i] <= 0;
  end else begin
    if (write_enable) begin
      memory[write_address] <= write_data;
    end
  end
end

endmodule
