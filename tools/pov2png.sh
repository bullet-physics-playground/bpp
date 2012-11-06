#!/bin/sh

#povray -d +i$1 +O$1.png -W320 -H200 +FN8 +L. +L.. +L../.. +L../../povray
povray -d +i$1 +O$1.png -W1920 -H1080 +FN8 +L. +L.. +L../.. +L../../povray
