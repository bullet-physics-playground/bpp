TARGET   = physics

TEMPLATE = app

CONFIG  *= debug_and_release

win32 {

  CONFIG += link_koppi_style_win32

  include(win32.pri)

} else {

  DEFINES += HAS_GETOPT

  CONFIG += link_pkgconfig

  physics-binary.path = /usr/bin
  physics-binary.files = physics
  physics-deskop.path = /usr/share/applications
  physics-deskop.files = physics.desktop
  physics-icons.path = /usr/share/icons/hicolor/scalable/apps
  physics-icons.files = icons/physics.svg

  INSTALLS += physics-binary physics-deskop physics-icons
}

mac {
  CONFIG += x86 ppc
  ICON = icons/physics.icns
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
RCC_DIR = .rcc

DEPENDPATH += .

INCLUDEPATH += /usr/include/bullet
INCLUDEPATH += /usr/local/include/bullet

INCLUDEPATH += src

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
           src/gui.cpp \
           src/cmd.cpp \
           src/code.cpp \
           src/objects/objects.cpp \
           src/objects/cam.cpp \
           src/high.cpp \
           src/prefs.cpp

HEADERS += src/objects/palette.h \
           src/viewer.h \
           src/objects/object.h \
           src/objects/cube.h \
           src/objects/sphere.h \
           src/objects/plane.h \
           src/objects/cylinder.h \
           src/objects/mesh3ds.h \
           src/coll.h \
           src/gui.h \
           src/cmd.h \
           src/code.h \
           src/objects/objects.h \
           src/objects/cam.h \
           src/high.h \
           src/prefs.h

FORMS   += src/gui.ui \
           src/prefs.ui

RESOURCES   += res.qrc

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
