# bullet-physics-playground

![physics-00.png](https://github.com/koppi/bullet-physics-playground/raw/master/demo/02-domino.png)

Features:

* LUA scripting (experimental)
* OpenGL gui (alpha)
* POV-Ray export (stable)

Demo videos created with bullet-physics-playground:

* [bullet-physics-playground](http://www.youtube.com/watch?v=19OirI8yjLc) - basic LUA scripting demo
* [povray fun](http://www.youtube.com/watch?v=3DLevGGYDAQ) - falling dice
* [dancing servos](http://www.youtube.com/watch?v=YBQGqMRh3c8) - compound objects with actuators
* [domino dynamics - II](http://www.youtube.com/watch?v=0QQYXvnrU1U) - dominos
* [domino dynamics - I](http://www.youtube.com/watch?v=3Q0V185vVnE) - dominos
* [4800 cubes - HD](http://www.youtube.com/watch?v=6r_kCF1TRAk) - 1st test

## Build bullet-physics-playground

Select your operating system:

 * [Build on Linux](https://github.com/koppi/bullet-physics-playground/wiki/Build-on-Linux)
 * [Build on Mac OSX](https://github.com/koppi/bullet-physics-playground/wiki/Build-on-Mac-OSX)
 * [Build on Windows](https://github.com/koppi/bullet-physics-playground/wiki/Build-on-Windows)

## Run bullet-physics-playground

```
$ ./physics 
```

physics options:

* -p generate POV-Ray output
* -s save screenshots

# LUA scripting examples

* [00-objects.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/00-objects.lua) - basic objects
* [01-test.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/01-test.lua) - LUA syntax testing
* [02-domino.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/02-domino.lua) - function definition and loop
* [03-math.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/03-math.lua) - math functions
* [04-anim.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/04-anim.lua) - callback functions

# Youtube needs more povray animations

Install povray, mencoder and mplayer:

```
$ sudo apt-get -y install povray povray-includes mencoder mplayer
```

Render the pov files to 1920x1080 png images and create anim.avi:

```
cd anim; for f in $(ls *.pov); do ./pov2png.sh $f; done; ./png2avi.sh
```

# Authors / Copyright

* © 2008-2012 [Jakob Flierl](https://github.com/koppi) - code
* © 2012 [Jaime Vives Piqueres](http://ignorancia.org/) - inspiration
