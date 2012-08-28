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
INCLUDEPATH += roboop/include
INCLUDEPATH += roboop/newmat
INCLUDEPATH += roboop/source

win32 {
  DEFINES += WIN32
} else {
  CONFIG += link_pkgconfig link_spacenav
  QMAKE_CXXFLAGS_WARN_ON =
  QMAKE_CXXFLAGS_DEBUG += -g3 -O0

  MOC_DIR = .moc
  OBJECTS_DIR = .obj
  UI_DIR = .ui
}

link_spacenav {
  LIBS += -lspnav
}

## Add linked libs and paths for headers and palettes here using pkg-config.
## If your system doesn't support pkg-config then comment out the next line and
## set these values below.
#CONFIG += link_pkgconfig

link_pkgconfig {
  message("Config using pkg-config version "$$system(pkg-config --version))
  PKGCONFIG += bullet alsa lua5.1 luabind

  LIBS += -lqglviewer-qt4 -lglut -lGL -l3ds -lroboop -lnewmat -Lroboop
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

SOURCES += main.cpp palette.cpp viewer.cpp object.cpp cube.cpp sphere.cpp \
           plane.cpp cylinder.cpp mesh3ds.cpp rm.cpp collisionfilter.cpp rm1.cpp \
           cubeaxes.cpp gui.cpp commandline.cpp dice.cpp spacenavigator.cpp spacenavigatorevent.cpp \
           SpaceNavigatorCam.cpp MidiIO.cpp MidiEvent.cpp RtMidi.cpp \
           codeeditor.cpp highlighter.cpp objects.cpp \
    roboop/source/utils.cpp \
    roboop/source/trajectory.cpp \
    roboop/source/stewart.cpp \
    roboop/source/sensitiv.cpp \
    roboop/source/robot.cpp \
    roboop/source/quaternion.cpp \
    roboop/source/kinemat.cpp \
    roboop/source/invkine.cpp \
    roboop/source/homogen.cpp \
    roboop/source/dynamics_sim.cpp \
    roboop/source/dynamics.cpp \
    roboop/source/delta_t.cpp \
    roboop/source/controller.cpp \
    roboop/source/control_select.cpp \
    roboop/source/config.cpp \
    roboop/source/comp_dqp.cpp \
    roboop/source/comp_dq.cpp \
    roboop/source/clik.cpp \
    roboop/newmat/cholesky.cpp \
    roboop/newmat/evalue.cpp \
    roboop/newmat/fft.cpp \
    roboop/newmat/hholder.cpp \
    roboop/newmat/jacobi.cpp \
    roboop/newmat/myexcept.cpp \
    roboop/newmat/newfft.cpp \
    roboop/newmat/newmat1.cpp \
    roboop/newmat/newmat2.cpp \
    roboop/newmat/newmat3.cpp \
    roboop/newmat/newmat4.cpp \
    roboop/newmat/newmat5.cpp \
    roboop/newmat/newmat6.cpp \
    roboop/newmat/newmat7.cpp \
    roboop/newmat/newmat8.cpp \
    roboop/newmat/newmat9.cpp \
    roboop/newmat/newmatex.cpp \
    roboop/newmat/newmatnl.cpp \
    roboop/newmat/newmatrm.cpp \
    roboop/newmat/nm_misc.cpp \
    roboop/newmat/solution.cpp \
    roboop/newmat/sort.cpp \
    roboop/newmat/submat.cpp \
    roboop/newmat/svd.cpp \
    roboop/newmat/bandmat.cpp

HEADERS += palette.h viewer.h   object.h   cube.h   sphere.h   \
           plane.h   cylinder.h   mesh3ds.h   rm.h   collisionfilter.h     rm1.h \
           cubeaxes.h   gui.h commandline.h dice.h spacenavigator.h spacenavigatorevent.cpp \
           SpaceNavigatorCam.h MidiIO.h MidiEvent.h RtMidi.h \
           codeeditor.h highlighter.h objects.h \
    roboop/source/utils.h \
    roboop/source/trajectory.h \
    roboop/source/stewart.h \
    roboop/source/robot.h \
    roboop/source/quaternion.h \
    roboop/source/dynamics_sim.h \
    roboop/source/controller.h \
    roboop/source/control_select.h \
    roboop/source/config.h \
    roboop/source/clik.h \
    roboop/newmat/controlw.h \
    roboop/newmat/include.h \
    roboop/newmat/myexcept.h \
    roboop/newmat/newmat.h \
    roboop/newmat/newmatap.h \
    roboop/newmat/newmatio.h \
    roboop/newmat/newmatnl.h \
    roboop/newmat/newmatrc.h \
    roboop/newmat/newmatrm.h \
    roboop/newmat/precisio.h \
    roboop/newmat/solution.h \
    roboop/newmat/tmt.h

FORMS   += gui.ui

RESOURCES += resources.qrc

QMAKE_DISTCLEAN += object_script.* .ui .moc .rcc .obj

OTHER_FILES +=
