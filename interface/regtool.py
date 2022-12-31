import serial
import argparse
import struct

ser = serial.Serial("/dev/ttyACM0", 115200)

def read_reg(addr):
	ser.write(struct.pack(">B", addr))

	data = ser.read(2)
	data = struct.unpack(">H", data)[0]

	return data

def write_reg(addr, value):
	ser.write(struct.pack(">BH", 0x80 | addr, value))

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("-w", "--write", action="store_true")
	parser.add_argument("address")
	parser.add_argument("data", nargs="?")

	args = parser.parse_args()

	if args.write and args.data == None:
		print("Error: Need to supply data to write")
		quit()
	
	# Parse as hex
	addr = int(args.address.replace("0x", ""), 16)

	# Limit address to 7 bits
	addr = addr & 0x7F

	if args.write:
		data = int(args.data.replace("0x", ""), 16)
		write_reg(addr, data)
	else:
		data = read_reg(addr)
		print(f"{data:04X}")