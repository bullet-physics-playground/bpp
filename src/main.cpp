#include <QApplication>

#include <iostream>

#include "gui.h"

#include <GL/freeglut.h>

int main(int argc, char **argv) {
    QApplication application(argc, argv);

    Gui *g;

    glutInit(&argc,argv);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);

    if (!QIcon::hasThemeIcon("document-new")) {
        QIcon::setThemeName("humanity");
    }

    g = new Gui();
    g->show();

    return application.exec();
}
