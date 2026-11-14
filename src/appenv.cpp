/**
 * @file appenv.cpp
 * @brief Where bpp keeps its per-user files (see appenv.h).
 */

#include "appenv.h"

#include <QSettings>
#include <QStandardPaths>

/// Organization name that locates the default (native) settings store.
static const char *const SETTINGS_ORGANIZATION = "bullet-physics-playground.github.io";
/// Application name of the settings store.
static const char *const SETTINGS_APPLICATION = "bpp";

const QString &userDirOverride() {
  static const QString dir = [] {
    const QString d = qEnvironmentVariable("BPP_USER_DIR");
    return d.isEmpty() ? d : QDir(d).absolutePath();
  }();
  return dir;
}

void syncPwd() {
#ifndef Q_OS_WIN
  qputenv("PWD", QDir::currentPath().toLocal8Bit());
#endif
}

// A folder under BPP_USER_DIR.
static QString under(const char *name) {
  return QDir(userDirOverride()).filePath(name);
}

QSettings *newSettings(QObject *parent) {
  if (!userDirOverride().isEmpty())
    return new QSettings(under("bpp.ini"), QSettings::IniFormat, parent);
  return new QSettings(SETTINGS_ORGANIZATION, SETTINGS_APPLICATION, parent);
}

QString userCacheDir() {
  if (!userDirOverride().isEmpty())
    return under("cache");
  return QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
}

QString userDataDir() {
  if (!userDirOverride().isEmpty())
    return under("data");
  return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

QString userRenderDir() {
  if (!userDirOverride().isEmpty())
    return under("renders");
  return QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
}
