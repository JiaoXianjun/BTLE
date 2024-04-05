// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o crc24_tb crc24_tb.v crc24.v crc24_core.v
// vvp crc24_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module crc24_tb #
(
  parameter CRC_STATE_BIT_WIDTH = 24
) (
);

reg clk;
reg rst;

reg [64*8:0] BTLE_CONFIG_FILENAME = "btle_config.txt";
reg [64*8:0] TEST_INPUT_FILENAME = "btle_tx_crc24_test_input.txt";
reg [64*8:0] TEST_OUTPUT_REF_FILENAME = "btle_tx_crc24_test_output_ref.txt";
reg [64*8:0] TEST_OUTPUT_FILENAME = "btle_tx_crc24_test_output.txt";

reg [31:0] btle_config_mem [0:31];
reg [(CRC_STATE_BIT_WIDTH-1) : 0] CRC_STATE_INIT_BIT;

reg [0:0] crc24_test_input_mem [0:4095];
reg [0:0] crc24_test_output_mem [0:4095];
reg [0:0] crc24_test_output_ref_mem [0:4095];

integer NUM_BIT_INPUT;
integer crc24_test_input_fd;
integer NUM_BIT_OUTPUT;
integer crc24_test_output_ref_fd;
integer crc24_test_output_fd;
integer NUM_ERROR;
integer i;
integer tmp;
initial begin
  $dumpfile("crc24_tb.vcd");
  $dumpvars;
  $readmemh(BTLE_CONFIG_FILENAME, btle_config_mem);
  CRC_STATE_INIT_BIT = btle_config_mem[2];
  $display("CRC_STATE_INIT_BIT %06x", CRC_STATE_INIT_BIT);

  // read test input
  $display("Reading input from %s", TEST_INPUT_FILENAME);
  NUM_BIT_INPUT = 0;
  crc24_test_input_fd = $fopen(TEST_INPUT_FILENAME, "r");
  tmp = $fscanf(crc24_test_input_fd, "%d", crc24_test_input_mem[NUM_BIT_INPUT]);
  while(tmp == 1) begin
    NUM_BIT_INPUT = NUM_BIT_INPUT + 1;
    tmp = $fscanf(crc24_test_input_fd, "%d", crc24_test_input_mem[NUM_BIT_INPUT]);
  end
  $fclose(crc24_test_input_fd);
  $display("%d read finish for test input.", NUM_BIT_INPUT);

  // read test output reference
  $display("Reading output ref from %s", TEST_OUTPUT_REF_FILENAME);
  NUM_BIT_OUTPUT = 0;
  crc24_test_output_ref_fd = $fopen(TEST_OUTPUT_REF_FILENAME, "r");
  tmp = $fscanf(crc24_test_output_ref_fd, "%d", crc24_test_output_ref_mem[NUM_BIT_OUTPUT]);
  while(tmp == 1) begin
    NUM_BIT_OUTPUT = NUM_BIT_OUTPUT + 1;
    tmp = $fscanf(crc24_test_output_ref_fd, "%d", crc24_test_output_ref_mem[NUM_BIT_OUTPUT]);
  end
  $fclose(crc24_test_output_ref_fd);
  $display("%d read finish for test output ref.", NUM_BIT_OUTPUT);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit;
reg crc_state_init_bit_load;
reg info_bit;
reg info_bit_valid;
reg info_bit_valid_last;

wire info_bit_after_crc24;
wire info_bit_after_crc24_valid;
wire info_bit_after_crc24_valid_last;

// test process
reg [31:0] clk_count;
reg [31:0] info_bit_count;
reg [31:0] bit_out_count;
reg bit_out_finish;
always @ (posedge clk) begin
  if (rst) begin
    crc_state_init_bit <= 0;
    crc_state_init_bit_load <= 0;
    info_bit <= 0;
    info_bit_valid <= 0;
    info_bit_valid_last <= 0;

    clk_count <= 1;
    info_bit_count <= 0;
    bit_out_count <= 0;
    bit_out_finish <= 0;
  end else begin
    crc_state_init_bit <= CRC_STATE_INIT_BIT;
    clk_count <= clk_count + 1;
    if (clk_count == 3) begin
      crc_state_init_bit_load <= 1;
      // $display("%h", crc_state_init_bit);
    end else begin
      crc_state_init_bit_load <= 0;
    end

    if (clk_count[3:0] == 0) begin // speed 1M
      if (info_bit_count < NUM_BIT_INPUT) begin
        info_bit <= crc24_test_input_mem[info_bit_count];
        info_bit_valid <= 1;
        if (info_bit_count == (NUM_BIT_INPUT-1)) begin
          info_bit_valid_last <= 1;
        end
        // $display("%h", crc24_test_input_mem[info_bit_count]);
      end
      info_bit_count <= info_bit_count + 1;
    end else begin
      info_bit_valid <= 0;
      info_bit_valid_last <= 0;
    end

    if (info_bit_count == (NUM_BIT_INPUT+30)) begin
      $display("%d input", NUM_BIT_INPUT);
      $display("%d output", bit_out_count);
      $display("Save output to %s", TEST_OUTPUT_FILENAME);
      // $writememh(TEST_OUTPUT_FILENAME, crc24_test_output_mem, 0, bit_out_count-1);
      crc24_test_output_fd = $fopen(TEST_OUTPUT_FILENAME, "w");
      for (i=0; i<bit_out_count; i=i+1) begin
        $fwrite(crc24_test_output_fd, "%d\n", crc24_test_output_mem[i]);
      end
      $fflush(crc24_test_output_fd);
      $fclose(crc24_test_output_fd);
      
      // check the output and the reference
      NUM_ERROR = 0;
      for (i=0; i<NUM_BIT_OUTPUT; i=i+1) begin
        if (crc24_test_output_mem[i] != crc24_test_output_ref_mem[i]) begin
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
    if (info_bit_after_crc24_valid) begin
      crc24_test_output_mem[bit_out_count] <= info_bit_after_crc24;
      if (info_bit_after_crc24_valid_last) begin
        bit_out_finish <= 1;
      end
      if (bit_out_finish == 0) begin
        bit_out_count <= bit_out_count + 1;
      end
    end
  end
end

crc24 # (
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

endmodule

