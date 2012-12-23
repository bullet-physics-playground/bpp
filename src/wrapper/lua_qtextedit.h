#ifndef LUA_QTEXTEDIT_H
#define LUA_QTEXTEDIT_H

#include "lua_qt.h"

#include "lua_qslot.h"

typedef class_<QLabel, QFrame>                      LQLabel;
typedef class_<QTextEdit, QAbstractScrollArea>      LQTextEdit;
typedef class_<QPlainTextEdit, QAbstractScrollArea> LQPlainTextEdit;
typedef class_<QLineEdit, QWidget>                  LQLineEdit;

LQLabel lqlabel();
LQTextEdit lqtextedit();
LQPlainTextEdit lqplaintextedit();
LQLineEdit lqlineedit();
#endif

