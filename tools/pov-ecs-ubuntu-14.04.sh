#!/usr/bin/env bash

# Install
#
# POV-Ray setup with LightsysIV, ffmpeg and youtube-upload on Ubuntu 14.04.
#
# see: https://github.com/bullet-physics-playground/bpp/issues/8

sudo apt-get -y install povray htop uptimed screen vim unzip make

cd
mkdir .povray
cd .povray
wget -c http://www.ignorancia.org/uploads/zips/lightsys4d.zip
unzip lightsys4d.zip
sudo su -c 'echo "Library_Path=\"/home/ubuntu/.povray/LightsysIV\"" >> /etc/povray/3.7/povray.ini'
cd

sudo add-apt-repository -y ppa:mc3man/trusty-media
sudo apt-get update
sudo apt-get -y install ffmpeg

sudo apt-get -y install python-dev python-pip
sudo pip install --upgrade google-api-python-client progressbar2

wget https://github.com/tokland/youtube-upload/archive/master.zip
unzip master.zip
cd youtube-upload-master
sudo python setup.py install
