TARGETS=$(shell ls -1 *.scad | sed 's/\.scad/.stl/g')

all: ${TARGETS}

%.stl: %.scad
	openscad -m make -o $@ $<
