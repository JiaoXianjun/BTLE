// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o btle_rx_core_tb btle_rx_core_tb.v btle_rx_core.v gfsk_demodulation.v search_unique_bit_sequence.v scramble_core.v crc24_core.v
// vvp btle_rx_core_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module btle_rx_core_tb #
(
  parameter GFSK_DEMODULATION_BIT_WIDTH = 16,
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter CRC_STATE_BIT_WIDTH = 24
) (
);

reg clk;
reg rst;

reg [64*8:0] BTLE_CONFIG_FILENAME  = "btle_config.txt";
reg [72*8:0] TEST_INPUT_I_FILENAME = "btle_rx_btle_rx_core_test_input_i.txt";
reg [72*8:0] TEST_INPUT_Q_FILENAME = "btle_rx_btle_rx_core_test_input_q.txt";
reg [72*8:0] TEST_OUTPUT_FILENAME  = "btle_rx_btle_rx_core_test_output.txt";
reg [72*8:0] TEST_OUTPUT_REF_FILENAME = "btle_rx_btle_rx_core_test_output_ref.txt";
reg [72*8:0] TEST_OUTPUT_CRC_OK_REF_FILENAME = "btle_rx_btle_rx_core_test_output_crc_ok_ref.txt";

reg [72*8:0] TEST_OUTPUT_BIT_FILENAME  = "btle_rx_btle_rx_core_test_output_bit.txt";

reg [(CRC_STATE_BIT_WIDTH-1) : 0]      CRC_STATE_INIT_BIT;
reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] CHANNEL_NUMBER;
reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  ACCESS_ADDRESS;
reg [31:0] btle_config_mem [0:31];

reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1):0] btle_rx_core_test_input_i_mem [0:4095];
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1):0] btle_rx_core_test_input_q_mem [0:4095];
reg [7:0] btle_rx_core_test_output_mem [0:4095];
reg [7:0] btle_rx_core_test_output_ref_mem [0:4095];
reg [0:0] btle_rx_core_test_output_crc_ok_ref_mem [0:3];

reg [0:0] btle_rx_core_test_output_bit_mem [0:4095];

integer btle_rx_core_test_input_i_fd;
integer btle_rx_core_test_input_q_fd;
integer btle_rx_core_test_output_fd;
integer btle_rx_core_test_output_ref_fd;
integer btle_rx_core_test_output_crc_ok_ref_fd;

integer btle_rx_core_test_output_bit_fd;

integer NUM_SAMPLE_INPUT;
integer NUM_OCTET_OUTPUT;
integer NUM_ERROR;

integer tmp;
integer i, j;

initial begin
  $dumpfile("btle_rx_core_tb.vcd");
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

  // read test input
  $display("Reading input I from %s", TEST_INPUT_I_FILENAME);
  NUM_SAMPLE_INPUT = 0;
  btle_rx_core_test_input_i_fd = $fopen(TEST_INPUT_I_FILENAME, "r");
  tmp = $fscanf(btle_rx_core_test_input_i_fd, "%d", btle_rx_core_test_input_i_mem[NUM_SAMPLE_INPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_INPUT = NUM_SAMPLE_INPUT + 1;
    tmp = $fscanf(btle_rx_core_test_input_i_fd, "%d", btle_rx_core_test_input_i_mem[NUM_SAMPLE_INPUT]);
  end
  $fclose(btle_rx_core_test_input_i_fd);
  $display("%d read finish for test input I.", NUM_SAMPLE_INPUT);
  if (NUM_SAMPLE_INPUT == 0) begin
    $display("NO INPUT! Please increase SNR to make sure at least ACCESS_ADDRESS (unique bit sequence) can be detected!");
    $finish;
  end

  $display("Reading input Q from %s", TEST_INPUT_Q_FILENAME);
  NUM_SAMPLE_INPUT = 0;
  btle_rx_core_test_input_q_fd = $fopen(TEST_INPUT_Q_FILENAME, "r");
  tmp = $fscanf(btle_rx_core_test_input_q_fd, "%d", btle_rx_core_test_input_q_mem[NUM_SAMPLE_INPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_INPUT = NUM_SAMPLE_INPUT + 1;
    tmp = $fscanf(btle_rx_core_test_input_q_fd, "%d", btle_rx_core_test_input_q_mem[NUM_SAMPLE_INPUT]);
  end
  $fclose(btle_rx_core_test_input_q_fd);
  $display("%d read finish for test input Q.", NUM_SAMPLE_INPUT);

  // read test output reference
  $display("Reading output crc_ok ref from %s", TEST_OUTPUT_CRC_OK_REF_FILENAME);
  NUM_OCTET_OUTPUT = 0;
  btle_rx_core_test_output_crc_ok_ref_fd = $fopen(TEST_OUTPUT_CRC_OK_REF_FILENAME, "r");
  tmp = $fscanf(btle_rx_core_test_output_crc_ok_ref_fd, "%h", btle_rx_core_test_output_crc_ok_ref_mem[NUM_OCTET_OUTPUT]);
  while(tmp == 1) begin
    NUM_OCTET_OUTPUT = NUM_OCTET_OUTPUT + 1;
    tmp = $fscanf(btle_rx_core_test_output_crc_ok_ref_fd, "%h", btle_rx_core_test_output_crc_ok_ref_mem[NUM_OCTET_OUTPUT]);
  end
  $fclose(btle_rx_core_test_output_crc_ok_ref_fd);
  $display("%d read finish from %s", NUM_OCTET_OUTPUT, TEST_OUTPUT_CRC_OK_REF_FILENAME);

  $display("Reading output ref from %s", TEST_OUTPUT_REF_FILENAME);
  NUM_OCTET_OUTPUT = 0;
  btle_rx_core_test_output_ref_fd = $fopen(TEST_OUTPUT_REF_FILENAME, "r");
  tmp = $fscanf(btle_rx_core_test_output_ref_fd, "%h", btle_rx_core_test_output_ref_mem[NUM_OCTET_OUTPUT]);
  while(tmp == 1) begin
    NUM_OCTET_OUTPUT = NUM_OCTET_OUTPUT + 1;
    tmp = $fscanf(btle_rx_core_test_output_ref_fd, "%h", btle_rx_core_test_output_ref_mem[NUM_OCTET_OUTPUT]);
  end
  $fclose(btle_rx_core_test_output_ref_fd);
  $display("%d read finish from %s", NUM_OCTET_OUTPUT, TEST_OUTPUT_REF_FILENAME);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] unique_bit_sequence;
reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number;
reg [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit;

reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i_signal;
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q_signal;
reg iq_valid;

wire hit_flag;
wire [6:0] payload_length;
wire payload_length_valid;
wire info_bit;
wire bit_valid;
wire [7:0] octet;
wire octet_valid;
wire decode_end;
wire crc_ok;
reg  crc_ok_store;

// test process
reg [31:0] clk_count;
reg [31:0] sample_in_count;
reg [31:0] bit_out_count;
reg [31:0] octet_out_count;
always @ (posedge clk) begin
  if (rst) begin
    unique_bit_sequence <= ACCESS_ADDRESS;
    channel_number <= CHANNEL_NUMBER;
    crc_state_init_bit <= CRC_STATE_INIT_BIT;

    i_signal <= 0;
    q_signal <= 0;
    iq_valid <= 0;

    clk_count <= 1;
    sample_in_count <= 0;
    bit_out_count <= 0;
    octet_out_count <= 0;

    crc_ok_store <= 0;
  end else begin
    unique_bit_sequence <= ACCESS_ADDRESS;
    channel_number <= CHANNEL_NUMBER;
    crc_state_init_bit <= CRC_STATE_INIT_BIT;

    clk_count <= clk_count + 1;

    if (clk_count[3:0] == 0) begin // speed 1M
      if (sample_in_count < NUM_SAMPLE_INPUT) begin
        i_signal <= btle_rx_core_test_input_i_mem[sample_in_count];
        q_signal <= btle_rx_core_test_input_q_mem[sample_in_count];
        iq_valid <= 1;
      end
      sample_in_count <= sample_in_count + 1;
    end else begin
      iq_valid <= 0;
    end

    if (sample_in_count == (NUM_SAMPLE_INPUT+30)) begin
      $display("%d NUM_SAMPLE_INPUT", NUM_SAMPLE_INPUT);
      $display("%d bit_out_count", bit_out_count);
      $display("%d octet_out_count", octet_out_count);

      $display("Save output bit to %s", TEST_OUTPUT_BIT_FILENAME);
      btle_rx_core_test_output_bit_fd = $fopen(TEST_OUTPUT_BIT_FILENAME, "w");
      for (i=0; i<bit_out_count; i=i+1) begin
        $fwrite(btle_rx_core_test_output_bit_fd, "%d\n", btle_rx_core_test_output_bit_mem[i]);
      end
      $fflush(btle_rx_core_test_output_bit_fd);
      $fclose(btle_rx_core_test_output_bit_fd);

      $display("Save output to %s", TEST_OUTPUT_FILENAME);
      btle_rx_core_test_output_fd = $fopen(TEST_OUTPUT_FILENAME, "w");
      for (i=0; i<octet_out_count; i=i+1) begin
        $fwrite(btle_rx_core_test_output_fd, "%02h\n", btle_rx_core_test_output_mem[i]);
      end
      $fwrite(btle_rx_core_test_output_fd, "\n");
      $fflush(btle_rx_core_test_output_fd);
      $fclose(btle_rx_core_test_output_fd);

      $display("crc_ok flag verilog %d python %d", crc_ok_store, btle_rx_core_test_output_crc_ok_ref_mem[0]);
      if (crc_ok_store == btle_rx_core_test_output_crc_ok_ref_mem[0]) begin
        $display("Test PASS.");
      end else begin
        $display("crc_ok flag is different! Test FAIL.");
      end

      $display("Compare the output and the reference: octet");
      NUM_ERROR = 0;
      for (i=0; i<NUM_OCTET_OUTPUT; i=i+1) begin
        if (btle_rx_core_test_output_ref_mem[i] != btle_rx_core_test_output_mem[i]) begin
          NUM_ERROR = NUM_ERROR + 1;
        end
      end
      $display("%d difference found", NUM_ERROR);
      if (NUM_ERROR > 0) begin
        if (crc_ok_store == 0) begin
          $display("Check %s VS %s", TEST_OUTPUT_FILENAME, TEST_OUTPUT_REF_FILENAME);
          $display("It is normal because CRC IS NOT OK.");
        end else begin
          $display("Please check %s VS %s", TEST_OUTPUT_FILENAME, TEST_OUTPUT_REF_FILENAME);
        end
      end

      $finish;
    end

    // record the result
    if (bit_valid) begin
      btle_rx_core_test_output_bit_mem[bit_out_count] <= info_bit;
      bit_out_count <= bit_out_count + 1;
    end

    // record the result
    if (octet_valid) begin
      btle_rx_core_test_output_mem[octet_out_count] <= octet;
      octet_out_count <= octet_out_count + 1;
    end

    // show some run time intermediate events
    if (hit_flag) begin
      $display("ACCESS_ADDRESS %08x detected", ACCESS_ADDRESS);
    end

    if (payload_length_valid) begin
      $display("payload_length %d octet", payload_length);
    end

    if (decode_end) begin
      crc_ok_store <= crc_ok;
      $display("crc_ok %d", crc_ok);
    end
  end
end

btle_rx_core # (
  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH),
  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE),
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH)
) btle_rx_core_i (
  .clk(clk),
  .rst(rst),

  .unique_bit_sequence(unique_bit_sequence),
  .channel_number(channel_number),
  .crc_state_init_bit(crc_state_init_bit),

  .i(i_signal),
  .q(q_signal),
  .iq_valid(iq_valid),

  .hit_flag(hit_flag),
  .payload_length(payload_length),
  .payload_length_valid(payload_length_valid),

  .info_bit(info_bit),
  .bit_valid(bit_valid),

  .octet(octet),
  .octet_valid(octet_valid),

  .decode_end(decode_end),
  .crc_ok(crc_ok)
);

endmodule

