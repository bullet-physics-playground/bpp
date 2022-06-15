#ifndef LUA_QMAINWINDOW_H
#define LUA_QMAINWINDOW_H

#include "lua_qt.h"

#include <luabind/class_info.hpp>
#include <luabind/detail/object_rep.hpp>

using namespace luabind;

typedef class_<QMainWindow,QWidget>         LQMainWindow;
typedef class_<QDockWidget,QWidget>         LQDockWidget;
typedef class_<QStatusBar,QWidget>          LQStatusBar;
typedef class_<QAbstractScrollArea,QFrame> LQAbstractScrollArea;
typedef class_<QMdiArea,QAbstractScrollArea> LQMdiArea;
typedef class_<QMdiSubWindow,QWidget> LQMdiSubWindow;
typedef class_<QSystemTrayIcon,QObject> LQSystemTrayIcon;

LQMainWindow lqmainwindow();
LQDockWidget lqdockwidget();
LQStatusBar lqstatusbar();
LQAbstractScrollArea lqabstractscrollarea();
LQMdiArea lqmdiarea();
LQMdiSubWindow lqmdisubwindow();
LQSystemTrayIcon lqsystemtrayicon();

class QTestType;
typedef class_<QTestType>         LQTestType;
LQTestType lqtesttype();
#endif
