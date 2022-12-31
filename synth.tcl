yosys read_verilog -Irtl/ rtl/*
yosys synth_ecp5 -top nxu8_debug
yosys write_json design.json