import regtool
import time

print("[+] Waiting...")

time.sleep(0)

print("[+] Started")

regtool.write_reg(0x00, 0xAAFE)

for x in range(0x7F):
	if regtool.read_reg(x) != 0x00:
		print(f"[*] Found {x:02X}")
