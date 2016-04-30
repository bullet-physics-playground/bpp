SCENE?=00-transform

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

240p:
	time nice povray ${SCENE}.ini -V +W426 +H240 +Q4 -A ${POV}

720p:
	time nice povray ${SCENE}.ini -V +W1280 +H720 +Q4 +A0.3 ${POV}

2160p:
	time nice povray ${SCENE}.ini -V +W3840 +H2160 +Q11 +A0.3 ${POV}

mkv:
#see https://storage.googleapis.com/jump-inspector/Jump_Inspector_Quick_Start.pdf
#	ffmpeg -i 4channel_ambisonic_audio.wav -i video.mp4 -map 0:a -map 1:v -c:a libvorbis -b:a 512k -channel_layout quad --c:v libx264 -b:v 40000k -bufsize 40000k video.mkv
	time nice ffmpeg -y -framerate 25 -pattern_type glob -i '${SCENE}?????.png' -c:v libx264 -preset veryslow -qp 0 -r 25 -pix_fmt yuv420p '${SCENE}.mkv'

distclean: clean
	/bin/rm -f ${SCENE}.pov ${SCENE}.ini *.pov-state ${SCENE}-?????.inc *.log

clean:
	/bin/rm -f *.png *.avi *.mov

dist: clean
	XZ_OPT=-9e tar -C .. -cvJf ../${SCENE}.tar.xz ${SCENE}
