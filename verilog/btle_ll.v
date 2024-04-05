// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// This link layer module interfaces with the host via UART HCI (Host Controller Interface), 
// and implements the link layer state machine according to the core spec,
// and control/bridge the phy (btle_tx and btle_rx)

// This is a dummpy module currently for link layer of BTLE
// In the future this could be real logic or a mcu core, such as risc-v

// iverilog -o btle_ll btle_ll.v uart_frame_rx.v  uart_frame_tx.v rx_clk_gen.v  tx_clk_gen.v

`timescale 1ns / 1ps
module btle_ll # (
	parameter	CLK_FREQUENCE	= 16_000_000,	//hz
  parameter BAUD_RATE		= 115200		,		  //9600、19200 、38400 、57600 、115200、230400、460800、921600
  parameter PARITY			= "NONE"	,		  //"NONE","EVEN","ODD"
  parameter FRAME_WD		= 8,					    //if PARITY="NONE",it can be 5~9;else 5~8

  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8,
  parameter CRC_STATE_BIT_WIDTH = 24,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,

  parameter LEN_UNIQUE_BIT_SEQUENCE = 32
) (
  input clk,
  input rst,

  // ====to host: UART HCI====
  input  uart_rx,
  output uart_tx,

  // ====to phy tx====
  output reg [3:0] tx_gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  output reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value,

  output reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address,
  output reg signed [(IQ_BIT_WIDTH-1) : 0] tx_cos_table_write_data,
  output reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address,
  output reg signed [(IQ_BIT_WIDTH-1) : 0] tx_sin_table_write_data,

  output reg [7:0]  tx_preamble,

  output reg [31:0] tx_access_address,
  output reg [(CRC_STATE_BIT_WIDTH-1) : 0] tx_crc_state_init_bit,
  output reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number,

  output reg [7:0] tx_pdu_octet_mem_data,
  output reg [5:0] tx_pdu_octet_mem_addr,
  output reg tx_start,
  input  wire tx_iq_valid_last,

  // ====to phy rx====
  output reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence,
  output reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number,
  output reg [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit,

  input wire  rx_hit_flag,
  input wire  rx_decode_run,
  input wire  rx_decode_end,
  input wire  rx_crc_ok,
  input wire  [6:0] rx_payload_length,

  output  reg  [5:0] rx_pdu_octet_mem_addr,
  input  wire  [7:0] rx_pdu_octet_mem_data
);

localparam [2:0] STANDBY                  = 0,
                 ADVERTISING              = 1,
                 INITIATING               = 2,
                 CONNECTION               = 3,
                 ISOCHRONOUS_BROADCASTING = 4,
                 SCANNING                 = 5,
                 SYNCHRONIZATION          = 6;

// ===========UART===========
// rx
wire [FRAME_WD-1:0]	rx_frame;
wire rx_done;
wire frame_error;

// tx
reg  frame_en;
reg  [FRAME_WD-1:0]	data_frame;
wire tx_done;
// ===========UART===========

wire [7:0] all_input;

assign all_input = ({7'd0, tx_iq_valid_last}|
                   ({7'd0, rx_hit_flag}<<1)|
                   ({7'd0, rx_decode_run}<<2)|
                   ({7'd0, rx_decode_end}<<3)|
                   ({7'd0, rx_crc_ok}<<4)|
                    {1'd0, rx_payload_length}|
                    rx_pdu_octet_mem_data&
                  (({7'd0, frame_error}<<5)|
                  ( {7'd0, rx_done}<<6)|
                           rx_frame));

reg [2:0] ll_state;
always @ (posedge clk) begin
  if (rst) begin
    tx_gauss_filter_tap_index <= 0;
    tx_gauss_filter_tap_value <= 0;

    tx_cos_table_write_address <= 0;
    tx_cos_table_write_data <= 0;
    tx_sin_table_write_address <= 0;
    tx_sin_table_write_data <= 0;

    tx_preamble <= 0;

    tx_access_address <= 0;
    tx_crc_state_init_bit <= 0;
    tx_channel_number <= 0;

    tx_pdu_octet_mem_data <= 0;
    tx_pdu_octet_mem_addr <= 0;
    tx_start <= 0;

    rx_unique_bit_sequence <= 0;
    rx_channel_number <= 0;
    rx_crc_state_init_bit <= 0;
    
    frame_en <= 0;
    data_frame <= 0;

    ll_state <= STANDBY;
  end else begin
    case(ll_state)
      STANDBY: begin
        // dummy logic. actual logic to be done
        tx_gauss_filter_tap_index <= tx_gauss_filter_tap_index+ 1;
        tx_gauss_filter_tap_value <= tx_gauss_filter_tap_value+ 1;

        tx_cos_table_write_address <= tx_cos_table_write_address+ 1;
        tx_cos_table_write_data <= tx_cos_table_write_data+ 1;
        tx_sin_table_write_address <= tx_sin_table_write_address+ 1;
        tx_sin_table_write_data <= tx_sin_table_write_data+ 1;

        tx_preamble <= tx_preamble + 1;

        tx_access_address <= tx_access_address + 1;
        tx_crc_state_init_bit <= tx_crc_state_init_bit + 1;
        tx_channel_number <= tx_channel_number + 1;

        tx_pdu_octet_mem_data <= tx_pdu_octet_mem_data + 1;
        tx_pdu_octet_mem_addr <= tx_pdu_octet_mem_addr + 1;
        tx_start <= tx_start + 1;

        rx_unique_bit_sequence <= rx_unique_bit_sequence + 1;
        rx_channel_number <= rx_channel_number + 1;
        rx_crc_state_init_bit <= rx_crc_state_init_bit + 1;

        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;

        frame_en <= frame_en + 1;
        data_frame <= data_frame + 1;

        if (all_input == 1)
          ll_state <= ADVERTISING;
      end
      ADVERTISING: begin
        // dummy logic. actual logic to be done
        tx_gauss_filter_tap_index <= tx_gauss_filter_tap_index+ 1;
        tx_gauss_filter_tap_value <= tx_gauss_filter_tap_value+ 1;

        tx_cos_table_write_address <= tx_cos_table_write_address+ 1;
        tx_cos_table_write_data <= tx_cos_table_write_data+ 1;
        tx_sin_table_write_address <= tx_sin_table_write_address+ 1;
        tx_sin_table_write_data <= tx_sin_table_write_data+ 1;

        tx_preamble <= tx_preamble + 1;

        tx_access_address <= tx_access_address + 1;
        tx_crc_state_init_bit <= tx_crc_state_init_bit + 1;
        tx_channel_number <= tx_channel_number + 1;

        tx_pdu_octet_mem_data <= tx_pdu_octet_mem_data + 1;
        tx_pdu_octet_mem_addr <= tx_pdu_octet_mem_addr + 1;
        tx_start <= tx_start + 1;

        rx_unique_bit_sequence <= rx_unique_bit_sequence + 1;
        rx_channel_number <= rx_channel_number + 1;
        rx_crc_state_init_bit <= rx_crc_state_init_bit + 1;

        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;

        frame_en <= frame_en + 1;
        data_frame <= data_frame + 1;

        if (all_input == 2)
          ll_state <= INITIATING;
      end
      INITIATING: begin
        // dummy logic. actual logic to be done
        tx_gauss_filter_tap_index <= tx_gauss_filter_tap_index+ 1;
        tx_gauss_filter_tap_value <= tx_gauss_filter_tap_value+ 1;

        tx_cos_table_write_address <= tx_cos_table_write_address+ 1;
        tx_cos_table_write_data <= tx_cos_table_write_data+ 1;
        tx_sin_table_write_address <= tx_sin_table_write_address+ 1;
        tx_sin_table_write_data <= tx_sin_table_write_data+ 1;

        tx_preamble <= tx_preamble + 1;

        tx_access_address <= tx_access_address + 1;
        tx_crc_state_init_bit <= tx_crc_state_init_bit + 1;
        tx_channel_number <= tx_channel_number + 1;

        tx_pdu_octet_mem_data <= tx_pdu_octet_mem_data + 1;
        tx_pdu_octet_mem_addr <= tx_pdu_octet_mem_addr + 1;
        tx_start <= tx_start + 1;

        rx_unique_bit_sequence <= rx_unique_bit_sequence + 1;
        rx_channel_number <= rx_channel_number + 1;
        rx_crc_state_init_bit <= rx_crc_state_init_bit + 1;

        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;

        frame_en <= frame_en + 1;
        data_frame <= data_frame + 1;

        if (all_input == 4)
          ll_state <= CONNECTION;
      end
      CONNECTION: begin
        // dummy logic. actual logic to be done
        tx_gauss_filter_tap_index <= tx_gauss_filter_tap_index+ 1;
        tx_gauss_filter_tap_value <= tx_gauss_filter_tap_value+ 1;

        tx_cos_table_write_address <= tx_cos_table_write_address+ 1;
        tx_cos_table_write_data <= tx_cos_table_write_data+ 1;
        tx_sin_table_write_address <= tx_sin_table_write_address+ 1;
        tx_sin_table_write_data <= tx_sin_table_write_data+ 1;

        tx_preamble <= tx_preamble + 1;

        tx_access_address <= tx_access_address + 1;
        tx_crc_state_init_bit <= tx_crc_state_init_bit + 1;
        tx_channel_number <= tx_channel_number + 1;

        tx_pdu_octet_mem_data <= tx_pdu_octet_mem_data + 1;
        tx_pdu_octet_mem_addr <= tx_pdu_octet_mem_addr + 1;
        tx_start <= tx_start + 1;

        rx_unique_bit_sequence <= rx_unique_bit_sequence + 1;
        rx_channel_number <= rx_channel_number + 1;
        rx_crc_state_init_bit <= rx_crc_state_init_bit + 1;

        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;

        frame_en <= frame_en + 1;
        data_frame <= data_frame + 1;

        if (all_input == 8)
          ll_state <= ISOCHRONOUS_BROADCASTING;
      end
      ISOCHRONOUS_BROADCASTING: begin
        // dummy logic. actual logic to be done
        tx_gauss_filter_tap_index <= tx_gauss_filter_tap_index+ 1;
        tx_gauss_filter_tap_value <= tx_gauss_filter_tap_value+ 1;

        tx_cos_table_write_address <= tx_cos_table_write_address+ 1;
        tx_cos_table_write_data <= tx_cos_table_write_data+ 1;
        tx_sin_table_write_address <= tx_sin_table_write_address+ 1;
        tx_sin_table_write_data <= tx_sin_table_write_data+ 1;

        tx_preamble <= tx_preamble + 1;

        tx_access_address <= tx_access_address + 1;
        tx_crc_state_init_bit <= tx_crc_state_init_bit + 1;
        tx_channel_number <= tx_channel_number + 1;

        tx_pdu_octet_mem_data <= tx_pdu_octet_mem_data + 1;
        tx_pdu_octet_mem_addr <= tx_pdu_octet_mem_addr + 1;
        tx_start <= tx_start + 1;

        rx_unique_bit_sequence <= rx_unique_bit_sequence + 1;
        rx_channel_number <= rx_channel_number + 1;
        rx_crc_state_init_bit <= rx_crc_state_init_bit + 1;

        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;

        frame_en <= frame_en + 1;
        data_frame <= data_frame + 1;

        if (all_input == 16)
          ll_state <= SCANNING;
      end
      SCANNING: begin
        // dummy logic. actual logic to be done
        tx_gauss_filter_tap_index <= tx_gauss_filter_tap_index+ 1;
        tx_gauss_filter_tap_value <= tx_gauss_filter_tap_value+ 1;

        tx_cos_table_write_address <= tx_cos_table_write_address+ 1;
        tx_cos_table_write_data <= tx_cos_table_write_data+ 1;
        tx_sin_table_write_address <= tx_sin_table_write_address+ 1;
        tx_sin_table_write_data <= tx_sin_table_write_data+ 1;

        tx_preamble <= tx_preamble + 1;

        tx_access_address <= tx_access_address + 1;
        tx_crc_state_init_bit <= tx_crc_state_init_bit + 1;
        tx_channel_number <= tx_channel_number + 1;

        tx_pdu_octet_mem_data <= tx_pdu_octet_mem_data + 1;
        tx_pdu_octet_mem_addr <= tx_pdu_octet_mem_addr + 1;
        tx_start <= tx_start + 1;

        rx_unique_bit_sequence <= rx_unique_bit_sequence + 1;
        rx_channel_number <= rx_channel_number + 1;
        rx_crc_state_init_bit <= rx_crc_state_init_bit + 1;

        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;

        frame_en <= frame_en + 1;
        data_frame <= data_frame + 1;

        if (all_input == 32)
          ll_state <= SYNCHRONIZATION;
      end
      SYNCHRONIZATION: begin
        // dummy logic. actual logic to be done
        tx_gauss_filter_tap_index <= tx_gauss_filter_tap_index+ 1;
        tx_gauss_filter_tap_value <= tx_gauss_filter_tap_value+ 1;

        tx_cos_table_write_address <= tx_cos_table_write_address+ 1;
        tx_cos_table_write_data <= tx_cos_table_write_data+ 1;
        tx_sin_table_write_address <= tx_sin_table_write_address+ 1;
        tx_sin_table_write_data <= tx_sin_table_write_data+ 1;

        tx_preamble <= tx_preamble + 1;

        tx_access_address <= tx_access_address + 1;
        tx_crc_state_init_bit <= tx_crc_state_init_bit + 1;
        tx_channel_number <= tx_channel_number + 1;

        tx_pdu_octet_mem_data <= tx_pdu_octet_mem_data + 1;
        tx_pdu_octet_mem_addr <= tx_pdu_octet_mem_addr + 1;
        tx_start <= tx_start + 1;

        rx_unique_bit_sequence <= rx_unique_bit_sequence + 1;
        rx_channel_number <= rx_channel_number + 1;
        rx_crc_state_init_bit <= rx_crc_state_init_bit + 1;

        rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;

        frame_en <= frame_en + 1;
        data_frame <= data_frame + 1;

        if (all_input == 64)
          ll_state <= STANDBY;
      end
    endcase
  end
end

uart_frame_tx #(
  .CLK_FREQUENCE(CLK_FREQUENCE),
  .BAUD_RATE(BAUD_RATE),
  .PARITY(PARITY),
  .FRAME_WD(FRAME_WD)
) uart_frame_tx_i (
  .clk(clk),
  .rst_n(!rst),
  .frame_en(frame_en),
  .data_frame(data_frame),
  .tx_done(tx_done),
  .uart_tx(uart_tx)
);

uart_frame_rx #(
  .CLK_FREQUENCE(CLK_FREQUENCE),
  .BAUD_RATE(BAUD_RATE),
  .PARITY(PARITY),
  .FRAME_WD(FRAME_WD)
) uart_frame_rx_i (
  .clk(clk),
  .rst_n(!rst),
  .uart_rx(uart_rx),
  .rx_frame(rx_frame),
  .rx_done(rx_done),
  .frame_error(frame_error)
);

endmodule

