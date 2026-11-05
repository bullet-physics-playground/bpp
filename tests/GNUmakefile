SHELL:=bash

# Detect operating system
UNAME_S := $(shell uname -s)

# Set application command based on OS
ifeq ($(UNAME_S),Darwin)
    DEBUG_APP = debug/bpp.app/Contents/MacOS/bpp
    RELEASE_APP = release/bpp.app/Contents/MacOS/bpp
else
    DEBUG_APP = debug/bpp
    RELEASE_APP = release/bpp
endif

all: debug release

# The Lua unit tests and the Lua API snapshot: quick. A failing test fails
# the target. "make check" runs every suite of tests/harness.py (see there;
# off Linux it runs the unit and smoke suites only).
debug:
	@echo "tests debug/bpp======================================"
	@python3 harness.py --bpp ../$(DEBUG_APP) unit api

release:
	@echo "tests release/bpp =================================================="
	@python3 harness.py --bpp ../$(RELEASE_APP) unit api

check:
	@python3 harness.py --bpp ../$(RELEASE_APP)

.PHONY: all debug release check
