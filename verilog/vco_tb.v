// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o vco_tb vco_tb.v vco.v dpram.v
// vvp vco_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module vco_tb #
(
  parameter VCO_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8
) (
);

reg clk;
reg rst;

reg [64*8:0] COS_TABLE_FILENAME = "cos_table.txt";
reg [64*8:0] SIN_TABLE_FILENAME = "sin_table.txt";
reg [64*8:0] TEST_INPUT_FILENAME = "btle_tx_vco_test_input.txt";
reg [64*8:0] TEST_OUTPUT_COS_REF_FILENAME = "btle_tx_vco_test_output_cos_ref.txt";
reg [64*8:0] TEST_OUTPUT_SIN_REF_FILENAME = "btle_tx_vco_test_output_sin_ref.txt";
reg [64*8:0] TEST_OUTPUT_COS_FILENAME = "btle_tx_vco_test_output_cos.txt";
reg [64*8:0] TEST_OUTPUT_SIN_FILENAME = "btle_tx_vco_test_output_sin.txt";

reg signed [(IQ_BIT_WIDTH-1):0] cos_table_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] sin_table_mem [0:4095];
reg signed [(VCO_BIT_WIDTH-1):0] vco_test_input_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] vco_test_output_cos_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] vco_test_output_sin_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] vco_test_output_cos_ref_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] vco_test_output_sin_ref_mem [0:4095];

integer vco_test_input_fd;
integer vco_test_output_cos_fd;
integer vco_test_output_sin_fd;
integer vco_test_output_cos_ref_fd;
integer vco_test_output_sin_ref_fd;
integer cos_table_fd;
integer sin_table_fd;
integer NUM_SAMPLE_INPUT;
integer NUM_SAMPLE_OUTPUT;
integer NUM_ERROR;
integer tmp;
integer i, j;

initial begin
  $dumpfile("vco_tb.vcd");
  $dumpvars;
  
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

  // read test input
  NUM_SAMPLE_INPUT = 0;
  vco_test_input_fd = $fopen(TEST_INPUT_FILENAME, "r");
  tmp = $fscanf(vco_test_input_fd, "%d", vco_test_input_mem[NUM_SAMPLE_INPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_INPUT = NUM_SAMPLE_INPUT + 1;
    tmp = $fscanf(vco_test_input_fd, "%d", vco_test_input_mem[NUM_SAMPLE_INPUT]);
  end
  $fclose(vco_test_input_fd);
  $display("%d read finish for test input.", NUM_SAMPLE_INPUT);

  // read test output reference
  $display("Reading output ref from %s", TEST_OUTPUT_COS_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  vco_test_output_cos_ref_fd = $fopen(TEST_OUTPUT_COS_REF_FILENAME, "r");
  tmp = $fscanf(vco_test_output_cos_ref_fd, "%d", vco_test_output_cos_ref_mem[NUM_SAMPLE_OUTPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_OUTPUT = NUM_SAMPLE_OUTPUT + 1;
    tmp = $fscanf(vco_test_output_cos_ref_fd, "%d", vco_test_output_cos_ref_mem[NUM_SAMPLE_OUTPUT]);
  end
  $fclose(vco_test_output_cos_ref_fd);
  $display("%d read finish for test output cos ref.", NUM_SAMPLE_OUTPUT);

  $display("Reading output ref from %s", TEST_OUTPUT_SIN_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  vco_test_output_sin_ref_fd = $fopen(TEST_OUTPUT_SIN_REF_FILENAME, "r");
  tmp = $fscanf(vco_test_output_sin_ref_fd, "%d", vco_test_output_sin_ref_mem[NUM_SAMPLE_OUTPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_OUTPUT = NUM_SAMPLE_OUTPUT + 1;
    tmp = $fscanf(vco_test_output_sin_ref_fd, "%d", vco_test_output_sin_ref_mem[NUM_SAMPLE_OUTPUT]);
  end
  $fclose(vco_test_output_sin_ref_fd);
  $display("%d read finish for test output sin ref.", NUM_SAMPLE_OUTPUT);

  clk = 0;
  rst = 0;
  
  #200 rst = 1;

  #200 rst = 0;
end

always begin
  #((1000.0/16.0)/2.0) clk = !clk; //16MHz
end

reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] cos_table_write_address;
reg signed [(IQ_BIT_WIDTH-1) : 0] cos_table_write_data;
reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] sin_table_write_address;
reg signed [(IQ_BIT_WIDTH-1) : 0] sin_table_write_data;

reg signed [(VCO_BIT_WIDTH-1) : 0] voltage_signal;
reg voltage_signal_valid;

wire signed [(IQ_BIT_WIDTH-1) : 0] cos_out;
wire signed [(IQ_BIT_WIDTH-1) : 0] sin_out;
wire sin_cos_out_valid;

// test process
reg [31:0] clk_count;
reg [31:0] sample_in_count;
reg [31:0] sample_out_count;
always @ (posedge clk) begin
  if (rst) begin
    cos_table_write_address <= 0;
    cos_table_write_data <= 0;
    sin_table_write_address <= 0;
    sin_table_write_data <= 0;

    voltage_signal <= 0;
    voltage_signal_valid <= 0;

    clk_count <= 0;
    sample_in_count <= 0;
    sample_out_count <= 0;
  end else begin
    clk_count <= clk_count + 1;

    // Initialize the cos sin table
    if (clk_count < (1<<SIN_COS_ADDR_BIT_WIDTH)) begin
      cos_table_write_address <= clk_count;
      cos_table_write_data <= cos_table_mem[clk_count];
      sin_table_write_address <= clk_count;
      sin_table_write_data <= sin_table_mem[clk_count];
    end else if (clk_count == (1<<SIN_COS_ADDR_BIT_WIDTH)) begin
      $display("cos sin table initialized.");
    end else begin

      if (clk_count[0] == 0) begin // speed 8M
        if (sample_in_count < NUM_SAMPLE_INPUT) begin
          voltage_signal <= vco_test_input_mem[sample_in_count];
          voltage_signal_valid <= 1;
          // $display("%h", vco_test_input_mem[sample_in_count]);
        end
        sample_in_count <= sample_in_count + 1;
      end else begin
        voltage_signal_valid <= 0;
      end

      if (sample_in_count == (NUM_SAMPLE_INPUT+30)) begin
        $display("%d input", NUM_SAMPLE_INPUT);
        $display("%d output", sample_out_count);
        
        $display("Save output cos to %s", TEST_OUTPUT_COS_FILENAME);
        vco_test_output_cos_fd = $fopen(TEST_OUTPUT_COS_FILENAME, "w");
        for (i=0; i<sample_out_count; i=i+1) begin
          $fwrite(vco_test_output_cos_fd, "%d\n", vco_test_output_cos_mem[i]);
        end
        $fflush(vco_test_output_cos_fd);
        $fclose(vco_test_output_cos_fd);

        $display("Save output sin to %s", TEST_OUTPUT_SIN_FILENAME);
        vco_test_output_sin_fd = $fopen(TEST_OUTPUT_SIN_FILENAME, "w");
        for (i=0; i<sample_out_count; i=i+1) begin
          $fwrite(vco_test_output_sin_fd, "%d\n", vco_test_output_sin_mem[i]);
        end
        $fflush(vco_test_output_sin_fd);
        $fclose(vco_test_output_sin_fd);

        // check the output and the reference
        $display("Compare the vco_test_output_cos_mem and the vco_test_output_cos_ref_mem ...");
        NUM_ERROR = 0;
        for (i=0; i<NUM_SAMPLE_OUTPUT; i=i+1) begin
          if (vco_test_output_cos_mem[i] != vco_test_output_cos_ref_mem[i]) begin
            NUM_ERROR = NUM_ERROR + 1;
          end
        end
        if (NUM_ERROR > 0) begin
          $display("%d error found!", NUM_ERROR);
          $display("Please check %s VS %s", TEST_OUTPUT_COS_FILENAME, TEST_OUTPUT_COS_REF_FILENAME);
        end else begin
          $display("%d error found! output cos Test PASS.", NUM_ERROR);
        end

        $display("Compare the vco_test_output_sin_mem and the vco_test_output_sin_ref_mem ...");
        NUM_ERROR = 0;
        for (i=0; i<NUM_SAMPLE_OUTPUT; i=i+1) begin
          if (vco_test_output_sin_mem[i] != vco_test_output_sin_ref_mem[i]) begin
            NUM_ERROR = NUM_ERROR + 1;
          end
        end
        if (NUM_ERROR > 0) begin
          $display("%d error found!", NUM_ERROR);
          $display("Please check %s VS %s", TEST_OUTPUT_SIN_FILENAME, TEST_OUTPUT_SIN_REF_FILENAME);
        end else begin
          $display("%d error found! output sin Test PASS.", NUM_ERROR);
        end

        $finish;
      end

      // record the result
      if (sin_cos_out_valid) begin
        vco_test_output_cos_mem[sample_out_count] <= cos_out;
        vco_test_output_sin_mem[sample_out_count] <= sin_out;
        sample_out_count <= sample_out_count + 1;
      end

    end
  end
end

vco # (
  .VCO_BIT_WIDTH(VCO_BIT_WIDTH),
  .SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
  .IQ_BIT_WIDTH(IQ_BIT_WIDTH)
) vco_i (
  .clk(clk),
  .rst(rst),

  .cos_table_write_address(cos_table_write_address),
  .cos_table_write_data(cos_table_write_data),
  .sin_table_write_address(sin_table_write_address),
  .sin_table_write_data(sin_table_write_data),

  .voltage_signal(voltage_signal),
  .voltage_signal_valid(voltage_signal_valid),
  
  .cos_out(cos_out),
  .sin_out(sin_out),
  .sin_cos_out_valid(sin_cos_out_valid)
);

endmodule

