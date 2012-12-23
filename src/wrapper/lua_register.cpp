#include <QtGui>

#include "lua_qslot.h"

#include <luabind/luabind.hpp>

#include <luabind/class_info.hpp>

#include "lua_liteptr.h"

#include "lua_qtypes.h"

#include "lua_serial.h"
#include "lua_network.h"

// TODO #include "lua_usbhid.h"
// TODO #include "lua_qglviewer.h"

#include "lua_util.h"

#include <luabind/out_value_policy.hpp>

using namespace luabind;

typedef lite_ptr<QLuaSlot> auto_slot;

Q_DECLARE_METATYPE(auto_slot)

lua_State* __pL = 0;

static QString getName(const QString& s){
    return s.left( s.indexOf(QChar('('),0));
}

bool checkMember(int index, const char * name)
{
    object o1(from_stack(__pL, index));
    if(type(o1) == LUA_TUSERDATA){
        object fun = o1[name];
        if(!fun){
            throw std::runtime_error(QString("member: %1 not defined").arg(name).toStdString());
            return false;
        }
        if(type(fun) != LUA_TFUNCTION){
            throw std::runtime_error(QString("member: %1 is not function").arg(name).toStdString());
            return false;
        }
    }else{
        throw std::runtime_error(QString("parameter %1 is not a valid object").arg(index).toStdString());
        return false;
    }
    return true;
}

QLuaSlot* get_signal(QObject* obj, const char* signal)
{
    QByteArray sig = QMetaObject::normalizedSignature(signal);
    QVariant v = obj->property(sig);
    if(v.isValid()){
        if(v.canConvert<auto_slot >()){
            auto_slot aslot = v.value<auto_slot>();
            return aslot.get();
        }
    }
    {
        auto_slot aslot(new QLuaSlot(signal));
        QVariant v;
        v.setValue(aslot);
        obj->setProperty(sig, v);
        return aslot.get();
    }
}

QLuaSlot* get_slot(QObject* obj, int index, const char* member)
{
    QByteArray mem = QMetaObject::normalizedSignature(member);
    QVariant v = obj->property(mem);
    if(v.isValid()){
        if(v.canConvert<auto_slot >()){
            auto_slot aslot = v.value<auto_slot>();
            return aslot.get();
        }
    }
    {
        auto_slot aslot(new QLuaSlot(object(from_stack(__pL, index)) , member));
        QVariant v;
        v.setValue(aslot);
        obj->setProperty(mem, v);
        return aslot.get();
    }
}

QLuaSlot* get_slot(const QObject* obj, const char* member)
{
    QByteArray mem = QMetaObject::normalizedSignature(member);
    QVariant v = obj->property(mem);
    if(v.isValid()){
        if(v.canConvert<auto_slot >()){
            auto_slot aslot = v.value<auto_slot>();
            return aslot.get();
        }
    }
    return 0;
}

QLuaSlot* set_slot(QObject* obj, object o, const char* member)
{
    QByteArray mem = QMetaObject::normalizedSignature(member);
    QVariant v = obj->property(mem);
    if(v.isValid()){
        if(v.canConvert<auto_slot >()){
            auto_slot aslot = v.value<auto_slot>();
            aslot.get()->set_object(o);
            return aslot.get();
        }
    }
    {
        auto_slot aslot(new QLuaSlot(o, member));
        QVariant v;
        v.setValue(aslot);
        obj->setProperty(mem, v);
        return aslot.get();
    }
}

QLuaSlot* get_slot(object obj)
{
    //auto_slot aslot(new QLuaSlot(obj , "dummy()"));
    //return aslot.get();
    //qDebug()<<object_cast<void(*)()>(obj);
    return new QLuaSlot(obj , "dummy()");
}

bool sigslot_connect(QObject* sender, const char* signal, QObject* recv, const char* member)
{
    QString s = QString("2%1").arg(signal);
    QString m = QString("1%1").arg(member);
    QByteArray sig = QMetaObject::normalizedSignature(signal);
    QByteArray slt = QMetaObject::normalizedSignature(member);
    int iSig = sender->metaObject()->indexOfSignal(sig);
    int iSlot = recv->metaObject()->indexOfSlot(slt);
    bool res = false;
    //qDebug()<<"iSignal:"<<iSig<<"  iSlot:"<<iSlot;
    //qDebug()<<(int)type(object(from_stack(__pL, 1)))<<(int)type(object(from_stack(__pL, 2)))
    //        <<(int)type(object(from_stack(__pL, 3)))<<(int)type(object(from_stack(__pL, 4)));
    if(iSig != -1 && iSlot != -1){
        res = QObject::connect(sender, s.toLocal8Bit().data(), recv, m.toLocal8Bit().data());
    }else if(iSig == -1 && iSlot == -1){
        if(!checkMember(1, getName(signal).toLocal8Bit().data())) return false;
        if(!checkMember(3, getName(member).toLocal8Bit().data())) return false;
        QLuaSlot* p_signal = get_signal(sender, signal);
        QLuaSlot* p_slot = get_slot(recv, 3, member);
        res = QObject::connect(p_signal, p_signal->signal() , p_slot, p_slot->slot());
    }else if(iSig == -1){
        // no signal, has slot
        if(!checkMember(1, getName(signal).toLocal8Bit().data())) return false;
        QLuaSlot* p_signal = get_signal(sender, signal);
        res = QObject::connect(p_signal, p_signal->signal(), recv, m.toLocal8Bit().data());
    }else{
        // has signal, not slot
        if(!checkMember(3, getName(member).toLocal8Bit().data())) return false;
        QLuaSlot* p_slot = get_slot(recv, 3, member);
        res = QObject::connect(sender, s.toLocal8Bit().data(), p_slot, p_slot->slot());
    }
    return res;
}

bool sigfunc_connect(QObject* sender, const char* signal, object func)
{
    QString s = QString("2%1").arg(signal);
    QByteArray sig = QMetaObject::normalizedSignature(signal);
    int iSig = sender->metaObject()->indexOfSignal(sig);
    bool res = false;
    if(type(func) != LUA_TFUNCTION && type(func) != LUA_TTABLE) return false;
    if(iSig == -1 ){
        if(!checkMember(1, getName(signal).toLocal8Bit().data())) return false;
        QLuaSlot* p_signal = get_signal(sender, signal);
        QLuaSlot* p_slot = set_slot(sender,func,signal);
        res = QObject::connect(p_signal, p_signal->signal() , p_slot, p_slot->slot());
    }else{
        // has signal, not slot
        QLuaSlot* p_slot = set_slot(sender,func,signal);
        res = QObject::connect(sender, s.toLocal8Bit().data(), p_slot, p_slot->slot());
    }
    return res;
}

void emit_signal(QObject* sender, object obj)
{
    const char* signal = object_cast<const char*>(obj);
    QByteArray sig = QMetaObject::normalizedSignature(signal);
    //qDebug()<<"emit_signal "<<object_cast<const char*>(obj)<<"  "<<sender->property(sig).toString();
    //qDebug()<<(bool)p1<<(bool)p2<<(bool)p3;
    //qDebug()<<"top:"<<lua_gettop(__pL);
    int top = lua_gettop(__pL);
    QVariant v = sender->property(sig);
    if(v.isValid() && v.canConvert<auto_slot>()){
    }else{
        return;
    }
    auto_slot s = v.value<auto_slot>();
    switch(top){
    case 2:
        {
            s.get()->emit_gen_signal();
        }
        break;
    case 3:
        {
            object p1(from_stack(__pL, 3));
            //qDebug()<<"type:"<<type(p1);
            if(type(p1) == LUA_TSTRING){
                s.get()->emit_gen_signal(object_cast<QString>(p1));
            }else if(type(p1) == LUA_TNUMBER){
                s.get()->emit_gen_signal(object_cast<int>(p1));
            }
        }
        break;
    }
}

static const char* toString(const QByteArray& arr)
{
    return arr.data();
}

static QByteArray toBase64(const QByteArray& arr)
{
    return arr.toBase64();
}

static QByteArray fromBase64(const QByteArray& arr)
{
    return QByteArray::fromBase64(arr);
}

static QByteArray fromString(const QString& str)
{
    return str.toAscii();
}

static int my_and(int x, int y) { return x & y;}
static int my_or(int x, int y) { return x | y;}
static int my_xor(int x, int y) { return x ^ y;}

void register_classes(lua_State* L)
{
    __pL = L;
    luabind::open(L);
    bind_class_info(L);
    luabind::module(L)
    [
        lqobject(),
        lqwidget(),

        lqevent(),
        lqinputevent(),
        lqcloseevent(),
        lqcontextmenuevent(),
        lqdropevent(),
        lqdragmoveevent(),
        lqdragenterevent(),
        lqdragleaveevent(),
        lqkeyevent(),
        lqmouseevent(),
        lqpaintevent(),
        lqtimerevent(),
        lqwheelevent(),
        lqresizeevent(),
        lqshowevent(),
        lqhideevent(),

        lqmainwindow(),
        lqdockwidget(),
        lqstatusbar(),
        //lqtesttype(),

        lqdialog(),
        lqframe(),
        lqgroupbox(),
        lqsplitter(),

        lqabstractscrollarea(),
        lqmdisubwindow(),
        lqmdiarea(),
        lqsystemtrayicon(),

        lqicon(),
        lqaction(),
        lqmenu(),
        lqmenubar(),
        lqtoolbar(),
        lqcursor(),

        lqpoint(),
        lqline(),
        lqpen(),
        //lqpolygon(),
        lqrect(),
        lqsize(),
        lqcolor(),
        lqbrush(),
        lqfont(),
        lqmargins(),

        lqlayout(),
        lqstatckedlayout(),
        lqformlayout(),
        lqgridlayout(),
        lqboxlayout(),
        lqvboxlayout(),
        lqhboxlayout(),
        lqspaceritem(),

        lqlabel(),
        lqtextedit(),
        lqplaintextedit(),
        lqlineedit(),

        lqabstractbutton(),
        lqcheckbox(),
        lqpushbutton(),
        lqradionbutton(),
        lqtoolbutton(),
        lqbuttongroup(),
        lqkeysequence(),

        lqcombobox(),
        lqlistwidgetitem(),
        lqlistwidget(),
        lqtreewidgetitem(),
        lqtreewidget(),
        lqtablewidgetitem(),
        lqtablewidget(),
        lqtablewidgetselectionrange(),

        lqtabwidget(),
        lqtoolbox(),

        lqabstractspinbox(),
        lqspinbox(),
        lqdoublespinbox(),

        lqdate(),
        lqtime(),
        lqdatetime(),
        lqdatetimeedit(),
        lqdateedit(),
        lqtimeedit(),
        lqtimer(),

        lqpainter(),
        lqimage(),
        lqpixmap(),
        lqbitmap(),
        //lqvariant(),

        lqprocessenvironment(),
        lqprocess(),
        lqapplication(),
        lqdesktopwidget(),
        lqclipboard(),
        lqsound(),
        lqfilesystemwatcher(),

        lqabstractslider(),
        lqslider(),
        lqscrollbar(),
        lqdial(),

        lqprogressbar(),
        lqprogressdialog(),

        lqhostaddress(),
        lqnetworkproxy(),
        lqtcpserver(),
        lqabstractsocket(),
        lqtcpsocket(),
        lqudpsocket(),
        lqhostinfo(),
        lqnetworkinterface(),
        lqnetworkaddressentry(),

        lqurl(),
        lqmimedata(),

        lqdrag(),
        lqregexp(),

        lqftp(),
        lqurlinfo(),
        lqtextcodec(),
        lqtextdecoder(),
        lqtextencoder(),

        lqfile(),
        lqtemporaryfile(),
        lqdir(),
        lqfileinfo(),

        /*
        lqusbhidinfo(),
        lqusbhid(),
        lqhidattr(),
        lqhidcaps(),
        */

        /*
        lqglwidget(),
        lqglviewer(),
        lqglvec(),
        lquaternion(),
        lqcamera(),
        lqobject3ds(),
        */

        lqutil(),

        class_<QVariant_wrapper>("QVariant_wrapper")
        .def(constructor<>()),
        def("connect", (bool(*)(QObject*, const char*, QObject* , const char* ))&sigslot_connect),
        def("connect", (bool(*)(QObject*, const char*, object))&sigfunc_connect),
        def("emit_signal", (void (*)(QObject*,object))&emit_signal),
        def("emit_signal", (void (*)(QObject*,object,object))&emit_signal),
        def("emit_signal", (void (*)(QObject*,object,object,object))&emit_signal),
        def("emit_signal", (void (*)(QObject*,object,object,object,object))&emit_signal),

        def("toString", toString),
        def("toBase64", toBase64),
        def("fromBase64", fromBase64),
        def("fromString", fromString),

        def("bit_and", my_and),
        def("bit_or", my_or),
        def("bit_xor", my_xor)
    ];
}
