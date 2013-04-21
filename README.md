# bullet-physics-playground

<a href="http://www.youtube.com/watch?feature=player_embedded&v=19OirI8yjLc&hd=1
" target="_blank"><img
src="http://img.youtube.com/vi/19OirI8yjLc/0.jpg"
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

* [00-objects.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/00-objects.lua) - basic objects
* [01-test.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/01-test.lua) - LUA syntax testing
* [02-domino.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/02-domino.lua) - function definition and loop
* [03-math.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/03-math.lua) - math functions
* [04-anim.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/04-anim.lua) - callback functions
* [05-mesh-chain.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/05-mesh-chain.lua) - Mesh3DS usage, transformations
* [06-mesh-chain-2.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/06-mesh-chain-2.lua) - Mesh3DS usage, transformations
* [07-coins-piles.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/07-coins-piles.lua) - POV-Ray export customisation
* [08-oranges-box.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/08-oranges-box.lua) - General usage demo
* [09-blocks-tower.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/09-blocks-tower.lua) - General usage demo
* [10-coins-3ds-box.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/10-coins-3ds-box.lua) - Usage of postSim() to add objects during simulation
* [11-car-hinge-slider.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/11-car-hinge-slider.lua) - Illustrates usage of hinge and slider constraints
* [12-collar-p2p.lua](https://github.com/koppi/bullet-physics-playground/blob/master/demo/12-collar-p2p.lua) - Illustrates usage of point-to-point constraints

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
