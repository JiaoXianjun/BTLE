// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Core_v5.3 figure3.4 on page 2734

`timescale 1ns / 1ps
module crc24_core #
(
  parameter CRC_STATE_BIT_WIDTH = 24
) (
  input wire clk,
  input wire rst,

  input  wire [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit, // load into lfsr (linear feedback shift register) upon crc_state_init_bit_load==1
  input  wire crc_state_init_bit_load,
  input  wire data_in,
  input  wire data_in_valid,
  output reg  [(CRC_STATE_BIT_WIDTH-1) : 0] lfsr
);

wire [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit_switch;
wire new_bit;

assign crc_state_init_bit_switch[7:0] = crc_state_init_bit[(16+7):(16+0)];
assign crc_state_init_bit_switch[(8+7):(8+0)] = crc_state_init_bit[(8+7):(8+0)];
assign crc_state_init_bit_switch[(16+7):(16+0)] = crc_state_init_bit[7:0];

assign new_bit = lfsr[23]^data_in;

always @ (posedge clk) begin
  if (rst) begin
    // lfsr <= 0;
    lfsr <= crc_state_init_bit_switch;
  end else begin
    if (crc_state_init_bit_load) begin
      lfsr <= crc_state_init_bit_switch;
    end else begin
      if (data_in_valid) begin
        // $display("%h %d %d", lfsr, data_in, new_bit);
        lfsr[0] <= new_bit;
        lfsr[1] <= lfsr[0]^new_bit;
        lfsr[2] <= lfsr[1];
        lfsr[3] <= lfsr[2]^new_bit;
        lfsr[4] <= lfsr[3]^new_bit;
        lfsr[5] <= lfsr[4];
        lfsr[6] <= lfsr[5]^new_bit;
        lfsr[7] <= lfsr[6];
        lfsr[8] <= lfsr[7];
        lfsr[9] <= lfsr[8]^new_bit;
        lfsr[10] <= lfsr[9]^new_bit;
        lfsr[23:11] <= lfsr[22:10];
      end
    end
  end
end

endmodule

