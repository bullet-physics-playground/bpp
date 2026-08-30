TARGET   = bpp

TEMPLATE = app

CONFIG  += c++11

PRECOMPILED_HEADER = src/pch.h

CONFIG  *= qt opengl warn_on shared thread debug_and_release
QT      *= opengl xml gui core

DEFINES += HAS_LIB_ASSIMP
DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
DEFINES += LUABIND_USE_CXX11
DEFINES += GLUT_DISABLE_ATEXIT_HACK

# POV-Ray VFE embedding: in-process F6 quick-render via POV-Ray's VFE API
# (see povray-mingw/ and src/povray/) instead of shelling out to a separate
# povray/pvengine process. Off by default -- enabling it requires a sibling
# povray/ source checkout and a prebuilt povray-mingw/povvfe static lib.
# Enable with `qmake "USE_VFE=1"`, or just change the 0 below.
isEmpty(USE_VFE): USE_VFE = 0
DEFINES += USE_VFE=$$USE_VFE

# QMAKE_CXXFLAGS += -Wno-attributes -Wno-deprecated -Wno-deprecated-copy -Wno-deprecated-declarations -Wno-reorder -Wno-parentheses -Wno-ignored-qualifiers -Wno-unused-local-typedefs -Wno-terminate
QMAKE_CXXFLAGS += -Wno-deprecated-copy
QMAKE_CXXFLAGS_RELEASE += -O3
QMAKE_CXXFLAGS_DEBUG   += -O0
QMAKE_CXXFLAGS_DEBUG   += -fno-sanitize=alignment

CONFIG(debug, debug|release) {
    DESTDIR = debug
}
CONFIG(release, debug|release) {
    DESTDIR = release
}

OBJECTS_DIR = $$DESTDIR/.obj
MOC_DIR = $$DESTDIR/.moc
RCC_DIR = $$DESTDIR/.qrc
UI_DIR = $$DESTDIR/.u

win32 {

  message(This is win32)

  CONFIG += build_with_msys2
  include(msys2.pri)

  RESOURCES   += res.qrc humanity.qrc

  RC_FILE      = bpp.rc

}

linux {

  CONFIG      += link_pkgconfig

  bpp-binary.path  = /usr/bin
  bpp-binary.files = release/bpp
  bpp-deskop.path  = /usr/share/applications
  bpp-deskop.files = bpp.desktop
  bpp-icons.path   = /usr/share/icons/hicolor/scalable/apps
  bpp-icons.files  = icons/bpp.svg
  bpp-man.path     = /usr/share/man/man1
  bpp-man.files    = bpp.1
  bpp-man.depends  = $(SOURCES)
  bpp-man.commands = help2man --no-discard-stderr -N -n \"Bullet Physics Playground\" -o bpp.1 release/bpp

  INSTALLS    += bpp-binary bpp-deskop bpp-icons bpp-man

  RESOURCES   += res.qrc humanity.qrc

  QMAKE_EXTRA_TARGETS += bpp-man

  gdb.depends  = debug
  gdb.commands = gdb -quiet -x gdb_commands.txt debug/bpp
  QMAKE_EXTRA_TARGETS += gdb

  export.commands = make -C export
  QMAKE_EXTRA_TARGETS += export

  tests.depends  = debug
  tests.commands = make -C tests debug
  tests.CONFIG   = phony
  QMAKE_EXTRA_TARGETS += tests

  # POV-Ray VFE embedding on Linux -- see povray-linux/README.md.
  # Linux twin of msys2.pri's WIN32_LINK_POVVFE block.
  equals(USE_VFE, 1) {
    LINUX_DIR_POVRAY = $$PWD/../povray

    INCLUDEPATH += \
      $$LINUX_DIR_POVRAY/source \
      $$LINUX_DIR_POVRAY/vfe \
      $$LINUX_DIR_POVRAY/vfe/unix \
      $$LINUX_DIR_POVRAY/platform/unix \
      $$LINUX_DIR_POVRAY/platform \
      $$LINUX_DIR_POVRAY/unix \
      $$LINUX_DIR_POVRAY/unix/povconfig

    DEFINES += HAVE_CONFIG_H
    DEFINES += BUILT_BY=\\\"bpp-povvfe-prototype\\\"

    LIBS += -L$$PWD/povray-linux/release -L$$PWD/povray-linux/debug -lpovvfe -lpthread
    PKGCONFIG += zlib libpng libjpeg libtiff-4
  }
}

mac {
  ICON         = icons/bpp.icns

  RESOURCES   += res.qrc humanity.qrc

  # Resolve Homebrew paths dynamically instead of hardcoding one
  # machine's Cellar version snapshot -- keeps this working across
  # Homebrew upgrades and across Intel (/usr/local) vs Apple Silicon
  # (/opt/homebrew) installs. qt@5 and lua are keg-only formulas (kept
  # out of the general prefix since other versions may coexist), so
  # look those up by name; libQGLViewer installs alongside whichever
  # Qt it was built against.
  BREW_PREFIX  = $$system(brew --prefix)
  QT5_PREFIX   = $$system(brew --prefix qt@5)
  LUA_PREFIX   = $$system(brew --prefix lua)
  LUA_INCLUDE  = $$system(ls -d $$LUA_PREFIX/include/lua5.* 2>/dev/null | head -1)

  INCLUDEPATH += $$BREW_PREFIX/include
  INCLUDEPATH += $$BREW_PREFIX/include/bullet
  INCLUDEPATH += $$BREW_PREFIX/include/QGLViewer
  INCLUDEPATH += $$QT5_PREFIX/include/QGLViewer
  INCLUDEPATH += $$LUA_INCLUDE

  LIBS += -F$$BREW_PREFIX/lib
  LIBS += -F$$QT5_PREFIX/lib
  LIBS += -L$$BREW_PREFIX/lib
  LIBS += -L$$QT5_PREFIX/lib
  LIBS += -L$$LUA_PREFIX/lib
  LIBS += -lluabind
  LIBS += -llua
  LIBS += -lSDL2
  LIBS += -lBulletDynamics
  LIBS += -lBulletCollision
  LIBS += -lLinearMath
  LIBS += -lassimp
  LIBS += -framework QGLViewer

  export.commands = make -C export
  QMAKE_EXTRA_TARGETS += export

  tests.depends  = debug
  tests.commands = make -C tests debug
  tests.CONFIG   = phony
  QMAKE_EXTRA_TARGETS += tests

  QMAKE_POST_LINK = $$PWD/scripts/deploy-mac.sh $$DESTDIR/$${TARGET}.app
}

win32 {
  DEFINES += BUILDTIME=\\\"$$system('echo %time%')\\\"
  DEFINES += BUILDDATE=\\\"$$system('powershell -NoProfile -Command Get-Date -Format yyyy-MM-dd')\\\"
  DEFINES += BULLET_VERSION=\\\"\\\"
} else {
  DEFINES += BUILDTIME=\\\"$$system(date '+%H:%M')\\\"
  DEFINES += BUILDDATE=\\\"$$system(date '+%Y-%m-%d')\\\"
  DEFINES += BULLET_VERSION=\\\"$$system(pkg-config bullet --modversion)\\\"
}

linux:link_pkgconfig {
#  message("Using pkg-config "$$system(pkg-config --version)".")

  LSB_RELEASE_ID  = $$system(. /etc/os-release; echo "$NAME")
  LSB_RELEASE_REL = $$system(. /etc/os-release; echo "$VERSION_ID")

  message(This is $$LSB_RELEASE_ID $$LSB_RELEASE_REL)

  contains(LSB_RELEASE_ID, Ubuntu): {
    contains(LSB_RELEASE_REL, 21.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 21.10) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 22.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 22.10) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 23.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 23.10) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 24.04) : {
      PKGCONFIG += lua5.1
      PKGCONFIG -= luabind 
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 25.04) : {
      PKGCONFIG += lua5.1
      PKGCONFIG -= luabind 
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 25.10) : {
      PKGCONFIG += lua5.1
      PKGCONFIG -= luabind 
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 26.04) : {
      PKGCONFIG += lua5.1
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
  }

  contains(LSB_RELEASE_ID, Debian): {
     contains(LSB_RELEASE_REL, 11) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 12) : {
     PKGCONFIG += lua5.2
     PKGCONFIG -= luabind
     PKGCONFIG += bullet
     PKGCONFIG += sdl2
     LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
     DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 13) : {
     PKGCONFIG += lua5.1
     PKGCONFIG -= luabind
     PKGCONFIG += bullet
     PKGCONFIG += sdl2
     LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
     DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
  }
  contains(LSB_RELEASE_ID, Raspbian): {
    contains(LSB_RELEASE_REL, 12) : {
     PKGCONFIG += lua5.1
     PKGCONFIG -= luabind
     PKGCONFIG += bullet
     PKGCONFIG += sdl2
     LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
     DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 13) : {
     PKGCONFIG += lua5.1
     PKGCONFIG -= luabind
     PKGCONFIG += bullet
     PKGCONFIG += sdl2
     LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
     DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
  }
  contains(LSB_RELEASE_ID, Mint): {
    PKGCONFIG += lua5.2
    PKGCONFIG -= luabind
    PKGCONFIG += bullet
    PKGCONFIG += sdl2
    LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lGL -lluabind
    DEFINES += HAVE_btHingeAccumulatedAngleConstraint
    DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
  }
  contains(LSB_RELEASE_ID, FreeBSD): {
    PKGCONFIG += bullet lua-5.1 sdl2
    LIBS += -lluabind -lQGLViewer -lGLEW -lGLU -lGL -lGL
  }

  contains(DEFINES, HAS_LIB_ASSIMP) {
    PKGCONFIG += assimp
  }

  # Bullet's own headers trigger -Wunused-parameter and similar warnings
  # under -Wall -Wextra. Re-adding its include dir via -isystem (on top of
  # the -I already added by PKGCONFIG) marks it as a system header
  # directory, so the compiler suppresses warnings from those headers.
  BULLET_INCDIR = $$system(pkg-config --cflags-only-I bullet)
  QMAKE_CXXFLAGS += $$replace(BULLET_INCDIR, -I, -isystem )
}

SOURCES     += $$files("src/*.cpp", true)
HEADERS     += $$files("src/*.h", true)
FORMS       += $$files("src/*.ui", true)

INCLUDEPATH += src
DEPENDPATH  += src
           
ICON         = icons/bpp.svg

OTHER_FILES += README.md LICENSE

OTHER_FILES += $$files("icons/*.*", true)
OTHER_FILES += $$files("demo/*.*", true)
OTHER_FILES += $$files("includes/*.*", true)
OTHER_FILES += $$files("export/*.*", true)

win32:DISTFILES += msys2.pri
win32:OTHER_FILES += bpp.nsi

unix:OTHER_FILES += debian/changelog
