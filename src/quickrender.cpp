#include "quickrender.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QObject>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>

#include "appenv.h"

QuickRender::Plan QuickRender::plan(QSettings *settings, const QSize &viewSize,
                                    const QString &scriptName, int frameNum,
                                    const QString &povargs) {
  QString renderResolution =
      settings->value("gui/renderResolution", "view size").toString();

  qDebug() << "renderResolution: " << renderResolution;

  int renderWidth, renderHeight;

  if (renderResolution.isEmpty() || renderResolution == "view size") {
    renderWidth = viewSize.width();
    renderHeight = viewSize.height();
  } else if (renderResolution.contains("x")) {
    QRegularExpression rx("(\\d+)");
    QString str = renderResolution;
    QStringList list;
    int pos = 0;

    while (true) {
      QRegularExpressionMatch m = rx.match(str, pos);
      if (!m.hasMatch())
        break;
      list << m.captured(1);
      pos = m.capturedStart() + m.capturedLength();
    }
    renderWidth = list.at(0).toInt();
    renderHeight = list.at(1).toInt();
  } else {
    renderWidth = viewSize.width();
    renderHeight = viewSize.height();
  }


  //    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
  //    for (int i = 0; i < env.toStringList().length(); i++) {
  //        qDebug() << env.toStringList().at(i);
  //    }

  QStringList args;

  QString sceneName;
  if (!scriptName.isEmpty()) {
    QFileInfo fi(scriptName);
    sceneName = fi.completeBaseName();
  } else {
    sceneName = "no_name";
  }

  QString cache =
      QStandardPaths::writableLocation(QStandardPaths::CacheLocation);

  QString defaultPovrayExe;
  QString defaultIncludes;

  QString pwd = startupWorkingDir();
  QString appDir = QCoreApplication::applicationDirPath();

#ifdef Q_OS_WIN
  defaultPovrayExe = QString("C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe");
  defaultIncludes  = QString("+L%1 +L%2\\includes").arg(cache, pwd);
#elif defined(Q_OS_LINUX)
  defaultPovrayExe = QString("/usr/bin/povray");
  defaultIncludes  = QString("+L%1 +L%2/includes").arg(cache, pwd);
#else
  defaultPovrayExe = QString("/opt/homebrew/bin/povray");
  defaultIncludes  = QString("+L%1 +L%2/includes +L%3/../includes").arg(cache, pwd, appDir);
#endif

  QString systemPovExe;
  {
    QStringList candidates;
#ifdef Q_OS_WIN
    candidates << "C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe";
#elif defined(Q_OS_LINUX)
    candidates << "/usr/bin/povray" << "/usr/local/bin/povray";
#else
    candidates << "/opt/homebrew/bin/povray" << "/usr/local/bin/povray" << "/usr/bin/povray";
#endif
    QString fromPath = QStandardPaths::findExecutable("povray");
    if (!fromPath.isEmpty())
      candidates.prepend(fromPath);
    for (const QString &c : candidates) {
      QFileInfo fi(c);
      if (fi.exists() && fi.isExecutable()) {
        systemPovExe = fi.absoluteFilePath();
        break;
      }
    }
  }
  if (systemPovExe.isEmpty()) systemPovExe = "POV-Ray not found!";

  QString defaultPreview = QString("%1 -c +d -A +p +Q11 +GA +FN10").arg(defaultIncludes);

  QString povray = settings->value("povray/executable").toString();
  if (povray.isEmpty() || (povray != "POV-Ray not found!" && !QFileInfo(povray).exists()))
    povray = systemPovExe;
  QString opts =   settings->value("povray/preview", defaultPreview).toString();

  args << opts.split(" ");

  args << QString("+W%1").arg(renderWidth);
  args << QString("+H%1").arg(renderHeight);

  QString desktop =
      QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
  QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd-hhmmss");
  QString fn = QString("%1").arg(frameNum, 5, 10, QChar('0'));

  //// ~/Desktop/bpp-timestamp.png
  // QString png = QString("%1/bpp-%2.png").arg(desktop, timestamp);
  //// ~/Desktop/bpp-timestamp-sceneName-frameNumber.png
  QString png = QString("%1%2bpp-%3-%4-%5.png")
                    .arg(desktop, QDir::separator(), timestamp, sceneName, fn);

  args << "+F"; // turn output file on
  args << QString("+O%1").arg(png);

  args << QString("+K%1").arg(frameNum); // pov clock is the frame number

  args << sceneName + ".pov";

  if(!povargs.isEmpty()) {
    args << povargs;
  }

  qDebug() << "executing " << povray << args;

  QDir dir(startupWorkingDir());

  QString defaultExportPath = QString("%1%2%3").arg(startupWorkingDir(), QDir::separator(), "export");

  QString exportDir = settings->value("povray/export", defaultExportPath).toString();
  QString sceneDir =
      dir.absoluteFilePath(exportDir + QDir::separator() + sceneName);
  qDebug() << "exportDir: " << exportDir;
  qDebug() << "sceneDir: " << sceneDir;


  Plan plan;
  plan.povray = povray;
  plan.args = args;
  plan.opts = opts;
  plan.width = renderWidth;
  plan.height = renderHeight;
  plan.sceneName = sceneName;
  plan.sceneDir = sceneDir;
  plan.png = png;
  return plan;
}

void QuickRender::start(const Plan &plan, QObject *context,
                        const std::function<void(const QString &)> &report) {
  // Deliberately parentless: a QProcess still running when its parent is
  // destroyed gets kill()ed (and waited on) from within ~QProcess(), which
  // both kills povray out from under the user and crashes bpp by invoking
  // the finished-signal lambda below while the Viewer is mid-teardown. With
  // no parent, closing bpp neither touches this QProcess nor the povray
  // process it wraps; on a normal, non-crashing exit it simply outlives us.
  QProcess *p = new QProcess();
  p->setProgram(plan.povray);
  p->setArguments(plan.args);
  p->setWorkingDirectory(plan.sceneDir);
  p->setProcessChannelMode(QProcess::MergedChannels);

  QObject::connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
          context, [report, p](int exitCode, QProcess::ExitStatus exitStatus) {
            if (exitCode != 0 || exitStatus == QProcess::CrashExit) {
              report(
                  QString("POV-Ray failed (exit code %1):\n%2")
                      .arg(exitCode)
                      .arg(QString::fromLocal8Bit(p->readAll())));
            }
            p->deleteLater();
          });
  QObject::connect(p, &QProcess::errorOccurred, context,
          [report, p](QProcess::ProcessError) {
            if (p->error() == QProcess::FailedToStart) {
              report(
                  QString("POV-Ray failed to start: %1").arg(p->errorString()));
              p->deleteLater();
            }
          });

  p->start();
}
