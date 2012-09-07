TARGET   = physics

TEMPLATE = app

###################################################################
# Choose your build style
###################################################################
CONFIG *= debug_and_release

###################################################################
# Windows (MinGW), Ubuntu for now.
###################################################################
win32 {
  DEFINES += HAS_MIDI

  CONFIG += link_koppi_style_win32
} else {
  DEFINES += HAS_GETOPT
  DEFINES += HAS_MIDI

  CONFIG += link_pkgconfig
}

win32 {
  DEFINES += BUILDTIME=\\\"$$system('echo %time%')\\\"
  DEFINES += BUILDDATE=\\\"$$system('echo %date%')\\\"
} else {
  DEFINES += BUILDTIME=\\\"$$system(date '+%H:%M')\\\"
  DEFINES += BUILDDATE=\\\"$$system(date '+%Y-%m-%d')\\\"
}

MOC_DIR = .moc
OBJECTS_DIR = .obj
UI_DIR = .ui

DEPENDPATH += .

INCLUDEPATH += /usr/include/bullet
INCLUDEPATH += /usr/local/include/bullet

INCLUDEPATH += src

INCLUDEPATH += src/objects/robots/roboop/include
INCLUDEPATH += src/objects/robots/roboop/newmat
INCLUDEPATH += src/objects/robots/roboop/source

link_pkgconfig {
  message("Using pkg-config "$$system(pkg-config --version)".")
  PKGCONFIG += bullet alsa lua5.1 luabind

  LIBS += -lqglviewer-qt4 -lglut -lGL -l3ds
}

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
  DEFINES += WIN32_LINK_GLUT
  DEFINES += WIN32_LINK_LIB3DS
  DEFINES += WIN32_LINK_BULLET
  DEFINES += WIN32_LINK_LUA
  DEFINES += WIN32_LINK_LUABIND
  DEFINES += WIN32_LINK_FREEGLUT
  DEFINES += WIN32_LINK_BOOST

  WIN32_DIR_LUA       = $$WIN32_DIR_LIB\\lua-5.1.14-win32-dll
  WIN32_DIR_LUABIND   = $$WIN32_DIR_LIB\\luabind-0.9.1
  WIN32_DIR_QGLVIEWER = $$WIN32_DIR_LIB\\libQGLViewer-2.3.17
  WIN32_DIR_LIB3DS    = $$WIN32_DIR_LIB\\lib3ds

## We use glut lib included with bullet.

  WIN32_DIR_GLUT      = $$WIN32_DIR_LIB\\bullet-r2552\\Glut
  WIN32_DIR_FREEGLUT  = $$WIN32_DIR_LIB\\freeglut-2.8.0-1-mingw
  WIN32_DIR_BULLET    = $$WIN32_DIR_LIB\\bullet-r2552
  WIN32_DIR_BOOST     = $$WIN32_DIR_LIB\\boost_1_51_0
}

CONFIG *= qt opengl
QT     *= opengl xml gui core

SOURCES += src/main.cpp \
           src/objects/palette.cpp \
           src/viewer.cpp \
           src/objects/object.cpp \
           src/objects/cube.cpp \
           src/objects/sphere.cpp \
           src/objects/plane.cpp \
           src/objects/cylinder.cpp \
           src/objects/mesh3ds.cpp \
           src/coll.cpp \
           src/objects/robots/rm.cpp \
           src/objects/robots/rm1.cpp \
           src/objects/cubeaxes.cpp \
           src/gui.cpp \
           src/cmd.cpp \
           src/objects/dice.cpp \
           src/code.cpp \
           src/objects/objects.cpp \
           src/objects/robots/roboop/source/utils.cpp \
           src/objects/robots/roboop/source/trajectory.cpp \
           src/objects/robots/roboop/source/stewart.cpp \
           src/objects/robots/roboop/source/sensitiv.cpp \
           src/objects/robots/roboop/source/robot.cpp \
           src/objects/robots/roboop/source/quaternion.cpp \
           src/objects/robots/roboop/source/kinemat.cpp \
           src/objects/robots/roboop/source/invkine.cpp \
           src/objects/robots/roboop/source/homogen.cpp \
           src/objects/robots/roboop/source/dynamics_sim.cpp \
           src/objects/robots/roboop/source/dynamics.cpp \
           src/objects/robots/roboop/source/delta_t.cpp \
           src/objects/robots/roboop/source/controller.cpp \
           src/objects/robots/roboop/source/control_select.cpp \
           src/objects/robots/roboop/source/config.cpp \
           src/objects/robots/roboop/source/comp_dqp.cpp \
           src/objects/robots/roboop/source/comp_dq.cpp \
           src/objects/robots/roboop/source/clik.cpp \
           src/objects/robots/roboop/newmat/cholesky.cpp \
           src/objects/robots/roboop/newmat/evalue.cpp \
           src/objects/robots/roboop/newmat/fft.cpp \
           src/objects/robots/roboop/newmat/hholder.cpp \
           src/objects/robots/roboop/newmat/jacobi.cpp \
           src/objects/robots/roboop/newmat/myexcept.cpp \
           src/objects/robots/roboop/newmat/newfft.cpp \
           src/objects/robots/roboop/newmat/newmat1.cpp \
           src/objects/robots/roboop/newmat/newmat2.cpp \
           src/objects/robots/roboop/newmat/newmat3.cpp \
           src/objects/robots/roboop/newmat/newmat4.cpp \
           src/objects/robots/roboop/newmat/newmat5.cpp \
           src/objects/robots/roboop/newmat/newmat6.cpp \
           src/objects/robots/roboop/newmat/newmat7.cpp \
           src/objects/robots/roboop/newmat/newmat8.cpp \
           src/objects/robots/roboop/newmat/newmat9.cpp \
           src/objects/robots/roboop/newmat/newmatex.cpp \
           src/objects/robots/roboop/newmat/newmatnl.cpp \
           src/objects/robots/roboop/newmat/newmatrm.cpp \
           src/objects/robots/roboop/newmat/nm_misc.cpp \
           src/objects/robots/roboop/newmat/solution.cpp \
           src/objects/robots/roboop/newmat/sort.cpp \
           src/objects/robots/roboop/newmat/submat.cpp \
           src/objects/robots/roboop/newmat/svd.cpp \
           src/objects/robots/roboop/newmat/bandmat.cpp \
           src/objects/cam.cpp \
    src/high.cpp

HEADERS += src/objects/palette.h \
           src/viewer.h \
           src/objects/object.h \
           src/objects/cube.h \
           src/objects/sphere.h \
           src/objects/plane.h \
           src/objects/cylinder.h \
           src/objects/mesh3ds.h \
           src/coll.h \
           src/objects/robots/rm.h \
           src/objects/robots/rm1.h \
           src/objects/cubeaxes.h \
           src/gui.h \
           src/cmd.h \
           src/objects/dice.h \
           src/code.h \
           src/objects/objects.h \
           src/objects/robots/roboop/source/utils.h \
           src/objects/robots/roboop/source/trajectory.h \
           src/objects/robots/roboop/source/stewart.h \
           src/objects/robots/roboop/source/robot.h \
           src/objects/robots/roboop/source/quaternion.h \
           src/objects/robots/roboop/source/dynamics_sim.h \
           src/objects/robots/roboop/source/controller.h \
           src/objects/robots/roboop/source/control_select.h \
           src/objects/robots/roboop/source/config.h \
           src/objects/robots/roboop/source/clik.h \
           src/objects/robots/roboop/newmat/controlw.h \
           src/objects/robots/roboop/newmat/include.h \
           src/objects/robots/roboop/newmat/myexcept.h \
           src/objects/robots/roboop/newmat/newmat.h \
           src/objects/robots/roboop/newmat/newmatap.h \
           src/objects/robots/roboop/newmat/newmatio.h \
           src/objects/robots/roboop/newmat/newmatnl.h \
           src/objects/robots/roboop/newmat/newmatrc.h \
           src/objects/robots/roboop/newmat/newmatrm.h \
           src/objects/robots/roboop/newmat/precisio.h \
           src/objects/robots/roboop/newmat/solution.h \
           src/objects/robots/roboop/newmat/tmt.h \
           src/objects/cam.h \
    src/high.h

# MIDI IO

contains(DEFINES, HAS_MIDI) {
  SRC_MIDI = src/midi

  INCLUDEPATH += $$SRC_MIDI

  SOURCES += $$SRC_MIDI/MidiIO.cpp \
             $$SRC_MIDI/MidiEvent.cpp \
             $$SRC_MIDI/RtMidi.cpp

  HEADERS += $$SRC_MIDI/MidiIO.h \
             $$SRC_MIDI/MidiEvent.h \
             $$SRC_MIDI/RtMidi.h
}

unix:!mac {
  contains(DEFINES, HAS_MIDI) {
      DEFINES += __LINUX_ALSASEQ__
  }
} else {
  DEFINES +=__WINDOWS_MM__
}

# WIN32 stuff

contains(DEFINES, WIN32_LINK_QGLVIEWER) {
#  message(Statically linking QGLViewer)

  INCLUDEPATH += $$WIN32_DIR_QGLVIEWER

  # Link

  LIBS += -lQGLViewer2
}

contains(DEFINES, WIN32_LINK_GLUT) {
# message(Statically linking glut)

  DEFINES += GLUT_NO_LIB_PRAGMA
  DEFINES += GLUT_NO_WARNING_DISABLE=1

  PATH_GLUT = $$WIN32_DIR_GLUT

  INCLUDEPATH += $$PATH_GLUT

  QMAKE_CXXFLAGS_WARN_ON += -Wno-unknown-pragmas

  # include

  LIBS += -L$$PATH_GLUT

  # link

  LIBS += -lglut32
}

contains(DEFINES, WIN32_LINK_FREEGLUT) {
# message(Statically linking freeglut)

  PATH_FREEGLUT = $$WIN32_DIR_FREEGLUT

  INCLUDEPATH += $$PATH_FREEGLUT\\include

  # include

  LIBS += -L$$PATH_FREEGLUT\\bin

  # link

  LIBS += -lfreeglut
}

contains(DEFINES, WIN32_LINK_LIB3DS) {
#  message(Statically linking lib3ds)

  SRC_LIB3DS  = $$WIN32_DIR_LIB3DS\\src

  INCLUDEPATH += $$SRC_LIB3DS

  HEADERS += $$SRC_LIB3DS\\lib3ds.h

  # include

  LIBS += -L$$WIN32_DIR_LIB3DS\\src

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

  LIBS += -L$$DIR_BULLET\\Extras/GIMPACTUtils
  LIBS += -L$$DIR_BULLET\\Extras/HACD
  LIBS += -L$$DIR_BULLET\\src\\BulletCollision
  LIBS += -L$$DIR_BULLET\\src\\BulletDynamics
  LIBS += -L$$DIR_BULLET\\src\\BulletMultithreaded
  LIBS += -L$$DIR_BULLET\\src\\BulletSoftBody
  LIBS += -L$$DIR_BULLET\\src\\LinearMath
  LIBS += -L$$DIR_BULLET\\Extras/Serialize/BulletFileLoader
  LIBS += -L$$DIR_BULLET\\Extras/Serialize/BulletWorldImporter
  LIBS += -L$$DIR_BULLET\\Extras/ConvexDecomposition
  LIBS += -L$$DIR_BULLET\\Extras/LibXML
  LIBS += -L$$DIR_BULLET\\Extras/LibXML/include

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

## Misc stuff

FORMS       += src/gui.ui

RESOURCES   += res.qrc

OTHER_FILES +=

DIRS_DC = object_script.* .ui .moc .rcc .obj *.pro.user $$TARGET

unix:QMAKE_DISTCLEAN  += -r $$DIRS_DC
win32:QMAKE_DISTCLEAN += /s /f /q $$DIRS_DC && rd /s /q $$DIRS_DC
