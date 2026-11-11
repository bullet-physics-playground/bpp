#include "params.h"

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include "lua_converters.h" // (QVariant and QString to and from Lua; luabind::object in a QVariant)

void Params::setOnChanged(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _onChanged = fn;
  }
}

void Params::add(lua_State *L, int frameNum, const QString &name, const QVariant &value,
                 const QString &comment, const OnError &onError) {
  // A QVariant carrying a Lua function is a push button parameter: the Gui
  // shows a button that invokes the function when it is pressed. A button
  // holds no value, so it is neither mirrored into a Lua global nor reported
  // to onParamChanged.
  if (value.userType() == qMetaTypeId<luabind::object>() &&
      luabind::type(qvariant_cast<luabind::object>(value)) == LUA_TFUNCTION) {
    _values[name] = value;

    ParamInfo info;
    info.value = value;
    info.isButton = true;
    info.buttonCallback = qvariant_cast<luabind::object>(value);
    info.comment = comment;
    _info[name] = info;

    return;
  }

  // A table whose every entry is a Lua function becomes one row of push
  // buttons: the table's keys (or positions) label the buttons, and clicking
  // one invokes its function. A button group holds no value, so it is neither
  // mirrored into a Lua global nor reported to onParamChanged.
  QList<QPair<QString, luabind::object>> callbacks;
  bool isGroup = false;
  if (value.userType() == QVariant::Map) {
    QVariantMap map = value.toMap();
    isGroup = !map.isEmpty();
    for (auto it = map.constBegin(); isGroup && it != map.constEnd(); ++it) {
      const QVariant &v = it.value();
      if (v.userType() != qMetaTypeId<luabind::object>() ||
          luabind::type(qvariant_cast<luabind::object>(v)) != LUA_TFUNCTION) {
        isGroup = false;
      } else {
        callbacks.append(qMakePair(it.key(), qvariant_cast<luabind::object>(v)));
      }
    }
  } else if (value.userType() == QVariant::List) {
    QVariantList list = value.toList();
    isGroup = !list.isEmpty();
    int i = 0;
    for (const QVariant &v : list) {
      ++i;
      if (v.userType() != qMetaTypeId<luabind::object>() ||
          luabind::type(qvariant_cast<luabind::object>(v)) != LUA_TFUNCTION) {
        isGroup = false;
        break;
      }
      callbacks.append(qMakePair(QString::number(i),
                                  qvariant_cast<luabind::object>(v)));
    }
  }

  if (isGroup && !callbacks.isEmpty()) {
    _values[name] = value;

    ParamInfo info;
    info.value = value;
    info.isButtonGroup = true;
    info.buttonCallbacks = callbacks;
    info.comment = comment;
    _info[name] = info;

    return;
  }

  _values[name] = value;

  ParamInfo info;
  info.value = value;
  info.comment = comment;
  _info[name] = info;

  if (L) {
    lua_State *ls = L;
    lua_pushstring(ls, name.toUtf8().constData());

    switch (value.userType()) {
    case QVariant::Int:
    case QVariant::LongLong:
      lua_pushinteger(ls, value.toInt());
      break;
    case QVariant::Double:
      lua_pushnumber(ls, value.toDouble());
      break;
    case QVariant::Bool:
      lua_pushboolean(ls, value.toBool());
      break;
    case QVariant::String:
      lua_pushstring(ls, value.toString().toUtf8().constData());
      break;
    default:
      lua_pushstring(ls, value.toString().toUtf8().constData());
      break;
    }

    //lua_settable(ls, LUA_GLOBALSINDEX);// Lua 5.1
	lua_setglobal(ls, name.toUtf8().constData()); // Lua 5.1 and 5.2
  }

  if (_onChanged) {
    try {
      luabind::call_function<void>(_onChanged, frameNum, name, value);
    } catch (const std::exception &e) {
      onError(e, "onParamChanged()");
    }
  }
}

void Params::addRange(lua_State *L, int frameNum, const QString &name, const btScalar &value,
                      const btScalar &min, const btScalar &max, const btScalar &step,
                      const QString &comment, const OnError &onError) {
  _values[name] = QVariant(value);
  ParamInfo info;
  info.value = QVariant(value);
  info.min = min;
  info.max = max;
  info.step = step;
  info.comment = comment;
  info.hasRange = true;
  _info[name] = info;
  if (L) {
    lua_State *ls = L;
    lua_pushstring(ls, name.toUtf8().constData());
    // Use lua_pushnumber (not lua_pushinteger) so fractional defaults
    // (e.g. addParam("rate", 0.12, ...)) survive the round trip through
    // the Lua global that getParam() reads back, instead of being
    // truncated to 0.
    lua_pushnumber(ls, value);
    lua_setglobal(ls, name.toUtf8().constData());
  }

  if (_onChanged) {
    try {
      luabind::call_function<void>(_onChanged, frameNum, name, value);
    } catch (const std::exception &e) {
      onError(e, "onParamChanged()");
    }
  }
}

void Params::press(lua_State *L, const QString &name, const QString &label, const OnError &onError) {
  ParamInfo info = _info.value(name);
  if (!info.isButton && !info.isButtonGroup) return;
  if (!L) return;

  luabind::object cb;
  if (info.isButtonGroup) {
    for (const auto &pair : info.buttonCallbacks) {
      if (pair.first == label) {
        cb = pair.second;
        break;
      }
    }
  } else {
    cb = info.buttonCallback;
  }

  // An unknown label leaves @p cb default-constructed (invalid); never call
  // luabind::type() on it - that would index the registry of a null state.
  if (!cb.is_valid() || luabind::type(cb) != LUA_TFUNCTION) return;

  try {
    luabind::call_function<void>(cb);
  } catch (const std::exception &e) {
    onError(e,
            QString("button \"%1\"%2")
                .arg(name)
                .arg(label.isEmpty() ? QString()
                                     : QString(" / %1").arg(label)));
  }
}

ParamInfo Params::info(const QString &name) const {
  return _info.value(name, ParamInfo());
}

QVariant Params::get(lua_State *L, const QString &name) const {
  if (L) {
    lua_State *ls = L;
    lua_getglobal(ls, name.toUtf8().constData());
    int luaType = lua_type(ls, -1);
    if (luaType == LUA_TNUMBER) {
      double n = lua_tonumber(ls, -1);
      lua_pop(ls, 1);
      return QVariant(n);
    } else if (luaType == LUA_TSTRING) {
      const char *s = lua_tostring(ls, -1);
      lua_pop(ls, 1);
      return QVariant(QString(s));
    } else if (luaType == LUA_TBOOLEAN) {
      bool b = lua_toboolean(ls, -1);
      lua_pop(ls, 1);
      return QVariant(b);
    }
    lua_pop(ls, 1);
  }
  return _values.value(name);
}

bool Params::show(const QString &prefix) {
  if (prefix == _filter)
    return false;
  _filter = prefix;
  return true;
}

QHash<QString, QVariant> Params::shown() const {
  if (_filter.isEmpty())
    return _values;
  QHash<QString, QVariant> shown;
  for (auto it = _values.constBegin(); it != _values.constEnd(); ++it)
    if (it.key().startsWith(_filter))
      shown.insert(it.key(), it.value());
  return shown;
}

// (also forgets the old script's ranges and its showParams() filter: a
// filter left over from a script that set one -- the Cabinet does -- hid
// every slider of whatever was opened next)
void Params::clear() {
  _values.clear();
  _info.clear();
  _filter.clear();
}

void Params::releaseLua() {
  _onChanged = luabind::object();
  // Release button callbacks and parameter values that carry a Lua object
  // (functions bound to push buttons) while the Lua state is still alive:
  // their luabind references would otherwise be released against the closed
  // state when the hashes are cleared or destroyed.
  for (ParamInfo &info : _info) {
    if (info.isButton) info.buttonCallback = luabind::object();
    if (info.isButtonGroup)
      for (auto &pair : info.buttonCallbacks)
        pair.second = luabind::object();
  }
  for (QVariant &value : _values)
    if (value.userType() == qMetaTypeId<luabind::object>())
      value = QVariant();
}
