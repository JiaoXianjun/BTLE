// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Author: halftop
// Github: https://github.com/halftop
// Email: yu.zh@live.com
// Description: 
// Dependencies: 
// Since: 2019-06-08 16:51:59
// LastEditors: halftop
// LastEditTime: 2019-06-08 16:51:59
// ********************************************************************
// Module Function:
`timescale 1ns / 1ps
module uart_frame_tx
#(
	parameter	CLK_FREQUENCE	= 50_000_000,		//hz
				BAUD_RATE		= 9600		,		//9600、19200 、38400 、57600 、115200、230400、460800、921600
				PARITY			= "NONE"	,		//"NONE","EVEN","ODD"
				FRAME_WD		= 8					//if PARITY="NONE",it can be 5~9;else 5~8
)
(
	input						clk			,	//system_clk
	input						rst_n		,	//system_reset
	input						frame_en	,	//once_tx_start
	input		[FRAME_WD-1:0]	data_frame	,	//data_to_tx
	output	reg					tx_done		,	//once_tx_done
	output	reg					uart_tx		 	//uart_tx_data
);

wire	bps_clk;

tx_clk_gen
#(
	.CLK_FREQUENCE	(CLK_FREQUENCE),		//hz
	.BAUD_RATE		(BAUD_RATE	)	 		//9600、19200 、38400 、57600 、115200、230400、460800、921600
)
tx_clk_gen_inst
(
	.clk			( clk		 ),		//system_clk
	.rst_n			( rst_n		 ),		//system_reset
	.tx_done		( tx_done	 ),		//once_tx_done
	.tx_start		( frame_en	 ),		//once_tx_start
	.bps_clk		( bps_clk	 ) 		//baud_rate_clk
);

localparam	IDLE		=	6'b00_0000	,
			READY		=	6'b00_0001	,
			START_BIT	=	6'b00_0010	,
			SHIFT_PRO	=	6'b00_0100	,
			PARITY_BIT	=	6'b00_1000	,
			STOP_BIT	=	6'b01_0000	,
			DONE		=	6'b10_0000	;

wire	[1:0]	verify_mode;
generate
	if (PARITY == "ODD")
		assign verify_mode = 2'b01;
	else if (PARITY == "EVEN")
		assign verify_mode = 2'b10;
	else
		assign verify_mode = 2'b00;
endgenerate

reg		[FRAME_WD-1:0]	data_reg	;
reg		[log2(FRAME_WD-1)-1:0] cnt	;
reg						parity_even	;
reg 	[5:0]			cstate		;
reg		[5:0]			nstate		;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		cnt <= 'd0;
	else if (cstate == SHIFT_PRO & bps_clk == 1'b1) 
		if (cnt == FRAME_WD-1)
			cnt <= 'd0;
		else
			cnt <= cnt + 1'b1;
	else
		cnt <= cnt;
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
		IDLE		: nstate = frame_en ? READY : IDLE	;
		READY		: nstate = (bps_clk == 1'b1) ? START_BIT : READY;
		START_BIT	: nstate = (bps_clk == 1'b1) ? SHIFT_PRO : START_BIT;
		SHIFT_PRO	: nstate = (cnt == FRAME_WD-1 & bps_clk == 1'b1) ? PARITY_BIT : SHIFT_PRO;
		PARITY_BIT	: nstate = (bps_clk == 1'b1) ? STOP_BIT : PARITY_BIT;
		STOP_BIT	: nstate = (bps_clk == 1'b1) ? DONE : STOP_BIT;
		DONE		: nstate = IDLE;
		default		: nstate = IDLE;
	endcase
end
//FSM-3
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		data_reg <= 'd0;
		uart_tx <= 1'b1;
		tx_done <= 1'b0;
		parity_even <= 1'b0;
	end else begin
		case (nstate)
			IDLE		: begin
							data_reg <= 'd0;
							tx_done <= 1'b0;
							uart_tx <= 1'b1;
						end
			READY		: begin
							data_reg <= 'd0;
							tx_done <= 1'b0;
							uart_tx <= 1'b1;
						end
			START_BIT	: begin
							data_reg <= data_frame;
							parity_even <= ^data_frame;
							uart_tx <= 1'b0;
							tx_done <= 1'b0;
						end
			SHIFT_PRO	: begin
							if(bps_clk == 1'b1) begin
								data_reg <= {1'b0,data_reg[FRAME_WD-1:1]};
								uart_tx <= data_reg[0];
							end else begin
								data_reg <= data_reg;
								uart_tx <= uart_tx;
							end
							tx_done <= 1'b0;
						end
			PARITY_BIT	: begin
							data_reg <= data_reg;
							tx_done <= 1'b0;
							case (verify_mode)
								2'b00: uart_tx <= 1'b1;		//若无校验多发一位STOP_BIT
								2'b01: uart_tx <= ~parity_even;
								2'b10: uart_tx <= parity_even;
								default: uart_tx <= 1'b1;
							endcase
						end
			STOP_BIT	: uart_tx <= 1'b1;
			DONE		: tx_done <= 1'b1;
			default		:  begin
							data_reg <= 'd0;
							uart_tx <= 1'b1;
							tx_done <= 1'b0;
							parity_even <= 1'b0;
						end
		endcase
	end
end

function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction

endmodule