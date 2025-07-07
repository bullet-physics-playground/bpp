#ifndef LUA_QGLVIEWER_H
#define LUA_QGLVIEWER_H

#include "lua_qt.h"

#include <QGLViewer/qglviewer.h>

#include "lua_qslot.h"

using namespace luabind;
using namespace qglviewer;

class Object3ds;

typedef class_<qglviewer::Camera,QObject> LQCamera;
typedef class_<QGLWidget,QWidget> LQGLWidget;
typedef class_<QGLViewer,QGLWidget> LQGLViewer;
typedef class_<qglviewer::Vec> LQGLVec;
typedef class_<qglviewer::Quaternion> LQuaternion;
typedef class_<Object3ds> LQObject3DS;

LQGLWidget lqglwidget();
LQGLViewer lqglviewer();
LQGLVec lqglvec();
LQCamera lqcamera();
LQuaternion lquaternion();
LQObject3DS lqobject3ds();

#endif // LUA_QGLVIEWER_H
