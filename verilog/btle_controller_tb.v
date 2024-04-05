// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2024 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

// To generate test vector and result reference, in python directory run:
// python3 test_vector_for_btle_verilog.py
// (arguments can be added: example_idx snr ppm_value)
// Run verilog simulation:
// iverilog -o btle_controller_tb btle_controller_tb.v btle_controller.v btle_ll.v uart_frame_rx.v uart_frame_tx.v rx_clk_gen.v tx_clk_gen.v btle_phy.v btle_rx.v btle_rx_core.v gfsk_demodulation.v search_unique_bit_sequence.v scramble_core.v crc24_core.v serial_in_ram_out.v dpram.v btle_tx.v crc24.v scramble.v gfsk_modulation.v bit_repeat_upsample.v gauss_filter.v vco.v
// vvp btle_controller_tb
// Check verilog outputs to see whether test pass.

`timescale 1ns / 1ps
module btle_controller_tb #
(
	parameter	CLK_FREQUENCE	= 16_000_000,	//hz
  parameter BAUD_RATE		= 115200		,		  //9600、19200 、38400 、57600 、115200、230400、460800、921600
  parameter PARITY			= "NONE"	,		  //"NONE","EVEN","ODD"
  parameter FRAME_WD		= 8,					    //if PARITY="NONE",it can be 5~9;else 5~8

  parameter CRC_STATE_BIT_WIDTH = 24,
  parameter CHANNEL_NUMBER_BIT_WIDTH = 6,
  parameter SAMPLE_PER_SYMBOL = 8,
  parameter GAUSS_FILTER_BIT_WIDTH = 16,
  parameter NUM_TAP_GAUSS_FILTER = 17,
  parameter VCO_BIT_WIDTH = 16,
  parameter SIN_COS_ADDR_BIT_WIDTH = 11,
  parameter IQ_BIT_WIDTH = 8,
  parameter GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT = 1,
  parameter GFSK_DEMODULATION_BIT_WIDTH = 16,
  parameter LEN_UNIQUE_BIT_SEQUENCE = 32,

  parameter PREAMBLE_BIT_WIDTH = 8
) (
);

localparam [1:0] TEST_TX     = 0,
                 TEST_RX     = 1,
                 TEST_FINISH = 2;
reg [1:0] test_state;

reg clk;
reg rst;

reg [64*8:0] BTLE_CONFIG_FILENAME  = "btle_config.txt";
reg [72*8:0] RX_TEST_INPUT_I_FILENAME = "btle_rx_test_input_i.txt";
reg [72*8:0] RX_TEST_INPUT_Q_FILENAME = "btle_rx_test_input_q.txt";
reg [72*8:0] RX_TEST_OUTPUT_FILENAME  = "btle_rx_test_output.txt";
reg [72*8:0] RX_TEST_OUTPUT_REF_FILENAME = "btle_rx_test_output_ref.txt";
reg [72*8:0] RX_TEST_OUTPUT_CRC_OK_REF_FILENAME = "btle_rx_test_output_crc_ok_ref.txt";

reg [64*8:0] GAUSS_FILTER_TAP_FILENAME = "gauss_filter_tap.txt";
reg [64*8:0] COS_TABLE_FILENAME = "cos_table.txt";
reg [64*8:0] SIN_TABLE_FILENAME = "sin_table.txt";
reg [64*8:0] TX_TEST_INPUT_FILENAME = "btle_tx_test_input.txt";
reg [64*8:0] TX_TEST_OUTPUT_I_REF_FILENAME = "btle_tx_test_output_i_ref.txt";
reg [64*8:0] TX_TEST_OUTPUT_Q_REF_FILENAME = "btle_tx_test_output_q_ref.txt";
reg [64*8:0] TX_TEST_OUTPUT_I_FILENAME = "btle_tx_test_output_i.txt";
reg [64*8:0] TX_TEST_OUTPUT_Q_FILENAME = "btle_tx_test_output_q.txt";

reg [(CRC_STATE_BIT_WIDTH-1) : 0]      CRC_STATE_INIT_BIT;
reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] CHANNEL_NUMBER;
reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0]  ACCESS_ADDRESS;
reg [(PREAMBLE_BIT_WIDTH-1) : 0]       PREAMBLE;
reg [31:0] btle_config_mem [0:31];

reg signed [(GAUSS_FILTER_BIT_WIDTH-1):0] gauss_filter_tap_mem [0:63];
reg signed [(IQ_BIT_WIDTH-1):0] cos_table_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] sin_table_mem [0:4095];

reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1):0] btle_rx_test_input_i_mem [0:4095];
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1):0] btle_rx_test_input_q_mem [0:4095];
reg [7:0] btle_rx_test_output_mem [0:4095];
reg [7:0] btle_rx_test_output_ref_mem [0:4095];
reg [0:0] btle_rx_test_output_crc_ok_ref_mem [0:3];

reg [7:0]  btle_tx_test_input_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_i_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_q_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_i_ref_mem [0:4095];
reg signed [(IQ_BIT_WIDTH-1):0] btle_tx_test_output_q_ref_mem [0:4095];

integer btle_rx_test_input_i_fd;
integer btle_rx_test_input_q_fd;
integer btle_rx_test_output_fd;
integer btle_rx_test_output_ref_fd;
integer btle_rx_test_output_crc_ok_ref_fd;

integer gauss_filter_tap_fd;
integer cos_table_fd;
integer sin_table_fd;
integer btle_tx_test_input_fd;
integer btle_tx_test_output_i_fd;
integer btle_tx_test_output_q_fd;
integer btle_tx_test_output_i_ref_fd;
integer btle_tx_test_output_q_ref_fd;

integer NUM_SAMPLE_INPUT;
integer NUM_OCTET_OUTPUT;

integer NUM_OCTET_INPUT;
integer NUM_SAMPLE_OUTPUT;

integer NUM_ERROR_TX_I;
integer NUM_ERROR_TX_Q;

integer NUM_ERROR;

integer tmp;
integer i, j;

initial begin
  $dumpfile("btle_controller_tb.vcd");
  $dumpvars;

  $display("Read %s", BTLE_CONFIG_FILENAME);
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

  // Read test input and output reference for receiver
  $display("Read test input and output reference for receiver");
  $display("Reading input I from %s", RX_TEST_INPUT_I_FILENAME);
  NUM_SAMPLE_INPUT = 0;
  btle_rx_test_input_i_fd = $fopen(RX_TEST_INPUT_I_FILENAME, "r");
  tmp = $fscanf(btle_rx_test_input_i_fd, "%d", btle_rx_test_input_i_mem[NUM_SAMPLE_INPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_INPUT = NUM_SAMPLE_INPUT + 1;
    tmp = $fscanf(btle_rx_test_input_i_fd, "%d", btle_rx_test_input_i_mem[NUM_SAMPLE_INPUT]);
  end
  $fclose(btle_rx_test_input_i_fd);
  $display("%d read finish for test input I.", NUM_SAMPLE_INPUT);
  if (NUM_SAMPLE_INPUT == 0) begin
    $display("NOT INPUT! Please increase SNR to make sure at least ACCESS_ADDRESS (unique bit sequence) can be detected!");
    $finish;
  end

  $display("Reading input Q from %s", RX_TEST_INPUT_Q_FILENAME);
  NUM_SAMPLE_INPUT = 0;
  btle_rx_test_input_q_fd = $fopen(RX_TEST_INPUT_Q_FILENAME, "r");
  tmp = $fscanf(btle_rx_test_input_q_fd, "%d", btle_rx_test_input_q_mem[NUM_SAMPLE_INPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_INPUT = NUM_SAMPLE_INPUT + 1;
    tmp = $fscanf(btle_rx_test_input_q_fd, "%d", btle_rx_test_input_q_mem[NUM_SAMPLE_INPUT]);
  end
  $fclose(btle_rx_test_input_q_fd);
  $display("%d read finish for test input Q.", NUM_SAMPLE_INPUT);

  // read test output reference
  $display("Reading output rx_crc_ok ref from %s", RX_TEST_OUTPUT_CRC_OK_REF_FILENAME);
  NUM_OCTET_OUTPUT = 0;
  btle_rx_test_output_crc_ok_ref_fd = $fopen(RX_TEST_OUTPUT_CRC_OK_REF_FILENAME, "r");
  tmp = $fscanf(btle_rx_test_output_crc_ok_ref_fd, "%h", btle_rx_test_output_crc_ok_ref_mem[NUM_OCTET_OUTPUT]);
  while(tmp == 1) begin
    NUM_OCTET_OUTPUT = NUM_OCTET_OUTPUT + 1;
    tmp = $fscanf(btle_rx_test_output_crc_ok_ref_fd, "%h", btle_rx_test_output_crc_ok_ref_mem[NUM_OCTET_OUTPUT]);
  end
  $fclose(btle_rx_test_output_crc_ok_ref_fd);
  $display("%d read finish from %s", NUM_OCTET_OUTPUT, RX_TEST_OUTPUT_CRC_OK_REF_FILENAME);

  $display("Reading output ref from %s", RX_TEST_OUTPUT_REF_FILENAME);
  NUM_OCTET_OUTPUT = 0;
  btle_rx_test_output_ref_fd = $fopen(RX_TEST_OUTPUT_REF_FILENAME, "r");
  tmp = $fscanf(btle_rx_test_output_ref_fd, "%h", btle_rx_test_output_ref_mem[NUM_OCTET_OUTPUT]);
  while(tmp == 1) begin
    NUM_OCTET_OUTPUT = NUM_OCTET_OUTPUT + 1;
    tmp = $fscanf(btle_rx_test_output_ref_fd, "%h", btle_rx_test_output_ref_mem[NUM_OCTET_OUTPUT]);
  end
  $fclose(btle_rx_test_output_ref_fd);
  $display("%d read finish from %s", NUM_OCTET_OUTPUT, RX_TEST_OUTPUT_REF_FILENAME);

  // Read test input and output reference for transmitter
  $display("Read test input and output reference for transmitter");
  $display("Reading input from %s", TX_TEST_INPUT_FILENAME);
  NUM_OCTET_INPUT = 0;
  btle_tx_test_input_fd = $fopen(TX_TEST_INPUT_FILENAME, "r");
  tmp = $fscanf(btle_tx_test_input_fd, "%h", btle_tx_test_input_mem[NUM_OCTET_INPUT]);
  while(tmp == 1) begin
    NUM_OCTET_INPUT = NUM_OCTET_INPUT + 1;
    tmp = $fscanf(btle_tx_test_input_fd, "%h", btle_tx_test_input_mem[NUM_OCTET_INPUT]);
  end
  $fclose(btle_tx_test_input_fd);
  $display("%d read finish for test input.", NUM_OCTET_INPUT);

  // read test output reference
  $display("Reading output ref from %s", TX_TEST_OUTPUT_I_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  btle_tx_test_output_i_ref_fd = $fopen(TX_TEST_OUTPUT_I_REF_FILENAME, "r");
  tmp = $fscanf(btle_tx_test_output_i_ref_fd, "%d", btle_tx_test_output_i_ref_mem[NUM_SAMPLE_OUTPUT]);
  while(tmp == 1) begin
    NUM_SAMPLE_OUTPUT = NUM_SAMPLE_OUTPUT + 1;
    tmp = $fscanf(btle_tx_test_output_i_ref_fd, "%d", btle_tx_test_output_i_ref_mem[NUM_SAMPLE_OUTPUT]);
  end
  $fclose(btle_tx_test_output_i_ref_fd);
  $display("%d read finish for test output cos ref.", NUM_SAMPLE_OUTPUT);

  $display("Reading output ref from %s", TX_TEST_OUTPUT_Q_REF_FILENAME);
  NUM_SAMPLE_OUTPUT = 0;
  btle_tx_test_output_q_ref_fd = $fopen(TX_TEST_OUTPUT_Q_REF_FILENAME, "r");
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

reg  uart_rx;
wire uart_tx;

wire baremetal_phy_intf_mode;

// for tx
reg [3:0] tx_gauss_filter_tap_index; // only need to set 0~8, 9~16 will be mirror of 0~7
reg signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_gauss_filter_tap_value;

reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_cos_table_write_address;
reg signed [(IQ_BIT_WIDTH-1) : 0] tx_cos_table_write_data;
reg [(SIN_COS_ADDR_BIT_WIDTH-1) : 0] tx_sin_table_write_address;
reg signed [(IQ_BIT_WIDTH-1) : 0] tx_sin_table_write_data;

reg [7:0]  preamble;

reg [(LEN_UNIQUE_BIT_SEQUENCE-1) : 0] access_address;
reg [(CRC_STATE_BIT_WIDTH-1) : 0] crc_state_init_bit;
reg crc_state_init_bit_load;
reg [(CHANNEL_NUMBER_BIT_WIDTH-1) : 0] channel_number;
reg channel_number_load;

reg [7:0] tx_pdu_octet_mem_data;
reg [5:0] tx_pdu_octet_mem_addr;

wire tx_start;

wire signed [(IQ_BIT_WIDTH-1) : 0] tx_i_signal;
wire signed [(IQ_BIT_WIDTH-1) : 0] tx_q_signal;
wire tx_iq_valid;
wire tx_iq_valid_last;
reg  tx_iq_valid_last_delay;

wire tx_phy_bit;
wire tx_phy_bit_valid;
wire tx_phy_bit_valid_last;

wire tx_bit_upsample;
wire tx_bit_upsample_valid;
wire tx_bit_upsample_valid_last;

wire signed [(GAUSS_FILTER_BIT_WIDTH-1) : 0] tx_bit_upsample_gauss_filter;
wire tx_bit_upsample_gauss_filter_valid;
wire tx_bit_upsample_gauss_filter_valid_last;

// for rx
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_i_signal;
reg signed [(GFSK_DEMODULATION_BIT_WIDTH-1) : 0] rx_q_signal;
reg rx_iq_valid;

wire rx_hit_flag;
wire rx_decode_run;
wire rx_decode_end;
wire rx_crc_ok;
reg  rx_crc_ok_store;
wire [2:0] rx_best_phase;
wire [6:0] rx_payload_length;

wire [7:0] rx_pdu_octet_mem_data;
reg  [5:0] rx_pdu_octet_mem_addr;

assign baremetal_phy_intf_mode = 1;

// test process
reg [31:0] clk_count;
reg [31:0] sample_in_count;
reg tx_test_ok;
reg rx_test_ok;
reg read_start;

reg  tx_gauss_filter_tap_init_done;
reg  tx_sin_cos_table_init_done;
reg  tx_pkt_mem_init_done;
wire tx_all_init_done;
reg  tx_all_init_done_delay;
reg  [31:0] sample_out_count;

reg  [31:0] phy_bit_count;
reg  [31:0] bit_upsample_count;
reg  [31:0] bit_upsample_gauss_filter_count;

assign tx_all_init_done = (tx_gauss_filter_tap_init_done&tx_sin_cos_table_init_done&tx_pkt_mem_init_done);
assign tx_start = (tx_all_init_done == 1 && tx_all_init_done_delay == 0);

always @ (posedge clk) begin
  if (rst) begin
    access_address <= ACCESS_ADDRESS;
    channel_number <= CHANNEL_NUMBER;
    crc_state_init_bit <= CRC_STATE_INIT_BIT;
    preamble <= PREAMBLE;

    rx_i_signal <= 0;
    rx_q_signal <= 0;
    rx_iq_valid <= 0;
    rx_pdu_octet_mem_addr <= 0;

    clk_count <= 0;
    sample_in_count <= 0;
    read_start <= 0;

    rx_crc_ok_store <= 0;

    tx_test_ok <= 0;
    rx_test_ok <= 0;

    tx_gauss_filter_tap_index <= 0;
    tx_gauss_filter_tap_value <= 0;

    tx_cos_table_write_address <= 0;
    tx_cos_table_write_data <= 0;
    tx_sin_table_write_address <= 0;
    tx_sin_table_write_data <= 0;

    crc_state_init_bit_load <= 0;
    channel_number_load <= 0;

    tx_pdu_octet_mem_data <= 0;
    tx_pdu_octet_mem_addr <= 0;

    tx_gauss_filter_tap_init_done <= 0;
    tx_sin_cos_table_init_done <= 0;
    tx_pkt_mem_init_done <= 0;
    tx_all_init_done_delay <= 0;

    sample_out_count <= 0;

    tx_iq_valid_last_delay <= 0;

    phy_bit_count <= 0;
    bit_upsample_count <= 0;
    bit_upsample_gauss_filter_count <= 0;

    test_state <= TEST_TX;
  end else begin
    clk_count <= clk_count + 1;

    access_address <= ACCESS_ADDRESS;
    channel_number <= CHANNEL_NUMBER;
    crc_state_init_bit <= CRC_STATE_INIT_BIT;
    preamble <= PREAMBLE;

    if (clk_count == 0) begin
      $display("Start TEST TX ...");
    end

    case(test_state)
      TEST_TX: begin
        tx_all_init_done_delay <= tx_all_init_done;

        tx_iq_valid_last_delay <= tx_iq_valid_last;

        if (clk_count < 9) begin
          tx_gauss_filter_tap_index <= clk_count;
          tx_gauss_filter_tap_value <= gauss_filter_tap_mem[clk_count];
        end else if (clk_count == 9) begin
          tx_gauss_filter_tap_init_done <= 1;
          $display("tx gauss filter taps initialized.");
        end

        if (clk_count < (1<<SIN_COS_ADDR_BIT_WIDTH)) begin
          tx_cos_table_write_address <= clk_count;
          tx_cos_table_write_data <= cos_table_mem[clk_count];
          tx_sin_table_write_address <= clk_count;
          tx_sin_table_write_data <= sin_table_mem[clk_count];
        end else if (clk_count == (1<<SIN_COS_ADDR_BIT_WIDTH)) begin
          tx_sin_cos_table_init_done <= 1;
          $display("tx cos sin table initialized.");
        end

        if (clk_count < NUM_OCTET_INPUT) begin
          tx_pdu_octet_mem_addr <= clk_count;
          tx_pdu_octet_mem_data <= btle_tx_test_input_mem[clk_count];
        end else if (clk_count == NUM_OCTET_INPUT) begin
          tx_pkt_mem_init_done <= 1;
          $display("tx pkt mem initialized.");
        end

        if (sample_out_count == 4095) begin
          $display("tx sample_out_count %d", sample_out_count);
          $display("tx Should NOT finish here!");
          $finish;
        end

        if (tx_iq_valid_last_delay) begin
          $display("tx clk_count %d", clk_count);
          $display("tx init_count %d", clk_count);
          $display("tx phy_bit_count %d", phy_bit_count);
          $display("tx bit_upsample_count %d", bit_upsample_count);
          $display("tx bit_upsample_gauss_filter_count %d", bit_upsample_gauss_filter_count);
          $display("tx sample_out_count %d", sample_out_count);

          $display("tx Save output I to %s", TX_TEST_OUTPUT_I_FILENAME);
          btle_tx_test_output_i_fd = $fopen(TX_TEST_OUTPUT_I_FILENAME, "w");
          for (i=0; i<sample_out_count; i=i+1) begin
            $fwrite(btle_tx_test_output_i_fd, "%d\n", btle_tx_test_output_i_mem[i]);
          end
          $fflush(btle_tx_test_output_i_fd);
          $fclose(btle_tx_test_output_i_fd);

          $display("tx Save output Q to %s", TX_TEST_OUTPUT_Q_FILENAME);
          btle_tx_test_output_i_fd = $fopen(TX_TEST_OUTPUT_Q_FILENAME, "w");
          for (i=0; i<sample_out_count; i=i+1) begin
            $fwrite(btle_tx_test_output_i_fd, "%d\n", btle_tx_test_output_q_mem[i]);
          end
          $fflush(btle_tx_test_output_i_fd);
          $fclose(btle_tx_test_output_i_fd);

          // check the output and the reference
          NUM_ERROR_TX_I = 0;
          for (i=0; i<NUM_SAMPLE_OUTPUT; i=i+1) begin
            if (btle_tx_test_output_i_mem[i] != btle_tx_test_output_i_ref_mem[i]) begin
              NUM_ERROR_TX_I = NUM_ERROR_TX_I + 1;
            end
          end
          if (NUM_ERROR_TX_I > 0) begin
            $display("tx %d error found!", NUM_ERROR_TX_I);
            $display("tx Please check %s VS %s", TX_TEST_OUTPUT_I_FILENAME, TX_TEST_OUTPUT_I_REF_FILENAME);
          end else begin
            $display("tx %d error found! output tx I Test PASS.", NUM_ERROR_TX_I);
          end

          NUM_ERROR_TX_Q = 0;
          for (i=0; i<NUM_SAMPLE_OUTPUT; i=i+1) begin
            if (btle_tx_test_output_q_mem[i] != btle_tx_test_output_q_ref_mem[i]) begin
              NUM_ERROR_TX_Q = NUM_ERROR_TX_Q + 1;
            end
          end
          if (NUM_ERROR_TX_Q > 0) begin
            $display("tx %d error found!", NUM_ERROR_TX_Q);
            $display("tx Please check %s VS %s", TX_TEST_OUTPUT_Q_FILENAME, TX_TEST_OUTPUT_Q_REF_FILENAME);
          end else begin
            $display("tx %d error found! output tx Q Test PASS.", NUM_ERROR_TX_Q);
          end

          if (NUM_ERROR_TX_Q == 0 && NUM_ERROR_TX_I == 0) begin
            tx_test_ok <= 1;
          end

          test_state <= TEST_RX;
          $display("Start TEST RX ...");
        end

        // record the result
        if (tx_iq_valid) begin
          btle_tx_test_output_i_mem[sample_out_count] <= tx_i_signal;
          btle_tx_test_output_q_mem[sample_out_count] <= tx_q_signal;
          sample_out_count <= sample_out_count + 1;
        end

        if (tx_phy_bit_valid) begin
          phy_bit_count <= phy_bit_count + 1;
        end

        if (tx_bit_upsample_valid) begin
          bit_upsample_count <= bit_upsample_count + 1;
        end

        if (tx_bit_upsample_gauss_filter_valid) begin
          bit_upsample_gauss_filter_count <= bit_upsample_gauss_filter_count + 1;
        end
      end

      TEST_RX: begin
        if (clk_count[0] == 0) begin // speed 8M
          if (sample_in_count < NUM_SAMPLE_INPUT) begin
            rx_i_signal <= btle_rx_test_input_i_mem[sample_in_count];
            rx_q_signal <= btle_rx_test_input_q_mem[sample_in_count];
            rx_iq_valid <= 1;
          end else begin
            rx_i_signal <= 0;
            rx_q_signal <= 0;
            rx_iq_valid <= 1;
          end
          sample_in_count <= sample_in_count + 1;
        end else begin
          rx_iq_valid <= 0;
        end

        if (sample_in_count == (NUM_SAMPLE_INPUT+800)) begin
          $display("rx %d NUM_SAMPLE_INPUT", NUM_SAMPLE_INPUT);
          $display("rx %d sample_in_count", sample_in_count);

          $display("rx Save output to %s", RX_TEST_OUTPUT_FILENAME);
          btle_rx_test_output_fd = $fopen(RX_TEST_OUTPUT_FILENAME, "w");
          for (i=0; i<(rx_payload_length+2); i=i+1) begin
            $fwrite(btle_rx_test_output_fd, "%02h\n", btle_rx_test_output_mem[i]);
          end
          $fwrite(btle_rx_test_output_fd, "\n");
          $fflush(btle_rx_test_output_fd);
          $fclose(btle_rx_test_output_fd);

          $display("rx crc_ok flag verilog %d python %d", rx_crc_ok_store, btle_rx_test_output_crc_ok_ref_mem[0]);
          if (rx_crc_ok_store == btle_rx_test_output_crc_ok_ref_mem[0]) begin
            $display("rx Test PASS.");
            rx_test_ok <= 1;
          end else begin
            $display("rx crc_ok flag is different! Test FAIL.");
          end

          $display("rx Compare the output and the reference: octet");
          NUM_ERROR = 0;
          for (i=0; i<NUM_OCTET_OUTPUT; i=i+1) begin
            if (btle_rx_test_output_mem[i] != btle_rx_test_output_ref_mem[i]) begin
              NUM_ERROR = NUM_ERROR + 1;
            end
          end
          $display("rx %d difference found", NUM_ERROR);
          if (NUM_ERROR > 0) begin
            $display("rx Please check %s VS %s", RX_TEST_OUTPUT_FILENAME, RX_TEST_OUTPUT_REF_FILENAME);
          end

          test_state <= TEST_FINISH;
          $display("TEST FINISH.");
        end

        if (read_start) begin
          if (rx_pdu_octet_mem_addr < (rx_payload_length+2)) begin
            btle_rx_test_output_mem[rx_pdu_octet_mem_addr] <= rx_pdu_octet_mem_data;
            rx_pdu_octet_mem_addr <= rx_pdu_octet_mem_addr + 1;
          end
        end

        // show some run time intermediate events
        if (rx_hit_flag) begin
          $display("rx ACCESS_ADDRESS %08x detected", ACCESS_ADDRESS);
        end

        if (rx_decode_end) begin
          read_start <= 1;
          rx_crc_ok_store <= rx_crc_ok;
          $display("rx payload_length %d octet", rx_payload_length);
          $display("rx best_phase idx (among %4d samples) %d", SAMPLE_PER_SYMBOL, rx_best_phase);
          $display("rx crc_ok %d", rx_crc_ok);
        end
      end
      
      TEST_FINISH: begin
        $display("tx test_ok %d", tx_test_ok);
        $display("rx test_ok %d", rx_test_ok);
        $finish;
      end
    endcase

  end
end

btle_controller # (
  .CLK_FREQUENCE(CLK_FREQUENCE),
  .BAUD_RATE(BAUD_RATE),
  .PARITY(PARITY),
  .FRAME_WD(FRAME_WD),

  .CRC_STATE_BIT_WIDTH(CRC_STATE_BIT_WIDTH),
  .CHANNEL_NUMBER_BIT_WIDTH(CHANNEL_NUMBER_BIT_WIDTH),
  .SAMPLE_PER_SYMBOL(SAMPLE_PER_SYMBOL),
  .GAUSS_FILTER_BIT_WIDTH(GAUSS_FILTER_BIT_WIDTH),
  .NUM_TAP_GAUSS_FILTER(NUM_TAP_GAUSS_FILTER),
  .VCO_BIT_WIDTH(VCO_BIT_WIDTH),
  .SIN_COS_ADDR_BIT_WIDTH(SIN_COS_ADDR_BIT_WIDTH),
  .IQ_BIT_WIDTH(IQ_BIT_WIDTH),
  .GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT(GAUSS_FIR_OUT_AMP_SCALE_DOWN_NUM_BIT_SHIFT),

  .GFSK_DEMODULATION_BIT_WIDTH(GFSK_DEMODULATION_BIT_WIDTH),
  .LEN_UNIQUE_BIT_SEQUENCE(LEN_UNIQUE_BIT_SEQUENCE)
) btle_controller_i (
  .clk(clk),
  .rst(rst),

  // ============================to host: UART HCI=========================
  .uart_rx(uart_rx),
  .uart_tx(uart_tx),

  // =========================to zero-IF RF transceiver====================
  .tx_i_signal(tx_i_signal),
  .tx_q_signal(tx_q_signal),
  .tx_iq_valid(tx_iq_valid),
  .tx_iq_valid_last(tx_iq_valid_last),

  .rx_i_signal(rx_i_signal),
  .rx_q_signal(rx_q_signal),
  .rx_iq_valid(rx_iq_valid),

  // ====baremetal phy interface. should be via uart in the future====
  .baremetal_phy_intf_mode(baremetal_phy_intf_mode), //currently 1 for external access. should be 0 in the future to let btle_ll control phy
  // for phy tx
  .ext_tx_gauss_filter_tap_index(tx_gauss_filter_tap_index), // only need to set 0~8, 9~16 will be mirror of 0~7
  .ext_tx_gauss_filter_tap_value(tx_gauss_filter_tap_value),

  .ext_tx_cos_table_write_address(tx_cos_table_write_address),
  .ext_tx_cos_table_write_data(tx_cos_table_write_data),
  .ext_tx_sin_table_write_address(tx_sin_table_write_address),
  .ext_tx_sin_table_write_data(tx_sin_table_write_data),

  .ext_tx_preamble(preamble),

  .ext_tx_access_address(access_address),
  .ext_tx_crc_state_init_bit(crc_state_init_bit),
  .ext_tx_crc_state_init_bit_load(crc_state_init_bit_load),
  .ext_tx_channel_number(channel_number),
  .ext_tx_channel_number_load(channel_number_load),

  .ext_tx_pdu_octet_mem_data(tx_pdu_octet_mem_data),
  .ext_tx_pdu_octet_mem_addr(tx_pdu_octet_mem_addr),

  .ext_tx_start(tx_start),

  // for phy tx debug purpose
  .ext_tx_phy_bit(tx_phy_bit),
  .ext_tx_phy_bit_valid(tx_phy_bit_valid),
  .ext_tx_phy_bit_valid_last(tx_phy_bit_valid_last),

  .ext_tx_bit_upsample(tx_bit_upsample),
  .ext_tx_bit_upsample_valid(tx_bit_upsample_valid),
  .ext_tx_bit_upsample_valid_last(tx_bit_upsample_valid_last),

  .ext_tx_bit_upsample_gauss_filter(tx_bit_upsample_gauss_filter),
  .ext_tx_bit_upsample_gauss_filter_valid(tx_bit_upsample_gauss_filter_valid),
  .ext_tx_bit_upsample_gauss_filter_valid_last(tx_bit_upsample_gauss_filter_valid_last),

  // for phy rx
  .ext_rx_unique_bit_sequence(access_address),
  .ext_rx_channel_number(channel_number),
  .ext_rx_crc_state_init_bit(crc_state_init_bit),

  .ext_rx_hit_flag(rx_hit_flag),
  .ext_rx_decode_run(rx_decode_run),
  .ext_rx_decode_end(rx_decode_end),
  .ext_rx_crc_ok(rx_crc_ok),
  .ext_rx_best_phase(rx_best_phase),
  .ext_rx_payload_length(rx_payload_length),

  .ext_rx_pdu_octet_mem_addr(rx_pdu_octet_mem_addr),
  .ext_rx_pdu_octet_mem_data(rx_pdu_octet_mem_data)
);

endmodule

