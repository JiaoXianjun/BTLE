// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Author: halftop
// Github: https://github.com/halftop
// Email: yu.zh@live.com
// Description: uart_tx_baud_rate_clk_generate
// Dependencies: 
// Since: 2019-06-07 15:36:59
// LastEditors: halftop
// LastEditTime: 2019-06-07 15:36:59
// ********************************************************************
// Module Function: generate_uart_tx_baud_rate_clk
`timescale 1ns / 1ps
module tx_clk_gen
#(
	parameter	CLK_FREQUENCE	= 50_000_000,		//hz
				BAUD_RATE		= 9600		 		//9600、19200 、38400 、57600 、115200、230400、460800、921600
)
(
	input					clk			,	//system_clk
	input					rst_n		,	//system_reset
	input					tx_done		,	//once_tx_done
	input					tx_start	,	//once_tx_start
	output	reg				bps_clk		 	//baud_rate_clk
);

localparam	BPS_CNT	=	CLK_FREQUENCE/BAUD_RATE-1,
			BPS_WD	=	log2(BPS_CNT);

reg	[BPS_WD-1:0] count;
reg c_state;
reg n_state;
//FSM-1			1'b0:IDLE	1'b1:send_data
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		c_state <= 1'b0;
	else
		c_state <= n_state;
end
//FSM-2
always @(*) begin
	case (c_state)
		1'b0: n_state = tx_start ? 1'b1 : 1'b0;
		1'b1: n_state = tx_done ? 1'b0 : 1'b1;
		default: n_state = 1'b0;
	endcase
end
//FSM-3 FSM's output(count_en) is equal to c_state

//baud_rate_clk_counter
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		count <= {BPS_WD{1'b0}};
	else if (!c_state)
		count <= {BPS_WD{1'b0}};
	else begin
		if (count == BPS_CNT) 
			count <= {BPS_WD{1'b0}};
		else
			count <= count + 1'b1;
	end
end
//baud_rate_clk_output
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		bps_clk <= 1'b0;
	else if (count == 'd1)
		bps_clk <= 1'b1;
	else
		bps_clk <= 1'b0;
end
//get_the_width_of_
function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction

endmodule

