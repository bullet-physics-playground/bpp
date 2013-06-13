# bullet-physics-playground

<a
href="http://www.youtube.com/watch?feature=player_embedded&v=19OirI8yjLc&hd=1"
target="_blank"><img src="http://img.youtube.com/vi/19OirI8yjLc/0.jpg"
alt="bullet-physics-playground" width="480" height="360" border="10" /></a>

Features:

* LUA scripting  (experimental)
* OpenGL gui     (experimental)
* POV-Ray export (stable)

Created with bullet-physics-playground:

* [Still images](https://github.com/koppi/bullet-physics-playground/wiki/Still-images)
* [Animations](https://github.com/koppi/bullet-physics-playground/wiki/Animations)

## Build

Select your operating system:

 * [Build on Linux](https://github.com/koppi/bullet-physics-playground/wiki/Build-on-Linux)
 * [Build on Mac OSX](https://github.com/koppi/bullet-physics-playground/wiki/Build-on-Mac-OSX)
 * [Build on Windows](https://github.com/koppi/bullet-physics-playground/wiki/Build-on-Windows)

## Run

```
$ ./physics 
```

# Document

* [Basic Usage HOWTO (WIP)](https://github.com/koppi/bullet-physics-playground/wiki/Basic-Usage-HOWTO)
* [LUA Scripting Reference (WIP)](https://github.com/koppi/bullet-physics-playground/wiki/LUA-Scripting-Reference)

## Examples

* [00-hello.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/00-hello.lua) - hello LUA
* [01-syntax.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/01-syntax.lua) - LUA syntax
* [02-dominos.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/02-dominos.lua) - dominos
* [03-math-fun.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/03-math-fun.lua) - math functions
* [04-callbacks.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/04-callbacks.lua) - callback functions
* [05-mesh-chain.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/05-mesh-chain.lua) - transform functions
* [06-mesh-chain2.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/06-mesh-chain2.lua) - transform functions
* [07-pilesofcoins.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/07-pilesofcoins.lua) - customize POV-Ray export
* [08-box-w-oranges.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/08-box-w-oranges.lua) - general usage demo
* [09-tower-w-blocks.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/09-tower-w-blocks.lua)
 - different values on v.fixedTimestep produce stabile / unstable results
* [10-3ds-box-w-coins.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/10-3ds-box-w-coins.lua) - usage of ```postSim()``` to add/remove objects during simulation
* [11-car-hinge-slider.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/11-car-hinge-slider.lua) - usage of hinge and slider constraints
* [12-collar-poin2point.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/12-collar-point2point.lua) - usage of point-to-point constraints

## Youtube

Install povray, mencoder and mplayer:

```
$ sudo apt-get -y install povray povray-includes mencoder mplayer
```

Render the pov files to 1920x1080 png images and create anim.avi:

```
cd anim; for f in $(ls *.pov); do ./pov2png.sh $f; done; ./png2avi.sh
```

## Authors

* © 2008 – 2013 [Jakob Flierl](https://github.com/koppi)
* © 2012 – 2013 [Jaime Vives Piqueres](http://ignorancia.org/)
