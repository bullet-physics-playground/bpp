QMAKE_CXXFLAGS_DEBUG += -g3 -O0
CONFIG += debug

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
INCLUDEPATH += roboop/include
INCLUDEPATH += roboop/newmat
INCLUDEPATH += roboop/source

MOC_DIR = .moc
OBJECTS_DIR = .obj
UI_DIR = .ui

CONFIG += link_pkgconfig
PKGCONFIG += bullet alsa lua5.1 luabind
QMAKE_CXXFLAGS_WARN_ON =

QT += xml opengl

unix:!mac {
    DEFINES += __LINUX_ALSASEQ__
}

LIBS += -lspnav -lqglviewer-qt4 -lglut -lGL -l3ds -lroboop -lnewmat -Lroboop

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
