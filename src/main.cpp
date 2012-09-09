#include <QApplication>
#include <QDebug>


#include "gui.h"

#include "viewer.h"

#ifdef WIN32
// #include <windows.h>
#endif

#include <GL/gl.h>			// Header File For The OpenGL32 Library
#include <GL/glu.h>			// Header File For The GLu32 Library
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

  g = new Gui(savePNG, savePOV);
  g->show();

  return application.exec();
}
