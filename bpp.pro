TARGET   = bpp

TEMPLATE = app

CONFIG += c++11

CONFIG *= qt opengl warn_on shared thread

#DEFINES       += HAS_LUA_GL

DEFINES        += HAS_LIB_ASSIMP
DEFINES        += BOOST_BIND_GLOBAL_PLACEHOLDERS

QMAKE_CXXFLAGS += -Wno-attributes -Wno-deprecated -Wno-deprecated-copy -Wno-deprecated-declarations -Wno-reorder -Wno-parentheses -Wno-ignored-qualifiers -Wno-unused-local-typedefs -Wno-terminate

win32 {

  CONFIG += build_with_msys2
  include(msys2.pri)

#  CONFIG += build_with_mxe
#  include(mxe.pri)

  RESOURCES   += res.qrc humanity.qrc

  RC_FILE      = bpp.rc

} else {

  CONFIG      += link_pkgconfig

  bpp-binary.path = /usr/bin
  bpp-binary.files = release/bpp
  bpp-deskop.path = /usr/share/applications
  bpp-deskop.files = bpp.desktop
  bpp-icons.path = /usr/share/icons/hicolor/scalable/apps
  bpp-icons.files = icons/bpp.svg
  bpp-man.path = /usr/share/man/man1
  bpp-man.files = bpp.1
  bpp-man.depends = $(SOURCES)
  bpp-man.commands = help2man --no-discard-stderr -N -n \"Bullet Physics Playground\" -o bpp.1 release/bpp

  INSTALLS    += bpp-binary bpp-deskop bpp-icons bpp-man

  RESOURCES   += res.qrc humanity.qrc

  QMAKE_EXTRA_TARGETS += bpp-man
}

mac {
  CONFIG      += x86 ppc
  ICON         = icons/bpp.icns
}

win32 {
  DEFINES += BUILDTIME=\\\"$$system('echo %time%')\\\"
  DEFINES += BUILDDATE=\\\"$$system('echo %date%')\\\"
  DEFINES += BULLET_VERSION=\\\"\\\"
} else {
  DEFINES += BUILDTIME=\\\"$$system(date '+%H:%M')\\\"
  DEFINES += BUILDDATE=\\\"$$system(date '+%Y-%m-%d')\\\"
  DEFINES += BULLET_VERSION=\\\"$$system(pkg-config bullet --modversion)\\\"
}

QMAKE_CXXFLAGS_RELEASE += -O3
QMAKE_CXXFLAGS_DEBUG   += -O0

CONFIG(debug, debug|release){
  DESTDIR = ./debug
  OBJECTS_DIR = debug/.obj
  MOC_DIR = debug/.moc
  RCC_DIR = debug/.rcc
  UI_DIR = debug/.ui
}

CONFIG(release, debug|release){
  DESTDIR = ./release
  OBJECTS_DIR = release/.obj
  MOC_DIR = release/.moc
  RCC_DIR = release/.rcc
  UI_DIR = release/.ui
}

INCLUDEPATH += /usr/include/bullet
INCLUDEPATH += /usr/local/include/bullet

unix:link_pkgconfig {
#  message("Using pkg-config "$$system(pkg-config --version)".")

  LSB_RELEASE_ID  = $$system(. /etc/os-release; echo "$NAME")
  LSB_RELEASE_REL = $$system(. /etc/os-release; echo "$VERSION_ID")

  message(This is $$LSB_RELEASE_ID $$LSB_RELEASE_REL)

  contains(LSB_RELEASE_ID, Ubuntu): {
    contains(LSB_RELEASE_REL, 22.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 22.10) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 23.04) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 23.10) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
  }
  contains(LSB_RELEASE_REL, 24.04) : {
      PKGCONFIG += lua5.1
      PKGCONFIG -= luabind 
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }

  contains(LSB_RELEASE_ID, Debian): {
     contains(LSB_RELEASE_REL, 11) : {
      PKGCONFIG += lua5.2
      PKGCONFIG -= luabind
      PKGCONFIG += bullet
      PKGCONFIG += sdl2
      LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
      DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
    contains(LSB_RELEASE_REL, 12) : {
     PKGCONFIG += lua5.2
     PKGCONFIG -= luabind
     PKGCONFIG += bullet
     PKGCONFIG += sdl2
     LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
     DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
    }
  }
  contains(LSB_RELEASE_ID, Mint): {
    PKGCONFIG += lua5.2
    PKGCONFIG -= luabind
    PKGCONFIG += bullet
    PKGCONFIG += sdl2
    LIBS += -lQGLViewer-qt5 -lGLEW -lGLU -lGL -lglut -lluabind
    DEFINES += HAVE_btHingeAccumulatedAngleConstraint
    DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
  }
  contains(LSB_RELEASE_ID, FreeBSD): {
    PKGCONFIG += bullet lua-5.1 sdl2
    LIBS += -lluabind -lQGLViewer -lGLEW -lGLU -lGL -lglut
  }

  contains(DEFINES, HAS_LIB_ASSIMP) {
    PKGCONFIG += assimp
  }
}

CONFIG  *= debug_and_release
CONFIG  *= qt opengl
CONFIG  += warn_on
CONFIG  += thread

QT      *= opengl xml network gui core

INCLUDEPATH += src/wrapper
DEPENDPATH  += src/wrapper

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
           src/code.h \
           src/high.h \
           src/cmd.h \
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

win32:DISTFILES += \
    mxe.pri \
    msys2.pri
