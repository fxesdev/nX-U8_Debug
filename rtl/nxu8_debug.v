/*
 * nX-U8 Debugger / Programmer
 * Top Level Module
 */

`default_nettype none
`timescale 1ns/1ns

module nxu8_debug (
	i_clk,
	i_uart_rx, o_uart_tx,
	o_nx_clk, io_nx_data
);

	`ifdef COCOTB_SIM
	/* Generate VCD dump */
	initial begin
		$dumpfile ("dump.vcd");
		$dumpvars (0, nxu8_debug);
		#1;
	end
	`endif

	/* Module Parameters */
	`ifdef COCOTB_SIM
	parameter UART_CYCLES_BIT = 10;
	`else
	parameter UART_CYCLES_BIT = 217; // 25 MHz to 115200 baud
	`endif

	parameter NX_CLK_DIV = 10;

	/* Module Interface */
	input  wire i_clk;
	input  wire i_uart_rx;
	output wire o_uart_tx;
	output wire o_nx_clk;
	inout  wire io_nx_data;

	/* UART RX */
	reg        r_urx_ack;
	wire [7:0] w_urx_data;
	wire       w_urx_data_rdy;

	uart_rx #(.CYCLES_BIT(UART_CYCLES_BIT)) urx0 (
		.i_clk(i_clk),
		.i_ack(r_urx_ack),
		.i_rx(i_uart_rx),
		.o_data(w_urx_data),
		.o_data_rdy(w_urx_data_rdy)
	);

	/* UART TX */
	reg       r_utx_start;
	reg [7:0] r_utx_data;
	wire      w_utx_busy;

	initial r_utx_start = 1'b0;

	uart_tx #(.CYCLES_BIT(UART_CYCLES_BIT)) utx0 (
		.i_clk(i_clk),
		.i_start(r_utx_start),
		.i_data(r_utx_data),
		.o_tx(o_uart_tx),
		.o_busy(w_utx_busy)
	);

	/* nX-U8 SerDes */
	reg         r_nx_start;
	reg   [6:0] r_nx_addr;
	reg  [15:0] r_nx_i_data;
	reg         r_nx_write;
	wire [15:0] w_nx_o_data;
	wire        w_nx_busy;

	nxu8_serdes #(.NX_CLK_DIV(NX_CLK_DIV)) nxu8 (
		.i_clk(i_clk),
		.i_start(r_nx_start),
		.i_addr(r_nx_addr),
		.i_data(r_nx_i_data),
		.i_wr(r_nx_write),
		.o_data(w_nx_o_data),
		.o_busy(w_nx_busy),
		.o_nx_clk(o_nx_clk),
		.io_nx_data(io_nx_data)
	);

	/* Byte Counter */
	reg r_byte_cnt;
	initial r_byte_cnt = 0;

	/* FSM States */
	localparam s_CMD   = 2'b00,
			   s_DATA  = 2'b01,
			   s_READ  = 2'b10,
			   s_WRITE = 2'b11;

	reg [1:0] r_state;
	initial r_state = s_CMD;

	/* UART <-> nX-U8 Bridge Logic */
	always @(posedge i_clk) begin
		case(r_state)
			s_CMD: begin
				r_urx_ack <= 0;
				r_utx_start <= 0;
				r_nx_start <= 0;
				r_byte_cnt <= 0;
				r_nx_addr <= w_urx_data[6:0];
				r_nx_write <= w_urx_data[7];

				if (w_urx_data_rdy) begin
					r_urx_ack <= 1;

					if (w_urx_data[7]) begin
						r_state <= s_DATA;
					end else begin
						r_nx_start <= 1;
						r_state <= s_READ;
					end
				end
			end
			
			s_DATA: begin
				r_urx_ack <= 0;

				if (w_urx_data_rdy) begin
					r_urx_ack <= 1;
					r_byte_cnt <= 1;

					r_nx_i_data <= {r_nx_i_data[7:0], w_urx_data};

					if (r_byte_cnt) begin
						r_nx_start <= 1;
						r_state <= s_WRITE;
					end
				end
			end
			
			s_READ: begin
				r_urx_ack <= 0;
				r_nx_start <= 0;
				r_utx_start <= 0;

				if (!w_nx_busy) begin
					if (!w_utx_busy) begin
						r_byte_cnt <= 1;

						r_utx_data <= r_byte_cnt ? w_nx_o_data[7:0] : w_nx_o_data[15:8];
						r_utx_start <= 1;

						if (r_byte_cnt)
							r_state <= s_CMD;
					end
				end
			end
			
			s_WRITE: begin
				r_urx_ack <= 0;
				r_nx_start <= 0;
				
				if (!w_nx_busy)
					r_state <= s_CMD;
			end
		endcase
	end

endmodule