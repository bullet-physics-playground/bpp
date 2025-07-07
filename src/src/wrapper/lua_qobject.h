#ifndef LUA_QOBJECT_H
#define LUA_QOBJECT_H

#include "lua_qt.h"

#include <boost/function.hpp>
#include <boost/shared_ptr.hpp>
#include <luabind/class_info.hpp>
using namespace luabind;

typedef class_<QObject, boost::shared_ptr<QObject> > LQObject;
typedef class_<QWidget, QObject>            LQWidget;
typedef class_<QVariant>                    LQVariant;

LQObject lqobject();
LQWidget lqwidget();
LQVariant lqvariant();

#endif
