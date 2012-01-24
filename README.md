# bullet-physics-playground

## INSTALL

### install qglviewer library and headers

```
 $ sudo apt-get install libqglviewer-qt4-dev
```

### install glut library and headers

```
 $ sudo apt-get install freeglut3-dev
```

### install 3ds library and headers

On Ubuntu 10.04:

```
 $ sudo apt-get -y install lib3ds-dev
```

On Ubuntu 9.04 & Ubuntu 11.04 & Ubuntu 11.10:

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

Linux:

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

Windows:

 TODO

## build physics

```
 $ qmake-qt4
 $ make -j 10
```


## run physics

```
 $ ./physics
```

Options:

 -p generate POV-Ray output
 -s save screenshots

# contact

* Jakob Flierl https://github.com/koppi
