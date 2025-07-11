#ifndef LUA_QBUTTON_H
#define LUA_QBUTTON_H

#include "lua_qt.h"

#include "lua_qslot.h"

struct QAbstractButtonWrap : public QAbstractButton, public luabind::wrap_base {
  QAbstractButtonWrap(QWidget *w) : QAbstractButton(w) {}
  QAbstractButtonWrap() {}
  virtual void paintEvent(QPaintEvent *e) {
    call_member<void>(this, "paintEvent", e);
  }
};

typedef class_<QAbstractButton, QAbstractButtonWrap, QWidget> LQAbstractButton;
typedef class_<QCheckBox, QAbstractButton> LQCheckBox;
typedef class_<QPushButton, QAbstractButton> LQPushButton;
typedef class_<QRadioButton, QAbstractButton> LQRadioButton;
typedef class_<QToolButton, QAbstractButton> LQToolButton;
typedef class_<QButtonGroup, QObject> LQButtonGroup;
typedef class_<QKeySequence> LQKeySequence;

LQAbstractButton lqabstractbutton();
LQCheckBox lqcheckbox();
LQPushButton lqpushbutton();
LQRadioButton lqradionbutton();
LQToolButton lqtoolbutton();
LQButtonGroup lqbuttongroup();
LQKeySequence lqkeysequence();

#endif
