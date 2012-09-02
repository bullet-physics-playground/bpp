#CONFIG += debug_and_release

## windows: you need:
##
## * VC 2008 SP1: Fix for vector <function <FT>> crash.
##   http://www.microsoft.com/en-us/download/details.aspx?id=15303
## * ..
##

win32 {
  DEFINES += BUILDTIME=\\\"$$system('echo %time%')\\\"
  DEFINES += BUILDDATE=\\\"$$system('echo %date%')\\\"
} else {
  DEFINES += BUILDTIME=\\\"$$system(date '+%H:%M')\\\"
  DEFINES += BUILDDATE=\\\"$$system(date '+%Y-%m-%d')\\\"
}

TEMPLATE = app
TARGET = physics
DEPENDPATH += .
INCLUDEPATH += .
INCLUDEPATH += /usr/include/bullet
INCLUDEPATH += /usr/local/include/bullet
INCLUDEPATH += objects/robots/roboop/include
INCLUDEPATH += objects/robots/roboop/newmat
INCLUDEPATH += objects/robots/roboop/source

win32 {
  DEFINES += WIN32
} else {
  DEFINES += HAS_GETOPT
  CONFIG += link_pkgconfig
  QMAKE_CXXFLAGS_WARN_ON =
  QMAKE_CXXFLAGS_DEBUG += -g3 -O0

  MOC_DIR = .moc
  OBJECTS_DIR = .obj
  UI_DIR = .ui
}

## Add linked libs and paths for headers and palettes here using pkg-config.
## If your system doesn't support pkg-config then comment out the next line and
## set these values below.
#CONFIG += link_pkgconfig

link_pkgconfig {
  message("Config using pkg-config version "$$system(pkg-config --version))
  PKGCONFIG += bullet alsa lua5.1 luabind

  LIBS += -lqglviewer-qt4 -lglut -lGL -l3ds -lroboop -lnewmat -Lobjects/robots/roboop
} else {
  message("Config not using pkg-config")

  LUA_SRC_DIR = C:\\Lua\\5.1
  INCLUDEPATH += $$LUA_SRC_DIR\\include
  LIBS += -L$$LUA_SRC_DIR\\lib -llua

  LUABIND_SRC_DIR = C:\\libs\\luabind-0.9.1
  INCLUDEPATH += $$LUABIND_SRC_DIR $$LUABIN_SRC_DIR\\include
  LIBS += -L$$LUABIND_SRC_DIR -lluabind
  DEFINES += LUABIND_DYNAMIC_LINK

  QGL_SRC_DIR = C:\\libs\\libQGLViewer-2.3.11
  INCLUDEPATH += $$QGL_SRC_DIR
  LIBS += -lqglviewer2

## http://www.transmissionzero.co.uk/software/freeglut-devel/
  GLUT_SRC_DIR = C:\\libs\\freeglut
  INCLUDEPATH += $$GLUT_SRC_DIR\\include
  LIBS += -L$$GLUT_SRC_DIR\\lib -lglut32 -lopengl32

  BUL_SRC_DIR = C:\\libs\\bullet-2.79\\src
  INCLUDEPATH += $$BUL_SRC_DIR

  BUL_LIB_DIR = C:\\libs\\dll\\bullet
  LIBS += -L$$BUL_LIB_DIR -lBulletCollision -lBulletDynamics -lBulletMultithreaded -lBulletSoftBody -lLinearMath /NODEFAULTLIB:LIBCMT

  BOOST_SRC_DIR = C:\\libs\\boost_1_47
  INCLUDEPATH += $$BOOST_SRC_DIR
  LIBS += -L$$BOOST_SRC_DIR\\lib

##  lib3ds-20080909.zip from http://code.google.com/p/lib3ds/
  L3DS_SRC_DIR = C:\\libs\\lib3ds-20080909
  INCLUDEPATH += C:\\libs\dll\\include
  LIBS += -llib3ds-1_3

## The following directory contains dlls for QGLViewer, lua.
  LIBS += -LC:\\libs\\dll
}

QT += xml opengl

unix:!mac {
    DEFINES += __LINUX_ALSASEQ__
}

SOURCES += main.cpp \
           objects/palette.cpp \
           viewer.cpp \
           objects/object.cpp \
           objects/cube.cpp \
           objects/sphere.cpp \
           objects/plane.cpp \
           objects/cylinder.cpp \
           objects/mesh3ds.cpp \
           collisionfilter.cpp \
           objects/robots/rm.cpp \
           objects/robots/rm1.cpp \
           objects/cubeaxes.cpp \
           gui.cpp \
           commandline.cpp \
           objects/dice.cpp \
           MidiIO.cpp \
           MidiEvent.cpp \
           RtMidi.cpp \
           codeeditor.cpp \
           highlighter.cpp \
           objects/objects.cpp \
           objects/robots/roboop/source/utils.cpp \
           objects/robots/roboop/source/trajectory.cpp \
           objects/robots/roboop/source/stewart.cpp \
           objects/robots/roboop/source/sensitiv.cpp \
           objects/robots/roboop/source/robot.cpp \
           objects/robots/roboop/source/quaternion.cpp \
           objects/robots/roboop/source/kinemat.cpp \
           objects/robots/roboop/source/invkine.cpp \
           objects/robots/roboop/source/homogen.cpp \
           objects/robots/roboop/source/dynamics_sim.cpp \
           objects/robots/roboop/source/dynamics.cpp \
           objects/robots/roboop/source/delta_t.cpp \
           objects/robots/roboop/source/controller.cpp \
           objects/robots/roboop/source/control_select.cpp \
           objects/robots/roboop/source/config.cpp \
           objects/robots/roboop/source/comp_dqp.cpp \
           objects/robots/roboop/source/comp_dq.cpp \
           objects/robots/roboop/source/clik.cpp \
           objects/robots/roboop/newmat/cholesky.cpp \
           objects/robots/roboop/newmat/evalue.cpp \
           objects/robots/roboop/newmat/fft.cpp \
           objects/robots/roboop/newmat/hholder.cpp \
           objects/robots/roboop/newmat/jacobi.cpp \
           objects/robots/roboop/newmat/myexcept.cpp \
           objects/robots/roboop/newmat/newfft.cpp \
           objects/robots/roboop/newmat/newmat1.cpp \
           objects/robots/roboop/newmat/newmat2.cpp \
           objects/robots/roboop/newmat/newmat3.cpp \
           objects/robots/roboop/newmat/newmat4.cpp \
           objects/robots/roboop/newmat/newmat5.cpp \
           objects/robots/roboop/newmat/newmat6.cpp \
           objects/robots/roboop/newmat/newmat7.cpp \
           objects/robots/roboop/newmat/newmat8.cpp \
           objects/robots/roboop/newmat/newmat9.cpp \
           objects/robots/roboop/newmat/newmatex.cpp \
           objects/robots/roboop/newmat/newmatnl.cpp \
           objects/robots/roboop/newmat/newmatrm.cpp \
           objects/robots/roboop/newmat/nm_misc.cpp \
           objects/robots/roboop/newmat/solution.cpp \
           objects/robots/roboop/newmat/sort.cpp \
           objects/robots/roboop/newmat/submat.cpp \
           objects/robots/roboop/newmat/svd.cpp \
           objects/robots/roboop/newmat/bandmat.cpp \
           objects/cam.cpp

HEADERS += objects/palette.h \
           viewer.h \
           objects/object.h \
           objects/cube.h \
           objects/sphere.h \
           objects/plane.h \
           objects/cylinder.h \
           objects/mesh3ds.h \
           collisionfilter.h \
           objects/robots/rm.h \
           objects/robots/rm1.h \
           objects/cubeaxes.h \
           gui.h \
           commandline.h \
           objects/dice.h \
           MidiIO.h \
           MidiEvent.h \
           RtMidi.h \
           codeeditor.h \
           highlighter.h \
           objects/objects.h \
           objects/robots/roboop/source/utils.h \
           objects/robots/roboop/source/trajectory.h \
           objects/robots/roboop/source/stewart.h \
           objects/robots/roboop/source/robot.h \
           objects/robots/roboop/source/quaternion.h \
           objects/robots/roboop/source/dynamics_sim.h \
           objects/robots/roboop/source/controller.h \
           objects/robots/roboop/source/control_select.h \
           objects/robots/roboop/source/config.h \
           objects/robots/roboop/source/clik.h \
           objects/robots/roboop/newmat/controlw.h \
           objects/robots/roboop/newmat/include.h \
           objects/robots/roboop/newmat/myexcept.h \
           objects/robots/roboop/newmat/newmat.h \
           objects/robots/roboop/newmat/newmatap.h \
           objects/robots/roboop/newmat/newmatio.h \
           objects/robots/roboop/newmat/newmatnl.h \
           objects/robots/roboop/newmat/newmatrc.h \
           objects/robots/roboop/newmat/newmatrm.h \
           objects/robots/roboop/newmat/precisio.h \
           objects/robots/roboop/newmat/solution.h \
           objects/robots/roboop/newmat/tmt.h \
           objects/cam.h

FORMS   += gui.ui

RESOURCES += res.qrc

QMAKE_DISTCLEAN += object_script.* .ui .moc .rcc .obj

OTHER_FILES +=
