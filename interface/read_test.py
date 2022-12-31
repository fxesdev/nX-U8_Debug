import time
from colorama import Fore
import regtool

while True:
	# Unlock
	regtool.write_reg(0x00, 0xAAFE)

	val = regtool.read_reg(0x40)

	if val != 0:
		print(Fore.GREEN, end="")
	else:
		print(Fore.RED, end="")

	print(f"{val:04X}")

	print(Fore.WHITE, end="")

	time.sleep(0.5)
