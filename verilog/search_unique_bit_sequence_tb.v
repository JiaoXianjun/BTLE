// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o search_unique_bit_sequence_tb search_unique_bit_sequence_tb.v search_unique_bit_sequence.v
// vvp search_unique_bit_sequence_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module search_unique_bit_sequence_tb #
(
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32
) (
);

reg clk;
reg rst;

reg [64*8:0] BTLE_CONFIG_FILENAME = "btle_config.txt";
reg [64*8:0] TEST_INPUT_FILENAME = "btle_rx_search_unique_bit_sequence_test_input.txt";
reg [64*8:0] TEST_OUTPUT_REF_FILENAME = "btle_rx_search_unique_bit_sequence_test_output_ref.txt";

reg [31:0] btle_config_mem [0:31];
reg signed [0:0] search_unique_bit_sequence_test_input_mem [0:4095];
reg signed [15:0] search_unique_bit_sequence_test_output_ref_mem [0:3];

reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] ACCESS_ADDRESS;

integer search_unique_bit_sequence_test_input_fd;
integer search_unique_bit_sequence_test_output_ref_fd;
integer NUM_BIT_INPUT;
integer NUM_SAMPLE_OUTPUT;
integer tmp;
integer i, j;

initial begin
  $dumpfile("search_unique_bit_sequence_tb.vcd");
  $dumpvars;
  $readmemh(BTLE_CONFIG_FILENAME, btle_config_mem);
  // ACCESS_ADDRESS = btle_config_mem[3];
  // byte re-order
  ACCESS_ADDRESS[7 :0]  = btle_config_mem[3][31:24];
  ACCESS_ADDRESS[15:8]  = btle_config_mem[3][23:16];
  ACCESS_ADDRESS[23:16] = btle_config_mem[3][15:8];
  ACCESS_ADDRESS[31:24] = btle_config_mem[3][7 :0];
  $display("ACCESS_ADDRESS %08x", ACCESS_ADDRESS);

  // read test input
  $display("Reading input from %s", TEST_INPUT_FILENAME);
  NUM_BIT_INPUT = 0;
  search_unique_bit_sequence_test_input_fd = $fopen(TEST_INPUT_FILENAME, "r");
  tmp = $fscanf(search_unique_bit_sequence_test_input_fd, "%h", search_unique_bit_sequence_test_input_mem[NUM_BIT_INPUT]);
  while(tmp == 1) begin
    NUM_BIT_INPUT = NUM_BIT_INPUT + 1;
    tmp = $fscanf(search_unique_bit_sequence_test_input_fd, "%h", search_unique_bit_sequence_test_input_mem[NUM_BIT_INPUT]);
  end
  $fclose(search_unique_bit_sequence_test_input_fd);
  $display("%d read finish from %s", NUM_BIT_INPUT, TEST_INPUT_FILENAME);

  // read test output reference
  $display("Reading output ref from %s", TEST_OUTPUT_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  search_unique_bit_sequence_test_output_ref_fd = $fopen(TEST_OUTPUT_REF_FILENAME, "r");
  tmp = $fscanf(search_unique_bit_sequence_test_output_ref_fd, "%d", search_unique_bit_sequence_test_output_ref_mem[NUM_SAMPLE_OUTPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_OUTPUT = NUM_SAMPLE_OUTPUT + 1;
    tmp = $fscanf(search_unique_bit_sequence_test_output_ref_fd, "%d", search_unique_bit_sequence_test_output_ref_mem[NUM_SAMPLE_OUTPUT]);
  end
  $fclose(search_unique_bit_sequence_test_output_ref_fd);
  $display("%d read finish from %s", NUM_SAMPLE_OUTPUT, TEST_OUTPUT_REF_FILENAME);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg bit;
reg bit_valid;
reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] unique_bit_sequence;

wire hit_flag;

// test process
reg [31:0] clk_count;
reg [31:0] bit_in_count;
always @ (posedge clk) begin
  if (rst) begin
    bit <= 0;
    bit_valid <= 0;
    unique_bit_sequence <= 0;

    clk_count <= 1;
    bit_in_count <= 0;
  end else begin
    clk_count <= clk_count + 1;

    unique_bit_sequence <= ACCESS_ADDRESS;

    if (clk_count[3:0] == 0) begin // speed 1M
      if (bit_in_count < NUM_BIT_INPUT) begin
        bit <= search_unique_bit_sequence_test_input_mem[bit_in_count];
        bit_valid <= 1;
      end
      bit_in_count <= bit_in_count + 1;
    end else begin
      bit_valid <= 0;
    end

    if (bit_in_count == (NUM_BIT_INPUT+30)) begin
      $display("%d input", NUM_BIT_INPUT);
      $finish;
    end

    // display while bit sequence hit
    if (hit_flag) begin
      $display("unique_bit_sequence full match at the %dth bit", bit_in_count);
      $display("unique_bit_sequence starting idx %d", bit_in_count - LEN_UNIQUE_BIT_SEQUENCE);
      $display("Compare the unique_bit_sequence starting idx and the search_unique_bit_sequence_test_output_ref_mem[0] ...");
      if ((bit_in_count - LEN_UNIQUE_BIT_SEQUENCE) == search_unique_bit_sequence_test_output_ref_mem[0]) begin
        $display("Same as python result %d. Test PASS.", search_unique_bit_sequence_test_output_ref_mem[0]);
      end else begin
        $display("Different from python result %d", search_unique_bit_sequence_test_output_ref_mem[0]);
      end
    end

  end
end

search_unique_bit_sequence # (
  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE)
) search_unique_bit_sequence_i (
  .clk(clk),
  .rst(rst),

  .phy_bit(bit),
  .bit_valid(bit_valid),
  .unique_bit_sequence(unique_bit_sequence),

  .hit_flag(hit_flag)
);

endmodule

