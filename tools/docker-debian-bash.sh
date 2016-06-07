#!/usr/bin/env bash
#
# Starts an interactive shell inside the docker container that is used to build the Debian package
#
xhost local:root
docker run -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -it travis.debian.net/bpp /bin/bash
