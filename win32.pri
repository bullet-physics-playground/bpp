link_koppi_style_win32 {
  #PKG_CONFIG=/opt/mxe/usr/bin/x86_64-w64-mingw32.shared-pkg-config

  WIN32_DIR_LIB = C:\Users\jakob\OneDrive\Documents\GitHub

  WIN32_DIR_DLL = $$WIN32_DIR_LIB\\dll

  LIBS += -L$$WIN32_DIR_DLL

  DEFINES += WIN32_LINK_QGLVIEWER
  DEFINES += WIN32_LINK_GLUT
  DEFINES += WIN32_LINK_BULLET
  DEFINES += WIN32_LINK_LUABIND
#  DEFINES += WIN32_LINK_FREEGLUT
#  DEFINES += WIN32_LINK_GLEW
  DEFINES += WIN32_LINK_BOOST
#  DEFINES += WIN32_LINK_SDL2

  DEFINES += WIN32_LINK_AUTOIMPORT

  CONFIG += link_pkgconfig

  PKGCONFIG += assimp
#  PKGCONFIG += boost
  PKGCONFIG += freeglut
  PKGCONFIG += glew
  PKGCONFIG += sdl2
#  PKGCONFIG += bullet
  PKGCONFIG += lua

  WIN32_DIR_LUABIND   = $$WIN32_DIR_LIB\\luabind
  WIN32_DIR_QGLVIEWER = $$WIN32_DIR_LIB\\libQGLViewer

## We use glut lib included with bullet.

  WIN32_DIR_GLUT      = $$WIN32_DIR_LIB\\bullet-r2552\\Glut
  WIN32_DIR_FREEGLUT  = $$WIN32_DIR_LIB\\freeglut-2.8.1-1-mingw
  WIN32_DIR_GLEW      = $$WIN32_DIR_LIB\\glew-1.10.0
  WIN32_DIR_BULLET    = $$WIN32_DIR_LIB\\bullet3
#  WIN32_DIR_BULLET    = /opt/bullet3-3.06
  WIN32_DIR_BOOST     = C:\msys64\mingw64
  WIN32_DIR_SDL2      = $$WIN32_DIR_LIB\\SDL2-2.0.22
}

contains(DEFINES, WIN32_LINK_AUTOIMPORT) {
  QMAKE_LFLAGS            = -Wl,-enable-auto-import
  QMAKE_LFLAGS_RELEASE    = -Wl,-s
  QMAKE_LFLAGS_DEBUG      =
}

contains(DEFINES, WIN32_LINK_FREEGLUT) {
  DEFINES += FREEGLUT_STATIC

  PATH_FREEGLUT = $$WIN32_DIR_FREEGLUT

  INCLUDEPATH += $$PATH_FREEGLUT\\include

  # include

  LIBS += -L$$PATH_FREEGLUT\\bin

  # link

  LIBS += -lfreeglut -lglu32 -lopengl32 -lwinmm -Wl,--subsystem,windows
}

contains(DEFINES, WIN32_LINK_GLEW) {

  PATH_GLEW = $$WIN32_DIR_GLEW

  INCLUDEPATH += $$PATH_GLEW\\include

  LIBS += -L$$PATH_GLEW\\lib

  LIBS += -lglew32
}

contains(DEFINES, WIN32_LINK_GLUT) {

  DEFINES += GLUT_NO_LIB_PRAGMA
  DEFINES += GLUT_NO_WARNING_DISABLE=1
  DEFINES += GLUT_DISABLE_ATEXIT_HACK

  DEFINES += D__GNUWIN32__
  DEFINES += WIN32
  DEFINES += NDEBUG
  DEFINES += _WINDOWS
  DEFINES += _MBCS

  PATH_GLUT = $$WIN32_DIR_GLUT

  INCLUDEPATH += $$PATH_GLUT

  QMAKE_CXXFLAGS_WARN_ON += -Wno-unknown-pragmas

  # include

  LIBS += -L$$PATH_GLUT

  # link

  LIBS += -lglu32 -lopengl32 -lwinmm -Wl,--subsystem,windows
  #LIBS += -lglut32 -lglu32 -lopengl32 -lwinmm -Wl,--subsystem,windows
}

contains(DEFINES, WIN32_LINK_QGLVIEWER) {

  INCLUDEPATH += $$WIN32_DIR_QGLVIEWER

  # Link

  CONFIG( debug, debug|release ) {
    LIBS += -L$$WIN32_DIR_QGLVIEWER\\QGLViewer -lQGLViewerd2
  } else {
    LIBS += -L$$WIN32_DIR_QGLVIEWER\\QGLViewer -lQGLViewer2
  }
}

contains(DEFINES, WIN32_LINK_BULLET) {

  # c++ - gcc warning" 'will be initialized after'
  unix:QMAKE_CXXFLAGS_WARN_ON += -Wno-reorder

  INCLUDEPATH += $$WIN32_DIR_BULLET\\src

  HEADERS += $$WIN32_DIR_BULLET\\src\\btBulletDynamicsCommon.h

  # Include

  LIBS += -L$$WIN32_DIR_BULLET\\build\\lib

  # Link

  LIBS += -lBulletSoftBody -lBulletDynamics -lBulletCollision -lLinearMath
}

contains(DEFINES, WIN32_LINK_LUABIND) {

#  DEFINES += LUABIND_DYNAMIC_LINK=1

  PATH_LUABIND = $$WIN32_DIR_LUABIND

  INCLUDEPATH += $$PATH_LUABIND $$PATH_LUABIND/build

  HEADERS += $$PATH_LUABIND/luabind/luabind.hpp

  # include

  LIBS += -L$$PATH_LUABIND/build/src -lluabind09

#  CONFIG( debug, debug|release ) {
##XXX    LIBS += -lluabind
#  } else {
#    LIBS += -L$$PATH_LUABIND\\bin\\gcc-mingw-4.4.0\\debug
#    LIBS += -lluabindd
#  }
}

contains(DEFINES, WIN32_LINK_BOOST) {

  INCLUDEPATH += $$WIN32_DIR_BOOST\\include

  # include

  LIBS += -L$$WIN32_DIR_BOOST\\mingw64\\lib

  # link ?
}

contains(DEFINES, WIN32_LINK_SDL2) {

# include

  INCLUDEPATH += $$WIN32_DIR_SDL2\\include

  LIBS += -L$$WIN32_DIR_SDL2\\lib\\x64

  # link
  LIBS += -lSDL2
}
