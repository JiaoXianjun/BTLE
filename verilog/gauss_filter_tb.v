// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o gauss_filter_tb gauss_filter_tb.v gauss_filter.v
// vvp gauss_filter_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module gauss_filter_tb #
(
  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter NUM_TAP_GAUSS_FILTER = 17
  // parameter NUM_BIT_INPUT = 3008
) (
);

reg clk;
reg rst;

reg [64*8:0] GAUSS_FILTER_TAP_FILENAME = "gauss_filter_tap.txt";
reg [64*8:0] TEST_INPUT_FILENAME = "btle_tx_gauss_filter_test_input.txt";
reg [64*8:0] TEST_OUTPUT_REF_FILENAME = "btle_tx_gauss_filter_test_output_ref.txt";
reg [64*8:0] TEST_OUTPUT_FILENAME = "btle_tx_gauss_filter_test_output.txt";

reg signed [(GAUSS_FILTER_BIT_WIDTH-1):0] gauss_filter_tap_mem [0:63];
reg [0:0] gauss_filter_test_input_mem [0:4095];
reg signed [(GAUSS_FILTER_BIT_WIDTH-1):0] gauss_filter_test_output_mem [0:4095];
reg signed [(GAUSS_FILTER_BIT_WIDTH-1):0] gauss_filter_test_output_ref_mem [0:4095];

integer NUM_BIT_INPUT;
integer NUM_SAMPLE_OUTPUT;
integer NUM_ERROR;

integer gauss_filter_tap_fd;
integer gauss_filter_test_input_fd;
integer gauss_filter_test_output_fd;
integer gauss_filter_test_output_ref_fd;
integer i;
integer tmp;

initial begin
  $dumpfile("gauss_filter_tb.vcd");
  $dumpvars;

  // read filter tap
  $display("Reading from %s", GAUSS_FILTER_TAP_FILENAME);
  gauss_filter_tap_fd = $fopen(GAUSS_FILTER_TAP_FILENAME, "r");
  for (i=0; i<((NUM_TAP_GAUSS_FILTER+1)/2); i=i+1) begin
    tmp = $fscanf(gauss_filter_tap_fd, "%d", gauss_filter_tap_mem[i]);
  end
  $fclose(gauss_filter_tap_fd);

  // read test input
  $display("Reading input from %s", TEST_INPUT_FILENAME);
  NUM_BIT_INPUT = 0;
  gauss_filter_test_input_fd = $fopen(TEST_INPUT_FILENAME, "r");
  tmp = $fscanf(gauss_filter_test_input_fd, "%d", gauss_filter_test_input_mem[NUM_BIT_INPUT]);
  while(tmp == 1) begin
    NUM_BIT_INPUT = NUM_BIT_INPUT + 1;
    tmp = $fscanf(gauss_filter_test_input_fd, "%d", gauss_filter_test_input_mem[NUM_BIT_INPUT]);
  end
  $fclose(gauss_filter_test_input_fd);
  $display("%d read finish for test input.", NUM_BIT_INPUT);

  // read test output reference
  $display("Reading output ref from %s", TEST_OUTPUT_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  gauss_filter_test_output_ref_fd = $fopen(TEST_OUTPUT_REF_FILENAME, "r");
  tmp = $fscanf(gauss_filter_test_output_ref_fd, "%d", gauss_filter_test_output_ref_mem[NUM_SAMPLE_OUTPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_OUTPUT = NUM_SAMPLE_OUTPUT + 1;
    tmp = $fscanf(gauss_filter_test_output_ref_fd, "%d", gauss_filter_test_output_ref_mem[NUM_SAMPLE_OUTPUT]);
  end
  $fclose(gauss_filter_test_output_ref_fd);
  $display("%d read finish for test output ref.", NUM_SAMPLE_OUTPUT);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg [3:0] tap_index; // only need to set 0~8, 9~16 will be mirror of 0~7
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tap_value;

reg bit_upsample;
reg bit_upsample_valid;

wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] bit_upsample_gauss_filter;
wire bit_upsample_gauss_filter_valid;

// test process
reg [31:0] clk_count;
reg [31:0] bit_upsample_count;
reg [31:0] bit_upsample_gauss_filter_count;
always @ (posedge clk) begin
  if (rst) begin
    tap_index <= 0;
    tap_value <= 0;

    bit_upsample <= 0;
    bit_upsample_valid <= 0;

    clk_count <= 0;
    bit_upsample_count <= 0;
    bit_upsample_gauss_filter_count <= 0;
  end else begin
    clk_count <= clk_count + 1;

    // Initialize the gauss filter taps
    if (clk_count < 9) begin
      tap_index <= clk_count;
      tap_value <= gauss_filter_tap_mem[clk_count];
    end else if (clk_count == 9) begin
      $display("gauss filter taps initialized.");
    end else begin

      if (clk_count[0] == 0) begin // speed 8M
        if (bit_upsample_count < NUM_BIT_INPUT) begin
          bit_upsample <= gauss_filter_test_input_mem[bit_upsample_count];
          bit_upsample_valid <= 1;
          // $display("%h", gauss_filter_test_input_mem[bit_upsample_count]);
        end
        bit_upsample_count <= bit_upsample_count + 1;
      end else begin
        bit_upsample_valid <= 0;
      end

      if (bit_upsample_count == (NUM_BIT_INPUT+30)) begin
        $display("%d input", NUM_BIT_INPUT);
        $display("%d output", bit_upsample_gauss_filter_count);
        $display("Save output to %s", TEST_OUTPUT_FILENAME);
        
        gauss_filter_test_output_fd = $fopen(TEST_OUTPUT_FILENAME, "w");
        for (i=0; i<bit_upsample_gauss_filter_count; i=i+1) begin
          $fwrite(gauss_filter_test_output_fd, "%d\n", gauss_filter_test_output_mem[i]);
        end
        $fflush(gauss_filter_test_output_fd);
        $fclose(gauss_filter_test_output_fd);

        // check the output and the reference
        $display("Compare the gauss_filter_test_output_mem and the gauss_filter_test_output_ref_mem ...");
        NUM_ERROR = 0;
        for (i=0; i<NUM_SAMPLE_OUTPUT; i=i+1) begin
          // $display("%d %d", gauss_filter_test_output_mem[i], gauss_filter_test_output_ref_mem[i]);
          if (gauss_filter_test_output_mem[i] != gauss_filter_test_output_ref_mem[i]) begin
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
      if (bit_upsample_gauss_filter_valid) begin
        gauss_filter_test_output_mem[bit_upsample_gauss_filter_count] = bit_upsample_gauss_filter;
        bit_upsample_gauss_filter_count <= bit_upsample_gauss_filter_count + 1;
      end

    end
  end
end

gauss_filter # (
  .GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
  .NUM_TAP_GAUSS_FILTER(NUM_TAP_GAUSS_FILTER)
) gauss_filter_i (
  .clk(clk),
  .rst(rst),

  .tap_index(tap_index),
  .tap_value(tap_value),

  .bit_upsample(bit_upsample),
  .bit_upsample_valid(bit_upsample_valid),
  .bit_upsample_valid_last(),
  .bit_upsample_gauss_filter(bit_upsample_gauss_filter),
  .bit_upsample_gauss_filter_valid(bit_upsample_gauss_filter_valid),
  .bit_upsample_gauss_filter_valid_last()
);

endmodule

