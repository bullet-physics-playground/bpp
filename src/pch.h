#ifndef PCH_H
#define PCH_H

/**
 * @file pch.h
 * @brief Precompiled header: the Qt, OpenGL and STL headers used throughout.
 *
 * Collected in one place so the compiler can pre-parse them once instead of
 * on every translation unit. It declares nothing of its own.
 */

// POV-Ray's vfe.h uses unqualified `Display` (resolved via `using namespace
// pov_frontend`) and the nested `pov_frontend::Display::RGBA8`. Qt6's
// qguiapplication_platform.h injects a global `typedef struct _XDisplay
// Display;` which makes that unqualified `Display` ambiguous and hides
// RGBA8. When VFE is enabled, parse povray's vfe.h here, before any Qt
// header, so `Display` resolves unambiguously while `::Display` does not
// exist yet. Qt's typedef is added afterwards; povray's headers are
// include-guarded so they are not re-parsed in the translation units that
// include them later. When VFE is disabled no povray header is parsed at
// all, so there is nothing to guard against.
#if USE_VFE
#include "vfe.h"
#endif

// Qt Core
#include <Qt>
#include <QByteArray>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QKeyEvent>
#include <QList>
#include <QMutex>
#include <QMutexLocker>
#include <QObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QString>
#include <QStringList>
#include <QTemporaryFile>
#include <QTextStream>
#include <QTimer>
#include <QVariant>
#include <QVarLengthArray>
#include <QVector>

// Qt GUI
#include <QCloseEvent>
#include <QColor>
#include <QFont>
#include <QMouseEvent>
#include <QPalette>
#include <QWheelEvent>

// Qt Widgets
#include <QAction>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QDialog>
#include <QDockWidget>
#include <QFileDialog>
#include <QFontDialog>
#include <QInputDialog>
#include <QKeySequence>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QMainWindow>
#include <QMenu>
#include <QMenuBar>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QProgressBar>
#include <QStatusBar>
#include <QSyntaxHighlighter>
#include <QToolBar>
#include <QWidget>

// Qt OpenGL
#include <QGLViewer/camera.h>
#include <QGLViewer/manipulatedFrame.h>
#include <QGLViewer/qglviewer.h>

// Gradients
#include <QConicalGradient>
#include <QLinearGradient>
#include <QRadialGradient>

// STL
#include <iostream>
#include <cmath>
#include <memory>
#include <vector>
#include <map>
#include <list>
#include <set>

// Third-party templates: these dominate compile cost (luabind is in 16 of
// 30 TUs, Bullet in 15) and are what makes the PCH worth having.
#include <lua.hpp>
#include <luabind/luabind.hpp>
#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>
#include <btBulletDynamicsCommon.h>
#include <btBulletCollisionCommon.h>

/*
#ifndef __gl_h_
# include <GL/gl.h>
#endif
#ifndef __glu_h_
# include <GL/glu.h>
#endif
#ifndef __glut_h_
# include <GL/glut.h>
#endif
*/

#endif
