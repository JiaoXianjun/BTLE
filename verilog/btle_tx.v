// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// iverilog -o btle_tx btle_tx.v sdpram_one_clk.v sdpram_two_clk.v crc24.v crc24_core.v scramble.v scramble_core.v gfsk_modulation.v bit_repeat_upsample.v gauss_filter.v vco.v 

`define KEEP_FOR_DBG (*mark_debug="true",DONT_TOUCH="TRUE"*)
// `define KEEP_FOR_DBG

`timescale 1ns / 1ps
module btle_tx #
(
  parameter integer NUM_BIT_PAYLOAD_LENGTH = 8, // 8 bit in the core spec 6.2
  parameter integer CRC_STATE_BIT_WIDTH = 24,
  parameter integer CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter integer SAMPLE_PER_SYMBOL = 8,
  parameter integer GAUSS_FILTER_BIT_WIDTH = 16,
  parameter integer NUM_TAP_GAUSS_FILTER = 17,
  parameter integer VCO_BIT_WIDTH = 16,
  parameter integer SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter integer IQ_BIT_WIDTH = 8,
  parameter integer GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1
) (
  input wire clk, // for baseband processing, 16MHz
  input wire rst,

  input wire clkb, // for writing pkt to ram with different/higher clock speed

  `KEEP_FOR_DBG input wire [3:0] gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  `KEEP_FOR_DBG input wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap_value,
  
  `KEEP_FOR_DBG input  wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] cos_table_write_address,
  `KEEP_FOR_DBG input  wire signed [(IQ_BIT_WIDTH-1) : 0] cos_table_write_data,
  `KEEP_FOR_DBG input  wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] sin_table_write_address,
  `KEEP_FOR_DBG input  wire signed [(IQ_BIT_WIDTH-1) : 0] sin_table_write_data,

  `KEEP_FOR_DBG input  wire [7:0]  preamble,

  `KEEP_FOR_DBG input  wire [31:0] access_address,
  `KEEP_FOR_DBG input  wire [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit, // load into lfsr (linear feedback shift register) upon crc_state_init_bit_load==1
  `KEEP_FOR_DBG input  wire crc_state_init_bit_load,
  `KEEP_FOR_DBG input  wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number, // load into lfsr (linear feedback shift register) upon channel_number_load==1
  `KEEP_FOR_DBG input  wire channel_number_load,

  `KEEP_FOR_DBG input  wire [7:0] pdu_octet_mem_data,
  `KEEP_FOR_DBG input  wire [NUM_BIT_PAYLOAD_LENGTH:0] pdu_octet_mem_addr,

  `KEEP_FOR_DBG input  wire tx_start,

  `KEEP_FOR_DBG output wire signed [(IQ_BIT_WIDTH-1) : 0] i,
  `KEEP_FOR_DBG output wire signed [(IQ_BIT_WIDTH-1) : 0] q,
  `KEEP_FOR_DBG output wire iq_valid,
  `KEEP_FOR_DBG output wire iq_valid_last,

  // for debug purpose
  `KEEP_FOR_DBG output wire phy_bit,
  `KEEP_FOR_DBG output wire phy_bit_valid,
  `KEEP_FOR_DBG output wire phy_bit_valid_last,

  `KEEP_FOR_DBG output wire bit_upsample,
  `KEEP_FOR_DBG output wire bit_upsample_valid,
  `KEEP_FOR_DBG output wire bit_upsample_valid_last,

  `KEEP_FOR_DBG output wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] bit_upsample_gauss_filter,
  `KEEP_FOR_DBG output wire bit_upsample_gauss_filter_valid,
  `KEEP_FOR_DBG output wire bit_upsample_gauss_filter_valid_last
);

localparam [1:0] IDLE               = 0,
                 TX_PREAMBLE_ACCESS = 1,
                 TX_PDU             = 2,
                 WAIT_LAST_SAMPLE   = 3;

`KEEP_FOR_DBG reg  [1:0] phy_tx_state;
`KEEP_FOR_DBG reg  [NUM_BIT_PAYLOAD_LENGTH:0] addr;
`KEEP_FOR_DBG wire [7:0] data;
`KEEP_FOR_DBG reg  [7:0] octet;
// wire adv_pdu_flag;
`KEEP_FOR_DBG reg  [NUM_BIT_PAYLOAD_LENGTH:0] payload_length;
`KEEP_FOR_DBG reg  [(NUM_BIT_PAYLOAD_LENGTH+3):0] bit_count;
`KEEP_FOR_DBG reg  [5:0] bit_count_preamble_access;

`KEEP_FOR_DBG reg info_bit;
`KEEP_FOR_DBG reg info_bit_valid;
`KEEP_FOR_DBG reg info_bit_valid_last;

`KEEP_FOR_DBG reg  [39:0] preamble_access_address;

`KEEP_FOR_DBG wire info_bit_after_crc24;
`KEEP_FOR_DBG wire info_bit_after_crc24_valid;
`KEEP_FOR_DBG wire info_bit_after_crc24_valid_last;

// wire phy_bit;
// wire phy_bit_valid;
// wire phy_bit_valid_last;

`KEEP_FOR_DBG wire signed [(IQ_BIT_WIDTH-1) : 0] i_internal;
`KEEP_FOR_DBG wire signed [(IQ_BIT_WIDTH-1) : 0] q_internal;

`KEEP_FOR_DBG reg [6:0] clk_count; // assume clk speed 16M, baseband phy_bit rate 1M. octet rate 1/8M. need 128x clk speed down to read octet memory.

// assign adv_pdu_flag = (channel_number==37 || channel_number==38 || channel_number==39);

assign i = (phy_tx_state == IDLE? 0 : i_internal);
assign q = (phy_tx_state == IDLE? 0 : q_internal);

// state machine to extract payload length and check crc
always @ (posedge clk) begin
  if (rst) begin
    addr <= 0;
    octet <= 0;

    payload_length <= 0;
    bit_count_preamble_access <= 0;
    bit_count <= 0;

    preamble_access_address <= 0;
    info_bit <= 0;
    info_bit_valid <= 0;
    info_bit_valid_last <= 0;

    clk_count <= 0;

    phy_tx_state <= IDLE;
  end else begin
    // if (phy_bit_valid) begin
    //   $display("%d", phy_bit);
    // end
    
    case(phy_tx_state)
      IDLE: begin
        addr <= 0;
        octet <= 0;

        payload_length <= {(NUM_BIT_PAYLOAD_LENGTH+1){1'b1}};
        bit_count_preamble_access <= 0;
        bit_count <= 0;

        info_bit <= 0;
        info_bit_valid <= 0;
        info_bit_valid_last <= 0;

        clk_count <= 0;

        preamble_access_address <= (tx_start? {access_address, preamble} : preamble_access_address);
        phy_tx_state <= (tx_start? TX_PREAMBLE_ACCESS : phy_tx_state);
      end

      TX_PREAMBLE_ACCESS: begin
        clk_count <= clk_count + 1;
        if (clk_count[3:0] == 1) begin // speed 1M
          info_bit <= preamble_access_address[0];
          info_bit_valid <= 1;
          preamble_access_address[38:0] <= preamble_access_address[39:1];

          bit_count_preamble_access <= bit_count_preamble_access + 1;

          if (bit_count_preamble_access == (40 - 1)) begin
            phy_tx_state <= TX_PDU;
          end
        end else begin
          info_bit_valid <= 0;
        end
      end

      TX_PDU: begin
        clk_count <= clk_count + 1;
        if (clk_count == 0) begin // speed 1/8M
          addr <= addr + 1;
          octet <= data;
        end
        if (clk_count[3:0] == 1) begin // speed 1M
          info_bit <= octet[0];
          info_bit_valid <= 1;
          octet[6:0] <= octet[7:1];

          bit_count <= bit_count + 1;

          if (bit_count == ((payload_length+2)*8 - 1)) begin
            info_bit_valid_last <= 1;
            phy_tx_state <= WAIT_LAST_SAMPLE;
          end
        end else begin
          info_bit_valid <= 0;
        end

        if (addr == 2 && clk_count == 1) begin
          // payload_length <= (adv_pdu_flag? octet[5:0] : octet[4:0]);
          payload_length <= {{(NUM_BIT_PAYLOAD_LENGTH+1-8){1'b0}}, octet};
        end

        if (addr == 2 && clk_count == 2) begin
          $display("payload_length %d", payload_length);
        end
      end
      
      WAIT_LAST_SAMPLE: begin
        info_bit_valid <= 0;
        info_bit_valid_last <= 0;
        phy_tx_state <= (iq_valid_last? IDLE : phy_tx_state);
      end
    endcase
  end
end

sdpram_two_clk # ( // 1 more addr bit is needed: the octet_valid actually will output 2 bytes header, payload length, 3 bytes CRC
  .DATA_WIDTH(8),
  .ADDRESS_WIDTH(NUM_BIT_PAYLOAD_LENGTH+1)
) btle_tx_sdpram_two_clk_i (
  .clk(clkb),
  .rst(rst),

  .write_address(pdu_octet_mem_addr),
  .write_data(pdu_octet_mem_data),
  .write_enable(1'b1),

  .clkb(clk),
  .read_address(addr),
  .read_data(data)
);

crc24 # (
  .NUM_BIT_PAYLOAD_LENGTH(NUM_BIT_PAYLOAD_LENGTH),
  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH)        
) crc24_i (
  .clk(clk),
  .rst(rst),

  .crc_state_init_bit(crc_state_init_bit),
  .crc_state_init_bit_load(crc_state_init_bit_load),

  .info_bit(info_bit),
  .info_bit_valid(info_bit_valid),
  .info_bit_valid_last(info_bit_valid_last),
  
  .info_bit_after_crc24(info_bit_after_crc24),
  .info_bit_after_crc24_valid(info_bit_after_crc24_valid),
  .info_bit_after_crc24_valid_last(info_bit_after_crc24_valid_last)
);

scramble # (
  .NUM_BIT_PAYLOAD_LENGTH(NUM_BIT_PAYLOAD_LENGTH),
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH)
) scramble_i (
  .clk(clk),
  .rst(rst),

  .channel_number(channel_number),
  .channel_number_load(channel_number_load),

  .data_in(info_bit_after_crc24),
  .data_in_valid(info_bit_after_crc24_valid),
  .data_in_valid_last(info_bit_after_crc24_valid_last),

  .data_out(phy_bit),
  .data_out_valid(phy_bit_valid),
  .data_out_valid_last(phy_bit_valid_last)
);

gfsk_modulation # (
  .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL),
  .GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
  .NUM_TAP_GAUSS_FILTER(NUM_TAP_GAUSS_FILTER),
  .VCO_BIT_WIDTH(VCO_BIT_WIDTH),
  .SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
  .IQ_BIT_WIDTH(IQ_BIT_WIDTH),
  .GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT(GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT)
) gfsk_modulation_i (
  .clk(clk),
  .rst(rst),

  .gauss_filter_tap_index(gauss_filter_tap_index), // only need to set 0~8, 9~16 will be mirror of 0~7
  .gauss_filter_tap_value(gauss_filter_tap_value),
  
  .cos_table_write_address(cos_table_write_address),
  .cos_table_write_data(cos_table_write_data),
  .sin_table_write_address(sin_table_write_address),
  .sin_table_write_data(sin_table_write_data),

  .phy_bit(phy_bit),
  .bit_valid(phy_bit_valid),
  .bit_valid_last(phy_bit_valid_last),

  .cos_out(i_internal),
  .sin_out(q_internal),
  .sin_cos_out_valid(iq_valid),
  .sin_cos_out_valid_last(iq_valid_last),

  .bit_upsample(bit_upsample),
  .bit_upsample_valid(bit_upsample_valid),
  .bit_upsample_valid_last(bit_upsample_valid_last),

  .bit_upsample_gauss_filter(bit_upsample_gauss_filter),
  .bit_upsample_gauss_filter_valid(bit_upsample_gauss_filter_valid),
  .bit_upsample_gauss_filter_valid_last(bit_upsample_gauss_filter_valid_last)
);

endmodule

