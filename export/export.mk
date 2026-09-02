SHELL:=/bin/bash

# Cloud rendering host alias "ec2" according to your ~/.ssh/config
# see https://github.com/bullet-physics-playground/bpp/issues/8

EC2?=ec2

# Custom POV-Ray options

POV?=+W1280 +H720 -J +FN10

# Custom POV-Ray include directives

POVINC?=+LLightsysIV

# Custom ffmpeg loop times (default x10 loops)

MKV_LOOP?=10

# Extra options for scripts/povomatic-job.py (e.g. --res 1080p --priority 5)

POVOMATIC_ARGS?=

# ----------------------------------------------------------------------------

POVOPT=${POVINC} ${POV}

all: quick

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
	@echo " Cluster rendering using slurm"
	@echo ""
	@echo "  make slurm           # render using the slurm workload manager"
	@echo "  make kubernetes      # render using kubernets cluster"
	@echo "  make povomatic       # submit to povomatic (POVOMATIC_ARGS='--res 1080p ...')"
	@echo ""
	@echo " YouTube"
	@echo ""
	@echo "  make youtube-up      # make and upload ${SCENE}.mkv      to YouTube"
	@echo "  make youtube-up-loop # make and upload ${SCENE}-loop.mkv to YouTube"
	@echo ""

quick:
	povray ${SCENE}.ini -V +W380 +H252 +Q3 -A +D -C -CC ${POVOPT} || true

final: 720p

720p:
	povray ${SCENE}.ini -V +W1280 +H720 +Q11 +A0.3 ${POVOPT} || true

mkv:
	ffmpeg -y -err_detect ignore_err -pattern_type glob -i '*.png' -c:v libx264 -preset veryslow -qp 0 -r 25 -pix_fmt yuv444p '${SCENE}.mkv'

mkv-8k:
	ffmpeg -y -threads 1 -filter_threads 1 -filter_complex_threads 1 -err_detect ignore_err -i %05d.png -c:v libx265 -r 25 -crf 18 -preset slow -pix_fmt yuv420p10le -vf "colorspace=bt709:iall=bt709:range=tv:fast=1" -color_primaries bt709 -color_trc bt709 -colorspace bt709 -movflags +faststart '${SCENE}.mkv'

mov-8k:
	ffmpeg -y -threads 1 -filter_threads 1 -filter_complex_threads 1 -err_detect ignore_err -i %05d.png -c:v prores_ks -profile:v 3 -vendor apl0 -pix_fmt yuv422p10le -vf scale=7680:4320 '${SCENE}.mov'

mkv-loop: mkv
	for i in {1..${MKV_LOOP}}; do printf "file '%s'\n" ${SCENE}.mkv >> loop.txt; done
	ffmpeg -y -f concat -i loop.txt -c copy ${SCENE}-loop.mkv
	rm loop.txt

ec2-up:
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress ../${SCENE}.tar.xz ${EC2}:.
	ssh ${EC2} "tar xvf ${SCENE}.tar.xz"

ec2-down:
	ssh ${EC2} "make -C ${SCENE} mkv"
	scp ${EC2}:${SCENE}/${SCENE}.mkv .

slurm:
	sbatch -J ${SCENE} -a 1-`ls -1 ?????.inc|wc -l` --export=POVOPT='${POVOPT}' ../povray.sbatch ${SCENE} `ls -1 *.inc | wc -l`

kubernetes:
	python3 ../../scripts/povray-job.py --start 1 --end `ls -1 ?????.inc | wc -l` --width 1280 --height 720 ${SCENE}.pov

log-kubernets:
	kubectl logs -f -l app=povray-worker --max-log-requests=50 --tail=50

povomatic:
	python3 ../../scripts/povomatic-job.py ${POVOMATIC_ARGS} .

#youtube-up: mkv
#	youtube-upload -t "Bullet Physics Playground – ${SCENE}" --privacy=unlisted --category "Science & Technology" ${SCENE}.mkv
#
#youtube-up-loop: mkv-loop
#	youtube-upload -t "Bullet Physics Playground – ${SCENE}" --privacy=unlisted --category "Science & Technology" ${SCENE}-loop.mkv

distclean: clean
	rm -f ${SCENE}.pov ${SCENE}.ini ?????.inc mesh_*.inc

clean:
	rm -f *.png *.mov *.mp4 *.mkv *.pov-state *.err *.out *.log

dist: clean
	cd .. && find ${SCENE} -print0 | sort -z | tar -cvJf ${SCENE}.tar.xz --no-recursion --null -T -
