win32-msvc* {
## Someone needs to try this with VC90

# VC90 needs:
#
# * VC 2008 SP1: Fix for vector <function <FT>> crash.
#   http://www.microsoft.com/en-us/download/details.aspx?id=15303
# * ..

  DEFINES += WIN32_VC90

# TODO: send your pull request and update the wiki.
}

link_koppi_style_win32 {
  message("Statically linking win32 libs (koppi style)")

## The libs are in C:\lib on koppi's hard drive. See:
#  github.com/koppi/bullet-physics-playground/wiki/Build-on-Windows

  WIN32_DIR_LIB = C:\\lib

  WIN32_DIR_DLL = $$WIN32_DIR_LIB\\dll

  LIBS += -L$$WIN32_DIR_DLL

  DEFINES += WIN32_LINK_QGLVIEWER
#  DEFINES += WIN32_LINK_GLUT
  DEFINES += WIN32_LINK_LIB3DS
  DEFINES += WIN32_LINK_BULLET
  DEFINES += WIN32_LINK_LUA
  DEFINES += WIN32_LINK_LUABIND
  DEFINES += WIN32_LINK_FREEGLUT
  DEFINES += WIN32_LINK_GLEW
  DEFINES += WIN32_LINK_BOOST

  DEFINES += WIN32_LINK_AUTOIMPORT

  WIN32_DIR_LUA       = $$WIN32_DIR_LIB\\lua-5.1.14-win32-dll
  WIN32_DIR_LUABIND   = $$WIN32_DIR_LIB\\luabind-0.9.1
  WIN32_DIR_QGLVIEWER = $$WIN32_DIR_LIB\\libQGLViewer-2.3.17
  WIN32_DIR_LIB3DS    = $$WIN32_DIR_LIB\\lib3ds-1.3.0

## We use glut lib included with bullet.

  WIN32_DIR_GLUT      = $$WIN32_DIR_LIB\\bullet-r2552\\Glut
  WIN32_DIR_FREEGLUT  = $$WIN32_DIR_LIB\\freeglut-2.8.0-1-mingw
  WIN32_DIR_GLEW      = $$WIN32_DIR_LIB\\glew-1.5.4-mingw32
  WIN32_DIR_BULLET    = $$WIN32_DIR_LIB\\bullet-r2552
  WIN32_DIR_BOOST     = $$WIN32_DIR_LIB\\boost_1_51_0
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

  LIBS += -L$$PATH_GLEW\\lib -L$$PATH_GLEW\\bin

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

  LIBS += -lglut32 -lglu32 -lopengl32 -lwinmm -Wl,--subsystem,windows
}

contains(DEFINES, WIN32_LINK_QGLVIEWER) {
#  message(Statically linking QGLViewer)

  INCLUDEPATH += $$WIN32_DIR_QGLVIEWER

  # Link

  LIBS += -lQGLViewer2
}

contains(DEFINES, WIN32_LINK_LIB3DS) {
#  message(Statically linking lib3ds)

  SRC_LIB3DS  = $$WIN32_DIR_LIB3DS

  INCLUDEPATH += $$SRC_LIB3DS

  # include

  LIBS += -L$$WIN32_DIR_LIB3DS\\release

  # link

  LIBS += -l3ds
}

contains(DEFINES, WIN32_LINK_BULLET) {
#  message(Statically linking Bullet Physics Library)

  # c++ - gcc warning" 'will be initialized after'
  QMAKE_CXXFLAGS_WARN_ON += -Wno-reorder

  INCLUDEPATH += $$WIN32_DIR_BULLET\\src

  HEADERS += $$WIN32_DIR_BULLET\\src\\btBulletDynamicsCommon.h

  # Include

  LIBS += -L$$WIN32_DIR_BULLET\\build\\lib

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

  DEFINES += LUABIND_DYNAMIC_LINK=1

  PATH_LUABIND = $$WIN32_DIR_LUABIND

  INCLUDEPATH += $$PATH_LUABIND

  # include

  LIBS += -L$$PATH_LUABIND\\stage\\lib

  # link

  LIBS += -lluabind
}

contains(DEFINES, WIN32_LINK_BOOST) {
#  message(Statically linking Boost)

  INCLUDEPATH += $$WIN32_DIR_BOOST

  # include

  LIBS += -L$$WIN32_DIR_BOOST\\stage\\lib

  # link ?
}
