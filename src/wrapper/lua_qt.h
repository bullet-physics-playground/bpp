#ifndef LUA_QT_WRAPPER_HPP
#define LUA_QT_WRAPPER_HPP

#include <QtGui>

#include "lua.hpp"

#include <luabind/luabind.hpp>

#include "boost/function.hpp"
#include "boost/type_traits/is_enum.hpp"
#include "luabind/detail/constructor.hpp"

#include "lua_converters.h"

using namespace luabind;
QWidget *lqwidget_init(QWidget *widget, const object &init_table);

bool obj_name_is(const object &obj, const char *name);

template <class T> QList<T> list_cast(const object &obj) {
  QList<T> list;
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      if (is_class<T>(*i)) {
        list.append(object_cast<T>(*i));
      }
    }
  }
  return list;
}

template <class T> object list_table(lua_State *L, const QList<T> &list) {
  object obj(luabind::newtable(L));
  for (int i = 0; i < list.count(); i++) {
    obj[i + 1] = list.at(i);
  }
  return obj;
}

/*
   cast a object to the member function param 1 type, if fail, return false
  */
template <class BT, class PFN>
bool q_cast(const object &obj, PFN(BT::*pfn), BT *m) {
  try {
    typedef typename boost::function_traits<PFN>::arg1_type T;
    typedef typename boost::remove_reference<T>::type T1;
    typedef typename boost::remove_const<T1>::type T2;
    if (!is_class<T2>(obj))
      return false;
    T2 t = object_cast<T2>(obj);
    (m->*pfn)(t);
    return true;
  } catch (...) {
  }
  return false;
}

template <class BT, class PFN, int n, class P1>
bool q_cast(const object &obj, PFN(BT::*pfn), BT *m, boost::arg<n>, P1 p1) {
  try {
    typedef typename boost::function_traits<PFN>::arg1_type T;
    typedef typename boost::remove_reference<T>::type T1;
    typedef typename boost::remove_const<T1>::type T2;
    if (!is_class<T2>(obj))
      return false;
    T2 t = object_cast<T2>(obj);
    (m->*pfn)(t, p1);
    return true;
  } catch (...) {
  }
  return false;
}

template <class BT, class PFN, int n, class P1>
bool q_cast(const object &obj, PFN(BT::*pfn), BT *m, P1 p1, boost::arg<n>) {
  try {
    typedef typename boost::function_traits<PFN>::arg2_type T;
    typedef typename boost::remove_reference<T>::type T1;
    typedef typename boost::remove_const<T1>::type T2;
    if (!is_class<T2>(obj))
      return false;
    T2 t = object_cast<T2>(obj);
    (m->*pfn)(p1, t);
    return true;
  } catch (...) {
  }
  return false;
}

/* constructor of classes
 */
template <typename T> T *construct(const argument &arg) {
  luabind::detail::construct<T, std::auto_ptr<T>,
                             typename constructor<>::signature>()(arg);
  return object_cast<T *>(arg);
}

template <typename T, typename T1> T *construct(const argument &arg, T1 t1) {
  luabind::detail::construct<T, std::auto_ptr<T>,
                             typename constructor<T1>::signature>()(arg, t1);
  return object_cast<T *>(arg);
}

template <typename T, typename T1, typename T2>
T *construct(const argument &arg, T1 t1, T2 t2) {
  luabind::detail::construct<T, std::auto_ptr<T>,
                             typename constructor<T1, T2>::signature>()(arg, t1,
                                                                        t2);
  return object_cast<T *>(arg);
}

template <typename T, typename T1, typename T2, typename T3>
T *construct(const argument &arg, T1 t1, T2 t2, T3 t3) {
  luabind::detail::construct<T, std::auto_ptr<T>,
                             typename constructor<T1, T2, T3>::signature>()(
      arg, t1, t2, t3);
  return object_cast<T *>(arg);
}

template <typename T, typename T1, typename T2, typename T3, typename T4>
T *construct(const argument &arg, T1 t1, T2 t2, T3 t3, T4 t4) {
  luabind::detail::construct<T, std::auto_ptr<T>,
                             typename constructor<T1, T2, T3, T4>::signature>()(
      arg, t1, t2, t3, t4);
  return object_cast<T *>(arg);
}

template <typename Type> struct LuaType {
  enum { v = 0 };
};
template <> struct LuaType<int> {
  enum { v = LUA_TNUMBER };
};
template <> struct LuaType<double> {
  enum { v = 21 };
};
template <> struct LuaType<const QString &> {
  enum { v = LUA_TSTRING };
};
template <> struct LuaType<bool> {
  enum { v = LUA_TBOOLEAN };
};
template <> struct LuaType<const object &> {
  enum { v = 777 };
};

template <typename T> struct ValueSetter {
  /*
  template<typename Tfn>
  ValueSetter(Tfn* pfn):arg_n(boost::function_traits<Tfn>::arity){
      memset(param,0,sizeof(param));
      my_test< boost::is_same<T*, typename
  boost::function_traits<Tfn>::arg1_type>::value >();
      my_test<boost::function_traits<Tfn>::arity==2>();
      boost::function<Tfn> p = pfn;
      param[0] = LuaType<typename boost::function_traits<Tfn>::arg2_type>::v;
      assign_pfn(p);
  }

  template<typename Tfn>
  ValueSetter(Tfn (T::*pfn) ):arg_n(boost::function_traits<Tfn>::arity+1){
      memset(param,0,sizeof(param));
      my_test<boost::function_traits<Tfn>::arity==1>();
      typedef typename boost::function_traits<Tfn>::result_type
  newTfn(T*,typename boost::function_traits<Tfn>::arg1_type);
      boost::function<newTfn> p = pfn;
      param[0] = LuaType<typename boost::function_traits<newTfn>::arg2_type>::v;
      assign_pfn(p);
  }
  */

  ValueSetter() : arg_n(0) {}

  template <typename R, typename T1> ValueSetter(R (T::*pfn)(T1)) : arg_n(2) {
    memset(param, 0, sizeof(param));
    boost::function<R(T *, T1)> p = pfn;
    param[0] = LuaType<T1>::v;
    assign_pfn(p);
  }

  template <typename R, typename T1> ValueSetter(R pfn(T *, T1)) : arg_n(2) {
    memset(param, 0, sizeof(param));
    boost::function<R(T *, T1)> p = pfn;
    param[0] = LuaType<T1>::v;
    assign_pfn(p);
  }

  void assign_pfn(boost::function<void(T *, int)> pfn) { fn_int = pfn; }
  void assign_pfn(boost::function<void(T *, const QString &)> pfn) {
    fn_string = pfn;
  }
  void assign_pfn(boost::function<void(T *, bool)> pfn) { fn_bool = pfn; }
  void assign_pfn(boost::function<void(T *, const QPoint &)> pfn) {
    fn_point = pfn;
  }
  void assign_pfn(boost::function<void(T *, const QSize &)> pfn) {
    fn_size = pfn;
  }
  void assign_pfn(boost::function<void(T *, const QRect &)> pfn) {
    fn_rect = pfn;
  }
  void assign_pfn(boost::function<void(T *, QLayout *)> pfn) {
    fn_layout = pfn;
  }
  void assign_pfn(boost::function<void(T *, const QMargins &)> pfn) {
    fn_margins = pfn;
  }
  void assign_pfn(boost::function<void(T *, const QColor &)> pfn) {
    fn_color = pfn;
  }
  void assign_pfn(boost::function<void(T *, const QBrush &)> pfn) {
    fn_brush = pfn;
  }
  void assign_pfn(boost::function<void(T *, const QFont &)> pfn) {
    fn_font = pfn;
  }
  void assign_pfn(boost::function<void(T *, const QIcon &)> pfn) {
    fn_icon = pfn;
  }
  void assign_pfn(boost::function<void(T *, const object &)> pfn) {
    fn_object = pfn;
  }
  void assign_pfn(boost::function<void(T *, double)> pfn) { fn_double = pfn; }

  void operator()(T *This, const object &obj) {
    switch (arg_n) {
    case 2:
      if (param[0] == 777) {
        fn_object(This, obj);
        break;
      }
      if (type(obj) == param[0]) {
        switch (param[0]) {
        case LUA_TNUMBER:
          fn_int(This, object_cast<int>(obj));
          break;
        case 21:
          fn_double(This, object_cast<double>(obj));
          break;
        case LUA_TSTRING:
          fn_string(This, object_cast<QString>(obj));
          break;
        case LUA_TBOOLEAN:
          fn_bool(This, object_cast<bool>(obj));
          break;
        default:
          break;
        }
      } else if (type(obj) == LUA_TUSERDATA) {
        // TODO
      }
      break;
    case 3:
      break;
    }
  }
  unsigned int arg_n;
  int param[4];
  boost::function<void(T *, int)> fn_int;
  boost::function<void(T *, const QString &)> fn_string;
  boost::function<void(T *, bool)> fn_bool;
  boost::function<void(T *, const QPoint &)> fn_point;
  boost::function<void(T *, const QSize &)> fn_size;
  boost::function<void(T *, const QRect &)> fn_rect;
  boost::function<void(T *, QLayout *)> fn_layout;
  boost::function<void(T *, const QMargins &)> fn_margins;
  boost::function<void(T *, const QColor &)> fn_color;
  boost::function<void(T *, const QBrush &)> fn_brush;
  boost::function<void(T *, const QFont &)> fn_font;
  boost::function<void(T *, const QIcon &)> fn_icon;
  boost::function<void(T *, const object &)> fn_object;
  boost::function<void(T *, double)> fn_double;
};

struct my_les {
  bool operator()(const QString &l, const QString &r) {
    return l.compare(r, Qt::CaseInsensitive) < 0;
  }
};

template <class T>
struct setter_map : public std::map<QString, ValueSetter<T>, my_les> {};

template <typename T>
T *lq_general_init(T *widget, const object &obj, setter_map<T> &set_map) {
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      if (type(i.key()) == LUA_TSTRING) {
        QString key = object_cast<QString>(i.key());
        if (set_map.find(key) != set_map.end()) {
          set_map[key](widget, *i);
        }
      }
    }
  }
  return widget;
}

template <typename T>
void table_init_general(const luabind::argument &arg, const object &obj);

template <class T, class X1 = detail::unspecified,
          class X2 = detail::unspecified, class X3 = detail::unspecified>
struct myclass_ : public class_<T, X1, X2, X3> {
  typedef std::map<QString, ValueSetter<T>, my_les> map_t;
  myclass_(const char *name, setter_map<T> &mp) : class_<T, X1, X2, X3>(name) {
    set_map = &mp;
  }
  myclass_(const char *name) : class_<T, X1, X2, X3>(name) { set_map = 0; }
  template <class T1> myclass_ &def(T1 t1) {
    class_<T, X1, X2, X3>::def(t1);
    return *this;
  }
  template <class T1, class T2> myclass_ &def(T1 t1, T2 t2) {
    class_<T, X1, X2, X3>::def(t1, t2);
    return *this;
  }
  template <class T1, class T2, class T3> myclass_ &def(T1 t1, T2 t2, T3 t3) {
    class_<T, X1, X2, X3>::def(t1, t2, t3);
    return *this;
  }
  template <class T1, class T2, class T3, class T4>
  myclass_ &def(T1 t1, T2 t2, T3 t3, T4 t4) {
    class_<T, X1, X2, X3>::def(t1, t2, t3, t4);
    return *this;
  }

  template <class B, class R>
  myclass_ &_property(const char *prop, R (B::*g)()) {
    class_<T, X1, X2, X3>::property(prop, g);
    return *this;
  }
  template <class B, class R>
  myclass_ &_property(const char *prop, R (B::*g)() const) {
    class_<T, X1, X2, X3>::property(prop, g);
    return *this;
  }
  template <class B, class R> myclass_ &_property(const char *prop, R g(B *)) {
    class_<T, X1, X2, X3>::property(prop, g);
    return *this;
  }

  template <class Getter> myclass_ &_property(const char *prop, Getter g) {
    class_<T, X1, X2, X3>::def(prop, g);
    return *this;
  }

  template <class B, class R, class Setter>
  myclass_ &_property(const char *prop, R (B::*g)(), Setter s) {
    if (set_map)
      (*set_map)[QString::fromLocal8Bit(prop)] = s;
    class_<T, X1, X2, X3>::property(prop, g, s);
    return *this;
  }

  template <class B, class R, class Setter>
  myclass_ &_property(const char *prop, R (B::*g)() const, Setter s) {
    if (set_map)
      (*set_map)[QString::fromLocal8Bit(prop)] = s;
    class_<T, X1, X2, X3>::property(prop, g, s);
    return *this;
  }

  template <class B, class R, class Setter>
  myclass_ &_property(const char *prop, R g(B *), Setter s) {
    if (set_map)
      (*set_map)[QString::fromLocal8Bit(prop)] = s;
    class_<T, X1, X2, X3>::property(prop, g, s);
    return *this;
  }

  template <class Getter, class Setter>
  myclass_ &_property(const char *prop, Getter g, Setter s) {
    static std::map<std::string, int> smp;
    class_<T, X1, X2, X3>::def(prop, g);
    std::string sp("set");
    sp += prop;
    sp[3] = ::toupper(sp[3]);
    smp[sp] = 1;
    class_<T, X1, X2, X3>::def(smp.find(sp)->first.c_str(), s);
    return *this;
  }

  template <class Getter> myclass_ &property(const char *prop, Getter g) {
    // class_<T,X1,X2,X3>::property(prop,g);
    _property(prop, g);
    return *this;
  }

  template <class Getter, class Setter>
  myclass_ &property(const char *prop, Getter g, Setter s) {
    // if(set_map)(*set_map)[QString::fromLocal8Bit(prop)] = s;
    // class_<T,X1,X2,X3>::property(prop,g,s);
    _property(prop, g, s);
    return *this;
  }
  template <class Getter, class Setter, class P1>
  myclass_ &property(const char *prop, Getter g, Setter s, const P1 &p1) {
    if (set_map)
      (*set_map)[QString::fromLocal8Bit(prop)] = s;
    class_<T, X1, X2, X3>::property(prop, g, s, p1);
    return *this;
  }
  template <class Getter, class Setter, class P1, class P2>
  myclass_ &property(const char *prop, Getter g, Setter s, const P1 &p1,
                     const P2 &p2) {
    if (set_map)
      (*set_map)[QString::fromLocal8Bit(prop)] = s;
    class_<T, X1, X2, X3>::property(prop, g, s, p1, p2);
    return *this;
  }
  setter_map<T> *set_map;
};

#define sig_prop(b, name) property(#name, b##_get_##name, b##_set_##name)

template <class B, class T>
inline void enum_filter_set_value(B *b, void (B::*fn)(T), int v) {
  (b->*fn)(T(v));
}
template <class B, class T>
inline int enum_filter_get_value(B *b, T (B::*fn)() const) {
  return (int)(b->*fn)();
}
template <class B, class T>
inline int enum_filter_get_value(B *b, T (B::*fn)()) {
  return (int)(b->*fn)();
}

#define ENUM_FILTER(base, getter, setter)                                      \
  static int base##_##getter(base *b) {                                        \
    return enum_filter_get_value(b, &base::getter);                            \
  }                                                                            \
  static void base##_##setter(base *b, int v) {                                \
    enum_filter_set_value(b, &base::setter, v);                                \
  }
#endif
