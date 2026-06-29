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
#include <QStatusBar>
#include <QTemporaryFile>
#include <QApplication>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

static int s_runningCount = 0;

OpenSCAD::OpenSCAD(QString sdl, btScalar mass) : Mesh(nullptr, mass) {
  this->sdl = sdl;
  m_process = nullptr;
  m_pendingMass = mass;
  m_stlReady = false;

  QCryptographicHash hashAlgo(QCryptographicHash::Sha1);
  hashAlgo.addData(sdl.toUtf8());
  QString hash = hashAlgo.result().toHex();

  QFileInfo cacheInfo(
      QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
  if (!cacheInfo.exists()) {
    QDir p(".");
    if (!p.mkpath(cacheInfo.absoluteFilePath())) {
      qDebug() << "unable to create " << cacheInfo.absoluteFilePath();
    }
  }

  QString stlfile =
      QStandardPaths::writableLocation(QStandardPaths::CacheLocation) +
      QDir::separator() + hash + ".stl";

  QFileInfo check_file(stlfile);
  if (check_file.exists() && check_file.isFile()) {
    loadFile(stlfile, mass);
    m_stlReady = true;
    return;
  }

  QString scadFile =
      QStandardPaths::writableLocation(QStandardPaths::CacheLocation) +
      QDir::separator() + hash + ".scad";
  QFile scad(scadFile);
  if (scad.open(QIODevice::WriteOnly | QIODevice::Text)) {
    qDebug() << "scad.fileName() = " << scad.fileName();
    QTextStream out(&scad);
    out << sdl;
    scad.close();

    QStringList args;

    QSettings s;
    QString openscad;

#ifdef Q_OS_WIN
    openscad = s.value("openscad/executable",
                       "C:\\Program Files\\OpenSCAD\\openscad.exe")
                   .toString();
#else
    openscad = s.value("openscad/executable", "/usr/bin/openscad").toString();
#endif

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

    if (m_process->exitStatus() == QProcess::CrashExit ||
        m_process->exitCode() != 0) {
      if (m_process->exitStatus() == QProcess::CrashExit) {
        qDebug() << "openscad process error";
      } else {
        qDebug() << tr("openscad exited with code: %1.").arg(m_process->exitCode());
        QString err = m_process->readAllStandardError();
        if (!err.isEmpty()) {
          qDebug() << err;
        }
      }
      m_process->deleteLater();
      m_process = nullptr;
    } else {
      loadFile(m_stlfile, m_pendingMass);
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
      loadFile(m_stlfile, m_pendingMass);
      m_stlReady = true;
      emit stlReady();
    }
  } else {
    qDebug() << tr("Error writing to file '%1'.").arg(scad.fileName());
  }
}

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
                .def(tostring(const_self))];
}

QString OpenSCAD::toString() const { return QString("OpenSCAD"); }
