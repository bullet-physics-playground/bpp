#ifndef LUA_QDIALOG_H
#define LUA_QDIALOG_H

#include "lua_qt.h"

typedef class_<QDialog, QWidget> LQDialog;
typedef class_<QFrame, QWidget> LQFrame;
typedef class_<QGroupBox, QWidget> LQGroupBox;
typedef class_<QSplitter, QFrame> LQSplitter;

LQDialog lqdialog();
LQFrame lqframe();
LQGroupBox lqgroupbox();
LQSplitter lqsplitter();

#endif // LUA_QDIALOG_H
