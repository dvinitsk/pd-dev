# set up appropriate variables

export SCRIPTS_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
export CL_ROOT     = $(realpath $(SCRIPTS_DIR)/../../)

# Select which testbench to run.
# Defaults to test_pd if TEST is not provided on the command line.
TEST ?= test_pd

# Testbench name (SV + C++ live in verif/tests)
export TEST_NAME   = $(CL_ROOT)/verif/tests/$(TEST)

# Simulation directory per simulator + test
export SIM_ROOT    = $(CL_ROOT)/verif/sim/$(SIMULATOR)
export SIM_DIR     = $(SIM_ROOT)/$(TEST)

# Default target: create sim dir, compile, then run
all: make_sim_dir compile run

# VCD file per test (optional, but nice)
VCD_FILE     ?= $(CL_ROOT)/$(TEST).vcd
VCD_FILE_STR ?= \"$(VCD_FILE)\"

# Pull in common rules and simulator-specific Makefiles
include ${PROJECT_ROOT}/common/verif/tb/scripts/Makefile.common.inc
