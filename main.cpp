#include <QApplication>
#include <QDebug>

#include "gui.h"

#include "viewer.h"

#include <GL/glut.h>

using namespace std;

int main(int argc, char **argv) {
  glutInit(&argc,argv);
  glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
  
  QApplication application(argc, argv);
  
  bool savePNG = false, savePOV = false;
  
  opterr = 0;
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

  qDebug() << " gui";

  Gui g(NULL, savePNG, savePOV);
  g.show();

  return application.exec();
}
