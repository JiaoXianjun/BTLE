// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o btle_tx_tb btle_tx_tb.v btle_tx.v dpram.v crc24.v crc24_core.v scramble.v scramble_core.v gfsk_modulation.v bit_repeat_upsample.v gauss_filter.v vco.v
// vvp btle_tx_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module btle_tx_tb #
(
  parameter CRC_STATE_BIT_WIDTH = 24,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32,
  parameter PREAMBLE_BIT_WIDTH = 8,
  parameter SAMPLE_PER_SYMBOL = 8,
  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter NUM_TAP_GAUSS_FILTER = 17,
  parameter VCO_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8,
  parameter GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1
) (
);

reg clk;
reg rst;

reg [64*8:0] BTLE_CONFIG_FILENAME = "btle_config.txt";
reg [64*8:0] GAUSS_FILTER_TAP_FILENAME = "gauss_filter_tap.txt";
reg [64*8:0] COS_TABLE_FILENAME = "cos_table.txt";
reg [64*8:0] SIN_TABLE_FILENAME = "sin_table.txt";
reg [64*8:0] TEST_INPUT_FILENAME = "btle_tx_test_input.txt";
reg [64*8:0] TEST_OUTPUT_I_REF_FILENAME = "btle_tx_test_output_i_ref.txt";
reg [64*8:0] TEST_OUTPUT_Q_REF_FILENAME = "btle_tx_test_output_q_ref.txt";
reg [64*8:0] TEST_OUTPUT_I_FILENAME = "btle_tx_test_output_i.txt";
reg [64*8:0] TEST_OUTPUT_Q_FILENAME = "btle_tx_test_output_q.txt";

reg [(CRC_STATE_BIT_WIDTH-1) : 0] CRC_STATE_INIT_BIT;
reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] CHANNEL_NUMBER;
reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] ACCESS_ADDRESS;
reg [(PREAMBLE_BIT_WIDTH-1) : 0] PREAMBLE;
reg [31:0] btle_config_mem [0:31];
reg signed [(GAUSS_FILTER_BIT_WIDTH-1):0] gauss_filter_tap_mem [0:63];
reg signed [(IQ_BIT_WIDTH-1):0] cos_table_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] sin_table_mem [0:4095];

reg [7:0]  btle_tx_test_input_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_i_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_q_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_i_ref_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_q_ref_mem [0:4095];

integer gauss_filter_tap_fd;
integer cos_table_fd;
integer sin_table_fd;
integer btle_tx_test_input_fd;
integer btle_tx_test_output_i_fd;
integer btle_tx_test_output_q_fd;
integer btle_tx_test_output_i_ref_fd;
integer btle_tx_test_output_q_ref_fd;
integer NUM_OCTET_INPUT;
integer NUM_SAMPLE_OUTPUT;
integer NUM_ERROR;
integer i;
integer tmp;

initial begin
  $dumpfile("btle_tx_tb.vcd");
  $dumpvars;
  $readmemh(BTLE_CONFIG_FILENAME, btle_config_mem);

  CHANNEL_NUMBER = btle_config_mem[1];
  $display("CHANNEL_NUMBER %d", CHANNEL_NUMBER);

  CRC_STATE_INIT_BIT = btle_config_mem[2];
  $display("CRC_STATE_INIT_BIT %06x", CRC_STATE_INIT_BIT);

  // ACCESS_ADDRESS = btle_config_mem[3];
  // byte re-order
  ACCESS_ADDRESS[7 :0]  = btle_config_mem[3][31:24];
  ACCESS_ADDRESS[15:8]  = btle_config_mem[3][23:16];
  ACCESS_ADDRESS[23:16] = btle_config_mem[3][15:8];
  ACCESS_ADDRESS[31:24] = btle_config_mem[3][7 :0];
  $display("ACCESS_ADDRESS %08x", ACCESS_ADDRESS);

  if (CHANNEL_NUMBER == 37 || CHANNEL_NUMBER == 38 || CHANNEL_NUMBER == 39) begin
    PREAMBLE = 8'haa;
  end else begin
    PREAMBLE = 8'h55;
  end
  $display("PREAMBLE %02x", PREAMBLE);

  // read test input
  // $readmemh("btle_tx_test_input.txt", btle_tx_test_input_mem);
  $display("Reading input from %s", TEST_INPUT_FILENAME);
  NUM_OCTET_INPUT = 0;
  btle_tx_test_input_fd = $fopen(TEST_INPUT_FILENAME, "r");
  tmp = $fscanf(btle_tx_test_input_fd, "%h", btle_tx_test_input_mem[NUM_OCTET_INPUT]);
  while(tmp == 1) begin
    NUM_OCTET_INPUT = NUM_OCTET_INPUT + 1;
    tmp = $fscanf(btle_tx_test_input_fd, "%h", btle_tx_test_input_mem[NUM_OCTET_INPUT]);
  end
  $fclose(btle_tx_test_input_fd);
  $display("%d read finish for test input.", NUM_OCTET_INPUT);

  // read test output reference
  $display("Reading output ref from %s", TEST_OUTPUT_I_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  btle_tx_test_output_i_ref_fd = $fopen(TEST_OUTPUT_I_REF_FILENAME, "r");
  tmp = $fscanf(btle_tx_test_output_i_ref_fd, "%d", btle_tx_test_output_i_ref_mem[NUM_SAMPLE_OUTPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_OUTPUT = NUM_SAMPLE_OUTPUT + 1;
    tmp = $fscanf(btle_tx_test_output_i_ref_fd, "%d", btle_tx_test_output_i_ref_mem[NUM_SAMPLE_OUTPUT]);
  end
  $fclose(btle_tx_test_output_i_ref_fd);
  $display("%d read finish for test output cos ref.", NUM_SAMPLE_OUTPUT);

  $display("Reading output ref from %s", TEST_OUTPUT_Q_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  btle_tx_test_output_q_ref_fd = $fopen(TEST_OUTPUT_Q_REF_FILENAME, "r");
  tmp = $fscanf(btle_tx_test_output_q_ref_fd, "%d", btle_tx_test_output_q_ref_mem[NUM_SAMPLE_OUTPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_OUTPUT = NUM_SAMPLE_OUTPUT + 1;
    tmp = $fscanf(btle_tx_test_output_q_ref_fd, "%d", btle_tx_test_output_q_ref_mem[NUM_SAMPLE_OUTPUT]);
  end
  $fclose(btle_tx_test_output_q_ref_fd);
  $display("%d read finish for test output sin ref.", NUM_SAMPLE_OUTPUT);

  // read gauss filter tap
  $display("Reading from %s", GAUSS_FILTER_TAP_FILENAME);
  gauss_filter_tap_fd = $fopen(GAUSS_FILTER_TAP_FILENAME, "r");
  for (i=0; i<((NUM_TAP_GAUSS_FILTER+1)/2); i=i+1) begin
    tmp = $fscanf(gauss_filter_tap_fd, "%d", gauss_filter_tap_mem[i]);
  end
  $fclose(gauss_filter_tap_fd);

  // read cos and sin table
  cos_table_fd = $fopen(COS_TABLE_FILENAME, "r");
  for (i=0; i<(1<<SIN_COS_ADDR_BIT_WIDTH); i=i+1) begin
    tmp = $fscanf(cos_table_fd, "%d", cos_table_mem[i]);
    // if (i%2 == 0) // error injection
    //   cos_table_mem[i] = 0;
  end
  $fclose(cos_table_fd);

  sin_table_fd = $fopen(SIN_TABLE_FILENAME, "r");
  for (i=0; i<(1<<SIN_COS_ADDR_BIT_WIDTH); i=i+1) begin
    tmp = $fscanf(sin_table_fd, "%d", sin_table_mem[i]);
    // if (i%2 == 0) // error injection
    //   sin_table_mem[i] = 0;
  end
  $fclose(sin_table_fd);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg [3:0] gauss_filter_tap_index; // only need to set 0~8, 9~16 will be mirror of 0~7
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] gauss_filter_tap_value;

reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] cos_table_write_address;
reg signed [(IQ_BIT_WIDTH-1) : 0] cos_table_write_data;
reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] sin_table_write_address;
reg signed [(IQ_BIT_WIDTH-1) : 0] sin_table_write_data;

reg [7:0]  preamble;

reg [31:0] access_address;
reg [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit;
reg crc_state_init_bit_load;
reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number;
reg channel_number_load;

reg [7:0] pdu_octet_mem_data;
reg [5:0] pdu_octet_mem_addr;

wire tx_start;

wire signed [(IQ_BIT_WIDTH-1) : 0] i_signal;
wire signed [(IQ_BIT_WIDTH-1) : 0] q_signal;
wire iq_valid;
wire iq_valid_last;
reg  iq_valid_last_delay;

// for debug purpose
wire phy_bit;
wire phy_bit_valid;
wire phy_bit_valid_last;

wire bit_upsample;
wire bit_upsample_valid;
wire bit_upsample_valid_last;

wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] bit_upsample_gauss_filter;
wire bit_upsample_gauss_filter_valid;
wire bit_upsample_gauss_filter_valid_last;

// test process
reg  gauss_filter_tap_init_done;
reg  sin_cos_table_init_done;
reg  pkt_mem_init_done;
wire all_init_done;
reg  all_init_done_delay;
reg  [31:0] clk_count;
reg  [31:0] sample_out_count;

reg  [31:0] phy_bit_count;
reg  [31:0] bit_upsample_count;
reg  [31:0] bit_upsample_gauss_filter_count;

assign all_init_done = (gauss_filter_tap_init_done&sin_cos_table_init_done&pkt_mem_init_done);
assign tx_start = (all_init_done == 1 && all_init_done_delay == 0);

always @ (posedge clk) begin
  if (rst) begin
    gauss_filter_tap_index <= 0;
    gauss_filter_tap_value <= 0;

    cos_table_write_address <= 0;
    cos_table_write_data <= 0;
    sin_table_write_address <= 0;
    sin_table_write_data <= 0;

    preamble <= PREAMBLE;
    access_address <= ACCESS_ADDRESS;
    crc_state_init_bit <= CRC_STATE_INIT_BIT;
    channel_number <= CHANNEL_NUMBER;
    crc_state_init_bit_load <= 0;
    channel_number_load <= 0;

    pdu_octet_mem_data <= 0;
    pdu_octet_mem_addr <= 0;

    gauss_filter_tap_init_done <= 0;
    sin_cos_table_init_done <= 0;
    pkt_mem_init_done <= 0;
    all_init_done_delay <= 0;

    clk_count <= 0;
    sample_out_count <= 0;

    iq_valid_last_delay <= 0;

    phy_bit_count <= 0;
    bit_upsample_count <= 0;
    bit_upsample_gauss_filter_count <= 0;
  end else begin
    clk_count <= clk_count + 1;

    preamble <= PREAMBLE;
    access_address <= ACCESS_ADDRESS;
    crc_state_init_bit <= CRC_STATE_INIT_BIT;
    channel_number <= CHANNEL_NUMBER;

    all_init_done_delay <= all_init_done;

    iq_valid_last_delay <= iq_valid_last;

    if (clk_count < 9) begin
      gauss_filter_tap_index <= clk_count;
      gauss_filter_tap_value <= gauss_filter_tap_mem[clk_count];
    end else if (clk_count == 9) begin
      gauss_filter_tap_init_done <= 1;
      $display("gauss filter taps initialized.");
    end

    if (clk_count < (1<<SIN_COS_ADDR_BIT_WIDTH)) begin
      cos_table_write_address <= clk_count;
      cos_table_write_data <= cos_table_mem[clk_count];
      sin_table_write_address <= clk_count;
      sin_table_write_data <= sin_table_mem[clk_count];
    end else if (clk_count == (1<<SIN_COS_ADDR_BIT_WIDTH)) begin
      sin_cos_table_init_done <= 1;
      $display("cos sin table initialized.");
    end

    if (clk_count < NUM_OCTET_INPUT) begin
      pdu_octet_mem_addr <= clk_count;
      pdu_octet_mem_data <= btle_tx_test_input_mem[clk_count];
    end else if (clk_count == NUM_OCTET_INPUT) begin
      pkt_mem_init_done <= 1;
      $display("tx pkt mem initialized.");
    end

    if (sample_out_count == 4095) begin
      $display("sample_out_count %d", sample_out_count);
      $display("Should NOT finish here!");
      $finish;
    end

    if (iq_valid_last_delay) begin
      $display("clk_count %d", clk_count);
      $display("phy_bit_count %d", phy_bit_count);
      $display("bit_upsample_count %d", bit_upsample_count);
      $display("bit_upsample_gauss_filter_count %d", bit_upsample_gauss_filter_count);
      $display("sample_out_count %d", sample_out_count);

      $display("Save output I to %s", TEST_OUTPUT_I_FILENAME);
      btle_tx_test_output_i_fd = $fopen(TEST_OUTPUT_I_FILENAME, "w");
      for (i=0; i<sample_out_count; i=i+1) begin
        $fwrite(btle_tx_test_output_i_fd, "%d\n", btle_tx_test_output_i_mem[i]);
      end
      $fflush(btle_tx_test_output_i_fd);
      $fclose(btle_tx_test_output_i_fd);

      $display("Save output Q to %s", TEST_OUTPUT_Q_FILENAME);
      btle_tx_test_output_i_fd = $fopen(TEST_OUTPUT_Q_FILENAME, "w");
      for (i=0; i<sample_out_count; i=i+1) begin
        $fwrite(btle_tx_test_output_i_fd, "%d\n", btle_tx_test_output_q_mem[i]);
      end
      $fflush(btle_tx_test_output_i_fd);
      $fclose(btle_tx_test_output_i_fd);

      // check the output and the reference
      NUM_ERROR = 0;
      for (i=0; i<NUM_SAMPLE_OUTPUT; i=i+1) begin
        if (btle_tx_test_output_i_mem[i] != btle_tx_test_output_i_ref_mem[i]) begin
          NUM_ERROR = NUM_ERROR + 1;
        end
      end
      if (NUM_ERROR > 0) begin
        $display("%d error found!", NUM_ERROR);
        $display("Please check %s VS %s", TEST_OUTPUT_I_FILENAME, TEST_OUTPUT_I_REF_FILENAME);
      end else begin
        $display("%d error found! output I Test PASS.", NUM_ERROR);
      end

      NUM_ERROR = 0;
      for (i=0; i<NUM_SAMPLE_OUTPUT; i=i+1) begin
        if (btle_tx_test_output_q_mem[i] != btle_tx_test_output_q_ref_mem[i]) begin
          NUM_ERROR = NUM_ERROR + 1;
        end
      end
      if (NUM_ERROR > 0) begin
        $display("%d error found!", NUM_ERROR);
        $display("Please check %s VS %s", TEST_OUTPUT_Q_FILENAME, TEST_OUTPUT_Q_REF_FILENAME);
      end else begin
        $display("%d error found! output Q Test PASS.", NUM_ERROR);
      end

      $finish;
    end

    // record the result
    if (iq_valid) begin
      btle_tx_test_output_i_mem[sample_out_count] <= i_signal;
      btle_tx_test_output_q_mem[sample_out_count] <= q_signal;
      sample_out_count <= sample_out_count + 1;
    end

    if (phy_bit_valid) begin
      phy_bit_count <= phy_bit_count + 1;
    end

    if (bit_upsample_valid) begin
      bit_upsample_count <= bit_upsample_count + 1;
    end

    if (bit_upsample_gauss_filter_valid) begin
      bit_upsample_gauss_filter_count <= bit_upsample_gauss_filter_count + 1;
    end
  end
end

btle_tx # (
.CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH),
.CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
.SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL),
.GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
.NUM_TAP_GAUSS_FILTER(NUM_TAP_GAUSS_FILTER),
.VCO_BIT_WIDTH(VCO_BIT_WIDTH),
.SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
.IQ_BIT_WIDTH(IQ_BIT_WIDTH),
.GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT(GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT)
) btle_tx_i (
  .clk(clk),
  .rst(rst),

  .gauss_filter_tap_index(gauss_filter_tap_index),
  .gauss_filter_tap_value(gauss_filter_tap_value),

  .cos_table_write_address(cos_table_write_address),
  .cos_table_write_data(cos_table_write_data),
  .sin_table_write_address(sin_table_write_address),
  .sin_table_write_data(sin_table_write_data),
  
  .preamble(preamble),

  .access_address(access_address),
  .crc_state_init_bit(crc_state_init_bit),
  .crc_state_init_bit_load(crc_state_init_bit_load),
  .channel_number(channel_number),
  .channel_number_load(channel_number_load),

  .pdu_octet_mem_data(pdu_octet_mem_data),
  .pdu_octet_mem_addr(pdu_octet_mem_addr),

  .tx_start(tx_start),

  .i(i_signal),
  .q(q_signal),
  .iq_valid(iq_valid),
  .iq_valid_last(iq_valid_last),

  // for debug purpose
  .phy_bit(phy_bit),
  .phy_bit_valid(phy_bit_valid),
  .phy_bit_valid_last(phy_bit_valid_last),

  .bit_upsample(bit_upsample),
  .bit_upsample_valid(bit_upsample_valid),
  .bit_upsample_valid_last(bit_upsample_valid_last),

  .bit_upsample_gauss_filter(bit_upsample_gauss_filter),
  .bit_upsample_gauss_filter_valid(bit_upsample_gauss_filter_valid),
  .bit_upsample_gauss_filter_valid_last(bit_upsample_gauss_filter_valid_last)
);

endmodule
