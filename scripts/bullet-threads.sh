#!/bin/bash
# Bullet 3.24 built with threads, for bpp's optional threaded build (November 2026).
#
# The system Bullet (Ubuntu's libbullet 3.24, Homebrew's, MSYS2's) is built without threads, so v:setThreads can't
# use more than one core with it. This fetches Bullet 3.24 (the same version) and builds it with threads, as static
# libraries, into lib/ (which git ignores); then build bpp against it:
#
#   scripts/bullet-threads.sh
#   mkdir -p ../build-mt && cd ../build-mt
#   qmake CONFIG+=bundled_bullet ../bpp/bpp.pro && make -j8
#
# Everything else -- the default build, the packages -- still uses the system Bullet. Built as Ubuntu builds its
# own (RelWithDebInfo, single precision), so with no threads asked for it runs as the system Bullet does.
# Bullet's own thread pool (BULLET2_MULTITHREADING alone: no OpenMP or TBB needed). Needs git, cmake and a C++
# compiler. Tried on Linux only.
set -e
cd "$(dirname "$0")/.."
TAG=3.24
COMMIT=7dee3436e747958e7088dfdcea0e4ae031ce619e   # (Bullet's tag 3.24)
SRC=lib/bullet3
OUT=$PWD/lib/bullet-mt
[ -d "$SRC/.git" ] || git -c advice.detachedHead=false clone --depth 1 --branch "$TAG" https://github.com/bulletphysics/bullet3.git "$SRC"
[ "$(git -C "$SRC" rev-parse HEAD)" = "$COMMIT" ] || { echo "$SRC is not Bullet $TAG; remove it and run this again"; exit 1; }
cmake -S "$SRC" -B "$SRC/build-mt" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DUSE_DOUBLE_PRECISION=OFF -DBULLET2_MULTITHREADING=ON \
  -DBUILD_EXTRAS=OFF -DBUILD_BULLET2_DEMOS=OFF -DBUILD_OPENGL3_DEMOS=OFF -DBUILD_CPU_DEMOS=OFF \
  -DBUILD_UNIT_TESTS=OFF -DBUILD_PYBULLET=OFF -DINSTALL_LIBS=ON -DCMAKE_INSTALL_PREFIX="$OUT" > /dev/null
cmake --build "$SRC/build-mt" -j"$( (nproc || sysctl -n hw.ncpu) 2> /dev/null || echo 2)" --target install > /dev/null
echo "Bullet $TAG with threads is in $OUT; now: qmake CONFIG+=bundled_bullet"
