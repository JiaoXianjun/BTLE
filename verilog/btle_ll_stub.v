// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: LicenseRef-MyCompany-Commercial

// This link layer module interfaces with the host via UART HCI (Host Controller Interface), 
// and axi lite interface as alternative channel for configuration and control.
// and implements the link layer state machine according to the core spec,
// and control/bridge the phy (btle_tx and btle_rx)

(* black_box *)

module btle_ll # (
  // Width of S_AXI data bus
  parameter integer C_S_AXI_DATA_WIDTH  = 32,
  // Width of S_AXI address bus
  parameter integer C_S_AXI_ADDR_WIDTH  = 8,

  // parameter CLK_FREQUENCE = 16_000_000, //hz
  parameter CLK_FREQUENCE = 100_000_000, //hz
  parameter BAUD_RATE     = 115200,     //9600、19200 、38400 、57600 、115200、230400、460800、921600
  parameter PARITY        = "NONE",     //"NONE","EVEN","ODD"
  parameter FRAME_WD      = 8,          //if PARITY="NONE",it can be 5~9;else 5~8

  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8,
  parameter CRC_STATE_BIT_WIDTH = 24,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,

  parameter LEN_UNIQUE_BIT_SEQUENCE = 32
) (
  // input clk,
  // input rst,

  // ====to host: UART HCI====
  input  uart_rx,
  output uart_tx,

  // ==========to phy tx======
  output wire [3:0] tx_gauss_filter_tap_index, // only need to set 0~8, 9~16 will be mirror of 0~7
  output wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value,

  output wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_cos_table_write_data,
  output wire [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address,
  output wire signed [(IQ_BIT_WIDTH-1) : 0] tx_sin_table_write_data,

  output wire [7:0]  tx_preamble,

  output wire [31:0] tx_access_address,
  output wire [(CRC_STATE_BIT_WIDTH-1) : 0] tx_crc_state_init_bit,
  output wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] tx_channel_number,

  output wire [7:0] tx_pdu_octet_mem_data,
  output wire [5:0] tx_pdu_octet_mem_addr,
  output wire tx_start,
  input  wire tx_iq_valid_last,

  // =========to phy rx=======
  output wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  rx_unique_bit_sequence,
  output wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] rx_channel_number,
  output wire [(CRC_STATE_BIT_WIDTH-1) : 0]      rx_crc_state_init_bit,

  input  wire rx_hit_flag,
  input  wire rx_decode_run,
  input  wire rx_decode_end,
  input  wire rx_crc_ok,
  input  wire [6:0] rx_payload_length,

  output wire [5:0] rx_pdu_octet_mem_addr,
  input  wire [7:0] rx_pdu_octet_mem_data,

  // Ports of Axi Slave Bus Interface
  input  wire axi_aclk,
  input  wire axi_aresetn,
  input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr,
  input  wire [2 : 0] axi_awprot,
  input  wire axi_awvalid,
  output wire axi_awready,
  input  wire [C_S_AXI_DATA_WIDTH-1 : 0] axi_wdata,
  input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb,
  input  wire axi_wvalid,
  output wire axi_wready,
  output wire [1 : 0] axi_bresp,
  output wire axi_bvalid,
  input  wire axi_bready,
  input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr,
  input  wire [2 : 0] axi_arprot,
  input  wire axi_arvalid,
  output wire axi_arready,
  output wire [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata,
  output wire [1 : 0] axi_rresp,
  output wire axi_rvalid,
  input  wire axi_rready
);
/* synthesis syn_black_box */
endmodule
