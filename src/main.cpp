#include <QApplication>
#include <QDebug>

#include "gui.h"

#include "viewer.h"

#ifdef WIN32
// #include <windows.h>
#endif

#include <GL/glew.h>
#include <GL/freeglut.h>

using namespace std;

int main(int argc, char **argv) {
//    qDebug() << "Bullet Physics Playground";

    QApplication application(argc, argv);
  
    bool savePNG = false, savePOV = false;

#ifdef HAS_GETOPT
  
  // int opterr = 0;
  int c;
  while ((c = getopt (argc, argv, "ps")) != -1) {
    switch (c) {
    case 's':
      savePNG = true;
      break;
    case 'p':
      savePOV = true;
      break;
    default:
      qDebug() << "unknown argument:\"" << c << "\". Exiting.";
      exit(1);
    }
  }

#endif

  Gui *g;

  glutInit(&argc,argv);
  glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);

#ifdef WIN32_LINK_THEME
  if (!QIcon::hasThemeIcon("document-new")) {
    QIcon::setThemeName("humanity");
  }
#endif

  g = new Gui(savePNG, savePOV);
  g->show();

  GLenum err = glewInit();
  if (GLEW_OK != err) {
    /* Problem: glewInit failed, something is seriously wrong. */
    fprintf(stderr, "Error: %s\n", glewGetErrorString(err));
    return 1;
  }
  fprintf(stdout, "Status: Using GLEW %s\n", glewGetString(GLEW_VERSION));

  return application.exec();
}
