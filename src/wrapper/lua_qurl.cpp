#include "lua_qurl.h"

#include "lua_qslot.h"

static setter_map<QUrl> lqurl_set_map;

QUrl* lqurl_init(QUrl* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqurl_set_map);
}
template<>
void table_init_general<QUrl>(const luabind::argument & arg, const object& obj)
{
    lqurl_init(construct<QUrl>(arg), obj);
}

namespace luabind
{
    QT_EMUN_CONVERTER(QUrl::ParsingMode)
    QT_EMUN_CONVERTER(QUrl::FormattingOptions)
    QT_EMUN_CONVERTER(Qt::DropActions)
    QT_EMUN_CONVERTER(Qt::DropAction)
    QT_EMUN_CONVERTER(QRegExp::CaretMode)
    QT_EMUN_CONVERTER(QRegExp::PatternSyntax)

    QByteArray byteArrayFromObject(const object& obj){
        QByteArray arr;
        for(iterator i2(obj),e2; i2!=e2; ++i2){
            int v = 0;
            if(type(*i2) == LUA_TNUMBER){
                v = object_cast<int>(*i2);
            }
            arr.append((char)v);
        }
        return arr;
    }
    object byteArrayToObject(lua_State* L, const QByteArray& arr){
        object tb = luabind::newtable(L);
        for(int j=0;j<arr.length();j++){
            tb[j+1] = (int)arr.at(j);
        }
        return tb;
    }

    template<>
    struct default_converter<QList<QByteArray> >
      : native_converter_base<QList<QByteArray> >
    {
        static int compute_score(lua_State* L, int index)
        {
            return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
        }

        QList<QByteArray> from(lua_State* L, int index)
        {
            object obj(luabind::from_stack(L,index));
            QList<QByteArray> res;
            for(iterator i(obj),e; i!=e; ++i){
                if(type(*i) == LUA_TTABLE){
                    res.append(byteArrayFromObject(*i));
                }
            }
            return res;
        }

        void to(lua_State* L, QList<QByteArray> const& arr)
        {
            object obj = luabind::newtable(L);
            for(int i=0;i<arr.length();i++){
                obj[i+1] = byteArrayToObject(L,arr.at(i));
            }
            obj.push(L);
        }
    };

    template<>
    struct default_converter<QList<QByteArray> const&>
      : default_converter<QList<QByteArray> >
    {};


    template<>
    struct default_converter<QList<QPair<QByteArray, QByteArray> > >
      : native_converter_base<QList<QPair<QByteArray, QByteArray> > >
    {
        static int compute_score(lua_State* L, int index)
        {
            return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
        }

        QList<QPair<QByteArray, QByteArray> > from(lua_State* L, int index)
        {
            object obj(luabind::from_stack(L,index));
            QList<QPair<QByteArray, QByteArray> > res;
            for(iterator i(obj),e; i!=e; ++i){
                if(type(*i) == LUA_TTABLE){
                    object p1,p2;
                    QPair<QByteArray, QByteArray> arr;
                    for(iterator i2(*i),e2; i2!=e2; ++i2){
                        if(!p1) p1 = *i2;
                        else if(!p2) p2 = *i2;
                        else break;
                    }
                    if(p1 && p1 && type(p1) == LUA_TTABLE && type(p2) == LUA_TTABLE){
                        res.append(QPair<QByteArray, QByteArray>(byteArrayFromObject(p1),byteArrayFromObject(p2)));
                    }
                }
            }
            return res;
        }

        void to(lua_State* L, QList<QPair<QByteArray, QByteArray> > const& arr)
        {
            object obj = luabind::newtable(L);
            for(int i=0;i<arr.length();i++){
                object p1 = byteArrayToObject(L, arr.at(i).first);
                object p2 = byteArrayToObject(L, arr.at(i).second);
                object t = luabind::newtable(L);
                t[1] = p1;
                t[2] = p2;
                obj[i+1] = t;
            }
            obj.push(L);
        }
    };

    template<>
    struct default_converter<QList<QPair<QByteArray, QByteArray> > const&>
      : default_converter<QList<QPair<QByteArray, QByteArray> > >
    {};

    template<typename T>
    T __getValue(const T& t) {return(t);}

    const char* __getValue(const QString& t) { return t.toLocal8Bit().constData(); }


    template <typename T1, typename T2>
    struct default_converter<QList<QPair<T1, T2> > >
      : native_converter_base<QList<QPair<T1, T2> > >
    {
        static int compute_score(lua_State* L, int index)
        {
            return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
        }

        QList<QPair<T1, T2> > from(lua_State* L, int index)
        {
            object obj(luabind::from_stack(L,index));
            QList<QPair<T1, T2> > res;
            for(iterator i(obj),e; i!=e; ++i){
                if(type(*i) == LUA_TTABLE){
                    object p1,p2;
                    QPair<T1, T2> arr;
                    for(iterator i2(*i),e2; i2!=e2; ++i2){
                        if(!p1) p1 = *i2;
                        else if(!p2) p2 = *i2;
                        else break;
                    }
                    if(p1 && p1 && is_class<T1>(p1) && is_class<T2>(p2)){
                        res.append(QPair<T1, T2>(object_cast<T1>(p1), object_cast<T2>(p2)));
                    }
                }
            }
            return res;
        }

        void to(lua_State* L, QList<QPair<T1, T2> > const& arr)
        {
            object obj = luabind::newtable(L);
            for(int i=0;i<arr.length();i++){
                object t = luabind::newtable(L);
                t[1] = __getValue(arr.at(i).first);
                t[2] = __getValue(arr.at(i).second);
                obj[i+1] = t;
            }
            obj.push(L);
        }
    };

    template<typename T1, typename T2>
    struct default_converter<QList<QPair<T1, T2> > const&>
      : default_converter<QList<QPair<T1, T2> > >
    {};
}

QString QUrl_queryPairDelimiter(QUrl* w)
{
    char ch = w->queryPairDelimiter();
    return QString(QChar(ch));
}

QString QUrl_queryValueDelimiter(QUrl* w)
{
    char ch = w->queryValueDelimiter();
    return QString(QChar(ch));
}

void QUrl_setQueryDelimiters(QUrl* w, QString c, QString d)
{
    w->setQueryDelimiters(c.at(0).toAscii(), d.at(0).toAscii());
}

QByteArray QUrl_toPercentEncoding1(const QString& input)
{
    return QUrl::toPercentEncoding(input);
}

QByteArray QUrl_toPercentEncoding2(const QString& input, const QByteArray & exclude)
{
    return QUrl::toPercentEncoding(input,exclude);
}

QString QUrl_toString(QUrl* w){ return w->toString();}

QByteArray QUrl_toEncoded(QUrl* w) { return w->toEncoded(); }
LQUrl lqurl()
{
    return
    myclass_<QUrl>("QUrl",lqurl_set_map)
    .def(constructor<>())
    .def(constructor<const QString &>())
    .def(constructor<const QUrl &>())
    .def(constructor<const QString &, QUrl::ParsingMode>())
    .def("__call", lqurl_init)
    .def("__int", table_init_general<QUrl>)
    .def("addEncodedQueryItem", &QUrl::addEncodedQueryItem)
    .def("addQueryItem", &QUrl::addQueryItem)
    .def("allEncodedQueryItemValues", &QUrl::allEncodedQueryItemValues)
    .def("allQueryItemValues", &QUrl::allQueryItemValues)
    .def("clear", &QUrl::clear)
    .def("encodedQueryItemValue", &QUrl::encodedQueryItemValue)
    .def("setEncodedUrl", (void (QUrl::*)(const QByteArray &, QUrl::ParsingMode))&QUrl::setEncodedUrl)
    .def("setEncodedUrl", (void (QUrl::*)(const QByteArray &))&QUrl::setEncodedUrl)
    .def("hasEncodedQueryItem", &QUrl::hasEncodedQueryItem)
    .def("hasQueryItem", &QUrl::hasQueryItem)
    .property("hasFragment", &QUrl::hasFragment)
    .property("hasQuery", &QUrl::hasQuery)
    .def("isParentOf", &QUrl::isParentOf)
    .property("isEmpty", &QUrl::isEmpty)
    .property("isRelative", &QUrl::isRelative)
    .property("isValid", &QUrl::isValid)
    .def("getPort", (int(QUrl::*)(int)const)&QUrl::port)
    .def("getPort", (int(QUrl::*)()const)&QUrl::port)
    .def("setPort", &QUrl::setPort)
    .def("queryItemValue", &QUrl::queryItemValue)
    .def("setQueryDelimiters", &QUrl::setQueryDelimiters)
    .def("setQueryDelimiters", QUrl_setQueryDelimiters)
    .def("removeAllEncodedQueryItems", &QUrl::removeAllEncodedQueryItems)
    .def("removeAllQueryItems", &QUrl::removeAllQueryItems)
    .def("removeEncodedQueryItem", &QUrl::removeEncodedQueryItem)
    .def("removeQueryItem", &QUrl::removeQueryItem)
    .def("toEncoded", &QUrl::toEncoded)
    .def("setUrl", (void (QUrl::*)(const QString &, QUrl::ParsingMode))&QUrl::setUrl)
    .def("setUrl", (void (QUrl::*)(const QString &))&QUrl::setUrl)

    .property("authority", &QUrl::setAuthority, &QUrl::authority)
    .property("fragment", &QUrl::fragment, &QUrl::setFragment)
    .property("host", &QUrl::host, &QUrl::setHost)
    .property("password", &QUrl::password, &QUrl::setPassword)
    .property("path", &QUrl::path, &QUrl::setPath)
    .property("port", (int(QUrl::*)()const)&QUrl::port, &QUrl::setPort)
    .property("queryPairDelimiter", QUrl_queryPairDelimiter)
    .property("queryValueDelimiter", QUrl_queryValueDelimiter)
    .property("scheme", &QUrl::scheme, &QUrl::setScheme)
    .property("toLocalFile", &QUrl::toLocalFile)
    .property("toEncoded", QUrl_toEncoded)
    .def("toString", &QUrl::toString)
    .def("__tostring", &QUrl::toString)
    .property("toString", QUrl_toString)
    .def("__tostring", QUrl_toString)
    .property("userInfo", &QUrl::userInfo, &QUrl::setUserInfo)
    .property("userName", &QUrl::userName, &QUrl::setUserName)

    .class_<QUrl>::property("encodedFragment", &QUrl::encodedFragment, &QUrl::setEncodedFragment)
    .property("encodedHost", &QUrl::encodedHost, &QUrl::setEncodedHost)
    .property("encodedPassword", &QUrl::encodedPassword, &QUrl::setEncodedPassword)
    .property("encodedPath", &QUrl::encodedPath, &QUrl::setEncodedPath)
    .property("encodedQuery", &QUrl::encodedQuery, &QUrl::setEncodedQuery)
    .property("encodedQueryItems", &QUrl::encodedQueryItems, &QUrl::setEncodedQueryItems)
    .property("encodedUserName", &QUrl::encodedUserName, &QUrl::setEncodedUserName)
    .property("errorString", &QUrl::errorString)
    .property("queryItems", &QUrl::queryItems, &QUrl::setQueryItems)

    .scope[
            def("fromAce", &QUrl::fromAce),
            def("fromEncoded", (QUrl(*)( const QByteArray &))&QUrl::fromEncoded),
            def("fromEncoded", (QUrl(*)( const QByteArray &,QUrl::ParsingMode))&QUrl::fromEncoded),
            def("fromLocalFile", &QUrl::fromLocalFile),
            def("fromPercentEncoding", &QUrl::fromPercentEncoding),
            def("fromUserInput", &QUrl::fromUserInput),
            def("idnWhitelist", &QUrl::idnWhitelist),
            def("setIdnWhitelist", &QUrl::setIdnWhitelist),
            def("toAce", &QUrl::toAce),
            def("toPercentEncoding", &QUrl::toPercentEncoding),
            def("toPercentEncoding", QUrl_toPercentEncoding1),
            def("toPercentEncoding", QUrl_toPercentEncoding2)
    ]
    ;
}

LQMimeData lqmimedata()
{
    return
    myclass_<QMimeData,QObject>("QMimeData")
    .def(constructor<>())
    .def("clear", &QMimeData::clear)
    .def("data", &QMimeData::data)
    .def("setData", &QMimeData::setData)
    .def("hasFormat", &QMimeData::hasFormat)
    .def("removeFormat", &QMimeData::removeFormat)

    .property("colorData", &QMimeData::hasColor)
    .property("hasHtml", &QMimeData::hasHtml)
    .property("hasImage", &QMimeData::hasImage)
    .property("hasText", &QMimeData::hasText)
    .property("hasUrls", &QMimeData::hasUrls)

    .property("html", &QMimeData::html, &QMimeData::setHtml)
    .property("text", &QMimeData::text, &QMimeData::setText)


    .class_<QMimeData,QObject>::property("colorData", &QMimeData::colorData, &QMimeData::setColorData)
    .property("formats", &QMimeData::formats)
    .property("imageData", &QMimeData::imageData, &QMimeData::setImageData)
    .property("urls", &QMimeData::urls, &QMimeData::setUrls)
    ;
}

Qt::DropAction QDrag_exec1(QDrag* w){ return w->exec(); }
Qt::DropAction QDrag_exec2(QDrag* w, Qt::DropActions supportedActions){ return w->exec(supportedActions); }
Qt::DropAction QDrag_exec3(QDrag* w, Qt::DropActions supportedActions, Qt::DropAction defAct){ return w->exec(supportedActions,defAct); }

static setter_map<QDrag> lqdrag_set_map;

QDrag* lqdrag_init(QDrag* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqdrag_set_map);
}
//template<>
//void table_init_general<QDrag>(const luabind::argument & arg, const object& obj)
//{
//    lqdrag_init(construct<QDrag>(arg), obj);
//}

SIGNAL_PROPERYT(lqdrag, actionChanged , QDrag,"(Qt::DropAction)")
SIGNAL_PROPERYT(lqdrag, targetChanged , QDrag,"(QWidget*)")
LQDrag lqdrag()
{
    return
    myclass_<QDrag,QObject>("QDrag",lqdrag_set_map)
    .def(constructor<QWidget*>())
    .def("__call", lqdrag_init)
    .def("exec", QDrag_exec1)
    .def("exec", QDrag_exec2)
    .def("exec", QDrag_exec3)
    .def("setDragCursor", &QDrag::setDragCursor)

    .sig_prop(lqdrag, actionChanged)
    .sig_prop(lqdrag, targetChanged)
    .property("hotSpot", &QDrag::hotSpot, &QDrag::setHotSpot)
    .class_<QDrag,QObject>::property("mimeData", &QDrag::mimeData, &QDrag::setMimeData)
    .property("pixmap", &QDrag::pixmap, &QDrag::setPixmap)
    .property("source", &QDrag::source)
    .property("target", &QDrag::target)
    ;
}

QString QRegExp_cap1(QRegExp* w){ return w->cap(); }
QString QRegExp_cap2(QRegExp* w, int n){ return w->cap(n); }
int QRegExp_indexIn1(QRegExp* w, const QString& str){ return w->indexIn(str); }
int QRegExp_indexIn2(QRegExp* w, const QString& str, int offset){ return w->indexIn(str,offset); }
int QRegExp_lastIndexIn1(QRegExp* w, const QString& str){ return w->lastIndexIn(str); }
int QRegExp_lastIndexIn2(QRegExp* w, const QString& str, int offset){ return w->lastIndexIn(str,offset); }
int QRegExp_pos1(QRegExp* w){ return w->pos();}
int QRegExp_pos2(QRegExp* w, int n){ return w->pos(n);}

LQRegExp lqregexp()
{
    return
    class_<QRegExp>("QRegExp")
    .def(constructor<>())
    .def(constructor<const QString &, Qt::CaseSensitivity, QRegExp::PatternSyntax>())
    .def(constructor<const QString &, Qt::CaseSensitivity>())
    .def(constructor<const QString &>())
    .def(constructor<const QRegExp &>())
    .def("cap", QRegExp_cap1)
    .def("cap", QRegExp_cap2)
    .def("indexIn", &QRegExp::indexIn)
    .def("indexIn", QRegExp_indexIn1)
    .def("indexIn", QRegExp_indexIn2)
    .def("lastIndexIn", &QRegExp::lastIndexIn)
    .def("lastIndexIn", QRegExp_lastIndexIn1)
    .def("lastIndexIn", QRegExp_lastIndexIn2)
    .def("pos", QRegExp_pos1)
    .def("pos", QRegExp_pos2)


    .property("captureCount", &QRegExp::captureCount)
    .property("capturedTexts", (QStringList (QRegExp::*)()const)&QRegExp::capturedTexts)
    .property("caseSensitivity", &QRegExp::caseSensitivity, &QRegExp::setCaseSensitivity)
    .property("errorString", (QString (QRegExp::*)()const)&QRegExp::errorString)
    .property("exactMatch", &QRegExp::exactMatch)
    .property("isEmpty", &QRegExp::isEmpty)
    .property("minimal", &QRegExp::isMinimal, &QRegExp::setMinimal)
    .property("isValid", &QRegExp::isValid)
    .property("matchedLength", &QRegExp::matchedLength)
    .property("pattern", &QRegExp::pattern, &QRegExp::setPattern)
    .property("patternSyntax", &QRegExp::patternSyntax, &QRegExp::setPatternSyntax)
    .scope[
            def("escape",  &QRegExp::escape)
    ]
    ;
}
