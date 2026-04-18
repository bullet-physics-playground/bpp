#define APP_VERSION QString("0.2.29")
#define APP_NAME QString("bpp")
#define APP_NAME_FULL tr("Bullet Physics Playground")
#define APP_ORGANIZATION QString("bullet-physics-playground.github.io")

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QFileInfo>
#include <QTimer>

#include "gui.h"
#include "prefs.h"
#include "viewer.h"

#include <GL/freeglut.h>

QTextStream &qStdOut() {
  static QTextStream ts(stdout);
  return ts;
}
QTextStream &qStdErr() {
  static QTextStream ts(stderr);
  return ts;
}

QString withoutExtension(const QString &fileName) {
  return fileName.left(fileName.lastIndexOf("."));
}

int main(int argc, char **argv) {

  // make xlib and glx thread safe under x11
  QCoreApplication::setAttribute(Qt::AA_X11InitThreads);

  QSharedPointer<QCoreApplication> app;

  // workaround for
  // https://forum.qt.io/topic/53298/qcommandlineparser-to-select-gui-or-non-gui-mode

  // On Linux: enable printing of version and help without DISPLAY variable set

  bool runCore = false;
  for (int i = 0; i < argc; i++) {
    if (QString(argv[i]) == "-h" || QString(argv[i]) == "--help" ||
        QString(argv[i]) == "-v" || QString(argv[i]) == "--version" ||
        QString(argv[i]) == "-r" || QString(argv[i]) == "--report-load") {
      runCore = true;
      break;
    }
  }

  if (runCore) {
    app = QSharedPointer<QCoreApplication>(new QCoreApplication(argc, argv));
  } else {
    app = QSharedPointer<QCoreApplication>(new QApplication(argc, argv));
    // Set style to fusion to prevent crash in Qt Breeze style plugin cleanup
    QApplication::setStyle("fusion");
  }

  // end workaround

  app->setApplicationName(APP_NAME);
  app->setApplicationVersion(APP_VERSION);

  QSettings *settings = new QSettings(APP_ORGANIZATION, APP_NAME);

  QCommandLineParser parser;

  parser.setApplicationDescription(
      QObject::tr("The Bullet Physics Playground"));
  parser.addHelpOption();
  parser.addVersionOption();

  QCommandLineOption luaOption(
      QStringList() << "f" << "file",
      QObject::tr("Runs the given Lua script without GUI."), "file");
  QCommandLineOption luaExpressionOption(
      QStringList() << "l" << "lua",
      QObject::tr("Runs the given Lua expression without GUI."), "expression");
  QCommandLineOption luaStdinOption(
      QStringList() << "i" << "stdin",
      QObject::tr("Interprets Lua code from stdin without GUI."));
  QCommandLineOption nOption(QStringList() << "n" << "frames",
                             QObject::tr("Number of frames to simulate."), "n",
                             "10");
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

  QCommandLineOption reportLoadOption(QStringList() << "r" << "report-load",
      QObject::tr("Print which script source would be used (positional or lastfile) and exit."));
  parser.addOption(reportLoadOption);

  parser.process(*app);

  QStringList positionalArgs = parser.positionalArguments();

  QString positionalLuaFile;
  for (int i = positionalArgs.size() - 1; i >= 0; --i) {
    if (positionalArgs[i].endsWith(".lua", Qt::CaseInsensitive)) {
      positionalLuaFile = positionalArgs[i];
      break;
    }
  }

  // If requested, report which script source would be used and exit (test mode)
  if (parser.isSet("report-load")) {
    if (!positionalLuaFile.isEmpty()) {
      qStdOut() << QString("positional:%1").arg(positionalLuaFile) << "\n";
      return 0;
    }

    // Check settings for lastFile
    settings->beginGroup("mainwindow");
    QString lastFile = settings->value("lastFile", "").toString();
    settings->endGroup();

    bool openLast = settings->value("gui/openlastfile", false).toBool();
    if (!openLast) {
      openLast = settings->value("openlastfile", false).toBool();
    }

    if (openLast && !lastFile.isEmpty()) {
      qStdOut() << QString("lastfile:%1").arg(lastFile) << "\n";
      return 0;
    }

    qStdOut() << "none\n";
    return 0;
  }

  if (!parser.isSet(luaOption) && !parser.isSet(luaStdinOption) &&
      !parser.isSet(luaExpressionOption) && positionalLuaFile.isEmpty()) {
    Gui *g;

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);

    if (!QIcon::hasThemeIcon("document-new")) {
      QIcon::setThemeName("humanity");
    }

    g = new Gui(settings);
    g->show();

    int ret = app->exec();
    delete g; // Qt will delete children, but explicit delete for top-level widget is good practice
    delete settings;
    glutExit();
    return ret;
} else {
    QStringList lua = parser.values(luaOption);
    QStringList luaExpression = parser.values(luaExpressionOption);

    if (positionalLuaFile.isEmpty() && lua.isEmpty() &&
        luaExpression.isEmpty() && !parser.isSet(luaStdinOption)) {
      qStdErr() << QObject::tr("Error: Option '--lua' requires a Lua script "
                                "file as an argument. Exiting.")
                       .arg(lua[0])
                << "\n";

      delete settings;

      return EXIT_FAILURE;
    }

    if (!positionalLuaFile.isEmpty() && lua.isEmpty() &&
        !parser.isSet(luaStdinOption) && luaExpression.isEmpty()) {
      // GUI mode with a .lua file argument: open in editor and start sim
      glutInit(&argc, argv);
      glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);

      if (!QIcon::hasThemeIcon("document-new")) {
        QIcon::setThemeName("humanity");
      }

      // Temporarily disable auto-loading the last file when a positional Lua
      // script is provided so the positional script takes precedence.
      QVariant oldOpenLast = settings->value("gui/openlastfile", false);
      settings->setValue("gui/openlastfile", false);

      Gui *g = new Gui(settings);
      g->show();

      // Restore the user's preference.
      settings->setValue("gui/openlastfile", oldOpenLast);

      g->fileOpen(positionalLuaFile);
      g->runProgram();

      int ret = app->exec();
      delete g;
      delete settings;
      return ret;
    }

    QString txt;

    if (!lua.isEmpty()) {
      QFile file(lua[0]);
      if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString errMsg = file.errorString();
        qStdErr() << QObject::tr("Error: reading '%1': %2. Exiting.")
                          .arg(lua[0], errMsg)
                   << "\n";
        return EXIT_FAILURE;
      }

      QTextStream in(&file);
      txt = in.readAll();
      file.close();
    } else if (!positionalLuaFile.isEmpty()) {
      QFile file(positionalLuaFile);
      if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString errMsg = file.errorString();
        qStdErr() << QObject::tr("Error: reading '%1': %2. Exiting.")
                          .arg(positionalLuaFile, errMsg)
                   << "\n";
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

    Viewer *v = new Viewer(nullptr, settings);

    QObject::connect(v, &Viewer::scriptHasOutput,
                     [=](QString o) { qStdOut() << o << "\n"; });
    QObject::connect(v, &Viewer::statusEvent,
                     [=](QString e) { qStdErr() << e << "\n"; });

    if (parser.isSet("verbose")) {
      QObject::connect(v, &Viewer::scriptStarts,
                       [=]() { qStdErr() << "scriptStarts()" << "\n"; });
      QObject::connect(v, &Viewer::scriptStopped,
                       [=]() { qStdErr() << "scriptStoppend()" << "\n"; });
      QObject::connect(v, &Viewer::scriptFinished,
                       [=]() { qStdErr() << "scriptFinished()" << "\n"; });
    }

    if (!lua.isEmpty()) {
      v->setScriptName(withoutExtension(lua[0]));
      v->setScriptBasePath(QFileInfo(lua[0]).absolutePath());
    } else if (!positionalLuaFile.isEmpty()) {
      v->setScriptName(withoutExtension(positionalLuaFile));
      v->setScriptBasePath(QFileInfo(positionalLuaFile).absolutePath());
    } else {
      v->setScriptName("stdin");
    }

    v->setSavePOV(parser.isSet("export"));

    v->parse(txt);
    v->startSim();

    for (int i = 0; i < n; ++i) {
      v->animate();
    }

    v->stopAnimation();
    v->close();

    QTimer::singleShot(100, qApp, []() { qApp->quit(); });

    int ret = app->exec();
    delete v;
    delete settings;
    glutExit();
    return ret;
  }
}
