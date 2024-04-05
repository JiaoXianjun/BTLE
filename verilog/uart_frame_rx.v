// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Author: halftop
// Github: https://github.com/halftop
// Email: yu.zh@live.com
// Description: 
// Dependencies: 
// Since: 2019-06-09 16:31:56
// LastEditors: halftop
// LastEditTime: 2019-06-09 16:31:56
// ********************************************************************
// Module Function:
`timescale 1ns / 1ps

module uart_frame_rx
#(
	parameter	CLK_FREQUENCE	= 50_000_000,		//hz
				BAUD_RATE		= 9600		,		//9600、19200 、38400 、57600 、115200、230400、460800、921600
				PARITY			= "NONE"	,		//"NONE","EVEN","ODD"
				FRAME_WD		= 8					//if PARITY="NONE",it can be 5~9;else 5~8
)
(
	input						clk			,		//sys_clk
	input						rst_n		,		
	input						uart_rx		,		
	output	reg	[FRAME_WD-1:0]	rx_frame	,		//frame_received,when rx_done = 1 it's valid
	output	reg					rx_done		,		//once_rx_done
	output	reg					frame_error	 		//when the PARITY is enable if frame_error = 1,the frame received is wrong
);

wire			sample_clk		;
wire			frame_en		;		//once_rx_start
reg				cnt_en			;		//sample_clk_cnt enable
reg		[3:0]	sample_clk_cnt	;		
reg		[log2(FRAME_WD+1)-1:0]		sample_bit_cnt	;
wire			baud_rate_clk	;

localparam	IDLE		=	5'b0_0000,
			START_BIT	=	5'b0_0001,
			DATA_FRAME	=	5'b0_0010,
			PARITY_BIT	=	5'b0_0100,
			STOP_BIT	=	5'b0_1000,
			DONE		=	5'b1_0000;

reg	[4:0]	cstate;
reg [4:0]	nstate;
//
wire	[1:0]	verify_mode;
generate
	if (PARITY == "ODD")
		assign verify_mode = 2'b01;
	else if (PARITY == "EVEN")
		assign verify_mode = 2'b10;
	else
		assign verify_mode = 2'b00;
endgenerate
//detect the start condition--the negedge of uart_rx
reg		uart_rx0,uart_rx1,uart_rx2,uart_rx3;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		uart_rx0 <= 1'b0;
		uart_rx1 <= 1'b0;
		uart_rx2 <= 1'b0;
		uart_rx3 <= 1'b0;
	end else begin
		uart_rx0 <= uart_rx ;
		uart_rx1 <= uart_rx0;
		uart_rx2 <= uart_rx1;
		uart_rx3 <= uart_rx2;
	end
end
//negedge of uart_rx-----start_bit
assign frame_en = uart_rx3 & uart_rx2 & ~uart_rx1 & ~uart_rx0;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		cnt_en <= 1'b0;
	else if (frame_en) 
		cnt_en <= 1'b1;
	else if (rx_done) 
		cnt_en <= 1'b0;
	else
		cnt_en <= cnt_en;
end

assign baud_rate_clk = sample_clk & sample_clk_cnt == 4'd8;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		sample_clk_cnt <= 4'd0;
	else if (cnt_en) begin
		if (baud_rate_clk) 
			sample_clk_cnt <= 4'd0;
		else if (sample_clk)
			sample_clk_cnt <= sample_clk_cnt + 1'b1;
		else
			sample_clk_cnt <= sample_clk_cnt;
	end else 
		sample_clk_cnt <= 4'd0;
end
//the start_bit is the first one (0),then the LSB of the data_frame is the second(1) ......
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		sample_bit_cnt <= 'd0;
	else if (cstate == IDLE)
		sample_bit_cnt <= 'd0;
	else if (baud_rate_clk)
		sample_bit_cnt <= sample_bit_cnt + 1'b1;
	else
		sample_bit_cnt <= sample_bit_cnt;
end
//read the readme
reg		[1:0]	sample_result	;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		sample_result <= 1'b0;
	else if (sample_clk) begin
		case (sample_clk_cnt)
			4'd0:sample_result <= 2'd0;
			4'd3,4'd4,4'd5: sample_result <= sample_result + uart_rx;
			default: sample_result <= sample_result;
		endcase
	end
end
//FSM-1
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		cstate <= IDLE;
	else 
		cstate <= nstate;
end
//FSM-2
always @(*) begin
	case (cstate)
		IDLE		: nstate = frame_en ? START_BIT : IDLE ;
		START_BIT	: nstate = (baud_rate_clk & sample_result[1] == 1'b0) ? DATA_FRAME : START_BIT ;
		DATA_FRAME	: begin
						case (verify_mode[1]^verify_mode[0])
							1'b1: nstate = (sample_bit_cnt == FRAME_WD & baud_rate_clk) ? PARITY_BIT : DATA_FRAME ;		//parity is enable
							1'b0: nstate = (sample_bit_cnt == FRAME_WD & baud_rate_clk) ? STOP_BIT : DATA_FRAME ;		//parity is disable
							default: nstate = (sample_bit_cnt == FRAME_WD & baud_rate_clk) ? STOP_BIT : DATA_FRAME ;	//defasult is disable
						endcase
					end
		PARITY_BIT	: nstate = baud_rate_clk ? STOP_BIT : PARITY_BIT ;
		STOP_BIT	: nstate = (baud_rate_clk & sample_result[1] == 1'b1) ? DONE : STOP_BIT ;
		DONE		: nstate = IDLE;
		default: nstate = IDLE;
	endcase
end
//FSM-3
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rx_frame	<= 'd0;
		rx_done		<= 1'b0;
		frame_error	<= 1'b0;
	end else begin
		case (nstate)
			IDLE		: begin
							rx_frame	<= 'd0;
							rx_done		<= 1'b0;
							frame_error	<= 1'b0;
						end 
			START_BIT	: begin
							rx_frame	<= 'd0;
							rx_done		<= 1'b0;
							frame_error	<= 1'b0;
						end 
			DATA_FRAME	: begin
							if (sample_clk & sample_clk_cnt == 4'd6) 
								rx_frame <= {sample_result[1],rx_frame[FRAME_WD-1:1]};
							else
								rx_frame	<= rx_frame;
							rx_done		<= 1'b0;
							frame_error	<= 1'b0;
						end 
			PARITY_BIT	: begin
							rx_frame	<= rx_frame;
							rx_done		<= 1'b0;
							if (sample_clk_cnt == 4'd8)
							frame_error	<= ^rx_frame ^ sample_result[1];
							else
							frame_error	<= frame_error;
						end 
			STOP_BIT	: begin
							rx_frame	<= rx_frame;
							rx_done		<= 1'b0;
							frame_error	<= frame_error;
						end 
			DONE		: begin
							frame_error	<= frame_error;
							rx_done		<= 1'b1;
							rx_frame	<= rx_frame;
						end 
			default: begin
							rx_frame	<= rx_frame;
							rx_done		<= 1'b0;
							frame_error	<= frame_error;
						end 
		endcase
	end
end

rx_clk_gen
#(
	.CLK_FREQUENCE	(CLK_FREQUENCE	),	//hz
	.BAUD_RATE		(BAUD_RATE		)	//9600、19200 、38400 、57600 、115200、230400、460800、921600
)
rx_clk_gen_inst
(
	.clk			( clk		 )	,
	.rst_n			( rst_n		 )	,
	.rx_start		( frame_en	 )	,
	.rx_done		( rx_done	 )	,
	.sample_clk	 	( sample_clk )	
);	

function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction
endmodule