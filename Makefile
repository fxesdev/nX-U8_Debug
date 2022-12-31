toplevel = top.v

all: synth bitstream flash

synth:
	yosys -p "tcl synth.tcl"

bitstream:
	nextpnr-ecp5 --25k --package CABGA256 --lpf top.lpf --json design.json --textcfg design.cfg --lpf-allow-unconstrained
	ecppack design.cfg --compress --svf nxu8_dbg.svf

flash:
	openocd -f flash.cfg

clean:
	rm -f design.json design.cfg nxu8_dbg.svf

test:
	cd bench && $(MAKE)