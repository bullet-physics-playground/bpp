#include "scriptkeys.h"

#include <QDebug>
#include <QKeyEvent>
#include <QKeySequence>
#include <QList>

#include <luabind/luabind.hpp>

#include "lua_converters.h" // (the key's name goes to Lua as a QString)

namespace {
// Name a key for the onKey() hook: its Qt key sequence text, except that the
// two Shift keys are told apart (pinball flippers are traditionally on the
// left and right Shift). Qt reports both as Key_Shift, so the side comes from
// the platform's native code.
QString luaKeyName(const QKeyEvent *e) {
  if (e->key() == Qt::Key_Shift) {
#if defined(Q_OS_MAC)
    const bool right = e->nativeVirtualKey() == 60; // kVK_RightShift
#elif defined(Q_OS_WIN)
    const bool right = e->nativeScanCode() == 54;
#else
    const bool right = e->nativeScanCode() == 62; // X11 / evdev keycode
#endif
    return right ? QStringLiteral("RShift") : QStringLiteral("LShift");
  }
  return QKeySequence(e->key()).toString(QKeySequence::PortableText);
}
} // namespace

void ScriptKeys::setOnKey(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _onKey = fn;
  }
}

void ScriptKeys::addShortcut(const QString &keys, const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _shortcuts.insert(keys, std::make_shared<luabind::object>(fn));
  }
}

void ScriptKeys::removeShortcut(const QString &keys) {
  _shortcuts.remove(keys);
}

void ScriptKeys::clear() {
  _onKey = luabind::object();
  _held.clear();
  // (the shared_ptr<luabind::object> destructors call luaL_unref)
  for (auto it = _shortcuts.begin(); it != _shortcuts.end(); ++it) {
    it->reset();
  }
  _shortcuts.clear();
}

bool ScriptKeys::press(const QKeyEvent *e, int frameNum, const OnError &onError) {
  if (_onKey) {
    if (e->isAutoRepeat()) {
      if (_held.contains(e->key()))
        return true;
    } else {
      bool consumed = false;
      try {
        luabind::object r = luabind::call_function<luabind::object>(
            _onKey, frameNum, luaKeyName(e), true);
        consumed = r && luabind::type(r) == LUA_TBOOLEAN &&
                   luabind::object_cast<bool>(r);
      } catch (const std::exception &ex) {
        onError(ex, "onKey()");
      }
      if (consumed) {
        _held.insert(e->key());
        return true;
      }
    }
  }

  int keyInt = e->key();
  Qt::Key key = static_cast<Qt::Key>(keyInt);

  if (key == Qt::Key_unknown) {
    qDebug() << "Unknown key from a macro probably";
    return true;
  }

  // the user have clicked just and only the special keys Ctrl, Shift, Alt,
  // Meta.
  if (key == Qt::Key_Control || key == Qt::Key_Shift || key == Qt::Key_Alt ||
      key == Qt::Key_Meta) {
    // qDebug() << "Single click of special key: Ctrl, Shift, Alt or Meta";
    // qDebug() << "New KeySequence:" <<
    // QKeySequence(keyInt).toString(QKeySequence::NativeText); return;
  }

  // check for a combination of user clicks
  Qt::KeyboardModifiers modifiers = e->modifiers();
  QString keyText = e->text();
  // if the keyText is empty than it's a special key like F1, F5, ...
  //  qDebug() << "Pressed Key:" << keyText;

  QList<Qt::Key> modifiersList;
  if (modifiers & Qt::ShiftModifier)
    keyInt += Qt::SHIFT;
  if (modifiers & Qt::ControlModifier)
    keyInt += Qt::CTRL;
  if (modifiers & Qt::AltModifier)
    keyInt += Qt::ALT;
  if (modifiers & Qt::MetaModifier)
    keyInt += Qt::META;

  QString seq = QKeySequence(keyInt).toString(QKeySequence::NativeText);
  // qDebug() << "KeySequence:" << seq;

  if (_shortcuts.contains(seq)) {
    try {
      luabind::call_function<void>(*_shortcuts.value(seq), frameNum);
    } catch (const std::exception &e) {
      onError(e, "onShortcut()");
    }

    return true; // skip built in command if overridden by shortcut
  }

  return false;
}

void ScriptKeys::release(const QKeyEvent *e, int frameNum, const OnError &onError) {
  if (!e->isAutoRepeat() && _onKey) {
    _held.remove(e->key());
    try {
      luabind::call_function<void>(_onKey, frameNum, luaKeyName(e), false);
    } catch (const std::exception &ex) {
      onError(ex, "onKey()");
    }
  }
}
