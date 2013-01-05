#ifndef LUA_QPROCESS_H
#define LUA_QPROCESS_H

#include "lua_qt.h"

typedef class_<QProcessEnvironment>  LQProcessEnvironment;
typedef class_<QProcess,QObject>  LQProcess;
typedef class_<QApplication,QObject>  LQApplication;
typedef class_<QDesktopWidget, QWidget> LQDesktopWidget;
typedef class_<QClipboard, QObject> LQClipboard;
typedef class_<QSound, QObject> LQSound;
typedef class_<QFileSystemWatcher, QObject> LQFileSystemWatcher;

LQProcessEnvironment lqprocessenvironment();
LQProcess lqprocess();
LQApplication lqapplication();

LQDesktopWidget lqdesktopwidget();
LQClipboard lqclipboard();
LQSound lqsound();
LQFileSystemWatcher lqfilesystemwatcher();

#endif // LUA_QPROCESS_H
