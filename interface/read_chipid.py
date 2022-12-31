import regtool
import time
from colorama import Fore

while True:
    # start debug interface
    regtool.write_reg(0x00, 0xaafe)

    print("-=-=-=-=-=-=-=-=-=-=-")

    # read ChipID
    chipid_words = []
    chipid_words.append(regtool.read_reg(0x40))
    chipid_words.append(regtool.read_reg(0x41))
    chipid_words.append(regtool.read_reg(0x42))
    chipid_words.append(regtool.read_reg(0x43))
    chipid_words.append(regtool.read_reg(0x50))
    chipid_words.append(regtool.read_reg(0x51))
    chipid_words.append(regtool.read_reg(0x52))
    chipid_words.append(regtool.read_reg(0x53))

    if set(chipid_words) != {0}:
        print(Fore.GREEN, end = "")
    else:
        print(Fore.RED, end = "")

    print("{:04x}{:04x}".format(chipid_words[1], chipid_words[0]))
    print("{:04x}{:04x}".format(chipid_words[3], chipid_words[2]))
    print("{:04x}{:04x}".format(chipid_words[5], chipid_words[4]))
    print("{:04x}{:04x}".format(chipid_words[7], chipid_words[6]))

    print(Fore.WHITE, end = "")

    time.sleep(0.5)
