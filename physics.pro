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

CONFIG += link_pkgconfig debug
PKGCONFIG += bullet alsa
QMAKE_CXXFLAGS_WARN_ON =

QT += xml opengl

unix:!mac {
    DEFINES += __LINUX_ALSASEQ__
}

LIBS += -lspnav -lqglviewer-qt4 -lglut -lGL -l3ds -lroboop -lnewmat -Lroboop

SOURCES += main.cpp palette.cpp viewer.cpp object.cpp cube.cpp sphere.cpp \
           plane.cpp cylinder.cpp mesh3ds.cpp rm.cpp collisionfilter.cpp rm1.cpp \
           cubeaxes.cpp gui.cpp cmdline.cpp dice.cpp spacenavigator.cpp spacenavigatorevent.cpp \
           SpaceNavigatorCam.cpp MidiIO.cpp MidiEvent.cpp RtMidi.cpp
HEADERS += palette.h viewer.h   object.h   cube.h   sphere.h   \
           plane.h   cylinder.h   mesh3ds.h   rm.h   collisionfilter.h     rm1.h \
           cubeaxes.h   gui.h cmdline.h dice.h spacenavigator.h spacenavigatorevent.cpp \
           SpaceNavigatorCam.h MidiIO.h MidiEvent.h RtMidi.h

FORMS   += gui.ui

QMAKE_DISTCLEAN += object_script.* .ui .moc .rcc .obj
