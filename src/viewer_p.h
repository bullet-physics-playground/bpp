#pragma once

/**
 * @file viewer_p.h
 * @brief What viewer.cpp shares with the other files of Viewer's methods
 *        (viewerworlds.cpp).
 */

#include <lua.hpp>
#include <btBulletDynamicsCommon.h>

#include <string>

// Raises a Lua error from a function luabind calls, with the same message
// luaL_error gives (where in the script, then what), but by throwing:
// luaL_error would jump straight out past luabind's C++ frames, never
// freeing what they hold (Lua is built as C). luabind::error tells luabind
// the message is already on the stack; it raises it once its frames are
// done. See tests/21-lua-errors.lua.
[[noreturn]] void luaFail(lua_State *L, const std::string &message);

// Every world's internal tick callback: a body's gyroscopic term, solved
// with its contacts and joints, for bodies marked gyroSolved (viewer.cpp
// says how).
void bppGyroPreTick(btDynamicsWorld *world, btScalar dt);
