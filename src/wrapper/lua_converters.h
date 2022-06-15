#ifndef LUA_CONVERTERS_H
#define LUA_CONVERTERS_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QString>
#include <QStringList>
#include <QList>
#include <QVector>
#include <QByteArray>
#include <QVariant>

Q_DECLARE_METATYPE(luabind::object)

struct QVariant_wrapper{
    QVariant variant()const{ return m_var;}
    void setVariant(const QVariant& var){ m_var = var;}
private:
    QVariant m_var;
};
template<typename T>bool is_class(const luabind::object& obj);
//  leave the function body empty,this will cause a compile error when type no defined in lua_qobject.cpp
//{ return false;}

QVariant var_from(lua_State* L, int index);
void var_to(lua_State* L, QVariant const& v);
std::string fromQString(const QString& str);

namespace luabind
{
template <>
struct default_converter<QString>
        : native_converter_base<QString>
{
    static int compute_score(lua_State* L, int index) {
        return lua_type(L, index) == LUA_TSTRING ? 0 : -1;
    }

    QString from(lua_State* L, int index) {
        return QString(lua_tostring(L, index));
    }

    void to(lua_State* L, QString const& x) {
        lua_pushstring(L, x.toUtf8());
    }
};

template <>
struct default_converter<QString const&>
        : default_converter<QString>
{};

template <>
struct default_converter<QStringList>
        : native_converter_base<QStringList>
{
    static int compute_score(lua_State* L, int index)
    {
        return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
    }

    QStringList from(lua_State* L, int index)
    {
        object obj(luabind::from_stack(L,index));
        QStringList arr;
        for(iterator i(obj),e; i!=e; ++i){
            QString v = 0;
            if(type(*i) == LUA_TSTRING){
                v = object_cast<QString>(*i);
                arr.append(v);
            }
        }
        return arr;
    }

    void to(lua_State* L, QStringList const& arr)
    {
        object obj = luabind::newtable(L);
        for(int i=0;i<arr.length();i++){
            obj[i+1] = arr.at(i).toStdString().c_str();
        }
        obj.push(L);
    }
};

template <>
struct default_converter<QStringList const&>
        : default_converter<QStringList>
{};


template <typename T>
struct default_converter<QList<T> >
        : native_converter_base<QList<T> >
{
    static int compute_score(lua_State* L, int index)
    {
        return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
    }

    QList<T> from(lua_State* L, int index)
    {
        object obj(luabind::from_stack(L,index));
        QList<T> arr;
        for(iterator i(obj),e; i!=e; ++i){
            if(is_class<T>(*i)){
                arr.append(object_cast<T>(*i));
            }
        }
        return arr;
    }

    void to(lua_State* L, QList<T> const& arr)
    {
        object obj = luabind::newtable(L);
        for(int i=0;i<arr.length();i++){
            obj[i+1] = arr.at(i);
        }
        obj.push(L);
    }
};

template <typename T>
struct default_converter<QList<T> const&>
        : default_converter<QList<T> >
{};

template <typename T>
struct default_converter<QList< QList<T> > >
        : native_converter_base<QList< QList<T> > >
{
    static int compute_score(lua_State* L, int index)
    {
        return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
    }

    QList< QList<T> > from(lua_State* L, int index)
    {
        object obj(luabind::from_stack(L,index));
        QList< QList<T> > arr;
        for(iterator i(obj),e; i!=e; ++i){
            QList<T> xx;
            for(iterator i2(*i),e2; i2 != e2; ++i2){
                if(is_class<T>(*i2)){
                    xx.append(object_cast<T>(*i2));
                }
            }
            arr.append(xx);
        }
        return arr;
    }
    void to(lua_State* L, QList< QList<T> > const& arr)
    {
        object obj = luabind::newtable(L);
        for(int i=0;i<arr.length();i++){
            const QList<T>& x = arr.at(i);
            object t = luabind::newtable(L);
            for(int j=0;j<x.length();j++){
                t[j+1] = x.at(j);
            }
            obj[i+1] = t;
        }
        obj.push(L);
    }
};

template <typename T>
struct default_converter<QList< QList<T> > const&>
        : default_converter<QList< QList<T> > >
{};

template <typename T>
struct default_converter<QVector<T> >
        : native_converter_base<QVector<T> >
{
    static int compute_score(lua_State* L, int index)
    {
        return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
    }

    QVector<T> from(lua_State* L, int index)
    {
        object obj(luabind::from_stack(L,index));
        QVector<T> arr;
        for(iterator i(obj),e; i!=e; ++i){
            if(is_class<T>(*i)){
                arr.append(object_cast<T>(*i));
            }
        }
        return arr;
    }

    void to(lua_State* L, QVector<T> const& arr)
    {
        object obj = luabind::newtable(L);
        for(int i=0;i<arr.count();i++){
            obj[i+1] = arr.at(i);
        }
        obj.push(L);
    }
};

template <typename T>
struct default_converter<QVector<T> const&>
        : default_converter<QVector<T> >
{};


template <>
struct default_converter<QByteArray>
        : native_converter_base<QByteArray>
{
    static int compute_score(lua_State* L, int index)
    {
        return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
    }

    QByteArray from(lua_State* L, int index)
    {
        object obj(luabind::from_stack(L,index));
        QByteArray arr;
        for(iterator i(obj),e; i!=e; ++i){
            int v = 0;
            if(type(*i) == LUA_TNUMBER){
                v = object_cast<int>(*i);
            }
            arr.append((char)v);
        }
        return arr;
    }

    void to(lua_State* L, QByteArray const& arr)
    {
        object obj = luabind::newtable(L);
        for(int i=0;i<arr.length();i++){
            obj[i+1] = (int)arr.at(i);
        }
        obj.push(L);
    }
};

template <>
struct default_converter<QByteArray const&>
        : default_converter<QByteArray>
{};

template <>
struct default_converter<QVariant>
        : native_converter_base<QVariant>
{
    static int compute_score(lua_State* L, int index)
    {
        lua_type(L, index);
        return 0;
    }

    QVariant from(lua_State* L, int index)
    {
        return var_from(L,index);
    }

    void to(lua_State* L, QVariant const& v)
    {
        var_to(L,v);
    }
};

template <>
struct default_converter<QVariant const&>
        : default_converter<QVariant>
{};

#define QT_ENUM_CONVERTER(T)        \
    template <>\
    struct default_converter<T>\
    : native_converter_base<T>\
{\
    static int compute_score(lua_State* L, int index)\
{\
    return lua_type(L, index) == LUA_TNUMBER ? 0 : -1;\
}\
    \
    T from(lua_State* L, int index)\
{\
    int x = lua_tonumber(L,index);\
    return T(x);\
}\
    \
    void to(lua_State* L, T x)\
{\
    lua_pushnumber(L, x);\
}\
};

QT_ENUM_CONVERTER(qint64)
}

#endif // LUA_CONVERTERS_H
