import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles, Event
from cocotb.utils import get_sim_time

import random

nxu8_memory = {}
nxu8_write = Event("nxu8_write")
nxu8_read = Event("nxu8_read")
uart_read = Event("uart_read")

async def nx_u8(dut):
	while True:
		# Read address
		addr = 0
		for x in range(7):
			await RisingEdge(dut.o_nx_clk)
			addr <<= 1
			addr |= dut.io_nx_data.value

		# Read/Write
		await RisingEdge(dut.o_nx_clk)
		write = not dut.io_nx_data.value

		if write:
			# Read 16 bits
			data = 0
			for x in range(16):
				await RisingEdge(dut.o_nx_clk)
				data <<= 1
				data |= dut.io_nx_data.value
			
			nxu8_memory[addr] = data

			print(f"[*] Write: {data:04X} to {addr:02X}")

			nxu8_write.set((addr, data))
		else:
			try:
				data = nxu8_memory[addr]
			except KeyError:
				data = 0x1234
				print(f"[-] Couldn't find data at {addr:02X}")

			print(f"[*] Read: {data:04X} from {addr:02X}")

			for x in range(16):
				await RisingEdge(dut.o_nx_clk)	
				dut.io_nx_data.value = 1 if (data & 0x8000) else 0
				data <<= 1
			
			nxu8_read.set((addr, data))

async def uart_rx(dut):
	while True:
		# Wait for start bit
		await FallingEdge(dut.o_uart_tx)

		# Wait 1.5 bits
		await ClockCycles(dut.i_clk, 15)

		# Get 8 bits
		data = 0
		for x in range(8):
			data >>= 1
			data |= 0x80 if dut.o_uart_tx.value else 0
			await ClockCycles(dut.i_clk, 10)
		
		print(f"[*] UART RX: {data:02X}")

		uart_read.set(data)

async def uart_tx(dut, data):
	print(f"[*] UART TX: {data:02X}")

	data = 0x200 | (data << 1)
	while data != 0:
		dut.i_uart_rx.value = data & 1
		data >>= 1
		await ClockCycles(dut.i_clk, 10)

@cocotb.test()
async def test(dut):
	dut.i_uart_rx.value = 1

	# DUT Clock
	cocotb.start_soon(Clock(dut.i_clk, 2, "ns").start())
	await ClockCycles(dut.i_clk, 2)

	# UART RX
	await cocotb.start(uart_rx(dut))

	# nX-U8 Emulator
	await cocotb.start(nx_u8(dut))

	# Write then read test
	for x in range(10):
		# Write random value to random address
		addr = random.getrandbits(7)
		data = random.getrandbits(16)

		await uart_tx(dut, 0x80 | addr)
		await uart_tx(dut, data >> 8)
		await uart_tx(dut, data & 0xFF)

		# Wait for write
		await nxu8_write.wait()
		nxu8_write.clear()

		# Check match
		assert(nxu8_write.data[0] == addr)
		assert(nxu8_write.data[1] == data)

		# Read back from memory
		await uart_tx(dut, addr)

		read = 0
		for x in range(2):
			await uart_read.wait()
			uart_read.clear()

			read <<= 8
			read |= uart_read.data

		# Check match
		assert(read == data)
	
	# Random read test
	for x in range(10):
		addr = random.getrandbits(7)
		data = random.getrandbits(16)

		nxu8_memory[addr] = data

		# Read from memory
		await uart_tx(dut, addr)

		read = 0
		for x in range(2):
			await uart_read.wait()
			uart_read.clear()

			read <<= 8
			read |= uart_read.data

		# Check match
		assert(read == data)