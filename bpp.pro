TARGET   = bpp

TEMPLATE = app

CONFIG += c++11

#DEFINES     += HAS_QEXTSERIAL
#DEFINES     += HAS_LUA_QT
#DEFINES     += HAS_LUA_GL

DEFINES     += HAS_LIB_ASSIMP

win32 {

  CONFIG += link_koppi_style_win32

  include(win32.pri)

  RESOURCES   += res.qrc humanity.qrc

  RC_FILE      = bpp.rc

} else {

  CONFIG      += link_pkgconfig

  bpp-binary.path = /usr/bin
  bpp-binary.files = bpp
  bpp-deskop.path = /usr/share/applications
  bpp-deskop.files = bpp.desktop
  bpp-icons.path = /usr/share/icons/hicolor/scalable/apps
  bpp-icons.files = icons/bpp.svg
  bpp-man.path = /usr/share/man/man1
  bpp-man.files = bpp.1
  bpp-man.depends = $(SOURCES)
  bpp-man.commands = help2man --no-discard-stderr -N -n \"Bullet Physics Playground\" -o bpp.1 ./bpp

  INSTALLS    += bpp-binary bpp-deskop bpp-icons bpp-man

  RESOURCES   += res.qrc humanity.qrc

  QMAKE_EXTRA_TARGETS += bpp-man
}

mac {
  CONFIG      += x86 ppc
  ICON         = icons/bpp.icns
}

win32 {
  DEFINES += BUILDTIME=\\\"HH:MM\\\"
  DEFINES += BUILDDATE=\\\"Y-m-d\\\"
} else {
  DEFINES += BUILDTIME=\\\"$$system(date '+%H:%M')\\\"
  DEFINES += BUILDDATE=\\\"$$system(date '+%Y-%m-%d')\\\"
}

QMAKE_CXXFLAGS_RELEASE += -O2
QMAKE_CXXFLAGS_DEBUG   += -O0

MOC_DIR = .moc
#OBJECTS_DIR = .obj
UI_DIR = .ui
RCC_DIR = .rcc

INCLUDEPATH += /usr/include/bullet
INCLUDEPATH += /usr/local/include/bullet

link_pkgconfig {
#  message("Using pkg-config "$$system(pkg-config --version)".")

  LSB_RELEASE_ID  = $$system(lsb_release -is)
  LSB_RELEASE_REL = $$system(lsb_release -rs)

  message(This is $$LSB_RELEASE_ID $$LSB_RELEASE_REL)

  contains(LSB_RELEASE_ID, Ubuntu): {
    contains(LSB_RELEASE_REL, 14.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG += luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer -lGLEW -lGLU -lGL -lglut
    }
    contains(LSB_RELEASE_REL, 16.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer -lGLEW -lGLU -lGL -lglut /usr/lib/libluabind.a
      DEFINES += HAVE_btHingeAccumulatedAngleConstraint
    }
    contains(LSB_RELEASE_REL, 18.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut /usr/lib/libluabind.a
      DEFINES += HAVE_btHingeAccumulatedAngleConstraint
    }
    contains(LSB_RELEASE_REL, 19.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut /usr/lib/libluabind.a
      DEFINES += HAVE_btHingeAccumulatedAngleConstraint
    }
    contains(LSB_RELEASE_REL, 20.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += HAVE_btHingeAccumulatedAngleConstraint
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 21.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += HAVE_btHingeAccumulatedAngleConstraint
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }  }
  contains(LSB_RELEASE_ID, Debian): {
    PKGCONFIG += bullet lua5.2 luabind sdl2
    LIBS += -lQGLViewer -lGLEW -lGLU -lGL -lglut
  }

  contains(DEFINES, HAS_LIB_ASSIMP) {
    PKGCONFIG += assimp
  }
}

contains(DEFINES, HAS_QEXTSERIAL) {
  INCLUDEPATH += lib/qextserial
  DEPENDPATH  += lib/qextserial

  HEADERS     += qextserialport_global.h \
                 qextserialport.h \
                 qextserialenumerator.h

  contains(DEFINES, HAS_LUA_QT) {
    HEADERS   += src/wrapper/qserial.h \
                 src/wrapper/lua_serial.h
  }

  SOURCES     += qextserialport.cpp

  contains(DEFINES, HAS_LUA_QT) {
    SOURCES   += src/wrapper/qserial.cpp \
                 src/wrapper/lua_serial.cpp
  }

  unix:SOURCES       += posix_qextserialport.cpp
  unix:!macx:SOURCES += qextserialenumerator_unix.cpp

  macx {
    SOURCES   += qextserialenumerator_osx.cpp
    LIBS      += -framework IOKit -framework CoreFoundation
  }

  win32 {
    SOURCES   += win_qextserialport.cpp qextserialenumerator_win.cpp
    DEFINES   += UNICODE
    DEFINES   += WINVER=0x0501 # needed for mingw
    LIBS      += -lsetupapi -ladvapi32 -luser32
  }

  unix:DEFINES   += _TTY_LINUX_ _TTY_NOWARN_
  win32:DEFINES  += _TTY_WIN_ _TTY_NOWARN_
}

CONFIG  *= debug_and_release
CONFIG  *= qt opengl
CONFIG  += warn_on
CONFIG  += thread

QT      *= opengl xml network gui core

INCLUDEPATH += src/wrapper
DEPENDPATH  += src/wrapper

contains(DEFINES, HAS_LUA_QT) {

# Lua wrapper classes

HEADERS += \
  lua_network.h \
  lua_util.h \
  lua_register.h \
  lua_qslot.h \
  lua_qtypes.h \
  lua_qt.h \
  lua_qaction.h \
  lua_qbutton.h \
  lua_qlayout.h \
  lua_qlist.h \
  lua_qmainwindow.h \
  lua_qobject.h \
  lua_qrect.h \
  lua_qtextedit.h \
  lua_qdialog.h \
  lua_qtabwidget.h \
  lua_qevent.h \
  lua_qspin.h \
  lua_qpainter.h \
  lua_qprocess.h \
  lua_qslider.h \
  lua_qurl.h \
  lua_qfile.h \
  lua_qftp.h

SOURCES += \
  lua_network.cpp \
  lua_qaction.cpp \
  lua_qbutton.cpp \
  lua_qlayout.cpp \
  lua_qlist.cpp \
  lua_qmainwindow.cpp \
  lua_qobject.cpp \
  lua_qrect.cpp \
  lua_qtextedit.cpp \
  lua_qdialog.cpp \
  lua_qtabwidget.cpp \
  lua_qevent.cpp \
  lua_qspin.cpp \
  lua_qpainter.cpp \
  lua_qprocess.cpp \
  lua_qslider.cpp \
  lua_qurl.cpp \
  lua_qfile.cpp \
  lua_qftp.cpp \
  lua_util.cpp \
  lua_register.cpp \
  lua_qslot.cpp
}

contains(DEFINES, HAS_LUA_GL) {
  INCLUDEPATH += lib/luagl/include
  DEPENDPATH  += lib/luagl/src

  SOURCES *= luagl_util.c \
             luagl.c \
             luaglu.c \
             luagl_const.c

  HEADERS *=

  HEADERS += lua_qglviewer.h
  SOURCES += lua_qglviewer.cpp
}

# Main BPP source files

INCLUDEPATH += src
DEPENDPATH  += src

SOURCES += src/main.cpp \
           src/viewer.cpp \
           src/objects/object.cpp \
           src/objects/objects.cpp \
           src/objects/palette.cpp \
           src/objects/cube.cpp \
           src/objects/sphere.cpp \
           src/objects/plane.cpp \
           src/objects/cylinder.cpp \
           src/objects/mesh.cpp \
           src/objects/cam.cpp \
           src/wrapper/lua_bullet.cpp \
           src/gui.cpp \
           src/cmd.cpp \
           src/code.cpp \
           src/high.cpp \
           src/prefs.cpp \
           src/objects/openscad.cpp \
    src/joystick/joystickhandler.cpp \
    src/joystick/joystickinfo.cpp \
    src/joystick/joystickinterface.cpp \
    src/joystick/joystickinterfacesdl.cpp

HEADERS += src/viewer.h \
           src/objects/object.h \
           src/objects/palette.h \
           src/objects/objects.h \
           src/objects/cube.h \
           src/objects/sphere.h \
           src/objects/plane.h \
           src/objects/cylinder.h \
           src/objects/mesh.h \
           src/objects/cam.h \
           src/wrapper/lua_bullet.h \
           src/wrapper/lua_converters.h \
           src/gui.h \
           src/cmd.h \
           src/code.h \
           src/high.h \
           src/prefs.h \
           src/objects/openscad.h \
    src/joystick/joystickballvector.h \
    src/joystick/joystickconstants.h \
    src/joystick/joystickhandler.h \
    src/joystick/joystickinfo.h \
    src/joystick/joystickinterface.h \
    src/joystick/joystickinterfacesdl.h

FORMS   += src/gui.ui \
           src/prefs.ui

ICON    = icons/bpp.svg

OTHER_FILES += README.md \
               icons/bpp.svg \
               icons/bpp.png \
               icons/bpp.hqx \
               icons/bpp.icns \
               icons/bpp.ico \
               bpp.nsi \
               License \
               debian/changelog

DIRS_DC = object_script.* .ui .moc .rcc .obj *.pro.user $$TARGET

unix:QMAKE_DISTCLEAN  += -r $$DIRS_DC
win32:QMAKE_DISTCLEAN += /s /f /q $$DIRS_DC && rd /s /q $$DIRS_DC
