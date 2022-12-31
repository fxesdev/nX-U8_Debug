import regtool

for key in range(2**16):
	# Test password
	regtool.write_reg(0, key)

	# Check 0x40
	val = regtool.read_reg(0x40)
	if val != 0:
		print(f"[+] Found KEY: {key:04X} VAL: {val:04X}")

		# Read chip id
		chipid_words = []
		chipid_words.append(regtool.read_reg(0x40))
		chipid_words.append(regtool.read_reg(0x41))
		chipid_words.append(regtool.read_reg(0x42))
		chipid_words.append(regtool.read_reg(0x43))
		chipid_words.append(regtool.read_reg(0x50))
		chipid_words.append(regtool.read_reg(0x51))
		chipid_words.append(regtool.read_reg(0x52))
		chipid_words.append(regtool.read_reg(0x53))

		print("{:04X}{:04X}".format(chipid_words[1], chipid_words[0]))
		print("{:04X}{:04X}".format(chipid_words[3], chipid_words[2]))
		print("{:04X}{:04X}".format(chipid_words[5], chipid_words[4]))
		print("{:04X}{:04X}".format(chipid_words[7], chipid_words[6]))

	if key % 2**11 == 0:
		print(f"[*] {round(100*key/2**16,2)}%")