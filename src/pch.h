#ifndef PCH_H
#define PCH_H

/**
 * @file pch.h
 * @brief Precompiled header: the Qt, OpenGL and STL headers used throughout.
 *
 * Collected in one place so the compiler can pre-parse them once instead of
 * on every translation unit. It declares nothing of its own.
 */

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
#include <QRegExp>
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
#include <QtGui>
#include <QCloseEvent>
#include <QColor>
#include <QFont>
#include <QMouseEvent>
#include <QPalette>
#include <QWheelEvent>

// Qt Widgets
#include <QtWidgets>
#include <QAction>
#include <QApplication>
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

#ifndef __gl_h_
# include <GL/gl.h>
#endif
#ifndef __glu_h_
# include <GL/glu.h>
#endif
#ifndef __glut_h_
# include <GL/glut.h>
#endif

#endif
