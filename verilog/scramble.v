// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// Core_v5.3 figure3.5 on page 2735

`timescale 1ns / 1ps
module scramble #
(
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6
) (
  input wire clk,
  input wire rst,

  input  wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number, // load into lfsr (linear feedback shift register) upon channel_number_load==1
  input  wire channel_number_load,
  input  wire data_in,
  input  wire data_in_valid,
  input  wire data_in_valid_last, // if this is true together with valid, it means last bit input
  output wire data_out,
  output wire data_out_valid,
  output wire data_out_valid_last // indicate last bit out together with data_out_valid
);

localparam [0:0] IDLE           = 0,
                 WORK_ON_INPUT  = 1;

reg [0:0] scramble_state;

wire data_in_valid_internal;
wire data_out_internal;
wire data_out_valid_internal;
wire scramble_start_for_input;
wire scramble_start_for_output;

reg data_in_delay;
reg data_in_valid_delay;
reg data_in_valid_last_delay;

reg [8:0] data_in_count;

assign scramble_start_for_input = (data_in_count>=40);
assign data_in_valid_internal = (scramble_start_for_input? data_in_valid : 0);

assign scramble_start_for_output = (data_in_count>=41);
assign data_out = (scramble_start_for_output? data_out_internal : data_in_delay);

assign data_out_valid = data_in_valid_delay;
assign data_out_valid_last = data_in_valid_last_delay;

scramble_core # (
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH)
) crc24_core_i (
  .clk(clk),
  .rst(rst),

  .channel_number(channel_number),
  .channel_number_load(channel_number_load),
  .data_in(data_in),
  .data_in_valid(data_in_valid_internal),
  .data_out(data_out_internal),
  .data_out_valid(data_out_valid_internal)
);

always @ (posedge clk) begin
  if (rst) begin
    data_in_delay <= 0;
    data_in_valid_delay <= 0;
    data_in_valid_last_delay <= 0;

    data_in_count <= 0;

    scramble_state <= IDLE;
  end else begin
    data_in_delay <= data_in;
    data_in_valid_delay <= data_in_valid;
    data_in_valid_last_delay <= data_in_valid_last;

    case(scramble_state)
      IDLE: begin
        data_in_count <= (data_in_valid ? (data_in_count+1) : data_in_count);

        scramble_state <= (data_in_valid ? WORK_ON_INPUT : scramble_state);
      end

      WORK_ON_INPUT: begin
        if (data_in_valid_last_delay) begin
          data_in_count <= 0;
          scramble_state <= IDLE;
        end else begin
          data_in_count <= (data_in_valid ? (data_in_count+1) : data_in_count);
        end
      end
    endcase
  end
end

endmodule
