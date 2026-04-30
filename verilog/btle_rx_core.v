// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

`define KEEP_FOR_DBG (*mark_debug="true",DONT_TOUCH="TRUE"*)

`timescale 1ns / 1ps
module btle_rx_core #
(
  parameter integer GFSK_DEMODULATION_BIT_WIDTH = 16,
  parameter integer LEN_UNIQUE_BIT_SEQUENCE = 32,
  parameter integer CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter integer CRC_STATE_BIT_WIDTH = 24,
  parameter integer NUM_BIT_PAYLOAD_LENGTH = 8 // 8 bit in the core spec 6.2
) (
  input wire clk,
  `KEEP_FOR_DBG input wire rst,

  input wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] unique_bit_sequence,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit,

  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i,
  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q,
  input wire iq_valid,

  `KEEP_FOR_DBG output wire hit_flag,
  `KEEP_FOR_DBG output wire [(NUM_BIT_PAYLOAD_LENGTH-1) : 0] payload_length_out,
  `KEEP_FOR_DBG output reg  payload_length_valid,

  `KEEP_FOR_DBG output wire info_bit,
  `KEEP_FOR_DBG output wire bit_valid,

  `KEEP_FOR_DBG output reg  [7:0] octet,
  `KEEP_FOR_DBG output reg  octet_valid,

  `KEEP_FOR_DBG output reg  decode_end,
  `KEEP_FOR_DBG output reg  crc_ok
);

localparam [1:0] IDLE           = 0,
                 EXTRACT_LENGTH = 1,
                 CHECK_CRC      = 2;

reg [NUM_BIT_PAYLOAD_LENGTH : 0] payload_length;
// `KEEP_FOR_DBG wire adv_pdu_flag; // not needed. according to core spec 6.2 all pdu has the same payload length field position
// wire hit_flag;
`KEEP_FOR_DBG wire phy_bit;
`KEEP_FOR_DBG wire phy_bit_valid;
wire [(CRC_STATE_BIT_WIDTH-1) : 0] lfsr;
wire [(CRC_STATE_BIT_WIDTH-1) : 0] crc24_bit;

`KEEP_FOR_DBG reg        bit_valid_delay;
`KEEP_FOR_DBG reg  [1:0] phy_rx_state;
`KEEP_FOR_DBG reg  [(NUM_BIT_PAYLOAD_LENGTH+3):0] bit_count;
`KEEP_FOR_DBG wire [NUM_BIT_PAYLOAD_LENGTH:0] octet_count;
// reg  [6:0] payload_length;

// assign adv_pdu_flag = (channel_number==37 || channel_number==38 || channel_number==39);

assign octet_count = bit_count[(NUM_BIT_PAYLOAD_LENGTH+3):3];

assign crc24_bit = lfsr;

assign payload_length_out = payload_length[(NUM_BIT_PAYLOAD_LENGTH-1) : 0];

// state machine to extract payload length and check crc
always @ (posedge clk) begin
  if (rst) begin
    bit_valid_delay <= 0;
    octet <= 0;
    octet_valid <= 0;
    bit_count <= 0;
    payload_length <= 0;
    payload_length_valid <= 0;
    decode_end <= 0;
    crc_ok <= 0;

    phy_rx_state <= IDLE;
  end else begin
    bit_valid_delay <= bit_valid;
    case(phy_rx_state)
      IDLE: begin
        octet <= 0;
        octet_valid <= 0;
        bit_count <= 0;
        payload_length <= 0;
        payload_length_valid <= 0;
        decode_end <= 0;
        crc_ok <= 0;

        phy_rx_state <= (hit_flag? EXTRACT_LENGTH : phy_rx_state);
      end

      EXTRACT_LENGTH: begin
        if (bit_valid) begin
          octet[7] <= info_bit;
          octet[6:0] <= octet[7:1];

          bit_count <= bit_count + 1;
        end
        if (octet_count == 2) begin
          // payload_length <= (adv_pdu_flag? octet[5:0] : octet[4:0]);
          payload_length <= octet;
          payload_length_valid <= 1;
          bit_count <= 0;
          phy_rx_state <= CHECK_CRC;
        end
        octet_valid <= (octet_count>=1? (bit_valid_delay && bit_count[2:0] == 0) : octet_valid);
      end
      
      CHECK_CRC: begin
        payload_length_valid <= 0;
        if (bit_valid) begin
          octet[7] <= info_bit;
          octet[6:0] <= octet[7:1];
          
          // $display("%d", info_bit);

          bit_count <= bit_count + 1;
        end

        octet_valid <= (bit_valid_delay && bit_count[2:0] == 0);

        if (octet_count == (payload_length+3)) begin
          // $display("payload_length %d", payload_length);
          // $display("crc24_bit    %06h", crc24_bit);
          
          decode_end <= 1;
          crc_ok <= (crc24_bit == 0);

          phy_rx_state <= IDLE;
        end 
        // else if (octet_count <= payload_length) begin
        //   octet_valid <= (bit_valid_delay && bit_count[2:0] == 0);
        // end else begin
        //   octet_valid <= 0;
        // end
      end
    endcase
  end
end

gfsk_demodulation # (
  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH)
) gfsk_demodulation_i (
  .clk(clk),
  .rst(rst),

  .i(i),
  .q(q),
  .iq_valid(iq_valid),

  .signal_for_decision(),
  .signal_for_decision_valid(),
  
  .phy_bit(phy_bit),
  .bit_valid(phy_bit_valid)
);

search_unique_bit_sequence # (
  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE)
) search_unique_bit_sequence_i (
  .clk(clk),
  .rst(rst),

  .phy_bit(phy_bit),
  .bit_valid(phy_bit_valid),
  .unique_bit_sequence(unique_bit_sequence),

  .hit_flag(hit_flag)
);

scramble_core # (
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH)
) scramble_core_i (
  .clk(clk),
  .rst(rst|hit_flag),

  .channel_number(channel_number),
  .channel_number_load(1'b0),
  .data_in(phy_bit),
  .data_in_valid(phy_bit_valid),

  .data_out(info_bit),
  .data_out_valid(bit_valid)
);

crc24_core # (
  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH)
) crc24_core_i (
  .clk(clk),
  .rst(rst|hit_flag),

  .crc_state_init_bit(crc_state_init_bit),
  .crc_state_init_bit_load(1'b0),
  .data_in(info_bit),
  .data_in_valid(bit_valid),

  .lfsr(lfsr)
);

endmodule

