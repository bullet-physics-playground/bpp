# POV-Ray Makefile -------------------------------------------------------------

POVRAY  ?= povray
POVOPT  ?= -c +d +v +sp4 +ep4

FILES   ?= 00-objects
RES     ?= LOW

# Dependencies -----------------------------------------------------------------
DOCPNG   = ${FILES:=.png}
DOCAVI   = ${FILES:=.avi}

AVICLEAN = ${FILES:=.aviclean}
PNGCLEAN = ${FILES:=.pngclean}

.SUFFIXES:
.SUFFIXES: .pov .ini .png .avi .aviclean .pngclean

all: png

png: $(DOCPNG)

avi: $(DOCAVI)

%.pov: Makefile settings.inc

%.png: %.ini %.pov
	$(POVRAY) $(POVOPT) '$<[$(RES)]' -i'${@:.png=.pov}' +fn +o'$@'

%.avi: %.ini %.pov
	$(POVRAY) $(POVOPT) '$<[$(RES)]' -i'${@:.avi=.pov}'

# Clean up code ----------------------------------------------------------------

%.aviclean:
	/bin/rm -fr '${@:.aviclean=.avi}'
%.pngclean:
	/bin/rm -fr '${@:.pngclean=.png}'

clean: $(AVICLEAN) $(PNGCLEAN)
	/bin/rm -fr *~ *.bak $(FILES)-*.inc $(FILES).avi $(FILES)*.png divx2pass.log *.pov-state
