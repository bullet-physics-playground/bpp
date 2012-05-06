# bullet-physics-playground

![physics-00.png](https://github.com/koppi/bullet-physics-playground/raw/master/physics-00.png)

Features:

* LUA scripting (experimental)
* POV-Ray export (stable)
* Midi Event handling (experimental)

Demo videos created with bullet-physics-playground:

* [bullet-physics-playground](http://www.youtube.com/watch?v=19OirI8yjLc) - basic LUA scripting demo
* [povray fun](http://www.youtube.com/watch?v=3DLevGGYDAQ)
* [dancing servos](http://www.youtube.com/watch?v=YBQGqMRh3c8)
* [domino dynamics - II](http://www.youtube.com/watch?v=0QQYXvnrU1U)
* [domino dynamics - I](http://www.youtube.com/watch?v=3Q0V185vVnE)
* [4800 cubes - HD](http://www.youtube.com/watch?v=6r_kCF1TRAk)

## Install from Ubuntu PPA

On Ubuntu, you cann install bullet-physics-playground from a PPA:

```
$ sudo apt-addrepository -y ppa:...
$ sudo apt-get update
$ sudo apt-get -y install bullet-physics-playground
```

## Install from source

### install qglviewer, glut, 3ds, lua5.1 and luabind libs and header packages

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
$ sudo apt-get -y install automake libtool cmake freeglut3-dev
```

```
$ svn checkout http://bullet.googlecode.com/svn/trunk/ bullet-read-only
$ cd bullet-read-only/ && sh autogen.sh
$ ./configure --prefix=/usr && make -j 10 && sudo make install
```

MacOS & Windows: see INSTALL in bullet src directory

### build & install spacenav for 3Dconnexion's 3D input device drivers

Space Navigator support is optional:

On Ubuntu 11.10 install libspacenav as follows:

```
$ sudo apt-get -y install libspnav-dev
```

On Ubuntu 9.04 & Ubuntu 11.04 install libspacenav as follows:

```
$ svn co https://spacenav.svn.sourceforge.net/svnroot/spacenav/trunk spacenav
$ cd spacenav/libspnav && ./configure --prefix=/usr 
$ make -j4 && sudo make install
```

```
$ cd ../spnavcfg && ./configure --prefix=/usr && make -j4 && sudo make install
$ cd ../spacenavd && ./configure --prefix=/usr && make -j4 && sudo make install
```

```
$ cd .. && sudo cp spacenavd/doc/example-spnavrc /etc/spnavrc
```

```
$ sudo vi /etc/spnavrc
```

and change the settings as appropriate.

```
$ cd spacenavd && sudo ./setup_init && cd ..
```

```
$ sudo vi /etc/init.d/spacenavd
```

and change path from "/usr/local/bin" to "/usr/bin".

```
$ sudo /etc/init.d/spacenavd start
```

## Build and run physics

```
$ qmake-qt4
$ make -j 10
$ ./physics 
```

physics options:

* -p generate POV-Ray output
* -s save screenshots

# Authors / Copyright

* &copyright; 2008-2012 Jakob Flierl https://github.com/koppi
