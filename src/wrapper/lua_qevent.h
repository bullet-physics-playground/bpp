#ifndef LUA_QEVENT_H
#define LUA_QEVENT_H

#include "lua_qt.h"

typedef class_<QEvent> LQEvent;
typedef class_<QInputEvent, QEvent> LQInputEvent;
typedef class_<QCloseEvent, QEvent> LQCloseEvent;
typedef class_<QContextMenuEvent, QInputEvent> LQContextMenuEvent;
typedef class_<QDropEvent, QEvent> LQDropEvent;
typedef class_<QDragMoveEvent, QDropEvent> LQDragMoveEvent;
typedef class_<QDragEnterEvent, QDragMoveEvent> LQDragEnterEvent;
typedef class_<QDragLeaveEvent, QEvent> LQDragLeaveEvent;

typedef class_<QKeyEvent, QInputEvent> LQKeyEvent;
typedef class_<QMouseEvent, QInputEvent> LQMouseEvent;
typedef class_<QPaintEvent, QEvent> LQPaintEvent;
typedef class_<QTimerEvent, QEvent> LQTimerEvent;
typedef class_<QWheelEvent, QInputEvent> LQWheelEvent;
typedef class_<QResizeEvent, QEvent> LQResizeEvent;
typedef class_<QShowEvent, QEvent> LQShowEvent;
typedef class_<QHideEvent, QEvent> LQHideEvent;

LQEvent lqevent();
LQInputEvent lqinputevent();
LQCloseEvent lqcloseevent();
LQContextMenuEvent lqcontextmenuevent();
LQDropEvent lqdropevent();
LQDragMoveEvent lqdragmoveevent();
LQDragEnterEvent lqdragenterevent();
LQDragLeaveEvent lqdragleaveevent();
LQKeyEvent lqkeyevent();
LQMouseEvent lqmouseevent();
LQPaintEvent lqpaintevent();
LQTimerEvent lqtimerevent();
LQWheelEvent lqwheelevent();
LQResizeEvent lqresizeevent();
LQShowEvent lqshowevent();
LQHideEvent lqhideevent();

#endif // LUA_QEVENT_H
