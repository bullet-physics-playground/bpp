#ifndef SCRIPTKEYS_H
#define SCRIPTKEYS_H

#include <QHash>
#include <QSet>
#include <QString>

#include <exception>
#include <functional>
#include <memory>

#include <luabind/object.hpp>

class QKeyEvent;

/**
 * @brief The keys a script handles: its v:onKey(function(N, key, down) ...
 * end) hook and its v:addShortcut(keys, function(N) ... end) shortcuts.
 *
 * A key goes to the hook first; if the hook returns true the key is the
 * script's, and so are its auto-repeats while it's held. Otherwise a
 * shortcut for the key, with its modifiers, runs instead of bpp's own key.
 */
class ScriptKeys {
public:
  /// Shows an error a hook raised, with the hook's name.
  using OnError = std::function<void(const std::exception &, const char *)>;

  /** @brief Sets the onKey hook (anything but a Lua function is ignored). */
  void setOnKey(const luabind::object &fn);

  /** @brief Binds a Lua function to a key sequence, as Qt writes it. */
  void addShortcut(const QString &keys, const luabind::object &fn);

  /** @brief Unbinds a key sequence. */
  void removeShortcut(const QString &keys);

  /**
   * @brief Drops the hook, the held keys and the shortcuts (a script ends).
   * Must run while the Lua state is still open: the functions held are
   * released against it.
   */
  void clear();

  /**
   * @brief A key pressed.
   * @return True if it was the script's (bpp's own key doesn't run).
   */
  bool press(const QKeyEvent *e, int frameNum, const OnError &onError);

  /** @brief A key released: the hook hears of it. */
  void release(const QKeyEvent *e, int frameNum, const OnError &onError);

private:
  luabind::object _onKey;  ///< Called for each key press and release.
  QSet<int> _held;         ///< Keys the onKey() hook consumed on press.
  QHash<QString, std::shared_ptr<luabind::object>> _shortcuts; ///< Lua
                          ///< functions bound to key sequences, keyed by the
                          ///< sequence's native text form.
};

#endif // SCRIPTKEYS_H
