// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o gfsk_demodulation_tb gfsk_demodulation_tb.v gfsk_demodulation.v
// vvp gfsk_demodulation_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module gfsk_demodulation_tb #
(
  parameter GFSK_DEMODULATION_BIT_WIDTH = 16
) (
);

reg clk;
reg rst;

reg [72*8:0] TEST_INPUT_I_FILENAME = "btle_rx_gfsk_demodulation_test_input_i.txt";
reg [72*8:0] TEST_INPUT_Q_FILENAME = "btle_rx_gfsk_demodulation_test_input_q.txt";
reg [72*8:0] TEST_OUTPUT_SIGNAL_FOR_DECISION_REF_FILENAME = "btle_rx_gfsk_demodulation_test_output_signal_for_decision_ref.txt";
reg [72*8:0] TEST_OUTPUT_BIT_REF_FILENAME = "btle_rx_gfsk_demodulation_test_output_bit_ref.txt";
reg [72*8:0] TEST_OUTPUT_SIGNAL_FOR_DECISION_FILENAME = "btle_rx_gfsk_demodulation_test_output_signal_for_decision.txt";
reg [72*8:0] TEST_OUTPUT_BIT_FILENAME = "btle_rx_gfsk_demodulation_test_output_bit.txt";

reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1):0] gfsk_demodulation_test_input_i_mem [0:4095];
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1):0] gfsk_demodulation_test_input_q_mem [0:4095];
reg [0:0] gfsk_demodulation_test_output_bit_mem [0:4095];
reg signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1):0] gfsk_demodulation_test_output_signal_for_decision_mem [0:4095];
reg [0:0] gfsk_demodulation_test_output_bit_ref_mem [0:4095];
reg signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1):0] gfsk_demodulation_test_output_signal_for_decision_ref_mem [0:4095];

integer gfsk_demodulation_test_input_i_fd;
integer gfsk_demodulation_test_input_q_fd;
integer gfsk_demodulation_test_output_bit_fd;
integer gfsk_demodulation_test_output_signal_for_decision_fd;
integer gfsk_demodulation_test_output_bit_ref_fd;
integer gfsk_demodulation_test_output_signal_for_decision_ref_fd;
integer NUM_SAMPLE_INPUT;
integer NUM_BIT_OUTPUT;
integer NUM_ERROR;
integer tmp;
integer i, j;

initial begin
  $dumpfile("gfsk_demodulation_tb.vcd");
  $dumpvars;

  // read test input
  $display("Reading input I from %s", TEST_INPUT_I_FILENAME);
  NUM_SAMPLE_INPUT = 0;
  gfsk_demodulation_test_input_i_fd = $fopen(TEST_INPUT_I_FILENAME, "r");
  tmp = $fscanf(gfsk_demodulation_test_input_i_fd, "%d", gfsk_demodulation_test_input_i_mem[NUM_SAMPLE_INPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_INPUT = NUM_SAMPLE_INPUT + 1;
    tmp = $fscanf(gfsk_demodulation_test_input_i_fd, "%d", gfsk_demodulation_test_input_i_mem[NUM_SAMPLE_INPUT]);
  end
  $fclose(gfsk_demodulation_test_input_i_fd);
  $display("%d read finish for test input I.", NUM_SAMPLE_INPUT);

  $display("Reading input Q from %s", TEST_INPUT_Q_FILENAME);
  NUM_SAMPLE_INPUT = 0;
  gfsk_demodulation_test_input_q_fd = $fopen(TEST_INPUT_Q_FILENAME, "r");
  tmp = $fscanf(gfsk_demodulation_test_input_q_fd, "%d", gfsk_demodulation_test_input_q_mem[NUM_SAMPLE_INPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_INPUT = NUM_SAMPLE_INPUT + 1;
    tmp = $fscanf(gfsk_demodulation_test_input_q_fd, "%d", gfsk_demodulation_test_input_q_mem[NUM_SAMPLE_INPUT]);
  end
  $fclose(gfsk_demodulation_test_input_q_fd);
  $display("%d read finish for test input Q.", NUM_SAMPLE_INPUT);

  // read test output reference
  $display("Reading output ref from %s", TEST_OUTPUT_SIGNAL_FOR_DECISION_REF_FILENAME);
  NUM_BIT_OUTPUT = 0;
  gfsk_demodulation_test_output_signal_for_decision_ref_fd = $fopen(TEST_OUTPUT_SIGNAL_FOR_DECISION_REF_FILENAME, "r");
  tmp = $fscanf(gfsk_demodulation_test_output_signal_for_decision_ref_fd, "%d", gfsk_demodulation_test_output_signal_for_decision_ref_mem[NUM_BIT_OUTPUT]);
  while(tmp == 1) begin
    NUM_BIT_OUTPUT = NUM_BIT_OUTPUT + 1;
    tmp = $fscanf(gfsk_demodulation_test_output_signal_for_decision_ref_fd, "%d", gfsk_demodulation_test_output_signal_for_decision_ref_mem[NUM_BIT_OUTPUT]);
  end
  $fclose(gfsk_demodulation_test_output_signal_for_decision_ref_fd);
  $display("%d read finish from %s", NUM_BIT_OUTPUT, TEST_OUTPUT_SIGNAL_FOR_DECISION_REF_FILENAME);

  $display("Reading output ref from %s", TEST_OUTPUT_BIT_REF_FILENAME);
  NUM_BIT_OUTPUT = 0;
  gfsk_demodulation_test_output_bit_ref_fd = $fopen(TEST_OUTPUT_BIT_REF_FILENAME, "r");
  tmp = $fscanf(gfsk_demodulation_test_output_bit_ref_fd, "%d", gfsk_demodulation_test_output_bit_ref_mem[NUM_BIT_OUTPUT]);
  while(tmp == 1) begin
    NUM_BIT_OUTPUT = NUM_BIT_OUTPUT + 1;
    tmp = $fscanf(gfsk_demodulation_test_output_bit_ref_fd, "%d", gfsk_demodulation_test_output_bit_ref_mem[NUM_BIT_OUTPUT]);
  end
  $fclose(gfsk_demodulation_test_output_bit_ref_fd);
  $display("%d read finish from %s", NUM_BIT_OUTPUT, TEST_OUTPUT_BIT_REF_FILENAME);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] i_signal;
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] q_signal;
reg iq_valid;

wire signed [(2*GFSK_DEMODULATION_BIT_WIDTH-1) : 0] signal_for_decision;
wire signal_for_decision_valid;

wire bit;
wire bit_valid;

// test process
reg [31:0] clk_count;
reg [31:0] sample_in_count;
reg [31:0] bit_out_count;
reg [31:0] signal_for_decision_out_count;
always @ (posedge clk) begin
  if (rst) begin
    i_signal <= 0;
    q_signal <= 0;
    iq_valid <= 0;

    clk_count <= 1;
    sample_in_count <= 0;
    bit_out_count <= 0;
    signal_for_decision_out_count <= 0;
  end else begin
    clk_count <= clk_count + 1;

    if (clk_count[3:0] == 0) begin // speed 1M
      if (sample_in_count < NUM_SAMPLE_INPUT) begin
        i_signal <= gfsk_demodulation_test_input_i_mem[sample_in_count];
        q_signal <= gfsk_demodulation_test_input_q_mem[sample_in_count];
        iq_valid <= 1;
      end
      sample_in_count <= sample_in_count + 1;
    end else begin
      iq_valid <= 0;
    end

    if (sample_in_count == (NUM_SAMPLE_INPUT+30)) begin
      $display("%d input", NUM_SAMPLE_INPUT);
      $display("%d bit output", bit_out_count);
      $display("%d signal for decision output", signal_for_decision_out_count);

      $display("Save output bit to %s", TEST_OUTPUT_BIT_FILENAME);
      gfsk_demodulation_test_output_bit_fd = $fopen(TEST_OUTPUT_BIT_FILENAME, "w");
      for (i=0; i<bit_out_count; i=i+1) begin
        $fwrite(gfsk_demodulation_test_output_bit_fd, "%d\n", gfsk_demodulation_test_output_bit_mem[i]);
      end
      $fflush(gfsk_demodulation_test_output_bit_fd);
      $fclose(gfsk_demodulation_test_output_bit_fd);

      $display("Save output signal for decision to %s", TEST_OUTPUT_SIGNAL_FOR_DECISION_FILENAME);
      gfsk_demodulation_test_output_signal_for_decision_fd = $fopen(TEST_OUTPUT_SIGNAL_FOR_DECISION_FILENAME, "w");
      for (i=0; i<signal_for_decision_out_count; i=i+1) begin
        $fwrite(gfsk_demodulation_test_output_signal_for_decision_fd, "%d\n", gfsk_demodulation_test_output_signal_for_decision_mem[i]);
      end
      $fflush(gfsk_demodulation_test_output_signal_for_decision_fd);
      $fclose(gfsk_demodulation_test_output_signal_for_decision_fd);

      $display("Compare the gfsk_demodulation_test_output_bit_mem and the gfsk_demodulation_test_output_bit_ref_mem ...");
      NUM_ERROR = 0;
      for (i=0; i<NUM_BIT_OUTPUT; i=i+1) begin
        if (gfsk_demodulation_test_output_bit_mem[i+1] != gfsk_demodulation_test_output_bit_ref_mem[i]) begin
          NUM_ERROR = NUM_ERROR + 1;
        end
      end
      if (NUM_ERROR > 0) begin
        $display("%d error found!", NUM_ERROR);
        $display("Please check %s VS %s", TEST_OUTPUT_BIT_FILENAME, TEST_OUTPUT_BIT_REF_FILENAME);
      end else begin
        $display("%d error found! output bit Test PASS.", NUM_ERROR);
      end

      $display("Compare the gfsk_demodulation_test_output_signal_for_decision_mem and the gfsk_demodulation_test_output_signal_for_decision_ref_mem ...");
      NUM_ERROR = 0;
      for (i=0; i<NUM_BIT_OUTPUT; i=i+1) begin
        if (gfsk_demodulation_test_output_signal_for_decision_mem[i+1] != gfsk_demodulation_test_output_signal_for_decision_ref_mem[i]) begin
          NUM_ERROR = NUM_ERROR + 1;
        end
      end
      if (NUM_ERROR > 0) begin
        $display("%d error found!", NUM_ERROR);
        $display("Please check %s VS %s", TEST_OUTPUT_SIGNAL_FOR_DECISION_FILENAME, TEST_OUTPUT_SIGNAL_FOR_DECISION_REF_FILENAME);
      end else begin
        $display("%d error found! output signal for decision Test PASS.", NUM_ERROR);
      end

      $finish;
    end

    // record the result
    if (bit_valid) begin
      gfsk_demodulation_test_output_bit_mem[bit_out_count] <= bit;
      bit_out_count <= bit_out_count + 1;
    end

    if (signal_for_decision_valid) begin
      gfsk_demodulation_test_output_signal_for_decision_mem[signal_for_decision_out_count] <= signal_for_decision;
      signal_for_decision_out_count <= signal_for_decision_out_count + 1;
    end

  end
end

gfsk_demodulation # (
  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH)
) gfsk_demodulation_i (
  .clk(clk),
  .rst(rst),

  .i(i_signal),
  .q(q_signal),
  .iq_valid(iq_valid),

  .signal_for_decision(signal_for_decision),
  .signal_for_decision_valid(signal_for_decision_valid),
  
  .phy_bit(bit),
  .bit_valid(bit_valid)
);

endmodule

