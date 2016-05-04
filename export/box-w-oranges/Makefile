SCENE?=box-w-oranges
POV?=

POVINC?=-LLightsysIV

POVOPT=${POVINC} ${POV}

all: help

help:
	@echo "usage:"
	@echo ""
	@echo " Local Rendering"
	@echo ""
	@echo "  make quick # render quick"
	@echo "  make final # render final"
	@echo ""
	@echo "  make mkv   # convert pngs to mkv with ffmpeg"
	@echo ""
	@echo "  make clean # cleanup"
	@echo "  make dist  # cleanup and create ../${SCENE}.tar.xz"
	@echo ""
	@echo " Clound Rendering"
	@echo ""
	@echo "  make ec2-up     # make ${SCENE}.tar.xz, upload and extract it to ec2:."
	@echo "  make ec2-down   # make ${SCENE}.mkv on ec2 with ffmpeg and scp to local machine"
	@echo "  make youtube-up # make ${SCENE}.mkv on ec2 with ffmpeg and upload to YouTube"
	@echo ""

quick:
	/usr/bin/time nice povray ${SCENE}.ini -V +W380 +H252 +Q4 -A +d ${POVOPT}

quickc:
	/usr/bin/time nice povray ${SCENE}.ini -V +W380 +H252 +Q4 -A +d +c ${POVOPT}

final: 720p

720p:
	/usr/bin/time nice povray ${SCENE}.ini -V +W1280 +H720 +Q11 +A0.3 ${POVOPT}

mkv:
	/usr/bin/time nice ffmpeg -y -framerate 25 -pattern_type glob -i '${SCENE}*.png' -c:v libx264 -preset veryslow -qp 0 -r 25 -pix_fmt yuv420p '${SCENE}.mkv'

ec2-up: dist
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress ../${SCENE}.tar.xz ec2:.
	ssh ec2 "tar xvf ${SCENE}.tar.xz"

ec2-down:
	ssh ec2 "make -C ${SCENE} mkv"
	scp ec2:${SCENE}/${SCENE}.mkv .

youtube-up: mkv
	youtube-upload -t "Bullet Physics Playground – ${SCENE}" --privacy=unlisted --category "Science & Technology" ${SCENE}.mkv

distclean: clean
	/bin/rm -f ${SCENE}.pov ${SCENE}.ini *.pov-state ${SCENE}-*.inc *.log

clean:
	/bin/rm -f ${SCENE}-*.png *.mkv *.pov-state

dist: clean
	XZ_OPT=-9e tar -C .. -cvJf ../${SCENE}.tar.xz ${SCENE}
