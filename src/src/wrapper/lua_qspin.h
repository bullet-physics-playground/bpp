#ifndef LUA_QSPIN_H
#define LUA_QSPIN_H

#include "lua_qt.h"

typedef class_<QAbstractSpinBox, QWidget> LQAbstractSpinBox;
typedef class_<QSpinBox, QAbstractSpinBox> LQSpinBox;
typedef class_<QDoubleSpinBox, QAbstractSpinBox> LQDoubleSpinBox;

typedef class_<QDate> LQDate;
typedef class_<QTime> LQTime;
typedef class_<QDateTime> LQDateTime;
typedef class_<QDateTimeEdit, QAbstractSpinBox> LQDateTimeEdit;
typedef class_<QDateEdit,QDateTimeEdit> LQDateEdit;
typedef class_<QTimeEdit,QDateTimeEdit> LQTimeEdit;
typedef class_<QTimer,QObject> LQTimer;


LQAbstractSpinBox lqabstractspinbox();
LQSpinBox lqspinbox();
LQDoubleSpinBox lqdoublespinbox();

LQDate lqdate();
LQTime lqtime();
LQDateTime lqdatetime();
LQDateTimeEdit lqdatetimeedit();
LQDateEdit lqdateedit();
LQTimeEdit lqtimeedit();
LQTimer lqtimer();

#endif // LUA_QSPIN_H
