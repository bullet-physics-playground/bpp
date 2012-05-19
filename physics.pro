CONFIG += debug

## windows: you need:
##
## * VC 2008 SP1: Fix for vector <function <FT>> crash.
##   http://www.microsoft.com/en-us/download/details.aspx?id=15303
## * ..
##

win32 {
  DEFINES += BUILDTIME=\\\"$$system('echo %time%')\\\"
  DEFINES += BUILDDATE=\\\"$$system('echo %date%')\\\"
} else {
  DEFINES += BUILDTIME=\\\"$$system(date '+%H:%M')\\\"
  DEFINES += BUILDDATE=\\\"$$system(date '+%Y-%m-%d')\\\"
}

TEMPLATE = app
TARGET = physics
DEPENDPATH += .
INCLUDEPATH += .
INCLUDEPATH += /usr/include/bullet
INCLUDEPATH += roboop/include
INCLUDEPATH += roboop/newmat
INCLUDEPATH += roboop/source

MOC_DIR = .moc
OBJECTS_DIR = .obj
UI_DIR = .ui

win32 {
  DEFINES += -DWIN32
  DEFINES += WIN32
} else {
  CONFIG += link_pkgconfig link_spacenav
  QMAKE_CXXFLAGS_WARN_ON =
  QMAKE_CXXFLAGS_DEBUG += -g3 -O0
}

link_spacenav {
  LIBS += -lspnav
}

## Add linked libs and paths for headers and palettes here using pkg-config.
## If your system doesn't support pkg-config then comment out the next line and
## set these values below.
#CONFIG += link_pkgconfig

link_pkgconfig {
  message("Config using pkg-config version "$$system(pkg-config --version))
  PKGCONFIG += bullet alsa lua5.1 luabind

  LIBS += -lqglviewer-qt4 -lglut -lGL -l3ds -lroboop -lnewmat -Lroboop
} else {
  message("Config not using pkg-config")

  LUA_SRC_DIR = C:\\Lua\\5.1
  INCLUDEPATH += $$LUA_SRC_DIR\\include
  LIBS += -L$$LUA_SRC_DIR\\lib -llua

  LUABIND_SRC_DIR = C:\\libs\\luabind-0.9.1
  INCLUDEPATH += $$LUABIND_SRC_DIR $$LUABIN_SRC_DIR\\include
  LIBS += -L$$LUABIND_SRC_DIR -lluabind

  QGL_SRC_DIR = C:\\libs\\libQGLViewer-2.3.11
  INCLUDEPATH += $$QGL_SRC_DIR
  LIBS += -lqglviewer2

  BUL_SRC_DIR = C:\\libs\\bullet-2.79\\src
  INCLUDEPATH += $$BUL_SRC_DIR

  BOOST_SRC_DIR = C:\\libs\\boost_1_47
  INCLUDEPATH += $$BOOST_SRC_DIR
  LIBS += -L$$BOOST_SRC_DIR\\lib

## http://www.idfun.de/glut64/
  GLUT_SRC_DIR = C:\\libs\\glut-3.7.6-bin
  INCLUDEPATH += $$GLUT_SRC_DIR
  LIBS += -L$$GLUT_SRC_DIR

##  lib3ds-20080909.zip from http://code.google.com/p/lib3ds/
  L3DS_SRC_DIR = C:\\libs\\lib3ds-20080909
  INCLUDEPATH += C:\libs\dll\include

## The following directory contains dlls for QGLViewer, lua.
  LIBS += -LC:\\libs\\dll
}

QT += xml opengl

unix:!mac {
    DEFINES += __LINUX_ALSASEQ__
}

SOURCES += main.cpp palette.cpp viewer.cpp object.cpp cube.cpp sphere.cpp \
           plane.cpp cylinder.cpp mesh3ds.cpp rm.cpp collisionfilter.cpp rm1.cpp \
           cubeaxes.cpp gui.cpp commandline.cpp dice.cpp spacenavigator.cpp spacenavigatorevent.cpp \
           SpaceNavigatorCam.cpp MidiIO.cpp MidiEvent.cpp RtMidi.cpp \
           codeeditor.cpp highlighter.cpp objects.cpp

HEADERS += palette.h viewer.h   object.h   cube.h   sphere.h   \
           plane.h   cylinder.h   mesh3ds.h   rm.h   collisionfilter.h     rm1.h \
           cubeaxes.h   gui.h commandline.h dice.h spacenavigator.h spacenavigatorevent.cpp \
           SpaceNavigatorCam.h MidiIO.h MidiEvent.h RtMidi.h \
           codeeditor.h highlighter.h objects.h

FORMS   += gui.ui

RESOURCES += resources.qrc

QMAKE_DISTCLEAN += object_script.* .ui .moc .rcc .obj
