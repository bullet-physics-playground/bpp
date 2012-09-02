# bullet-physics-playground

![physics-00.png](https://github.com/koppi/bullet-physics-playground/raw/master/demo/02-domino.png)

Features:

* LUA scripting (experimental)
* OpenGL gui (alpha)
* POV-Ray export (stable)
* Midi Event handling (experimental)

Demo videos created with bullet-physics-playground:

* [bullet-physics-playground](http://www.youtube.com/watch?v=19OirI8yjLc) - basic LUA scripting demo
* [povray fun](http://www.youtube.com/watch?v=3DLevGGYDAQ) - falling dice
* [dancing servos](http://www.youtube.com/watch?v=YBQGqMRh3c8) - compound objects with actuators
* [domino dynamics - II](http://www.youtube.com/watch?v=0QQYXvnrU1U) - dominos
* [domino dynamics - I](http://www.youtube.com/watch?v=3Q0V185vVnE) - dominos
* [4800 cubes - HD](http://www.youtube.com/watch?v=6r_kCF1TRAk) - 1st test

## Install from source

### install libs and header packages

```
$ sudo apt-get -y install libqglviewer-qt4-dev freeglut3-dev lib3ds-dev libluabind-dev liblua5.1-0-dev
```

On Ubuntu 9.04 & Ubuntu 11.04 & Ubuntu 11.10 install lib3ds as follows:

```
$ svn checkout http://lib3ds.googlecode.com/svn/trunk/ lib3ds-read-only
$ cd lib3ds-read-only/ && sh autogen.sh
$ ./configure --prefix=/usr && make -j 10 && sudo make install
```

### build & install bullet library and headers

Linux:

```
$ sudo apt-get -y install automake libtool cmake freeglut3-dev subversion
```

```
$ svn checkout http://bullet.googlecode.com/svn/trunk/ bullet-read-only
$ cd bullet-read-only/ && sh autogen.sh
$ ./configure --prefix=/usr && make -j 10 && sudo make install
```

MacOS & Windows: see INSTALL in bullet src directory.

## Build and run physics

```
$ qmake-qt4
$ make -j 10
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

# Youtube needs more POV-Ray animations

HOWTO render the pov files to 1920x1080 png images and create anim.avi:

```
cd anim; for f in $(ls *.pov); do ./pov2png.sh $f; done; ./png2avi.sh
```

# Authors / Copyright

* © 2008-2012 [Jakob Flierl](https://github.com/koppi) - project start
* © 2012 [Jaime Vives Piqueres](http://ignorancia.org/) - inspiration
