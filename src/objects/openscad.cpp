/**
 * @file openscad.cpp
 * @brief Implementation of the OpenSCAD-generated mesh.
 */

#include "openscad.h"

#include <QCryptographicHash>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMainWindow>
#include <QProcess>
#include <QProgressBar>
#include <QSettings>
#include <QStandardPaths>
#include <QScopedPointer>
#include <QStatusBar>
#include <QTemporaryFile>
#include <QApplication>
#include <QHash>
#include <QSet>
#include <QTextStream>
#include <QThread>

#include "appenv.h"

#include <stdexcept>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

/// How many OpenSCAD processes are running, so the busy indicator is only
/// hidden once the last of them has finished.
static int s_runningCount = 0;

OpenSCAD::OpenSCAD(QString sdl, btScalar mass, bool centerOfMass)
    : Mesh(nullptr, mass) {
  this->sdl = sdl;
  m_process = nullptr;
  m_pendingMass = mass;
  m_centerOfMass = centerOfMass;
  m_stlReady = false;

  QCryptographicHash hashAlgo(QCryptographicHash::Sha1);
  hashAlgo.addData(sdl.toUtf8());
  QString hash = hashAlgo.result().toHex();

  QFileInfo cacheInfo(
      userCacheDir());
  if (!cacheInfo.exists()) {
    QDir p(".");
    if (!p.mkpath(cacheInfo.absoluteFilePath())) {
      qDebug() << "unable to create " << cacheInfo.absoluteFilePath();
    }
  }

  QString stlfile =
      userCacheDir() +
      QDir::separator() + hash + ".stl";

  QFileInfo check_file(stlfile);
  if (check_file.exists() && check_file.isFile()) {
    loadFile(stlfile, mass, m_centerOfMass);
    m_stlReady = true;
    return;
  }

  QString scadFile =
      userCacheDir() +
      QDir::separator() + hash + ".scad";
  QFile scad(scadFile);
  if (scad.open(QIODevice::WriteOnly | QIODevice::Text)) {
    qDebug() << "scad.fileName() = " << scad.fileName();
    QTextStream out(&scad);
    out << sdl;
    scad.close();

    QStringList args;

    QString openscad = executable();

    args << "-o";
    args << stlfile;
    args << scad.fileName();

    qDebug() << "executing openscad " << args;

    m_stlfile = stlfile;

    m_process = new QProcess(this);

    showProgressBar();

    m_process->start(openscad, args);
    m_process->waitForFinished(-1);

    hideProgressBar();

    int exitCode = m_process->exitCode();
    QString openscadError;

    if (m_process->exitStatus() == QProcess::CrashExit || exitCode != 0) {
      if (m_process->exitStatus() == QProcess::CrashExit) {
        qDebug() << "openscad process error";
      } else {
        qDebug() << tr("openscad exited with code: %1.").arg(exitCode);
        openscadError = m_process->readAllStandardError();
        if (!openscadError.isEmpty()) {
          qDebug() << openscadError;
        }
      }
      m_process->deleteLater();
      m_process = nullptr;
    } else {
      loadFile(m_stlfile, m_pendingMass, m_centerOfMass);
      m_stlReady = true;
      m_process->deleteLater();
      m_process = nullptr;
      emit stlReady();
      return;
    }

    // Try to load the STL file even if OpenSCAD reported an error,
    // since the file may have been written despite the non-zero exit.
    QFileInfo stlCheck(m_stlfile);
    if (stlCheck.exists() && stlCheck.isFile()) {
      loadFile(m_stlfile, m_pendingMass, m_centerOfMass);
      m_stlReady = true;
      emit stlReady();
    } else {
      QString msg =
          QString("OpenSCAD failed to generate mesh file: %1").arg(stlfile);
      if (exitCode == 1 && !openscadError.isEmpty()) {
        msg += "\n" + openscadError;
      }
      throw std::runtime_error(msg.toStdString());
    }
  } else {
    throw std::runtime_error(
        QString("Could not write OpenSCAD file: %1").arg(scad.fileName()).toStdString());
  }
}

QString OpenSCAD::executable() {
  // (bpp's own store: a bare QSettings names no organization and reads
  // another, so the executable set in the preferences went unseen)
  QScopedPointer<QSettings> s(newSettings());
  QString openscad = s->value("openscad/executable").toString();
  if (openscad.isEmpty() || !QFileInfo(openscad).exists()) {
    QStringList candidates;
#ifdef Q_OS_WIN
    candidates << "C:\\Program Files\\OpenSCAD\\openscad.exe";
#elif defined(Q_OS_LINUX)
    candidates << "/usr/bin/openscad" << "/usr/local/bin/openscad";
#else
    candidates << "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
               << "/opt/homebrew/bin/openscad"
               << "/usr/local/bin/openscad"
               << "/usr/bin/openscad";
#endif
    QString fromPath = QStandardPaths::findExecutable("openscad");
    if (!fromPath.isEmpty())
      candidates.prepend(fromPath);
    for (const QString &c : candidates) {
      QFileInfo fi(c);
      if (fi.exists() && fi.isExecutable()) {
        openscad = fi.absoluteFilePath();
        break;
      }
    }
  }
  if (openscad.isEmpty()) {
#ifdef Q_OS_WIN
    openscad = "C:\\Program Files\\OpenSCAD\\openscad.exe";
#elif defined(Q_OS_LINUX)
    openscad = "/usr/bin/openscad";
#else
    openscad = "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD";
#endif
  }

  return openscad;
}

// ---------------------------------------------------------------------
// Parts built in the background: openscadBuild(sdl) starts OpenSCAD on the
// source if its mesh isn't in the cache yet, and says how it stands, so a
// caller (Babbage's Hall, loading exhibits) can go on and come back for it.
// A few run at once, one per spare core. Each writes to <hash>.part.stl,
// renamed to <hash>.stl only once OpenSCAD has finished well, so a mesh
// half written is never read. The OpenSCAD constructor then finds the mesh
// in the cache and loads it at once.
// ---------------------------------------------------------------------
static bool s_background = true;
void OpenSCAD::setBackgroundBuilds(bool on) { s_background = on; }

namespace {
struct ScadJob {
  QString hash, scad, part, stl;
};

class ScadBuilds : public QObject {
public:
  static ScadBuilds &instance() {
    static ScadBuilds b;
    return b;
  }

  QString status(const QString &sdl) {
    QCryptographicHash hashAlgo(QCryptographicHash::Sha1);
    hashAlgo.addData(sdl.toUtf8());
    const QString hash = hashAlgo.result().toHex();
    const QString dir = userCacheDir();
    const QString stl = dir + QDir::separator() + hash + ".stl";
    if (QFileInfo(stl).isFile())
      return "ready";
    if (m_failed.contains(hash))
      return "failed: " + m_failed.value(hash);
    if (m_running.contains(hash) || m_queued.contains(hash))
      return "building";
    QDir().mkpath(dir);
    ScadJob job;
    job.hash = hash;
    job.stl = stl;
    job.scad = dir + QDir::separator() + hash + ".scad";
    job.part = dir + QDir::separator() + hash + ".part.stl";
    QFile f(job.scad);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text))
      return "failed: could not write " + job.scad;
    QTextStream out(&f);
    out << sdl;
    f.close();
    if (!s_background) {
      // (a run with no event loop, as bpp -n: built now, waited for, as
      // the OpenSCAD constructor does; its frames don't run on meanwhile)
      QProcess p;
      OpenSCAD::showProgressBar();
      p.start(OpenSCAD::executable(), QStringList() << "-o" << job.part << job.scad);
      bool ran = p.waitForFinished(-1);
      OpenSCAD::hideProgressBar();
      return finish(job, ran && p.exitStatus() == QProcess::NormalExit ? p.exitCode() : -1,
                    ran ? p.exitStatus() : QProcess::CrashExit, p.readAllStandardError());
    }
    m_queue.append(job);
    m_queued.insert(hash);
    startNext();
    return "building";
  }

  int count() const { return m_running.size() + m_queue.size(); }

private:
  QHash<QString, QString> m_failed;      // hash -> what OpenSCAD said
  QHash<QString, QProcess *> m_running;  // hash -> its process
  QList<ScadJob> m_queue;
  QSet<QString> m_queued;

  static int most() { return qMax(1, QThread::idealThreadCount() - 1); }

  void startNext() {
    while (m_running.size() < most() && !m_queue.isEmpty()) {
      const ScadJob job = m_queue.takeFirst();
      m_queued.remove(job.hash);
      QProcess *p = new QProcess(this);
      m_running.insert(job.hash, p);
      OpenSCAD::showProgressBar();
      connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
              [this, p, job](int code, QProcess::ExitStatus st) { done(p, job, code, st); });
      connect(p, &QProcess::errorOccurred, this, [this, p, job](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) done(p, job, -1, QProcess::CrashExit);
      });
      qDebug() << "openscad, in the background:" << job.scad;
      p->start(OpenSCAD::executable(), QStringList() << "-o" << job.part << job.scad);
    }
  }

  // (the mesh renamed into place, or what went wrong kept; how it stands)
  QString finish(const ScadJob &job, int code, QProcess::ExitStatus st, const QByteArray &stderrText) {
    if (st == QProcess::NormalExit && code == 0 && QFileInfo(job.part).isFile()) {
      QFile::remove(job.stl);
      if (QFile::rename(job.part, job.stl))
        return "ready";
      if (QFileInfo(job.stl).isFile()) {   // (another bpp on the same cache built it too)
        QFile::remove(job.part);
        return "ready";
      }
      m_failed.insert(job.hash, "could not rename " + job.part);
    } else if (QFileInfo(job.stl).isFile()) {
      return "ready";                      // (as above, and its part file went with it)
    } else {
      QString err = QString::fromLocal8Bit(stderrText).trimmed();
      if (err.isEmpty())
        err = st == QProcess::CrashExit ? QString("OpenSCAD did not run (%1)").arg(OpenSCAD::executable())
                                        : QString("OpenSCAD exited with code %1").arg(code);
      m_failed.insert(job.hash, err);
      QFile::remove(job.part);
    }
    return "failed: " + m_failed.value(job.hash);
  }

  void done(QProcess *p, const ScadJob &job, int code, QProcess::ExitStatus st) {
    if (!m_running.contains(job.hash) || m_running.value(job.hash) != p)
      return;  // (already counted: a failure to start also finishes)
    m_running.remove(job.hash);
    OpenSCAD::hideProgressBar();
    finish(job, code, st, p->readAllStandardError());
    p->deleteLater();
    startNext();
  }
};
}  // namespace

QString openscadBuild(QString sdl) { return ScadBuilds::instance().status(sdl); }
int openscadBuilds() { return ScadBuilds::instance().count(); }

void OpenSCAD::showProgressBar() {
  s_runningCount++;
  QMainWindow *mainWindow = nullptr;
  for (QWidget *widget : QApplication::topLevelWidgets()) {
    mainWindow = qobject_cast<QMainWindow *>(widget);
    if (mainWindow)
      break;
  }
  if (mainWindow) {
    QProgressBar *progressBar =
        mainWindow->findChild<QProgressBar *>(QString::fromUtf8("bppProgressBar"));
    if (progressBar) {
      progressBar->show();
      mainWindow->statusBar()->showMessage(tr("Running OpenSCAD..."));
    }
  }
}

void OpenSCAD::hideProgressBar() {
  s_runningCount--;
  if (s_runningCount > 0)
    return;

  QMainWindow *mainWindow = nullptr;
  for (QWidget *widget : QApplication::topLevelWidgets()) {
    mainWindow = qobject_cast<QMainWindow *>(widget);
    if (mainWindow)
      break;
  }
  if (mainWindow) {
    QProgressBar *progressBar =
        mainWindow->findChild<QProgressBar *>(QString::fromUtf8("bppProgressBar"));
    if (progressBar) {
      progressBar->hide();
      mainWindow->statusBar()->clearMessage();
    }
  }
}

bool OpenSCAD::isReady() const { return m_stlReady; }

void OpenSCAD::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<OpenSCAD, Mesh>("OpenSCAD")
                .def(constructor<QString, btScalar>(), adopt(result))
                .def(constructor<QString, btScalar, bool>(), adopt(result))
                .def(tostring(const_self))
                .def(const_self == const_self),
            def("openscadBuild", &openscadBuild),
            def("openscadBuilds", &openscadBuilds)];
}

QString OpenSCAD::toString() const { return QString("OpenSCAD"); }
