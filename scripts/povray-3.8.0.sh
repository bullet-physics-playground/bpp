#!/usr/bin/env bash

export POV_DIR=povray-3.8.0
# (--disable-optimiz CXXFLAGS=-O2: configure's own -O3 -ffast-math gave, with
# GCC 13 on Ubuntu 24.04, a POV-Ray that can't parse a default camera --
# "Viewing angle has to be smaller than 180" -- and renders bpp's scenes
# blank; -O2 without -ffast-math renders them right.)
export POV_CFG="--prefix=/opt/povray-3.8.0 --program-prefix=pov-3.8.0- --enable-watch-cursor --disable-optimiz CXXFLAGS=-O2"

sudo apt -y install build-essential devscripts automake libboost-dev libboost-thread-dev zlib1g-dev libpng-dev libjpeg-dev libtiff5-dev libopenexr-dev libsdl1.2-dev

git clone --depth 1 https://github.com/bullet-physics-playground/povray $POV_DIR

cd $POV_DIR

 cd unix/ ; ./prebuild.sh ; cd ../

bash bootstrap

./configure $POV_CFG COMPILED_BY="Jakob Flierl <jakob.flierl@gmail.com>"

make -j5 all

# make check

sudo make install
