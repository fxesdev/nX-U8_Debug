/*
 * nX-U8 Debugger / Programmer
 * nX-U8 Debug Port SerDes
 */

`default_nettype none
`timescale 1ns/1ns

module nxu8_serdes(
	i_clk,
	i_start, i_addr, i_data, i_wr,
	o_data, o_busy, o_valid,
	o_nx_clk, io_nx_data
);

	/* Module Parameters */
	parameter NX_CLK_DIV = 10;

	/* Module Interface */
	input  wire        i_clk;
	input  wire        i_start;
	input  wire  [6:0] i_addr;
	input  wire [15:0] i_data;
	input  wire        i_wr;
	output wire [15:0] o_data;
	output wire        o_busy;
	output wire        o_valid;
	output wire        o_nx_clk;
	inout  wire        io_nx_data;

	assign o_busy = r_dbg_clk_en | i_start;
	assign o_valid = r_valid;
	assign o_data = r_data;
	assign o_nx_clk = r_dbg_clk;

	/* Data Tristate */
	reg r_write;
	assign io_nx_data = r_write ? r_data[15] : 1'bz;

	/* Data Register */
	reg [15:0] r_data;

	/* Data Valid */
	reg r_valid;
	initial r_valid = 0;

	/* Debug Clock Generation */
	reg r_dbg_clk;

	reg [$clog2(NX_CLK_DIV/2)-1:0] r_dbg_clk_cnt;

	reg r_dbg_clk_en;
	initial r_dbg_clk_en = 0;

	always @(posedge i_clk)
		if (r_dbg_clk_en)
			if(r_dbg_clk_cnt == NX_CLK_DIV/2-1) begin
				r_dbg_clk_cnt <= 0;
				r_dbg_clk <= !r_dbg_clk;
			end else
				r_dbg_clk_cnt <= r_dbg_clk_cnt + 1;
		else begin
			r_dbg_clk <= 0;
			r_dbg_clk_cnt <= 0;
		end
	
	/* Clock Center Detection */
	wire w_clk_negedge = (r_dbg_clk_cnt == NX_CLK_DIV/2-1) && r_dbg_clk;

	/* Bit Counter */
	reg [3:0] r_bit_cnt;

	/* FSM States */
	localparam s_IDLE  = 2'b00,
			   s_ADDR  = 2'b01,
			   s_READ  = 2'b10,
			   s_WRITE = 2'b11;

	reg [1:0] r_state;
	initial r_state = s_IDLE;

	/* FSM Logic */
	always @(posedge i_clk)
		case(r_state)
			s_IDLE: begin
				r_write <= 1'b0;
				r_dbg_clk_en <= 0;
				r_bit_cnt <= 0;

				if (i_start) begin
					r_data <= {i_addr, !i_wr, {8{1'b0}}};
					r_valid <= 0;
					r_dbg_clk_en <= 1;
					r_write <= 1;
					r_state <= s_ADDR;
				end
			end

			s_ADDR:
				if (w_clk_negedge) begin
					r_bit_cnt <= r_bit_cnt + 1;
					r_data <= {r_data[14:0], 1'b0};

					if (r_bit_cnt == 7) begin
						r_bit_cnt <= 0;

						if (i_wr) begin
							r_data <= i_data;
							r_state <= s_WRITE;
						end else begin
							r_write <= 0;
							r_state <= s_READ;
						end
					end
				end
			
			s_READ:
				if (w_clk_negedge) begin
					r_bit_cnt <= r_bit_cnt + 1;
					r_data <= {r_data[14:0], io_nx_data};

					if (r_bit_cnt == 15) begin
						r_valid <= 1;
						r_dbg_clk_en <= 0;
						r_state <= s_IDLE;
					end
				end

			s_WRITE:
				if (w_clk_negedge) begin
					r_bit_cnt <= r_bit_cnt + 1;
					r_data <= {r_data[14:0], 1'b0};

					if (r_bit_cnt == 15) begin
						r_dbg_clk_en <= 0;
						r_state <= s_IDLE;
					end
				end
		endcase

endmodule