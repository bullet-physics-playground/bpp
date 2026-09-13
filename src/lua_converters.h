#ifndef LUA_CONVERTERS_H
#define LUA_CONVERTERS_H

/**
 * @file lua_converters.h
 * @brief Luabind default_converter specializations for the Qt value types.
 *
 * Luabind consults @c luabind::default_converter<T> whenever it has to move a
 * @c T across the C++/Lua boundary, so specializing it here is what lets a
 * bound function simply take or return a QString, a QStringList, a QList, a
 * QVector, a QByteArray or a QVariant and have it appear on the Lua side as a
 * plain string or table.
 *
 * Every specialization follows the same shape:
 * - @c compute_score() tells luabind how well a value on the stack matches the
 *   type, returning 0 for a match and -1 for no match, which is how overload
 *   resolution picks between candidates;
 * - @c from() pulls a value off the Lua stack and builds the Qt type;
 * - @c to() pushes a Qt value onto the Lua stack.
 *
 * Sequence types map to Lua tables indexed from 1, following Lua's own
 * convention. Each specialization is paired with one for @c const& so that
 * both by-value and by-reference signatures are accepted.
 */

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QByteArray>
#include <QList>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QVector>

Q_DECLARE_METATYPE(luabind::object)

/**
 * @brief Holds a QVariant so it can be handed around as a bound class.
 *
 * A QVariant has no Lua identity of its own; wrapping it in a plain struct
 * gives luabind something concrete to attach to.
 */
struct QVariant_wrapper {
  /**
   * @brief Returns the wrapped value.
   * @return The stored QVariant.
   */
  QVariant variant() const { return m_var; }

  /**
   * @brief Replaces the wrapped value.
   * @param var The value to store.
   */
  void setVariant(const QVariant &var) { m_var = var; }

private:
  QVariant m_var; ///< The wrapped value.
};

/**
 * @brief Tests whether a Lua object holds an instance of a bound class @c T.
 *
 * Declared without a definition on purpose: the generic template is never
 * meant to be instantiated, so using one of the QList, QVector or nested QList
 * converters with a type that has no explicit specialization of this function
 * fails to build rather than silently misbehaving.
 *
 * @tparam T The bound class to test for.
 * @param obj The Lua object to inspect.
 * @return True if @p obj holds a @c T.
 */
template <typename T> bool is_class(const luabind::object &obj);
//  leave the function body empty,this will cause a compile error when type no
//  defined in lua_qobject.cpp
//{ return false;}

/**
 * @brief Converts the Lua value at a stack index into a QVariant.
 *
 * Maps the Lua types onto their natural QVariant counterparts: nil to an
 * invalid variant, booleans, numbers and strings to the matching types, and
 * anything else to a variant holding the luabind::object itself.
 *
 * @param L     The Lua state.
 * @param index Stack index of the value to read.
 * @return The converted value.
 */
QVariant var_from(lua_State *L, int index);

/**
 * @brief Pushes a QVariant onto the Lua stack.
 *
 * The inverse of var_from(): an invalid variant becomes nil, the primitive
 * types become their Lua equivalents, and a variant carrying a
 * luabind::object pushes that object back.
 *
 * @param L The Lua state.
 * @param v The value to push.
 */
void var_to(lua_State *L, QVariant const &v);

/**
 * @brief Converts a QString to a std::string.
 *
 * Declared for use by binding code that needs a std::string; there is no
 * definition in this project.
 *
 * @param str The string to convert.
 * @return The same text as a std::string.
 */
std::string fromQString(const QString &str);

namespace luabind {
/**
 * @brief Converts between QString and a Lua string.
 */
template <> struct default_converter<QString> : native_converter_base<QString> {
  /**
   * @brief Scores a stack value as a QString candidate.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return 0 if the value is a Lua string, -1 otherwise.
   */
  static int compute_score(lua_State *L, int index) {
    return lua_type(L, index) == LUA_TSTRING ? 0 : -1;
  }

  /**
   * @brief Reads a Lua string off the stack.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return The value as a QString.
   */
  QString from(lua_State *L, int index) {
    return QString(lua_tostring(L, index));
  }

  /**
   * @brief Pushes a QString as a UTF-8 Lua string.
   * @param L The Lua state.
   * @param x The string to push.
   */
  void to(lua_State *L, QString const &x) { lua_pushstring(L, x.toUtf8()); }
};

/// Lets a @c const @c QString& parameter use the QString converter.
template <>
struct default_converter<QString const &> : default_converter<QString> {};

/**
 * @brief Converts between QStringList and a Lua table of strings.
 */
template <>
struct default_converter<QStringList> : native_converter_base<QStringList> {
  /**
   * @brief Scores a stack value as a QStringList candidate.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return 0 if the value is a Lua table, -1 otherwise.
   */
  static int compute_score(lua_State *L, int index) {
    return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
  }

  /**
   * @brief Builds a QStringList from a Lua table.
   *
   * Entries that are not strings are skipped rather than converted.
   *
   * @param L     The Lua state.
   * @param index Stack index of the table.
   * @return The string entries, in iteration order.
   */
  QStringList from(lua_State *L, int index) {
    object obj(luabind::from_stack(L, index));
    QStringList arr;
    for (iterator i(obj), e; i != e; ++i) {
      QString v = 0;
      if (type(*i) == LUA_TSTRING) {
        v = object_cast<QString>(*i);
        arr.append(v);
      }
    }
    return arr;
  }

  /**
   * @brief Pushes a QStringList as a Lua table indexed from 1.
   * @param L   The Lua state.
   * @param arr The strings to push.
   */
  void to(lua_State *L, QStringList const &arr) {
    object obj = luabind::newtable(L);
    for (int i = 0; i < arr.length(); i++) {
      obj[i + 1] = arr.at(i).toStdString().c_str();
    }
    obj.push(L);
  }
};

/// Lets a @c const @c QStringList& parameter use the QStringList converter.
template <>
struct default_converter<QStringList const &> : default_converter<QStringList> {
};

/**
 * @brief Converts between QList<T> and a Lua table of bound objects.
 * @tparam T Element type; it needs an explicit is_class() specialization.
 */
template <typename T>
struct default_converter<QList<T>> : native_converter_base<QList<T>> {
  /**
   * @brief Scores a stack value as a QList candidate.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return 0 if the value is a Lua table, -1 otherwise.
   */
  static int compute_score(lua_State *L, int index) {
    return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
  }

  /**
   * @brief Builds a QList from a Lua table.
   *
   * Entries that do not hold a @c T are skipped.
   *
   * @param L     The Lua state.
   * @param index Stack index of the table.
   * @return The matching entries, in iteration order.
   */
  QList<T> from(lua_State *L, int index) {
    object obj(luabind::from_stack(L, index));
    QList<T> arr;
    for (iterator i(obj), e; i != e; ++i) {
      if (is_class<T>(*i)) {
        arr.append(object_cast<T>(*i));
      }
    }
    return arr;
  }

  /**
   * @brief Pushes a QList as a Lua table indexed from 1.
   * @param L   The Lua state.
   * @param arr The elements to push.
   */
  void to(lua_State *L, QList<T> const &arr) {
    object obj = luabind::newtable(L);
    for (int i = 0; i < arr.length(); i++) {
      obj[i + 1] = arr.at(i);
    }
    obj.push(L);
  }
};

/// Lets a @c const @c QList<T>& parameter use the QList converter.
template <typename T>
struct default_converter<QList<T> const &> : default_converter<QList<T>> {};

/**
 * @brief Converts between QList<QList<T>> and a Lua table of tables.
 * @tparam T Innermost element type; it needs an is_class() specialization.
 */
template <typename T>
struct default_converter<QList<QList<T>>>
    : native_converter_base<QList<QList<T>>> {
  /**
   * @brief Scores a stack value as a nested QList candidate.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return 0 if the value is a Lua table, -1 otherwise.
   */
  static int compute_score(lua_State *L, int index) {
    return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
  }

  /**
   * @brief Builds a list of lists from a Lua table of tables.
   *
   * Inner entries that do not hold a @c T are skipped; every outer entry
   * produces a list, even an empty one.
   *
   * @param L     The Lua state.
   * @param index Stack index of the outer table.
   * @return The nested lists, in iteration order.
   */
  QList<QList<T>> from(lua_State *L, int index) {
    object obj(luabind::from_stack(L, index));
    QList<QList<T>> arr;
    for (iterator i(obj), e; i != e; ++i) {
      QList<T> xx;
      for (iterator i2(*i), e2; i2 != e2; ++i2) {
        if (is_class<T>(*i2)) {
          xx.append(object_cast<T>(*i2));
        }
      }
      arr.append(xx);
    }
    return arr;
  }

  /**
   * @brief Pushes a list of lists as a Lua table of tables, indexed from 1.
   * @param L   The Lua state.
   * @param arr The nested lists to push.
   */
  void to(lua_State *L, QList<QList<T>> const &arr) {
    object obj = luabind::newtable(L);
    for (int i = 0; i < arr.length(); i++) {
      const QList<T> &x = arr.at(i);
      object t = luabind::newtable(L);
      for (int j = 0; j < x.length(); j++) {
        t[j + 1] = x.at(j);
      }
      obj[i + 1] = t;
    }
    obj.push(L);
  }
};

/// Lets a @c const @c QList<QList<T>>& parameter use the nested converter.
template <typename T>
struct default_converter<QList<QList<T>> const &>
    : default_converter<QList<QList<T>>> {};

/**
 * @brief Converts between QVector<T> and a Lua table of bound objects.
 * @tparam T Element type; it needs an explicit is_class() specialization.
 */
template <typename T>
struct default_converter<QVector<T>> : native_converter_base<QVector<T>> {
  /**
   * @brief Scores a stack value as a QVector candidate.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return 0 if the value is a Lua table, -1 otherwise.
   */
  static int compute_score(lua_State *L, int index) {
    return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
  }

  /**
   * @brief Builds a QVector from a Lua table.
   *
   * Entries that do not hold a @c T are skipped.
   *
   * @param L     The Lua state.
   * @param index Stack index of the table.
   * @return The matching entries, in iteration order.
   */
  QVector<T> from(lua_State *L, int index) {
    object obj(luabind::from_stack(L, index));
    QVector<T> arr;
    for (iterator i(obj), e; i != e; ++i) {
      if (is_class<T>(*i)) {
        arr.append(object_cast<T>(*i));
      }
    }
    return arr;
  }

  /**
   * @brief Pushes a QVector as a Lua table indexed from 1.
   * @param L   The Lua state.
   * @param arr The elements to push.
   */
  void to(lua_State *L, QVector<T> const &arr) {
    object obj = luabind::newtable(L);
    for (int i = 0; i < arr.count(); i++) {
      obj[i + 1] = arr.at(i);
    }
    obj.push(L);
  }
};

/// Lets a @c const @c QVector<T>& parameter use the QVector converter.
template <typename T>
struct default_converter<QVector<T> const &> : default_converter<QVector<T>> {};

/**
 * @brief Converts between QByteArray and a Lua table of byte values.
 *
 * The bytes are carried as numbers rather than as a Lua string, so binary data
 * containing embedded zeros survives the round trip.
 */
template <>
struct default_converter<QByteArray> : native_converter_base<QByteArray> {
  /**
   * @brief Scores a stack value as a QByteArray candidate.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return 0 if the value is a Lua table, -1 otherwise.
   */
  static int compute_score(lua_State *L, int index) {
    return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
  }

  /**
   * @brief Builds a QByteArray from a Lua table of numbers.
   *
   * Entries that are not numbers contribute a zero byte, so the length of the
   * result always matches the length of the table.
   *
   * @param L     The Lua state.
   * @param index Stack index of the table.
   * @return The bytes, truncated to @c char.
   */
  QByteArray from(lua_State *L, int index) {
    object obj(luabind::from_stack(L, index));
    QByteArray arr;
    for (iterator i(obj), e; i != e; ++i) {
      int v = 0;
      if (type(*i) == LUA_TNUMBER) {
        v = object_cast<int>(*i);
      }
      arr.append((char)v);
    }
    return arr;
  }

  /**
   * @brief Pushes a QByteArray as a Lua table of numbers, indexed from 1.
   * @param L   The Lua state.
   * @param arr The bytes to push.
   */
  void to(lua_State *L, QByteArray const &arr) {
    object obj = luabind::newtable(L);
    for (int i = 0; i < arr.length(); i++) {
      obj[i + 1] = (int)arr.at(i);
    }
    obj.push(L);
  }
};

/// Lets a @c const @c QByteArray& parameter use the QByteArray converter.
template <>
struct default_converter<QByteArray const &> : default_converter<QByteArray> {};

/**
 * @brief Converts between QVariant and any Lua value.
 *
 * Delegates to var_from() and var_to(), which decide the mapping from the
 * actual Lua type at hand.
 */
template <>
struct default_converter<QVariant> : native_converter_base<QVariant> {
  /**
   * @brief Scores a stack value as a QVariant candidate.
   *
   * A QVariant accepts anything, so this always matches.
   *
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return Always 0.
   */
  static int compute_score(lua_State *L, int index) {
    lua_type(L, index);
    return 0;
  }

  /**
   * @brief Reads any Lua value into a QVariant.
   * @param L     The Lua state.
   * @param index Stack index of the value.
   * @return The converted value.
   */
  QVariant from(lua_State *L, int index) { return var_from(L, index); }

  /**
   * @brief Pushes a QVariant as the matching Lua value.
   * @param L The Lua state.
   * @param v The value to push.
   */
  void to(lua_State *L, QVariant const &v) { var_to(L, v); }
};

/// Lets a @c const @c QVariant& parameter use the QVariant converter.
template <>
struct default_converter<QVariant const &> : default_converter<QVariant> {};

/**
 * @brief Defines a converter that carries an integer-like type as a Lua number.
 *
 * Generates a default_converter specialization for @p T whose @c compute_score
 * accepts Lua numbers, whose @c from truncates the number and casts it to
 * @p T, and whose @c to pushes it back as a number. Intended for the Qt enum
 * and fixed-width integer types, which have no Lua counterpart of their own.
 *
 * @param T The type to generate a converter for.
 */
#define QT_ENUM_CONVERTER(T)                                                   \
  template <> struct default_converter<T> : native_converter_base<T> {         \
    static int compute_score(lua_State *L, int index) {                        \
      return lua_type(L, index) == LUA_TNUMBER ? 0 : -1;                       \
    }                                                                          \
                                                                               \
    T from(lua_State *L, int index) {                                          \
      int x = lua_tonumber(L, index);                                          \
      return T(x);                                                             \
    }                                                                          \
                                                                               \
    void to(lua_State *L, T x) { lua_pushnumber(L, x); }                       \
  };

QT_ENUM_CONVERTER(qint64)
} // namespace luabind

#endif // LUA_CONVERTERS_H
