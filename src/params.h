#ifndef PARAMS_H
#define PARAMS_H

#include <QHash>
#include <QList>
#include <QPair>
#include <QString>
#include <QVariant>

#include <exception>
#include <functional>

#include <LinearMath/btScalar.h>
#include <luabind/object.hpp>

struct lua_State;

/**
 * @brief A script parameter and everything the GUI needs to present it.
 *
 * Scripts register parameters with Viewer::addParam(); the Gui turns each one
 * into a slider, a check box, an editable cell or a push button, depending on
 * what is known about it here.
 */
struct ParamInfo {
  QVariant value;        ///< The value the parameter was last given.
  btScalar min = 0.0;    ///< Lower bound; only meaningful if #hasRange.
  btScalar max = 100.0;  ///< Upper bound; only meaningful if #hasRange.
  btScalar step = 0.0;   ///< Step size for the slider; 0 means pick a default.
  QString comment;       ///< Description shown in the parameter's tooltip.
  bool hasRange = false; ///< True if the script declared a min and max, which
                         ///< is what makes the parameter a slider.
  bool isButton = false; ///< True if the parameter is a push button: pressing
                         ///< it calls #buttonCallback instead of editing a value.
  luabind::object buttonCallback; ///< The Lua function invoked when the button
                                  ///< is pressed; only meaningful if #isButton.
  bool isButtonGroup = false; ///< True if the parameter is one row of several
                              ///< push buttons: pressing one calls its entry in
                              ///< #buttonCallbacks instead of editing a value.
  QList<QPair<QString, luabind::object>> buttonCallbacks; ///< (label, callback)
                                                          ///< for each button in
                                                          ///< the row; only
                                                          ///< meaningful if
                                                          ///< #isButtonGroup.
};

/**
 * @brief A script's parameters (v:addParam): their values, what the Params
 * pane needs to show each, which it shows (v:showParams), and the
 * onParamChanged hook.
 *
 * A value parameter is mirrored into a Lua global of its name, which
 * get() reads back, so a script that sets the global sets the parameter;
 * the hook hears of each value parameter given. A push button or a row of
 * them holds functions instead, called by press().
 */
class Params {
public:
  /// Shows an error a script's function raised, saying where it was.
  using OnError = std::function<void(const std::exception &, const QString &)>;

  /** @brief Sets the onParamChanged hook (anything but a function: ignored). */
  void setOnChanged(const luabind::object &fn);

  /**
   * @brief Adds a parameter, or gives one a new value. A Lua function makes
   * a push button, a table of functions a row of them; anything else is a
   * value, mirrored into the global @p name and passed to the hook.
   * @param L        The script's Lua state (null: none yet).
   * @param frameNum The frame, passed to the hook.
   * @param name     The parameter's name.
   * @param value    Its value.
   * @param comment  Its description, the pane's tooltip.
   * @param onError  Shows an error the hook raised.
   */
  void add(lua_State *L, int frameNum, const QString &name, const QVariant &value,
           const QString &comment, const OnError &onError);

  /**
   * @brief Adds a number with a range, a slider in the pane, or gives it a
   * new value; mirrored into the global @p name and passed to the hook.
   * @param step The slider's step; 0 picks one.
   * (The other parameters as add().)
   */
  void addRange(lua_State *L, int frameNum, const QString &name, const btScalar &value,
                const btScalar &min, const btScalar &max, const btScalar &step,
                const QString &comment, const OnError &onError);

  /**
   * @brief Presses a push button: calls its function (for a row, the one
   * labelled @p label). Anything else, or an unknown label, does nothing.
   */
  void press(lua_State *L, const QString &name, const QString &label, const OnError &onError);

  /** @brief What the pane needs to show a parameter (a default if unknown). */
  ParamInfo info(const QString &name) const;

  /**
   * @brief A parameter's value: its Lua global if that holds a number,
   * string or boolean (the script may have set it), else the value given.
   */
  QVariant get(lua_State *L, const QString &name) const;

  /** @brief Every parameter's value, buttons too. */
  QHash<QString, QVariant> all() const { return _values; }

  /**
   * @brief Shows only the parameters whose names start with @p prefix (all,
   * for an empty one).
   * @return True if that changed what's shown.
   */
  bool show(const QString &prefix);

  /** @brief The parameters the pane shows (see show()). */
  QHash<QString, QVariant> shown() const;

  /**
   * @brief Forgets every parameter, their ranges and the filter (a script
   * is replaced).
   */
  void clear();

  /**
   * @brief Drops the hook and every function the parameters hold, while
   * the script's Lua state is still open: their references are released
   * against it.
   */
  void releaseLua();

private:
  QHash<QString, QVariant> _values;    ///< Current value of each parameter.
  QHash<QString, ParamInfo> _info;     ///< Range, step and comment for each.
  QString _filter;                     ///< Which the Params pane shows (see show()).
  luabind::object _onChanged;          ///< Called when a parameter changes.
};

#endif // PARAMS_H
