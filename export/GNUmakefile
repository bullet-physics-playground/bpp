# BPP export top-level Makefile-------------------------------------------------

-include scripts/common.mk

MAKEFLAGS += --no-print-directory

DIRS = $(shell find -mindepth 2 -name 'GNUmakefile' -printf '%h\n' | sed -e 's/\.\///' | sort -u)

DIRS_BUILD = $(DIRS:%=build-%)
DIRS_FINAL = $(DIRS:%=final-%)
DIRS_SLURM = $(DIRS:%=slurm-%)
DIRS_KUBERNETES = $(DIRS:%=kubernetes-%)
DIRS_CLEAN = $(DIRS:%=clean-%)
DIRS_DISTCLEAN = $(DIRS:%=distclean-%)

all: $(DIRS_BUILD)

$(DIRS_BUILD):
	@echo " $(@:build-%=%)"
	$(Q)$(MAKE) -C $(@:build-%=%) all

final: $(DIRS_FINAL)

$(DIRS_FINAL):
	@echo " $(@:final-%=%)"
	$(Q)$(MAKE) -C $(@:final-%=%) final

slurm: $(DIRS_SLURM)

$(DIRS_SLURM):
	@echo " $(@slurm-%=%))"
	$(Q)$(MAKE) -C $(@:slurm-%=%) slurm

kubernetes: $(DIRS_KUBERNETES)

$(DIRS_KUBERNETES):
	@echo " $(@kubernetes-%=%))"
	$(Q)$(MAKE) -C $(@:kubernetes-%=%) kubernetes

clean: $(DIRS_CLEAN)

$(DIRS_CLEAN):
	@echo " $(@:clean-%=%)"
	$(Q)$(MAKE) -C $(@:clean-%=%) clean

distclean: $(DIRS_DISTCLEAN)

$(DIRS_DISTCLEAN):
	@echo " $(@:distclean-%=%)"
	$(Q)$(MAKE) -C $(@:distclean-%=%) distclean


.PHONY: all $(DIRS_BUILD) final $(DIRS_FINAL) slurm $(DIRS_SLURM) kubernetes $(DIRS_KUBERNETES) clean $(DIRS_CLEAN) distclean $(DIRS_DISTCLEAN)
