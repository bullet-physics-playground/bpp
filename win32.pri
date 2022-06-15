link_koppi_style_win32 {
#  message("Statically linking win32 libs (koppi style)")

## The libs are in C:\lib on koppi's hard drive. See:
#  github.com/koppi/bullet-physics-playground/wiki/Build-on-Windows

  WIN32_DIR_LIB = C:\\lib

  WIN32_DIR_DLL = $$WIN32_DIR_LIB\\dll

  LIBS += -L$$WIN32_DIR_DLL

  DEFINES += WIN32_LINK_QGLVIEWER
  DEFINES += WIN32_LINK_GLUT
#  DEFINES += WIN32_LINK_BULLET
#  DEFINES += WIN32_LINK_LUA
#  DEFINES += WIN32_LINK_LUABIND
#  DEFINES += WIN32_LINK_FREEGLUT
#  DEFINES += WIN32_LINK_GLEW
  DEFINES += WIN32_LINK_BOOST
  DEFINES += WIN32_LINK_SDL2

  DEFINES += WIN32_LINK_AUTOIMPORT

  CONFIG += link_pkgconfig

#  DEFINES -= HAS_LIB_ASSIMP
  PKGCONFIG += assimp
  PKGCONFIG += glut
  PKGCONFIG += glew
  PKGCONFIG += sdl2
  PKGCONFIG += bullet
  PKGCONFIG += lua
#  PKGCONFIG += luabind
  LIBS += -lluabind09

  WIN32_DIR_LUA       = /opt/mxe/usr/i686-w64-mingw32.shared
  WIN32_DIR_LUABIND   = /opt/mxe/usr/i686-w64-mingw32.shared
  WIN32_DIR_QGLVIEWER = /opt/libQGLViewer

## We use glut lib included with bullet.

  WIN32_DIR_GLUT      = $$WIN32_DIR_LIB\\bullet-r2552\\Glut
  WIN32_DIR_FREEGLUT  = $$WIN32_DIR_LIB\\freeglut-2.8.1-1-mingw
  WIN32_DIR_GLEW      = $$WIN32_DIR_LIB\\glew-1.10.0
  WIN32_DIR_BULLET    = $$WIN32_DIR_LIB\\bullet3-2.89
  WIN32_DIR_BULLET    = /opt/bullet3-3.06
  WIN32_DIR_BOOST     = $$WIN32_DIR_LIB\\boost_1_51_0
  WIN32_DIR_SDL2      = $$WIN32_DIR_LIB\\SDL2-2.0.22
}

contains(DEFINES, WIN32_LINK_AUTOIMPORT) {
# message(Enabling auto import: This should work unless it involves constant data structures referencing symbols from auto-imported DLLs.)
  QMAKE_LFLAGS            = -Wl,-enable-auto-import
  QMAKE_LFLAGS_RELEASE    = -Wl,-s
  QMAKE_LFLAGS_DEBUG      =
}

contains(DEFINES, WIN32_LINK_FREEGLUT) {
# message(Statically linking freeglut)

  DEFINES += FREEGLUT_STATIC

  PATH_FREEGLUT = $$WIN32_DIR_FREEGLUT

  INCLUDEPATH += $$PATH_FREEGLUT\\include

  # include

  LIBS += -L$$PATH_FREEGLUT\\bin

  # link

  LIBS += -lfreeglut -lglu32 -lopengl32 -lwinmm -Wl,--subsystem,windows
}

contains(DEFINES, WIN32_LINK_GLEW) {
# message(Statically linking glew)

  PATH_GLEW = $$WIN32_DIR_GLEW

  INCLUDEPATH += $$PATH_GLEW\\include

  LIBS += -L$$PATH_GLEW\\lib -L$$PATH_GLEW\\lib

  LIBS += -lglew32
}

contains(DEFINES, WIN32_LINK_GLUT) {
# message(Statically linking glut)

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
#  message(Statically linking QGLViewer)

  INCLUDEPATH += $$WIN32_DIR_QGLVIEWER

  # Link

  CONFIG( debug, debug|release ) {
    LIBS += -L$$WIN32_DIR_QGLVIEWER\\QGLViewer -lQGLViewerd2
  } else {
    LIBS += -L$$WIN32_DIR_QGLVIEWER\\QGLViewer -lQGLViewer2
  }
}

contains(DEFINES, WIN32_LINK_BULLET) {
#  message(Statically linking Bullet Physics Library)

  # c++ - gcc warning" 'will be initialized after'
  unix:QMAKE_CXXFLAGS_WARN_ON += -Wno-reorder

  INCLUDEPATH += $$WIN32_DIR_BULLET\\src

  HEADERS += $$WIN32_DIR_BULLET\\src\\btBulletDynamicsCommon.h

  # Include

  LIBS += -L$$WIN32_DIR_BULLET\\lib

  LIBS += -L$$DIR_BULLET\\Extras\\GIMPACTUtils
  LIBS += -L$$DIR_BULLET\\Extras\\HACD
  LIBS += -L$$DIR_BULLET\\src\\BulletCollision
  LIBS += -L$$DIR_BULLET\\src\\BulletDynamics
  LIBS += -L$$DIR_BULLET\\src\\BulletMultithreaded
  LIBS += -L$$DIR_BULLET\\src\\BulletSoftBody
  LIBS += -L$$DIR_BULLET\\src\\LinearMath
  LIBS += -L$$DIR_BULLET\\Extras\\Serialize\\BulletFileLoader
  LIBS += -L$$DIR_BULLET\\Extras\\Serialize\\BulletWorldImporter
  LIBS += -L$$DIR_BULLET\\Extras\\ConvexDecomposition
  LIBS += -L$$DIR_BULLET\\Extras\\LibXML
  LIBS += -L$$DIR_BULLET\\Extras\\LibXML\\include

  # Link

  LIBS += -lGIMPACTUtils
  LIBS += -lHACD
  LIBS += -lConvexDecomposition
  LIBS += -lBulletDynamics
  LIBS += -lBulletCollision
  LIBS += -lBulletMultithreaded
  LIBS += -lBulletSoftBody
  LIBS += -lLinearMath
  LIBS += -lBulletWorldImporter
  LIBS += -lBulletFileLoader
}

contains(DEFINES, WIN32_LINK_LUA) {
#  message(Statically linking LUA)

  INCLUDEPATH += $$WIN32_DIR_LUA\\include

  HEADERS += $$WIN32_DIR_LUA\\include\\lua.hpp

  # include

  LIBS += -L$$WIN32_DIR_LUA

  # link

  LIBS += -llua51
}

contains(DEFINES, WIN32_LINK_LUABIND) {
#  message(Statically linking luabind)

#  DEFINES += LUABIND_DYNAMIC_LINK=1

  PATH_LUABIND = $$WIN32_DIR_LUABIND

  INCLUDEPATH += $$PATH_LUABIND

  # include

#  CONFIG( debug, debug|release ) {
##XXX    LIBS += -lluabind
#  } else {
#    LIBS += -L$$PATH_LUABIND\\bin\\gcc-mingw-4.4.0\\debug
#    LIBS += -lluabindd
#  }
}

contains(DEFINES, WIN32_LINK_BOOST) {
#  message(Statically linking Boost)

  INCLUDEPATH += $$WIN32_DIR_BOOST

  # include

  LIBS += -L$$WIN32_DIR_BOOST\\stage\\lib

  # link ?
}

contains(DEFINES, WIN32_LINK_SDL2) {
#  message(Linking SDL2)

# include

  INCLUDEPATH += $$WIN32_DIR_SDL2\\include

  LIBS += -L$$WIN32_DIR_SDL2\\lib\\x64

  # link
  LIBS += -lSDL2
}
