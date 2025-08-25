// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

`define KEEP_FOR_DBG (*mark_debug="true",DONT_TOUCH="TRUE"*)

`timescale 1ns / 1ps
module search_unique_bit_sequence #
(
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32
) (
  input wire clk,
  input wire rst,

  `KEEP_FOR_DBG input wire phy_bit,
  `KEEP_FOR_DBG input wire bit_valid,
  `KEEP_FOR_DBG input wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] unique_bit_sequence,
  `KEEP_FOR_DBG output wire hit_flag
);

reg bit_valid_delay1;
`KEEP_FOR_DBG reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] bit_store;

assign hit_flag = (bit_store == unique_bit_sequence)&bit_valid_delay1;

always @ (posedge clk) begin
  if (rst) begin
    bit_store <= 0;
    bit_valid_delay1 <= 0;
  end else begin
    bit_valid_delay1 <= bit_valid;
    if (bit_valid) begin
      bit_store[LEN_UNIQUE_BIT_SEQUENCE-1] <= phy_bit;
      bit_store[(LEN_UNIQUE_BIT_SEQUENCE-2) : 0] <= bit_store[(LEN_UNIQUE_BIT_SEQUENCE-1) : 1];
    end
  end
end

endmodule
