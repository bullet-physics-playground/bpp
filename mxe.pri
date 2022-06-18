build_with_mxe {

  CONFIG    += link_pkgconfig
  PKG_CONFIG =i686-w64-mingw32.static-pkg-config

  CONFIG-= windows
  QMAKE_LFLAGS += $$QMAKE_LFLAGS_WINDOWS

  QMAKE_LFLAGS += -Wl,--allow-multiple-definition

  PKGCONFIG += assimp
  PKGCONFIG += minizip
  PKGCONFIG += glut
  PKGCONFIG += glew
  PKGCONFIG += sdl2
  PKGCONFIG += lua
  PKGCONFIG += bullet

  LIBS += -lglu32 -lopengl32 -lwinmm -Wl,--subsystem,windows

  INCLUDEPATH += ../libQGLViewer

  CONFIG( debug, debug|release ) {
    LIBS += -L../libQGLViewer/QGLViewer -lQGLViewerd2
  } else {
    LIBS += -L../libQGLViewer/QGLViewer -lQGLViewer2
  }

  INCLUDEPATH += ../luabind/build
  INCLUDEPATH += ../luabind

  LIBS += -L../luabind/build/src
  LIBS += -lluabind09

}
