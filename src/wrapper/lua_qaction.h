#ifndef LUA_QACTION_H
#define LUA_QACTION_H

#include "lua_qt.h"

#include "lua_qslot.h"

using namespace luabind;

typedef class_<QIcon>                       LQIcon;
typedef class_<QAction,QObject>             LQAction;
typedef class_<QMenuBar,QWidget>            LQMenuBar;
typedef class_<QMenu,QWidget>               LQMenu;
typedef class_<QToolBar, QWidget>           LQToolBar;
typedef class_<QCursor>                     LQCursor;

LQAction lqaction();
LQMenuBar lqmenubar();
LQMenu  lqmenu();
LQToolBar lqtoolbar();
LQIcon lqicon();
LQCursor lqcursor();
#endif
