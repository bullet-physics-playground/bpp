#include "lua_qevent.h"
#include "luabind/dependency_policy.hpp"

namespace luabind{
    QT_EMUN_CONVERTER(Qt::KeyboardModifiers)
    QT_EMUN_CONVERTER(Qt::MouseButtons)
    QT_EMUN_CONVERTER(Qt::MouseButton)
    QT_EMUN_CONVERTER(Qt::DropAction)
    QT_EMUN_CONVERTER(Qt::DropActions)
}

template<typename T>
bool isEvent(QEvent::Type type);

template<typename T>
struct myEventFilter : public QObject
{
    myEventFilter(const object& obj):m_obj(obj){}
    virtual bool eventFilter(QObject * obj, QEvent * event)
    {
        try{
            if(isEvent<T>(event->type())){
                T* evt = static_cast<T *>(event);
                if(evt){
                    bool res = false;
                    if(type(m_obj) == LUA_TFUNCTION){
                        res = call_function<bool>(m_obj,obj,evt);
                    }else if(type(m_obj) == LUA_TTABLE){
                        object c,f;
                        for(iterator i(m_obj),e;i!=e;++i){
                            if(type(*i) == LUA_TUSERDATA){
                                c = *i;
                            }else if(type(*i) == LUA_TFUNCTION){
                                f = *i;
                            }else if(type(*i) == LUA_TSTRING){
                                f = *i;
                            }
                        }
                        if(f && c){
                            if(type(f) == LUA_TFUNCTION){
                                res = call_function<bool>(f,c,obj,evt);
                            }else if(type(f) == LUA_TSTRING){
                                res = call_member<bool>(c,object_cast<const char*>(f),obj,evt);
                            }
                        }
                    }
                    if(res) return res;
                }
            }
        }catch(...){}
        return QObject::eventFilter(obj,event);
    }
private:
    object m_obj;
};

template<>bool isEvent<QEvent>(QEvent::Type){ return true; }
template<>bool isEvent<QInputEvent>(QEvent::Type){ return true; }
template<>bool isEvent<QCloseEvent>(QEvent::Type type){ return type == QEvent::Close; }
template<>bool isEvent<QContextMenuEvent>(QEvent::Type type){ return type == QEvent::ContextMenu; }
template<>bool isEvent<QKeyEvent>(QEvent::Type type){ return type == QEvent::KeyPress || type == QEvent::KeyRelease; }
template<>bool isEvent<QMouseEvent>(QEvent::Type type){
    switch(type){
    case QEvent::MouseButtonDblClick:
    case QEvent::MouseMove:
    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonRelease:
        return true;
    default:
        return false;
    }
    return false;
}
template<>bool isEvent<QWheelEvent>(QEvent::Type type){ return type == QEvent::Wheel; }
template<>bool isEvent<QPaintEvent>(QEvent::Type type){ return type == QEvent::Paint; }
template<>bool isEvent<QTimerEvent>(QEvent::Type type){ return type == QEvent::Timer; }
template<>bool isEvent<QResizeEvent>(QEvent::Type type){ return type == QEvent::Resize; }
template<>bool isEvent<QShowEvent>(QEvent::Type type){ return type == QEvent::Show; }
template<>bool isEvent<QHideEvent>(QEvent::Type type){ return type == QEvent::Hide; }
template<>bool isEvent<QDropEvent>(QEvent::Type type){ return type == QEvent::Drop; }
template<>bool isEvent<QDragEnterEvent>(QEvent::Type type){ return type == QEvent::DragEnter; }
template<>bool isEvent<QDragMoveEvent>(QEvent::Type type){ return type == QEvent::DragMove; }
template<>bool isEvent<QDragLeaveEvent>(QEvent::Type type){ return type == QEvent::DragLeave; }

template<typename T>
QObject* event_filter(const object& obj)
{
    return new myEventFilter<T>(obj);
}

void lqevent_init_general(const luabind::argument & arg)
{
    construct<QEvent>(arg,QEvent::Type(0));
}

LQEvent lqevent()
{
    return
    class_<QEvent>("QEvent")
    .def("__init",lqevent_init_general)
    .def(constructor<QEvent::Type>())
    .def("accept", &QEvent::accept)
    .def("ignore", &QEvent::ignore)
    .property("type" , &QEvent::type)
    .property("accepted" , &QEvent::isAccepted, &QEvent::setAccepted)
    .scope[ def("filter", event_filter<QEvent>)]
    ;
}

LQInputEvent lqinputevent()
{
    return
    LQInputEvent("QInputEvent")
    .property("modifiers", &QInputEvent::modifiers, &QInputEvent::setModifiers)
    .scope[ def("filter", event_filter<QInputEvent>)]
    ;
}
LQCloseEvent lqcloseevent()
{
    return
    LQCloseEvent("QCloseEvent")
    .scope[ def("filter", event_filter<QCloseEvent>)]
    ;
}

LQContextMenuEvent lqcontextmenuevent()
{
    return
    LQContextMenuEvent("QContextMenuEvent")
    .property("globalPos", &QContextMenuEvent::globalPos)
    .property("globalX", &QContextMenuEvent::globalX)
    .property("globalY", &QContextMenuEvent::globalY)
    .property("pos", &QContextMenuEvent::pos)
    .property("x", &QContextMenuEvent::x)
    .property("y", &QContextMenuEvent::y)
    .property("reason", &QContextMenuEvent::reason)
    .scope[ def("filter", event_filter<QContextMenuEvent>)]
    ;
}

LQKeyEvent lqkeyevent()
{
    return
    LQKeyEvent("QKeyEvent")
    .def("matches", &QKeyEvent::matches)
    .property("count", &QKeyEvent::count)
    .property("autoRepeat", &QKeyEvent::isAutoRepeat)
    .property("key", &QKeyEvent::key)
    .property("text", &QKeyEvent::text)
    .property("modifiers", &QKeyEvent::modifiers)
    .scope[ def("filter", event_filter<QKeyEvent>)]
    ;
}

LQMouseEvent lqmouseevent()
{
    return
    LQMouseEvent("QMouseEvent")
    .property("button", &QMouseEvent::button)
    .property("buttons", &QMouseEvent::buttons)
    .property("globalPos", &QMouseEvent::globalPos)
    .property("globalX", &QMouseEvent::globalX)
    .property("globalY", &QMouseEvent::globalY)
    .property("pos", &QMouseEvent::pos)
    .property("x", &QMouseEvent::x)
    .property("y", &QMouseEvent::y)
    .scope[ def("filter", event_filter<QMouseEvent>)]
    ;
}

LQWheelEvent lqwheelevent()
{
    return
    LQWheelEvent("QWheelEvent")
    .property("buttons", &QWheelEvent::buttons)
    .property("globalPos", &QWheelEvent::globalPos)
    .property("globalX", &QWheelEvent::globalX)
    .property("globalY", &QWheelEvent::globalY)
    .property("pos", &QWheelEvent::pos)
    .property("x", &QWheelEvent::x)
    .property("y", &QWheelEvent::y)
    .property("orientation", &QWheelEvent::orientation)
    .scope[ def("filter", event_filter<QWheelEvent>)]
    ;
}

LQPaintEvent lqpaintevent()
{
    return
    LQPaintEvent("QPaintEvent")
    .property("rect", &QPaintEvent::rect)
    .scope[ def("filter", event_filter<QPaintEvent>)]
    ;
}
LQTimerEvent lqtimerevent()
{
    return
    LQTimerEvent("QTimerEvent")
    .property("timerId", &QTimerEvent::timerId)
    .scope[ def("filter", event_filter<QTimerEvent>)]
    ;
}

LQResizeEvent lqresizeevent()
{
    return
    LQResizeEvent("QResizeEvent")
    .property("oldSize", &QResizeEvent::oldSize)
    .property("size", &QResizeEvent::size)
    .scope[ def("filter", event_filter<QResizeEvent>)]
    ;
}

LQShowEvent lqshowevent()
{
    return
    LQShowEvent("QShowEvent")
    .scope[ def("filter", event_filter<QShowEvent>)]
    ;
}

LQHideEvent lqhideevent()
{
    return
    LQHideEvent("QHideEvent")
    .scope[ def("filter", event_filter<QHideEvent>)]
    ;
}

LQDropEvent lqdropevent()
{
    return
    LQDropEvent("QDropEvent")
    .def("acceptProposedAction", &QDropEvent::acceptProposedAction)

    .property("dropAction", &QDropEvent::dropAction, &QDropEvent::setDropAction)
    .property("keyboardModifiers", &QDropEvent::keyboardModifiers)
    .property("mimeData", &QDropEvent::mimeData)
    .property("mouseButtons", &QDropEvent::mouseButtons)
    .property("possibleActions", &QDropEvent::possibleActions)
    .property("proposedAction", &QDropEvent::proposedAction)
    .property("source", &QDropEvent::source)
    .property("pos", &QDropEvent::pos)
    .scope[ def("filter", event_filter<QDropEvent>)]
    ;
}

LQDragMoveEvent lqdragmoveevent()
{
    return
    LQDragMoveEvent("QDragMoveEvent")
    .def("accept", ( void (QDragMoveEvent::*)())&QDragMoveEvent::accept)
    .def("accept", ( void (QDragMoveEvent::*)(const QRect&))&QDragMoveEvent::accept)
    .def("ignore", ( void (QDragMoveEvent::*)())&QDragMoveEvent::ignore)
    .def("ignore", ( void (QDragMoveEvent::*)(const QRect&))&QDragMoveEvent::ignore)
    .property("answerRect", &QDragMoveEvent::answerRect)
    .scope[ def("filter", event_filter<QDragMoveEvent>)]
    ;
}

LQDragEnterEvent lqdragenterevent()
{
    return
    LQDragEnterEvent("QDragEnterEvent")
    .scope[ def("filter", event_filter<QDragEnterEvent>)]
    ;
}

LQDragLeaveEvent lqdragleaveevent()
{
    return
    LQDragLeaveEvent("QDragLeaveEvent")
    .scope[ def("filter", event_filter<QDragLeaveEvent>)]
    ;
}
