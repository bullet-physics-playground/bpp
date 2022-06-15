#define APP_VERSION QString("v0.0.6")
#define APP_NAME QString("bpp")
#define APP_NAME_FULL tr("Bullet Physics Playground")
#define APP_ORGANIZATION QString("bullet-physics-playground.github.io")

#include <QApplication>

#include <QCommandLineParser>
#include <QCommandLineOption>

#include "gui.h"
#include "viewer.h"

#include <GL/freeglut.h>

QTextStream& qStdOut() { static QTextStream ts( stdout ); return ts; }
QTextStream& qStdErr() { static QTextStream ts( stderr ); return ts; }

QString withoutExtension(const QString & fileName) {
    return fileName.left(fileName.lastIndexOf("."));
}

int main(int argc, char **argv) {

    // make xlib and glx thread safe under x11
    QCoreApplication::setAttribute(Qt::AA_X11InitThreads);

    QSharedPointer<QCoreApplication> app;

    // workaround for https://forum.qt.io/topic/53298/qcommandlineparser-to-select-gui-or-non-gui-mode

    // On Linux: enable printing of version and help without DISPLAY variable set

    bool runCore = false;
    for (int i = 0; i < argc; i++) {
        if (QString(argv[i]) == "-h" ||
                QString(argv[i]) == "--help" ||
                QString(argv[i]) == "-v" ||
                QString(argv[i]) == "--version" ) {
            runCore = true;
            break;
        }
    }

    if (runCore) {
        app = QSharedPointer<QCoreApplication>(new QCoreApplication(argc, argv));
    } else {
        app = QSharedPointer<QCoreApplication>(new QApplication(argc, argv));
    }

    // end workaround

    QSettings *settings = new QSettings(APP_ORGANIZATION, APP_NAME);

    app->setApplicationName(APP_NAME);
    app->setApplicationVersion(APP_VERSION);

    QCommandLineParser parser;

    parser.setApplicationDescription(QObject::tr("The Bullet Physics Playground"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption luaOption(QStringList() << "f" << "file",
                                 QObject::tr("Runs the given Lua script without GUI."), "file");
    QCommandLineOption luaExpressionOption(QStringList() << "l" << "lua",
                                           QObject::tr("Runs the given Lua expression without GUI."), "expression");
    QCommandLineOption luaStdinOption(QStringList() << "i" << "stdin",
                                      QObject::tr("Interprets Lua code from stdin without GUI."));
    QCommandLineOption nOption(QStringList() << "n" << "frames",
                               QObject::tr("Number of frames to simulate."), "n", "10");
    QCommandLineOption povExportOption(QStringList() << "e" << "export",
                                     QObject::tr("Export frames to POV-Ray."));
    QCommandLineOption verboseOption(QStringList() << "V" << "verbose",
                                     QObject::tr("Verbose output."));
    parser.addOption(luaOption);
    parser.addOption(luaExpressionOption);
    parser.addOption(luaStdinOption);
    parser.addOption(nOption);
    parser.addOption(povExportOption);
    parser.addOption(verboseOption);

    parser.process(*app);

    if (!parser.isSet(luaOption) && !parser.isSet(luaStdinOption) && !parser.isSet(luaExpressionOption)) {
        Gui *g;

        glutInit(&argc,argv);
        glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);

        if (!QIcon::hasThemeIcon("document-new")) {
            QIcon::setThemeName("humanity");
        }

        g = new Gui(settings);
        g->show();

        return app->exec();
    } else {
        QStringList lua = parser.values(luaOption);
        QStringList luaExpression = parser.values(luaExpressionOption);

        if (lua.isEmpty() && luaExpression.isEmpty() && !parser.isSet(luaStdinOption)) {
            qStdErr() << QObject::tr("Error: Option '--lua' requires a Lua script file as an argument. Exiting.") << "\n";
            return EXIT_FAILURE;
        }

        QString txt;

        if (!lua.isEmpty()) {
            QFile file(lua[0]);
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QString errMsg = file.errorString();
                qStdErr() << QObject::tr("Error: reading '%1': %2. Exiting.").arg(lua[0], errMsg) << "\n";
                return EXIT_FAILURE;
            }

            QTextStream in(&file);
            txt = in.readAll();
            file.close();
        }

        if (parser.isSet(luaStdinOption)) {
            QTextStream in(stdin);
            txt += "\n" + in.readAll();
        }

        if (!luaExpression.isEmpty()) {
            txt += "\n" + luaExpression[0];
        }

        int n = parser.value(nOption).toInt();
        if (n < 0) {
            qStdErr() << QObject::tr("Error: -n must be >= 0. Exiting.") << "\n";
            return EXIT_FAILURE;
        }

        Viewer *v = new Viewer(NULL, settings);

        QObject::connect(v, &Viewer::scriptHasOutput, [=](QString o) {
            qStdOut() << o << "\n";
        });
        QObject::connect(v, &Viewer::statusEvent, [=](QString e) {
            qStdErr() << e << "\n";
        });

        if (parser.isSet("verbose"))  {
            QObject::connect(v, &Viewer::scriptStarts, [=]() {
                qStdErr() << "scriptStarts()" << "\n";
            });
            QObject::connect(v, &Viewer::scriptStopped, [=]() {
                qStdErr() << "scriptStoppend()" << "\n";
            });
            QObject::connect(v, &Viewer::scriptFinished, [=]() {
                qStdErr() << "scriptFinished()" << "\n";
            });
        }

        if (!lua.isEmpty()) {
            v->setScriptName(withoutExtension(lua[0]));
        } else {
            v->setScriptName("stdin");
        }

        v->setSavePOV(parser.isSet("export"));

        v->parse(txt);
        v->startSim();

        for (int i = 0; i < n; ++i) {
            v->animate();
        }

        v->close();

        QMetaObject::invokeMethod(qApp, "quit", Qt::QueuedConnection);

        return app->exec();
    }
}
