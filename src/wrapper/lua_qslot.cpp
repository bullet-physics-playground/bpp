#include "lua_qslot.h"

#include <QDebug>
#include "qextserialenumerator.h"
#ifdef Q_OS_WIN
// #include "qusbhid/qusbhid.h"
#endif

QLuaSlot::QLuaSlot(const QString& signature, bool autoDelete) :
    QObject(0),m_signature(signature),m_delete_when_done(autoDelete)
{
    //qDebug()<<"QLua Slot create: "<<this;;
}

QLuaSlot::QLuaSlot(const object& obj, const QString& signature, bool autoDelete) :
        QObject(0), m_obj(obj),m_signature(signature),m_delete_when_done(autoDelete)
{
    m_method = signature.left( signature.indexOf(QChar('('),0));
    //qDebug()<<"QLua Slot create by obj: "<<this;;
}

QLuaSlot::~QLuaSlot()
{
    //qDebug()<<"QLua Slot delete:"<<this;
}

void QLuaSlot::emit_gen_signal()
{
    emit general_signal();
}

void QLuaSlot::emit_gen_signal(QString s)
{
    emit general_signal(s);
}

void QLuaSlot::emit_gen_signal(int v)
{
    emit general_signal(v);
}

QByteArray QLuaSlot::slot() const
{
    QString sub = m_signature;
    sub.remove(0, sub.indexOf(QChar('(')));
    QString m = QString("1general_slot%1").arg(sub);
    return m.toAscii();
}

QByteArray QLuaSlot::signal() const
{
    QString sub = m_signature;
    sub.remove(0, sub.indexOf(QChar('(')));
    QString m = QString("2general_signal%1").arg(sub);
    return m.toAscii();
}

void general_slot(const object& m_obj, const QString& m_method)
{
    if(type(m_obj) == LUA_TFUNCTION){
        call_function<void>(m_obj);
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
                call_function<void>(f,c);
            }else if(type(f) == LUA_TSTRING){
                call_member<void>(c,object_cast<const char*>(f));
            }
        }
    }else{
        call_member<void>(m_obj,m_method.toLocal8Bit().constData());
    }
}

template<class T>
void general_slot(const object& m_obj, const QString& m_method, T t)
{
    if(type(m_obj) == LUA_TFUNCTION){
        call_function<void>(m_obj,t);
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
                call_function<void>(f,c,t);
            }else if(type(f) == LUA_TSTRING){
                call_member<void>(c,object_cast<const char*>(f),t);
            }
        }
    }else{
        call_member<void>(m_obj,m_method.toLocal8Bit().constData(),t);
    }
}

template<class T1, class T2>
void general_slot(const object& m_obj, const QString& m_method, T1 t1, T2 t2)
{
    if(type(m_obj) == LUA_TFUNCTION){
        call_function<void>(m_obj,t1,t2);
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
                call_function<void>(f,c,t1,t2);
            }else if(type(f) == LUA_TSTRING){
                call_member<void>(c,object_cast<const char*>(f),t1,t2);
            }
        }
    }else{
        call_member<void>(m_obj,m_method.toLocal8Bit().constData(),t1,t2);
    }
}

template<class T1, class T2, class T3>
void general_slot(const object& m_obj, const QString& m_method, T1 t1, T2 t2, T3 t3)
{
    if(type(m_obj) == LUA_TFUNCTION){
        call_function<void>(m_obj,t1,t2,t3);
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
                call_function<void>(f,c,t1,t2,t3);
            }else if(type(f) == LUA_TSTRING){
                call_member<void>(c,object_cast<const char*>(f),t1,t2,t3);
            }
        }
    }else{
        call_member<void>(m_obj,m_method.toLocal8Bit().constData(),t1,t2,t3);
    }
}

template<class T1, class T2, class T3, class T4>
void general_slot(const object& m_obj, const QString& m_method, T1 t1, T2 t2, T3 t3, T4 t4)
{
    if(type(m_obj) == LUA_TFUNCTION){
        call_function<void>(m_obj,t1,t2,t3,t4);
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
                call_function<void>(f,c,t1,t2,t3,t4);
            }else if(type(f) == LUA_TSTRING){
                call_member<void>(c,object_cast<const char*>(f),t1,t2,t3,t4);
            }
        }
    }else{
        call_member<void>(m_obj,m_method.toLocal8Bit().constData(),t1,t2,t3,t4);
    }
}


inline void gen_slot(const object& m_obj, const QString& m_method)
{
    try{
        general_slot(m_obj,m_method);
    }
    catch (...)
    {}
}

template<typename T>
inline void gen_slot(const object& m_obj, const QString& m_method, T t)
{
    try{
        general_slot(m_obj,m_method,t);
    }
    catch (...)
    {}
}

template<typename T1, typename T2>
inline void gen_slot(const object& m_obj, const QString& m_method, T1 t1, T2 t2)
{
    try{
        general_slot(m_obj,m_method,t1,t2);
    }
    catch (...)
    {}
}
template<typename T1, typename T2, typename T3>
inline void gen_slot(const object& m_obj, const QString& m_method, T1 t1, T2 t2, T3 t3)
{
    try{
        general_slot(m_obj,m_method,t1,t2,t3);
    }
    catch (...)
    {}
}
template<typename T1, typename T2, typename T3, typename T4>
inline void gen_slot(const object& m_obj, const QString& m_method, T1 t1, T2 t2, T3 t3, T4 t4)
{
    try{
        general_slot(m_obj,m_method,t1,t2,t3,t4);
    }
    catch (...)
    {}
}

void QLuaSlot::general_slot()
{
    ::gen_slot(m_obj,m_method);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(char param)
{
    ::gen_slot(m_obj,m_method,param);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(short param)
{
    ::gen_slot(m_obj,m_method,param);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(int param)
{
    ::gen_slot(m_obj,m_method,param);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(double param)
{
    ::gen_slot(m_obj,m_method,param);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(bool param)
{
    ::gen_slot(m_obj,m_method,param);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QString& param)
{
    ::gen_slot(m_obj,m_method,param.toLocal8Bit().constData());
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QListWidgetItem* param)
{
    ::gen_slot(m_obj,m_method,param);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QListWidgetItem* param1,QListWidgetItem* param2)
{
    ::gen_slot(m_obj,m_method,param1,param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QTreeWidgetItem* param)
{
    ::gen_slot(m_obj,m_method,param);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QTreeWidgetItem* param1,QTreeWidgetItem* param2)
{
    ::gen_slot(m_obj,m_method,param1,param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QTreeWidgetItem* param1,int param2)
{
    ::gen_slot(m_obj,m_method,param1,param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(int param1, int param2)
{
    ::gen_slot(m_obj,m_method,param1,param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(int param1, int param2, int param3, int param4)
{
    ::gen_slot(m_obj,m_method,param1,param2,param3,param4);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QTableWidgetItem* param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QTableWidgetItem* param1, QTableWidgetItem* param2)
{
    ::gen_slot(m_obj,m_method,param1,param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(qint64 param1)
{
    ::gen_slot(m_obj,m_method, (int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QextPortInfo& param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QMdiSubWindow* param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QSystemTrayIcon::ActivationReason param1)
{
    ::gen_slot(m_obj,m_method,(int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QDate& param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QTime& param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QDateTime& param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QAction* param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QProcess::ProcessError param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QProcess::ExitStatus param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QProcess::ProcessState param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QWidget* param1, QWidget* param2)
{
    ::gen_slot(m_obj,m_method,param1,param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QWidget* param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QAbstractSocket::SocketError param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QAbstractSocket::SocketState param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QClipboard::Mode param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QHostInfo& param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(Qt::DropAction param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(int param1, bool param2)
{
    ::gen_slot(m_obj,m_method,param1,param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(qint64 param1,qint64 param2)
{
    ::gen_slot(m_obj,m_method,(int)param1,(int)param2);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QUrlInfo & param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(int param1,const QString& param2)
{
    ::gen_slot(m_obj,m_method,param1,param2.toLocal8Bit().constData());
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(Qt::DockWidgetAreas param1)
{
    ::gen_slot(m_obj,m_method,(int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(Qt::DockWidgetArea param1)
{
    ::gen_slot(m_obj,m_method,(int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(QDockWidget::DockWidgetFeatures param1)
{
    ::gen_slot(m_obj,m_method,(int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QSize& param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(Qt::ToolButtonStyle param1)
{
    ::gen_slot(m_obj,m_method,(int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(Qt::Orientation param1)
{
    ::gen_slot(m_obj,m_method,(int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(Qt::ToolBarAreas param1)
{
    ::gen_slot(m_obj,m_method,(int)param1);
    if(m_delete_when_done)this->deleteLater();
}

void QLuaSlot::general_slot(const QMouseEvent* param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}

#ifdef Q_OS_WIN
/*
void QLuaSlot::general_slot(const QUsbHidInfo& param1)
{
    ::gen_slot(m_obj,m_method,param1);
    if(m_delete_when_done)this->deleteLater();
}
*/
#endif
