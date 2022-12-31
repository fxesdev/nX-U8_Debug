/*
 * nX-U8 Debugger / Programmer
 * UART TX Module
 */

`default_nettype none
`timescale 1ns/1ns

module uart_tx (
	i_clk,
	i_start,
	i_data,
	o_tx, o_busy
);

	/* Module Parameters */
	parameter CYCLES_BIT = 217;

	/* Module Interface */
	input  wire       i_clk;
	input  wire       i_start;
	input  wire [7:0] i_data;
	output wire       o_tx;
	output wire       o_busy;

	assign o_tx = (r_state == s_IDLE) ? 1 : r_data[0];
	assign o_busy = (r_state != s_IDLE) | i_start;

	/* Clock and Bit Counter */
	reg [$clog2(CYCLES_BIT-1)-1:0] r_clk_cnt;
	reg [3:0] r_bit_cnt;

	/* Data Register */
	reg [9:0] r_data;

	/* FSM States */
	localparam s_IDLE = 1'b0,
			   s_SEND = 1'b1;

	reg r_state;
	initial r_state = s_IDLE;

	/* FSM Logic */
	always @(posedge i_clk)
		case(r_state)
			s_IDLE: begin
				r_data <= {1'b1, i_data, 1'b0};		// Stop Bit, Data & Start Bit
				r_bit_cnt <= 0;
				r_clk_cnt <= 0;

				if (i_start)
					r_state <= s_SEND;
			end

			s_SEND: begin
				if(r_clk_cnt == CYCLES_BIT-1) begin
					r_bit_cnt <= r_bit_cnt + 1;
					r_clk_cnt <= 0;
					r_data <= {1'b1, r_data[9:1]};

					if (r_bit_cnt == 9) // Stop Bit, Data & Start Bit
						r_state <= s_IDLE;
					
				end else
					r_clk_cnt <= r_clk_cnt + 1;
			end
		endcase

endmodule