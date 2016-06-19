[![Build Status](https://travis-ci.org/bullet-physics-playground/bpp.svg?branch=master)](https://travis-ci.org/bullet-physics-playground/bpp) [![Join the chat at https://gitter.im/bullet-physics-playground/bpp](https://badges.gitter.im/bullet-physics-playground/bpp.svg)](https://gitter.im/bullet-physics-playground/bpp?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<a
href="https://www.youtube.com/watch?v=RwMhyvVPsQI&list=PL-OhsevLGGI2bFpOqzqnWsGILh9a5YkDr" target="_blank"><img src="http://img.youtube.com/vi/RwMhyvVPsQI/maxresdefault.jpg" alt="Bullet Physics Playground" width="640" border="10" /></a>

Features:

* [Lua](https://www.lua.org/) scripting   (experimental)
* [OpenGL](https://www.opengl.org/) GUI      (experimental)
* [OpenSCAD](http://www.openscad.org/) import (experimental)
* [POV-Ray](http://www.povray.org/) / [Lightsys](http://www.ignorancia.org/en/index.php?page=Lightsys) export (stable)

Created with Bullet Physics Playground:

* Join the [G+ community](https://plus.google.com/communities/118046861018657351607).

### Build

Select your operating system:

 * [Build on Linux](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Linux)
 * [Build on Windows](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Windows)
 * [Build on Mac OS-X](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Mac-OS-X)

### Run

Start with GUI:
```bash
$ ./bpp
```

Start without GUI and render a 400 frames animation with POV-Ray from the command-line:
```bash
$ echo "render = 1" | ./bpp -f demo/basic/00-hello-pov.lua -n 400 -i
```

Pipe bpp simulation data into [gnuplot](https://en.wikipedia.org/wiki/Gnuplot):
```bash
$ ./bpp -n 200 -f demo/basic/00-hello-cmdline.lua | gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"
```

For more demos, see [demo/](https://github.com/bullet-physics-playground/bpp/tree/master/demo).

## Wiki

* [Basic Usage HOWTO](https://github.com/bullet-physics-playground/bpp/wiki/Basic-Usage-HOWTO)
* [LUA-Bindings-Reference](https://github.com/bullet-physics-playground/bpp/wiki/LUA-Bindings-Reference)
* [POV-Ray on Amazon EC2](https://github.com/bullet-physics-playground/bpp/wiki/POV%E2%80%93Ray-on-Amazon-EC2) WIP

### Authors

* © 2008 – 2016 [@koppi](https://github.com/koppi) – Initial release.
* © 2012 – 2013 [@jaimevives](https://github.com/jaimevives) – POV-Ray export.
