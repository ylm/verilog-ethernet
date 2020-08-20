TRELLIS?=/usr/share/trellis

#############################################################################
# Author: Lane Brooks/Keith Fife
# Date: 04/28/2006
# License: GPL
# Desc: This is a Makefile intended to take a verilog rtl design
# through the Xilinx ISE tools to generate configuration files for
# Xilinx FPGAs. This file is generic and just a template. As such
# all design specific options such as synthesis files, fpga part type,
# prom part type, etc should be set in the top Makefile prior to
# including this file. Alternatively, all parameters can be passed
# in from the command line as well.
#
##############################################################################
#
# Parameter:
# SYN_FILES - Space seperated list of files to be synthesized
# PART - FPGA part (see Xilinx documentation)
# PROM - PROM part
# NGC_PATHS - Space seperated list of any dirs with pre-compiled ngc files.
# UCF_FILES - Space seperated list of user constraint files. Defaults to xilinx/$(FPGA_TOP).ucf
#
#
# Example Calling Makefile:
#
# SYN_FILES = fpga.v fifo.v clks.v
# PART = xc3s1000
# FPGA_TOP = fpga
# PROM = xc18v04
# NGC_PATH = ipLib1 ipLib2
# FPGA_ARCH = spartan6
# SPI_PROM_SIZE = (in bytes)
# include xilinx.mk
#############################################################################
#
# Command Line Example:
# make -f xilinx.mk PART=xc3s1000-4fg320 SYN_FILES="fpga.v test.v" FPGA_TOP=fpga
#
##############################################################################
#
# Required Setup:
#
# %.ucf - user constraint file. Needed by ngdbuild
#
# Optional Files:
# %.xcf - user constraint file. Needed by xst.
# %.ut - File for pin states needed by bitgen


.PHONY: clean bit prom fpga spi


# Mark the intermediate files as PRECIOUS to prevent make from
# deleting them (see make manual section 10.4).
.PRECIOUS: %.ngc %.ngd %_map.ncd %.ncd %.twr %.bit %_timesim.v

# include the local Makefile for project for any project specific targets
CONFIG ?= config.mk
-include ../$(CONFIG)

SYN_FILES_REL = $(patsubst %, ../%, $(SYN_FILES))
INC_FILES_REL = $(patsubst %, ../%, $(INC_FILES))
INC_PATHS_REL = $(patsubst %, ../%, $(INC_PATHS))
NGC_PATHS_REL = $(patsubst %, ../%, $(NGC_PATHS))

ifdef LPF_FILES
  LPF_FILES_REL = $(patsubst %, ../%, $(LPF_FILES))
else
  LPF_FILES_REL = $(FPGA_TOP).lpf
endif

ifdef CLK_FILES
  CLK_FILES_REL = $(patsubst %, ../%, $(CLK_FILES))
else
  CLK_FILES_REL = $(FPGA_TOP).py
endif



fpga: $(FPGA_TOP).bit

mcs: $(FPGA_TOP).mcs

prom: $(FPGA_TOP).spi

spi: $(FPGA_TOP).spi

fpgasim: $(FPGA_TOP)_sim.v


########################### XST TEMPLATES ############################
# There are 2 files that XST uses for synthesis that we auto generate.
# The first is a project file which is just a list of all the verilog
# files. The second is the src file which passes XST all the options.
# See XST user manual for XST options.
%.json: $(SYN_FILES_REL) $(INC_FILES_REL)
	rm -rf defines.v
	touch defines.v
	for x in $(DEFS); do echo '`define' $$x >> defines.v; done
	yosys -p "synth_ecp5 -json $@ -top $(FPGA_TOP)" $(SYN_FILES_REL) defines.v


########################### ISE TRANSLATE ############################
# ngdbuild will automatically use a ucf called %.ucf if one is found.
# We setup the dependancy such that %.ucf file is required. If any
# pre-compiled ncd files are needed, set the NGC_PATH variable as a space
# seperated list of directories that include the pre-compiled ngc files.
%.config: %.json $(LPF_FILES_REL) $(CLK_FILES_REL)
	nextpnr-ecp5 --json $< --lpf $(LPF_FILES_REL) --pre-pack $(CLK_FILES_REL) --textcfg $@ --um5g-45k --package CABGA381


%.bit: %.config
	ecppack --svf-rowsize 100000 --svf $*.svf $< $@

%.svf: %.bit

prog: attosoc.svf
	openocd -f ${TRELLIS}/misc/openocd/ecp5-versa5g.cfg -c "transport select jtag; init; svf $<; exit"

.PHONY: attosoc_sim clean prog
.PRECIOUS: attosoc.json attosoc_out.config attosoc.bit
