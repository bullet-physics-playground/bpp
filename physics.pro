TARGET   = physics

TEMPLATE = app

DEFINES     += HAS_QEXTSERIAL
DEFINES     += HAS_LUA_QT
DEFINES     += HAS_LUA_GL

win32 {

  CONFIG += link_koppi_style_win32

  include(win32.pri)

  RESOURCES   += res.qrc humanity.qrc

} else {

  CONFIG      += link_pkgconfig

  physics-binary.path = /usr/bin
  physics-binary.files = physics
  physics-deskop.path = /usr/share/applications
  physics-deskop.files = physics.desktop
  physics-icons.path = /usr/share/icons/hicolor/scalable/apps
  physics-icons.files = icons/physics.svg

  INSTALLS    += physics-binary physics-deskop physics-icons

  RESOURCES   += res.qrc

}

mac {
  CONFIG      += x86 ppc
  ICON         = icons/physics.icns
}

win32 {
  DEFINES += BUILDTIME=\\\"$$system('echo %time%')\\\"
  DEFINES += BUILDDATE=\\\"$$system('echo %date%')\\\"
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
  message("Using pkg-config "$$system(pkg-config --version)".")
  PKGCONFIG += bullet lua5.1 luabind

  LIBS += -lqglviewer-qt4 -lGLEW -lGLU -lGL -lglut -l3ds

  # If you se the latest QGLViewer sources from www.libqglviewer.com
  # use the followings LIBS instead:

  #LIBS += -lQGLViewer -lGLEW -lglut -lGL -l3ds

  # and on ubuntu 12.04 use -lGLU instead -lGL:

  #LIBS += -lQGLViewer -lGLEW -lglut -lGLU -l3ds
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

QT     *= opengl xml network gui core

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

  HEADERS *= lib/luagl/include/luagl.h \
             lib/luagl/include/luaglu.h

  HEADERS += lua_qglviewer.h
  SOURCES += lua_qglviewer.cpp
}

# Main BPP source files

INCLUDEPATH += src
DEPENDPATH  += src

SOURCES += main.cpp \
           viewer.cpp \
           objects/object.cpp \
           objects/objects.cpp \
           objects/palette.cpp \
           objects/cube.cpp \
           objects/sphere.cpp \
           objects/plane.cpp \
           objects/cylinder.cpp \
           objects/mesh3ds.cpp \
           objects/cam.cpp \
           gui.cpp \
           cmd.cpp \
           code.cpp \
           high.cpp \
           prefs.cpp \
    src/wrapper/lua_bullet.cpp

HEADERS += viewer.h \
           objects/object.h \
           objects/palette.h \
           objects/objects.h \
           objects/cube.h \
           objects/sphere.h \
           objects/plane.h \
           objects/cylinder.h \
           objects/mesh3ds.h \
           objects/cam.h \
           src/wrapper/lua_converters.h \
           gui.h \
           cmd.h \
           code.h \
           high.h \
           prefs.h \
    src/wrapper/lua_bullet.h

FORMS   += gui.ui \
           prefs.ui

ICON    = icons/physics.svg

OTHER_FILES += README.md \
               icons/physics.svg \
               icons/physics.png \
               icons/physics.hqx \
               icons/physics.icns \
               icons/physics.ico

DIRS_DC = object_script.* .ui .moc .rcc .obj *.pro.user $$TARGET

unix:QMAKE_DISTCLEAN  += -r $$DIRS_DC
win32:QMAKE_DISTCLEAN += /s /f /q $$DIRS_DC && rd /s /q $$DIRS_DC
