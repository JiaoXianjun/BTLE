// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// iverilog -o btle_rx btle_rx.v btle_rx_core.v gfsk_demodulation.v search_unique_bit_sequence.v scramble_core.v crc24_core.v serial_in_ram_out.v dpram.v

`timescale 1ns / 1ps
module btle_rx #
(
  parameter SAMPLE_PER_SYMBOL = 8,
  parameter GFSK_DEMODULATION_BIT_WIDTH = 16,
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter CRC_STATE_BIT_WIDTH = 24
) (
  input wire clk,
  input wire rst,

  input wire [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] unique_bit_sequence,
  input wire [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number,
  input wire [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit,

  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i,
  input wire signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q,
  input wire iq_valid,

  output wire hit_flag,
  output reg  decode_run,
  output reg  decode_end,
  output reg  crc_ok,
  output reg  [2:0] best_phase,
  
  output reg  [6:0] payload_length,

  output reg  [7:0] pdu_octet_mem_data,
  input  wire [5:0] pdu_octet_mem_addr
);

// state machine output decode end
localparam [0:0] IDLE                     = 0,
                 WAIT_DECODE_END_LONGEST  = 1;

reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i_store [0 : (SAMPLE_PER_SYMBOL-1)];
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q_store [0 : (SAMPLE_PER_SYMBOL-1)];
reg [(SAMPLE_PER_SYMBOL-1) : 0] iq_valid_store;
reg [2:0] iq_phase;

wire [(SAMPLE_PER_SYMBOL-1) : 0] hit_flag_internal;
wire [6:0] payload_length_internal [0 : (SAMPLE_PER_SYMBOL-1)];
wire [(SAMPLE_PER_SYMBOL-1) : 0] payload_length_valid;
wire [(SAMPLE_PER_SYMBOL-1) : 0] bit_internal;
wire [(SAMPLE_PER_SYMBOL-1) : 0] bit_valid;
wire [7:0] octet_internal [0 : (SAMPLE_PER_SYMBOL-1)];
wire [(SAMPLE_PER_SYMBOL-1) : 0] octet_valid;
wire [(SAMPLE_PER_SYMBOL-1) : 0] decode_end_internal;
wire [(SAMPLE_PER_SYMBOL-1) : 0] crc_ok_internal;

// reg  [5:0] addr_internal [0 : (SAMPLE_PER_SYMBOL-1)];
wire [7:0] data_internal [0 : (SAMPLE_PER_SYMBOL-1)];

reg  [6:0] payload_length_store [0 : (SAMPLE_PER_SYMBOL-1)];
reg  [(SAMPLE_PER_SYMBOL-1) : 0] crc_ok_store;
reg  [(SAMPLE_PER_SYMBOL-1) : 0] decode_end_store;
wire [(SAMPLE_PER_SYMBOL-1) : 0] decode_end_and_crc_ok_store;
reg  [(SAMPLE_PER_SYMBOL-1) : 0] hit_flag_all_phase;

wire [6:0] payload_length_store_wire [0 : (SAMPLE_PER_SYMBOL-1)];

wire hit_flag_any;
reg  hit_flag_any_delay;
wire decode_end_all;
wire decode_end_any;
wire decode_end_early;

// reg       timeout_count_enable;
// reg [3:0] timeout_count_sample;
reg [0:0] decode_end_state;

assign payload_length_store_wire[0] = payload_length_store[0];
assign payload_length_store_wire[1] = payload_length_store[1];
assign payload_length_store_wire[2] = payload_length_store[2];
assign payload_length_store_wire[3] = payload_length_store[3];
assign payload_length_store_wire[4] = payload_length_store[4];
assign payload_length_store_wire[5] = payload_length_store[5];
assign payload_length_store_wire[6] = payload_length_store[6];
assign payload_length_store_wire[7] = payload_length_store[7];

assign hit_flag_any = (|hit_flag_all_phase);
assign decode_end_all = (&decode_end_store);
assign decode_end_any = (|decode_end_store);
assign decode_end_and_crc_ok_store = (decode_end_store&crc_ok_store);
assign decode_end_early = (|decode_end_and_crc_ok_store);

assign hit_flag = (hit_flag_any==1 && hit_flag_any_delay==0);

// output interface
always @ (posedge clk) begin
  if (rst) begin
    decode_run <= 0;
    hit_flag_any_delay <= 0;
    decode_end <= 0;
    crc_ok <= 0;
    best_phase <= 0;
    payload_length <= 0;

    decode_end_state <= IDLE;
    // timeout_count_sample <= 0;
    // timeout_count_enable <= 0;
  end else begin
    hit_flag_any_delay <= hit_flag_any;

    if (hit_flag) begin
      decode_run <= 1;
    end else if (decode_end) begin
      decode_run <= 0;
    end

    case (decode_end_and_crc_ok_store)
      8'h01 : begin 
        best_phase <= 0;
        payload_length <= payload_length_store_wire[0];
        end
      8'h02 : begin 
        best_phase <= 1;
        payload_length <= payload_length_store_wire[1];
        end
      8'h04 : begin 
        best_phase <= 2;
        payload_length <= payload_length_store_wire[2];
        end
      8'h08 : begin 
        best_phase <= 3;
        payload_length <= payload_length_store_wire[3];
        end
      8'h10 : begin 
        best_phase <= 4;
        payload_length <= payload_length_store_wire[4];
        end
      8'h20 : begin 
        best_phase <= 5;
        payload_length <= payload_length_store_wire[5];
        end
      8'h40 : begin 
        best_phase <= 6;
        payload_length <= payload_length_store_wire[6];
        end
      8'h80 : begin 
        best_phase <= 7;
        payload_length <= payload_length_store_wire[7];
        end
      default:begin 
        best_phase <= best_phase;
        payload_length <= payload_length;
        end
    endcase

    case(decode_end_state)
      IDLE: begin
        decode_end <= 0;
        crc_ok <= 0;
        // timeout_count_sample <= 0;
        // timeout_count_enable <= 0;
        decode_end_state <= (hit_flag? WAIT_DECODE_END_LONGEST : decode_end_state);
      end

      WAIT_DECODE_END_LONGEST: begin
        // timeout_count_enable <= (decode_end_any == 1? 1 : timeout_count_enable);
        // timeout_count_sample <= ( (iq_valid && timeout_count_enable)? (timeout_count_sample+1) : timeout_count_sample);

        if (decode_end_early) begin
          decode_end <= 1;
          crc_ok <= 1;
          decode_end_state <= IDLE;
        // end else if (timeout_count_sample == SAMPLE_PER_SYMBOL) begin // issue decode_end_any happens much earlier than the correct decode_end&crc_ok, this case will terminate the whole rx too early!
        end else if (decode_end_all) begin // worse case, all decoder runs to the end without crc_ok
          decode_end <= 1;
          decode_end_state <= IDLE;
        end
      end

    endcase

  end
end

// output selector
always @* begin
  case (best_phase)
      3'd0 : begin 
        pdu_octet_mem_data = data_internal[0]; 
        end
      3'd1 : begin 
        pdu_octet_mem_data = data_internal[1]; 
        end
      3'd2 : begin 
        pdu_octet_mem_data = data_internal[2]; 
        end
      3'd3 : begin 
        pdu_octet_mem_data = data_internal[3]; 
        end
      3'd4 : begin 
        pdu_octet_mem_data = data_internal[4]; 
        end
      3'd5 : begin 
        pdu_octet_mem_data = data_internal[5]; 
        end
      3'd6 : begin 
        pdu_octet_mem_data = data_internal[6]; 
        end
      3'd7 : begin
        pdu_octet_mem_data = data_internal[7]; 
        end
  endcase
end

// distribute sample into all 8 phases
integer idx;
always @ (posedge clk) begin
  if (rst) begin
    iq_valid_store <= 0;
    iq_phase <= 0;
    // generate
      for (idx=0; idx<SAMPLE_PER_SYMBOL; idx = idx + 1) begin
        i_store[idx] <= 0;
        q_store[idx] <= 0;
      end
    // endgenerate
  end else begin
    if (iq_valid) begin
      iq_phase <= iq_phase + 1;
      i_store[iq_phase] <= i;
      q_store[iq_phase] <= q;
      iq_valid_store <= (1<<iq_phase);
    end else begin
      iq_valid_store <= 0;
    end
  end
end

genvar gen_idx;
generate
  for (gen_idx=0; gen_idx<SAMPLE_PER_SYMBOL; gen_idx=gen_idx+1) begin
    btle_rx_core # (
      .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH),
      .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE),
      .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
      .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH)
    ) btle_rx_core_i (
      .clk(clk),
      .rst(rst|decode_end_early|decode_end_all),

      .unique_bit_sequence(unique_bit_sequence),
      .channel_number(channel_number),
      .crc_state_init_bit(crc_state_init_bit),

      .i(i_store[gen_idx]),
      .q(q_store[gen_idx]),
      .iq_valid(iq_valid_store[gen_idx]),

      .hit_flag(hit_flag_internal[gen_idx]),
      .payload_length(payload_length_internal[gen_idx]),
      .payload_length_valid(payload_length_valid[gen_idx]),

      .info_bit(bit_internal[gen_idx]),
      .bit_valid(bit_valid[gen_idx]),

      .octet(octet_internal[gen_idx]),
      .octet_valid(octet_valid[gen_idx]),

      .decode_end(decode_end_internal[gen_idx]),
      .crc_ok(crc_ok_internal[gen_idx])
    );

    serial_in_ram_out # (
      .DATA_WIDTH(8),
      .ADDRESS_WIDTH(6)
    ) serial_in_ram_out_i (
      .clk(clk),
      .rst(rst|hit_flag_internal[gen_idx]),

      .data_in(octet_internal[gen_idx]),
      .data_in_valid(octet_valid[gen_idx]),

      .addr(pdu_octet_mem_addr),
      .data(data_internal[gen_idx])
    );

    always @ (posedge clk) begin
      if (rst|hit_flag_internal[gen_idx]) begin
        payload_length_store[gen_idx] <= 0;
      end else if (payload_length_valid[gen_idx]) begin
        payload_length_store[gen_idx] <= payload_length_internal[gen_idx];
      end
    end

    always @ (posedge clk) begin
      // if (rst|hit_flag_internal[gen_idx]|decode_end_early|decode_end_all) begin
      if (rst|hit_flag_internal[gen_idx]) begin
        crc_ok_store[gen_idx] <= 0;
        decode_end_store[gen_idx] <= 0;
      end else if (decode_end_internal[gen_idx]) begin
        crc_ok_store[gen_idx] <= crc_ok_internal[gen_idx];
        decode_end_store[gen_idx] <= 1;
      end
    end

    always @ (posedge clk) begin
      if (rst|decode_end_internal[gen_idx]|decode_end_early|decode_end_all) begin
        hit_flag_all_phase[gen_idx] <= 0;
      end else if (hit_flag_internal[gen_idx]) begin
        hit_flag_all_phase[gen_idx] <= 1;
      end
    end
  end
endgenerate

endmodule
