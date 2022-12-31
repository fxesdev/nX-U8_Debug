# Makefile

# defaults
SIM ?= icarus
COCOTB_HDL_TIMEPRECISION = 1ns
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../rtl/*.v

TOPLEVEL = nxu8_debug
MODULE = bench

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim