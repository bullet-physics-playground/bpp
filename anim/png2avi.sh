#!/bin/sh

OPT=-mf fps=25 -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=1000:turbo:vpass=1
#OPT=-mf fps=25 -ovc lavc -lavcopts mbd=2:trell=yes:v4mv=yes:vbitrate=400000
#OPT=-mf fps=25 -ovc lavc -lavcopts vcodec=mpeg4:mbd=1:vbitrate=9000

mencoder "mf://*.png" $OPT -o anim.avi 
