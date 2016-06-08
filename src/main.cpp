#include <QApplication>

#include <QCommandLineParser>
#include <QCommandLineOption>
#include <GL/freeglut.h>

#include "gui.h"
#include "viewer.h"

QTextStream& qStdOut() { static QTextStream ts( stdout ); return ts; }
QTextStream& qStdErr() { static QTextStream ts( stderr ); return ts; }

int main(int argc, char **argv) {
    QApplication application(argc, argv);
    application.setApplicationVersion("0.0.3");

    QCommandLineParser parser;

    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption luaOption(QStringList() << "l" << "lua",
                                 QObject::tr("Runs the given Lua script without GUI."), "file", "script.lua");
    QCommandLineOption nOption(QStringList() << "n" << "frames",
                               QObject::tr("Number of frames to simulate."), "n");
    QCommandLineOption verboseOption(QStringList() << "V" << "verbose",
                                     QObject::tr("Verbose output."));
    parser.addOption(luaOption);
    parser.addOption(nOption);
    parser.addOption(verboseOption);

    parser.process(application);

    if (!parser.isSet(luaOption)) {
        Gui *g;

        glutInit(&argc,argv);
        glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);

        if (!QIcon::hasThemeIcon("document-new")) {
            QIcon::setThemeName("humanity");
        }

        g = new Gui();
        g->show();

        return application.exec();
    } else {
        QStringList lua = parser.values(luaOption);

        if (lua.isEmpty()) {
            qStdErr() << QObject::tr("Error: Option '--lua' requires a Lua script file as an argument. Exiting.") << endl;
            return EXIT_FAILURE;
        }

        QFile file(lua[0]);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString errMsg = file.errorString();
            qStdErr() << QObject::tr("Error: reading '%1': %2. Exiting.").arg(lua[0], errMsg) << endl;
            return EXIT_FAILURE;
        }

        QTextStream in(&file);
        QString txt = in.readAll();
        file.close();;

        int n = parser.value(nOption).toInt();
        if (n < 1) {
            qStdErr() << QObject::tr("Error: -n must be > 1. Exiting.") << endl;
            return EXIT_FAILURE;
        }

        Viewer *v = new Viewer();

        QObject::connect(v, &Viewer::scriptHasOutput, [=](QString o) {
            qStdOut() << o << endl;
        });
        QObject::connect(v, &Viewer::statusEvent, [=](QString e) {
            qStdErr() << e << endl;
        });

        if (parser.isSet("verbose"))  {
            QObject::connect(v, &Viewer::scriptStarts, [=]() {
                qStdErr() << "scriptStarts()" << endl;
            });
            QObject::connect(v, &Viewer::scriptStopped, [=]() {
                qStdErr() << "scriptStoppend()" << endl;
            });
            QObject::connect(v, &Viewer::scriptFinished, [=]() {
                qStdErr() << "scriptFinished()" << endl;
            });
        }

        v->setScriptName(lua[0]);
        v->parse(txt);
        v->startSim();

        for (int i = 0; i < n; ++i) {
            v->animate();
        }

        v->close();

        QMetaObject::invokeMethod(qApp, "quit", Qt::QueuedConnection);

        return application.exec();
    }
}
