#include <QApplication>

#include <iostream>

#include "gui.h"

#include <GL/glew.h>
#include <GL/freeglut.h>

int main(int argc, char **argv) {
  QApplication application(argc, argv);

  Gui *g;

  glutInit(&argc,argv);
  glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);

#ifdef WIN32_LINK_THEME
  if (!QIcon::hasThemeIcon("document-new")) {
    QIcon::setThemeName("humanity");
  }
#endif

  g = new Gui();
  g->show();

  GLenum err = glewInit();
  if (GLEW_OK != err) {
    std::cout << "Error: " << glewGetErrorString(err) << " Exiting." << endl;
    return 1;
  }

  return application.exec();
}
