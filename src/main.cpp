/**
 * @file main.cpp
 * @brief Program entry point, command line handling and headless simulation.
 *
 * bpp runs in one of three modes, picked apart here from the command line:
 * a plain QCoreApplication for @c --help / @c --version / @c --report-load,
 * the full Gui for interactive use, and a windowless Viewer that steps a
 * script for a fixed number of frames for @c -f / @c -l / @c -i.
 */

/// Version string reported by @c --version and recorded in the settings.
#define APP_VERSION QString("0.3.37")
/// Short application name; also the QSettings application key.
#define APP_NAME QString("bpp")
/// Translated, human readable application name.
#define APP_NAME_FULL tr("Bullet Physics Playground")
/// Organization name used to locate the QSettings store.
#define APP_ORGANIZATION QString("bullet-physics-playground.github.io")

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QFileInfo>
#include <QDir>
#include <QTimer>

#include "appenv.h"
#include "gui.h"
#include "prefs.h"
#include "viewer.h"

#include "glutils.h"

/**
 * @brief Returns the process-wide QTextStream wrapping stdout.
 *
 * A function-local static, so the stream is constructed on first use and
 * shares one buffer across every caller.
 *
 * @return Reference to the stdout stream.
 */
QTextStream &qStdOut() {
  static QTextStream ts(stdout);
  return ts;
}
/**
 * @brief Returns the process-wide QTextStream wrapping stderr.
 *
 * Used for diagnostics and error messages so they stay separable from the
 * script output written to qStdOut().
 *
 * @return Reference to the stderr stream.
 */
QTextStream &qStdErr() {
  static QTextStream ts(stderr);
  return ts;
}

/**
 * @brief Strips the extension from a file name.
 *
 * Used to turn a script path into the base name that the Viewer uses when it
 * names exported POV-Ray frames and images.
 *
 * @param fileName Name or path to strip.
 * @return Everything before the last @c '.'. If there is no dot the result is
 *         an empty string, because QString::lastIndexOf() returns -1.
 */
QString withoutExtension(const QString &fileName) {
  return fileName.left(fileName.lastIndexOf("."));
}

/**
 * @brief Entry point: parses the command line and starts the chosen mode.
 *
 * Captures the start-up working directory, then scans argv directly - before
 * QCommandLineParser runs - to decide which flavour of application object is
 * needed, since constructing a QApplication requires a display that
 * @c --help and @c --version must work without. The same early scan selects
 * the @c offscreen QPA plugin when a headless run has no display available,
 * and prefers XWayland over native Wayland for GUI runs so that saved window
 * and dock geometry can actually be restored.
 *
 * The modes are then: report the script that would be loaded and exit; show
 * the Gui, optionally opening and running a positional script; or build a
 * windowless Viewer, feed it script text from a file, stdin and/or @c --lua,
 * step it @c --frames times and exit.
 *
 * @param argc Argument count as received from the C runtime.
 * @param argv Argument vector as received from the C runtime.
 * @return 0 on success, EXIT_FAILURE if a script could not be read or the
 *         arguments were inconsistent; in GUI mode, the exit code of the Qt
 *         event loop.
 */
int main(int argc, char **argv) {

  // Capture the launch directory before anything (e.g. opening a script)
  // can change the process's current working directory.
  startupWorkingDir();

  // make xlib and glx thread safe under x11
  QCoreApplication::setAttribute(Qt::AA_X11InitThreads);

  QSharedPointer<QCoreApplication> app;

  // workaround for
  // https://forum.qt.io/topic/53298/qcommandlineparser-to-select-gui-or-non-gui-mode

  // On Linux: enable printing of version and help without DISPLAY variable set

  bool runCore = false;
  bool headlessSimulate = false;
  for (int i = 0; i < argc; i++) {
    QString arg = QString(argv[i]);
    if (arg == "-h" || arg == "--help" || arg == "-v" || arg == "--version" ||
        arg == "-r" || arg == "--report-load") {
      runCore = true;
      break;
    }
    if (arg == "-f" || arg == "--file" || arg == "-l" || arg == "--lua" ||
        arg == "-i" || arg == "--stdin") {
      headlessSimulate = true;
    }
  }

  // Headless simulate mode (-f/-l/-i) never shows a window, but Viewer is a
  // QWidget (via QGLViewer) and still needs a real QApplication with a
  // working QPA platform plugin - QCoreApplication isn't enough. If there's
  // no display to connect to, fall back to the offscreen plugin so this can
  // run on a bare server/CI/container instead of aborting with "could not
  // connect to display". Only do this when the user hasn't already picked a
  // platform themselves.
  if (headlessSimulate && qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM") &&
      qEnvironmentVariableIsEmpty("DISPLAY") &&
      qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
    qputenv("QT_QPA_PLATFORM", "offscreen");
  }

  // Native Wayland forbids clients from positioning their own top-level
  // windows (the compositor has sole authority over placement), so
  // Gui::loadSettings()'s restoreGeometry()/restoreState() can't actually
  // restore the saved window/dock positions there - the window just gets
  // centered every time. XWayland doesn't have this restriction, so prefer
  // it when it's available and the user hasn't already picked a platform.
  if (!runCore && !headlessSimulate &&
      qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM") &&
      !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY") &&
      !qEnvironmentVariableIsEmpty("DISPLAY")) {
    qputenv("QT_QPA_PLATFORM", "xcb");
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

    if (!QIcon::hasThemeIcon("document-new")) {
      QIcon::setThemeName("humanity");
    }

    g = new Gui(settings);
    g->show();

    int ret = app->exec();
    delete g; // Qt will delete children, but explicit delete for top-level widget is good practice
    delete settings;
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
      v->setScriptBasePath(QDir::toNativeSeparators(QFileInfo(lua[0]).absolutePath()));
    } else if (!positionalLuaFile.isEmpty()) {
      v->setScriptName(withoutExtension(positionalLuaFile));
      v->setScriptBasePath(QDir::toNativeSeparators(QFileInfo(positionalLuaFile).absolutePath()));
    } else {
      v->setScriptName("stdin");
    }

    v->setSavePOV(parser.isSet("export"));

    v->parse(txt);
    v->startSim();

    for (int i = 1; i <= n; ++i) {
      v->animate();
    }

    v->stopAnimation();
    v->close();

    // In command-line mode, we don't need the event loop since simulation is done
    // Just delete the viewer and return
    delete v;
    delete settings;
    return 0;
  }
}
