TEMPLATE = app
CONFIG += console c++11 warn_off
CONFIG -= app_bundle
QT += core gui
TARGET = tworenders

DEFINES += _CONSOLE OPENEXR_MISSING BUILDING_AMD64
DEFINES += BUILT_BY=\\\"bpp-povvfe-prototype\\\"
DEFINES -= UNICODE _UNICODE

POVRAY = $$PWD/../../../povray
BPP = $$PWD/../../src

INCLUDEPATH += \
    $$POVRAY/source \
    $$POVRAY/vfe \
    $$POVRAY/vfe/win \
    $$POVRAY/platform/windows \
    $$POVRAY/platform \
    $$POVRAY/windows/povconfig \
    $$BPP/povray

CONFIG += link_pkgconfig
PKGCONFIG += zlib libpng libjpeg libtiff-4

QMAKE_CXXFLAGS += -std=gnu++11 -g -O0
QMAKE_LFLAGS_RELEASE -= -Wl,-s

SOURCES += \
    main.cpp \
    $$BPP/povray/bppvfesession.cpp \
    $$BPP/povray/bppvfedisplay.cpp
HEADERS += \
    $$BPP/povray/bppvfesession.h \
    $$BPP/povray/bppvfedisplay.h

LIBS += -L$$PWD/../release -L$$PWD/../debug -lpovvfe
PRE_TARGETDEPS += $$PWD/../release/libpovvfe.a
