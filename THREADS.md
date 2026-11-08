
scripts/bullet-threads.sh
qmake CONFIG+=bundled_bullet
rm -rf release/bpp release/bpp.gch
make -j8
