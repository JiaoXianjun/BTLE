// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o scramble_tb scramble_tb.v scramble.v scramble_core.v
// vvp scramble_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module scramble_tb #
(
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6
) (
);

reg clk;
reg rst;

reg [64*8:0] BTLE_CONFIG_FILENAME = "btle_config.txt";
reg [64*8:0] TEST_INPUT_FILENAME = "btle_tx_scramble_test_input.txt";
reg [64*8:0] TEST_OUTPUT_REF_FILENAME = "btle_tx_scramble_test_output_ref.txt";
reg [64*8:0] TEST_OUTPUT_FILENAME = "btle_tx_scramble_test_output.txt";

reg [31:0] btle_config_mem [0:31];
reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] CHANNEL_NUMBER;

reg [0:0] scramble_test_input_mem [0:4095];
reg [0:0] scramble_test_output_mem [0:4095];
reg [0:0] scramble_test_output_ref_mem [0:4095];

integer NUM_BIT_INPUT;
integer scramble_test_input_fd;
integer NUM_BIT_OUTPUT;
integer scramble_test_output_ref_fd;
integer scramble_test_output_fd;
integer NUM_ERROR;
integer i;
integer tmp;

initial begin
  $dumpfile("scramble_tb.vcd");
  $dumpvars;
  $readmemh(BTLE_CONFIG_FILENAME, btle_config_mem);
  CHANNEL_NUMBER = btle_config_mem[1];
  $display("CHANNEL_NUMBER %d", CHANNEL_NUMBER);

  // read test input
  $display("Reading input from %s", TEST_INPUT_FILENAME);
  NUM_BIT_INPUT = 0;
  scramble_test_input_fd = $fopen(TEST_INPUT_FILENAME, "r");
  tmp = $fscanf(scramble_test_input_fd, "%d", scramble_test_input_mem[NUM_BIT_INPUT]);
  while(tmp == 1) begin
    NUM_BIT_INPUT = NUM_BIT_INPUT + 1;
    tmp = $fscanf(scramble_test_input_fd, "%d", scramble_test_input_mem[NUM_BIT_INPUT]);
  end
  $fclose(scramble_test_input_fd);
  $display("%d read finish for test input.", NUM_BIT_INPUT);

  // read test output reference
  $display("Reading output ref from %s", TEST_OUTPUT_REF_FILENAME);
  NUM_BIT_OUTPUT = 0;
  scramble_test_output_ref_fd = $fopen(TEST_OUTPUT_REF_FILENAME, "r");
  tmp = $fscanf(scramble_test_output_ref_fd, "%d", scramble_test_output_ref_mem[NUM_BIT_OUTPUT]);
  while(tmp == 1) begin
    NUM_BIT_OUTPUT = NUM_BIT_OUTPUT + 1;
    tmp = $fscanf(scramble_test_output_ref_fd, "%d", scramble_test_output_ref_mem[NUM_BIT_OUTPUT]);
  end
  $fclose(scramble_test_output_ref_fd);
  $display("%d read finish for test output.", NUM_BIT_OUTPUT);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number;
reg channel_number_load;
reg data_in;
reg data_in_valid;
reg data_in_valid_last;

wire data_out;
wire data_out_valid;
wire data_out_valid_last;

// test process
reg [31:0] clk_count;
reg [31:0] info_bit_count;
reg [31:0] bit_out_count;
reg bit_out_finish;
always @ (posedge clk) begin
  if (rst) begin
    channel_number <= 0;
    channel_number_load <= 0;
    data_in <= 0;
    data_in_valid <= 0;
    data_in_valid_last <= 0;

    clk_count <= 1;
    info_bit_count <= 0;
    bit_out_count <= 0;
    bit_out_finish <= 0;
  end else begin
    channel_number <= CHANNEL_NUMBER;
    clk_count <= clk_count + 1;
    if (clk_count == 3) begin
      channel_number_load <= 1;
      // $display("%h", channel_number);
    end else begin
      channel_number_load <= 0;
    end

    if (clk_count[3:0] == 0) begin // speed 1M
      if (info_bit_count < NUM_BIT_INPUT) begin
        data_in <= scramble_test_input_mem[info_bit_count];
        data_in_valid <= 1;
        if (info_bit_count == (NUM_BIT_INPUT-1)) begin
          data_in_valid_last <= 1;
        end
        // $display("%h", scramble_test_input_mem[info_bit_count]);
      end
      info_bit_count <= info_bit_count + 1;
    end else begin
      data_in_valid <= 0;
      data_in_valid_last <= 0;
    end

    if (info_bit_count == (NUM_BIT_INPUT+30)) begin
      $display("%d input", NUM_BIT_INPUT);
      $display("%d output", bit_out_count);
      $display("Save output to %s", TEST_OUTPUT_FILENAME);
      // $writememh(TEST_OUTPUT_FILENAME, scramble_test_output_mem, 0, bit_out_count-1);
      scramble_test_output_fd = $fopen(TEST_OUTPUT_FILENAME, "w");
      for (i=0; i<bit_out_count; i=i+1) begin
        $fwrite(scramble_test_output_fd, "%d\n", scramble_test_output_mem[i]);
      end
      $fflush(scramble_test_output_fd);
      $fclose(scramble_test_output_fd);

      // check the output and the reference
      $display("Compare the scramble_test_output_mem and the scramble_test_output_ref_mem ...");
      NUM_ERROR = 0;
      for (i=0; i<NUM_BIT_OUTPUT; i=i+1) begin
        if (scramble_test_output_mem[i] != scramble_test_output_ref_mem[i]) begin
          NUM_ERROR = NUM_ERROR + 1;
        end
      end
      if (NUM_ERROR > 0) begin
        $display("%d error found!", NUM_ERROR);
        $display("Please check %s VS %s", TEST_OUTPUT_FILENAME, TEST_OUTPUT_REF_FILENAME);
      end else begin
        $display("%d error found! Test PASS.", NUM_ERROR);
      end
      $finish;
    end

    // record the result
    if (data_out_valid) begin
      scramble_test_output_mem[bit_out_count] <= data_out;
      if (data_out_valid_last) begin
        bit_out_finish <= 1;
      end
      if (bit_out_finish == 0) begin
        bit_out_count <= bit_out_count + 1;
      end
    end
  end
end

scramble # (
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH)        
) scramble_i (
  .clk(clk),
  .rst(rst),

  .channel_number(channel_number),
  .channel_number_load(channel_number_load),
  .data_in(data_in),
  .data_in_valid(data_in_valid),
  .data_in_valid_last(data_in_valid_last),
  .data_out(data_out),
  .data_out_valid(data_out_valid),
  .data_out_valid_last(data_out_valid_last)
);

endmodule

