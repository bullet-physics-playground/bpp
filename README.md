<a
href="https://www.youtube.com/watch?v=RwMhyvVPsQI&list=PL-OhsevLGGI2bFpOqzqnWsGILh9a5YkDr" target="_blank"><img src="http://img.youtube.com/vi/RwMhyvVPsQI/maxresdefault.jpg" alt="Bullet Physics Playground" width="640" border="10" /></a>

Features:

* [Lua](https://www.lua.org/) scripting   (experimental, sometimes segfaults)
* [OpenGL](https://www.opengl.org/)-2 GUI      (experimental, no OpenCL features)
* [OpenSCAD](http://www.openscad.org/) import (experimental, sometimes crashes)
* [POV-Ray](http://www.povray.org/) / [Lightsys](http://www.ignorancia.org/en/index.php?page=Lightsys) export (stable)

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

For a list of Lua-accessible classes, functions and properties, run:
```bash
$ ./bpp -f demo/basic/00-luabind.lua
```

# Basic Usage HOWTO

## Viewer

### Keyboard shortcuts

* "s" starts/stops the physics simulation
* "p" toggles the POV-Ray export mode
* "g" toggles the PNG screenshot saving mode
* "a" toggles display of world axis
* "f" toggles FPS display 
* Enter starts/stops the animation
* Space toggles between fly/revolve camera modes
* Use arrow keys to move the camera 
* "h" shows QGLViewer help window: note the above shortcuts overwrite the QGLViewer ones under the "Keyboard" tab.

### Mouse usage

Press "h" to show QGLViewer help window, and click on the "Mouse" tab to see all the possible mouse actions.

## Editor

The editor has a few known problems:
 
* It will crash if you try to use a non-existant file for a Mesh object. It will crash too if you try to edit the file name. The workaround is to comment out the Mesh and v:add() lines before editing them.

* With scripts which load many objects, or big meshes, the typing can be very slow.

# Wiki

* [Basic Usage HOWTO](https://github.com/bullet-physics-playground/bpp/wiki/Basic-Usage-HOWTO)
* [LUA-Bindings-Reference](https://github.com/bullet-physics-playground/bpp/wiki/LUA-Bindings-Reference)
* [POV-Ray on Amazon EC2](https://github.com/bullet-physics-playground/bpp/wiki/POV%E2%80%93Ray-on-Amazon-EC2)

# Authors

* © 2008 – 2021 [@koppi](https://github.com/koppi) – Initial release.
* © 2012 – 2016 [@jaimevives](https://github.com/jaimevives) – POV-Ray export.
