#ifndef LUA_UTIL_H
#define LUA_UTIL_H

#include "lua_qt.h"

class QUtil {
  // dummy class, used to strore the static functions
};
typedef class_<QUtil> LQUtil;

LQUtil lqutil();

#endif // LUA_UTIL_H
