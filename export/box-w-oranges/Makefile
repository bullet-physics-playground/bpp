SCENE?=box-w-oranges

all:
	@echo "usage:"
	@echo ""
	@echo "  make quick # render quick"
	@echo "  make final # render final"
	@echo ""
	@echo "  make mkv   # convert pngs to mkv with ffmpeg"
	@echo ""
	@echo "  make clean # cleanup"
	@echo "  make dist  # cleanup and create ../${SCENE}.tar.xz"
	@echo ""

quick:
	time nice povray ${SCENE}.ini -V +W380 +H252 +Q4 -A +d ${POV}

quickc:
	time nice povray ${SCENE}.ini -V +W760 +H506 +Q4 -A +d +c ${POV}

final:
	time nice povray ${SCENE}.ini -V +W760 +H506 +Q11 +A0.3 -d +c ${POV}

mkv:
	time nice ffmpeg -y -framerate 25 -pattern_type glob -i '${SCENE}*.png' -c:v libx264 -preset veryslow -qp 0 -r 25 -pix_fmt yuv420p '${SCENE}.mkv'

distclean: clean
	/bin/rm -f ${SCENE}.pov ${SCENE}.ini *.pov-state ${SCENE}-*.inc *.log

clean:
	/bin/rm -f ${SCENE}-*.png *.mkv

dist: clean
	XZ_OPT=-9e tar -C .. -cvJf ../${SCENE}.tar.xz ${SCENE}
