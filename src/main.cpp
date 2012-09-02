#include <QApplication>
#include <QDebug>


#include "gui.h"

#include "viewer.h"

#ifdef WIN32
// #include <windows.h>
#endif

// #include <GL/glut.h>

using namespace std;

int main(int argc, char **argv) {
    glutInit(&argc,argv);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
  
    QApplication application(argc, argv);
  
    bool savePNG = false, savePOV = false;

#ifdef HAS_GETOPT
  
  int opterr = 0;
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

  Gui g(savePNG, savePOV);
  g.show();

  return application.exec();
}
