build_with_msys2 {
  CONFIG-= windows
  QMAKE_LFLAGS += $$QMAKE_LFLAGS_WINDOWS

  HOME = $$PWD/..
  message($$HOME)

  DEFINES += WIN32_LINK_QGLVIEWER
  DEFINES += WIN32_LINK_BULLET
  DEFINES += WIN32_LINK_LUABIND
  DEFINES += WIN32_LINK_BOOST

  DEFINES += WIN32_LINK_AUTOIMPORT

  CONFIG += link_pkgconfig
  PKGCONFIG += assimp bullet glew freeglut sdl2 lua5.1

  WIN32_DIR_LUABIND   = $$HOME/luabind
  WIN32_DIR_QGLVIEWER = $$HOME/libQGLViewer

  LIBS += -lSDL2main

  # SpaceNavigator HID support
  LIBS += -lhid -lsetupapi
}

contains(DEFINES, WIN32_LINK_AUTOIMPORT) {
  QMAKE_LFLAGS            = -static-libgcc -static-libstdc++ -Wl,-enable-auto-import
  QMAKE_LFLAGS_RELEASE    = -Wl,-s
  QMAKE_LFLAGS_DEBUG      =
}

contains(DEFINES, WIN32_LINK_QGLVIEWER) {

  INCLUDEPATH += $$WIN32_DIR_QGLVIEWER

  # Link

  CONFIG( debug, debug|release ) {
    LIBS += -L$$WIN32_DIR_QGLVIEWER\\QGLViewer -lQGLViewerd3 -lopengl32
  } else {
    LIBS += -L$$WIN32_DIR_QGLVIEWER\\QGLViewer -lQGLViewer3 -lopengl32
  }
}

contains(DEFINES, WIN32_LINK_BULLET) {

  # c++ - gcc warning" 'will be initialized after'
  unix:QMAKE_CXXFLAGS_WARN_ON += -Wno-reorder

  INCLUDEPATH += $$WIN32_DIR_BULLET\\src

  # Include

  LIBS += -L$$WIN32_DIR_BULLET\\build\\lib

  # Link

  LIBS += -lBulletSoftBody -lBulletDynamics -lBulletCollision -lLinearMath
}

contains(DEFINES, WIN32_LINK_LUABIND) {

#  DEFINES += LUABIND_DYNAMIC_LINK=1

  PATH_LUABIND = $$WIN32_DIR_LUABIND

  INCLUDEPATH += $$PATH_LUABIND $$PATH_LUABIND/build

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
