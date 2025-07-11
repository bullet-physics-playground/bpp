#ifndef LUA_QSLIDER_H
#define LUA_QSLIDER_H

#include "lua_qt.h"

typedef class_<QAbstractSlider, QWidget> LQAbstractSlider;
typedef class_<QSlider, QAbstractSlider> LQSlider;
typedef class_<QScrollBar, QAbstractSlider> LQScrollBar;
typedef class_<QDial, QAbstractSlider> LQDial;

typedef class_<QProgressBar, QWidget> LQProgressBar;
typedef class_<QProgressDialog, QDialog> LQProgressDialog;

LQAbstractSlider lqabstractslider();
LQSlider lqslider();
LQScrollBar lqscrollbar();
LQDial lqdial();

LQProgressBar lqprogressbar();
LQProgressDialog lqprogressdialog();
#endif // LUA_QSLIDER_H
