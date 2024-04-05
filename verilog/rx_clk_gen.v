// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Author: halftop
// Github: https://github.com/halftop
// Email: yu.zh@live.com
// Description: generate uart rx sample clk = 9 x BAUD_RATE
// Dependencies: 
// Since: 2019-06-09 16:30:57
// LastEditors: halftop
// LastEditTime: 2019-06-09 16:30:57
// ********************************************************************
// Module Function: generate uart rx sample clk = 9 x BAUD_RATE
`timescale 1ns / 1ps

module rx_clk_gen
#(
	parameter	CLK_FREQUENCE	= 50_000_000,	//hz
				BAUD_RATE		= 9600		 	//9600、19200 、38400 、57600 、115200、230400、460800、921600
)
(
	input					clk			,
	input					rst_n		,
	input					rx_start	,
	input					rx_done		,
	output	reg				sample_clk	 
);

localparam	SMP_CLK_CNT	=	CLK_FREQUENCE/BAUD_RATE/9 - 1,
			CNT_WIDTH	=	log2(SMP_CLK_CNT)			 ;

reg		[CNT_WIDTH-1:0]	clk_count	;
reg		cstate;
reg		nstate;
//FSM-1	1'b0:IDLE 1'b1:RECEIVE
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cstate <= 1'b0;
	end else begin
		cstate <= nstate;
	end
end
//FSM-2
always @(*) begin
	case (cstate)
		1'b0: nstate = rx_start ? 1'b1 : 1'b0;
		1'b1: nstate = rx_done ? 1'b0 : 1'b1 ;
		default: nstate = 1'b0;
	endcase
end
//FSM-3 FSM's output(clk_count_en) is equal to cstate

//sample_clk_counter
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		clk_count <= 'd0;
	else if (!cstate) 
		clk_count <= 'd0;
	else if (clk_count == SMP_CLK_CNT)
		clk_count <= 'd0;
	else
		clk_count <= clk_count + 1'b1;
end
//generate sample_clk = 9xBAUD_RATE
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		sample_clk <= 1'b0;
	else if (clk_count == 1'b1) 
		sample_clk <= 1'b1;
	else 
		sample_clk <= 1'b0;
end
//get the width of sample_clk_counter
function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction

endmodule