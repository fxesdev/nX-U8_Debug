/*
 * nX-U8 Debugger / Programmer
 * UART RX Module
 */

`default_nettype none
`timescale 1ns/1ns

module uart_rx (
	i_clk,
	i_ack,
	i_rx,
	o_data, o_data_rdy
);

	/* Module Parameters */
	parameter CYCLES_BIT = 217;

	/* Module Interface */
	input  wire       i_clk;
	input  wire       i_ack;
	input  wire       i_rx;
	output wire [7:0] o_data;
	output wire       o_data_rdy;

	assign o_data = r_data;
	assign o_data_rdy = r_data_rdy && !r_ack_recvd && !i_ack;

	reg [7:0] r_data;
	reg r_data_rdy;

	initial r_data = 0;
	initial r_data_rdy = 0;

	/* i_rx Synchroniser */
	reg [1:0] r_rx;
	always @(posedge i_clk)
		r_rx <= {i_rx, r_rx[1]};
	
	/* Acknowledge Recieved */
	reg r_ack_recvd;
	initial r_ack_recvd = 0;

	/* Clock and Bit Counter */
	reg [$clog2(CYCLES_BIT-1)-1:0] r_clk_cnt;
	reg [3:0] r_bit_cnt;

	/* FSM States */
	localparam s_IDLE = 2'b00,
			   s_RECV = 2'b01,
			   s_WAIT = 2'b10;

	reg [1:0] r_state;
	initial r_state = s_IDLE;

	/* FSM Logic */
	always @(posedge i_clk)
		case(r_state)
			s_IDLE: begin
				// Hold data ready high until ack
				if (r_ack_recvd)
					r_data_rdy <= 1'b0;

				r_ack_recvd <= r_ack_recvd | i_ack;

				r_bit_cnt <= 1'b0;
				r_clk_cnt <= CYCLES_BIT/2;	// Sample in center of bit

				if(r_rx[0] == 1'b0) begin	// Start bit detection
					r_ack_recvd <= 1'b0;
					r_data_rdy <= 1'b0;
					r_state <= s_RECV;
				end
			end

			s_RECV: begin
				if(r_clk_cnt == CYCLES_BIT-1) begin
					r_bit_cnt <= r_bit_cnt + 1;
					r_clk_cnt <= 0;
					r_data <= {r_rx[0], r_data[7:1]};

					if (r_bit_cnt == 8)	begin // 8 data-bits + 1 stop-bit
						r_data_rdy <= 1'b1;
						r_state <= s_WAIT;
					end

				end else
					r_clk_cnt <= r_clk_cnt + 1;
			end

			s_WAIT: begin
				// Hold data ready high until ack
				if (r_ack_recvd)
					r_data_rdy <= 1'b0;

				r_ack_recvd <= r_ack_recvd | i_ack;

				// Wait 1 bit time
				if(r_clk_cnt == CYCLES_BIT-1)
					r_state <= s_IDLE;
				else
					r_clk_cnt <= r_clk_cnt + 1;
			end
		endcase

endmodule