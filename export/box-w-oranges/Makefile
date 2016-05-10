SHELL:=/bin/bash

SCENE?=$(shell basename `pwd`)

# Cloud rendering host alias "ec2" according to your ~/.ssh/config
# see https://github.com/bullet-physics-playground/bpp/issues/8

EC2?=ec2

# Custom POV-Ray options

POV?=

# Custom POV-Ray include directives

POVINC?=-LLightsysIV

# Custom ffmpeg loop times (default x10 loops)

MKV_LOOP?=10

# ----------------------------------------------------------------------------

POVOPT=${POVINC} ${POV}

all: help

help:
	@echo "usage:"
	@echo ""
	@echo " Local Rendering"
	@echo ""
	@echo "  make quick    # render quick"
	@echo "  make final    # render final"
	@echo ""
	@echo "  make mkv      # make ${SCENE}.mkv      with ffmpeg"
	@echo "  make mkv-loop # make ${SCENE}-loop.mkv (looped ${MKV_LOOP}) times with ffmpeg"
	@echo ""
	@echo "  make clean    # cleanup"
	@echo "  make dist     # cleanup and create ../${SCENE}.tar.xz"
	@echo ""
	@echo " Cloud Rendering on ${EC2}"
	@echo ""
	@echo "  make ec2-up    # make ${SCENE}.tar.xz, upload and extract it to ${EC2}:."
	@echo "  make ec2-down  # make ${SCENE}.mkv on ${EC2} with ffmpeg and scp to local machine"
	@echo ""
	@echo "  see https://github.com/bullet-physics-playground/bpp/issues/8 for POV-Ray on Amazon EC2"
	@echo ""
	@echo " YouTube"
	@echo ""
	@echo "  make youtube-up      # make and upload ${SCENE}.mkv      to YouTube"
	@echo "  make youtube-up-loop # make and upload ${SCENE}-loop.mkv to YouTube"
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

mkv-loop: mkv
	for i in {1..${MKV_LOOP}}; do printf "file '%s'\n" ${SCENE}.mkv >> loop.txt; done
	ffmpeg -y -f concat -i loop.txt -c copy ${SCENE}-loop.mkv
	rm loop.txt

ec2-up: dist
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress ../${SCENE}.tar.xz ${EC2}:.
	ssh ${EC2} "tar xvf ${SCENE}.tar.xz"

ec2-down:
	ssh ${EC2} "make -C ${SCENE} mkv"
	scp ${EC2}:${SCENE}/${SCENE}.mkv .

youtube-up: mkv
	youtube-upload -t "Bullet Physics Playground – ${SCENE}" --privacy=unlisted --category "Science & Technology" ${SCENE}.mkv

youtube-up-loop: mkv-loop
	youtube-upload -t "Bullet Physics Playground – ${SCENE}" --privacy=unlisted --category "Science & Technology" ${SCENE}-loop.mkv

distclean: clean
	/bin/rm -f ${SCENE}.pov ${SCENE}.ini *.pov-state ${SCENE}-*.inc *.log

clean:
	/bin/rm -f ${SCENE}-*.png *.mkv *.pov-state

dist: clean
	find . -print0 | sort -z | XZ_OPT=-9e tar -cvJf ../${SCENE}.tar.xz --no-recursion --null -T -
