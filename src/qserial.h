#ifndef QSERIAL_H
#define QSERIAL_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <qextserialport.h>
#include <qextserialenumerator.h>

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

#include "bindings.h" // for Lua QString => string mapping

class QSerial;

std::ostream& operator<<(std::ostream& ostream, const QSerial& s);
std::ostream& operator<<(std::ostream& ostream, const QextPortInfo& p);

class QSerial : public QextSerialPort
{
    Q_OBJECT
public:
  explicit QSerial();
  explicit QSerial(const QString& port);

    QList<QextPortInfo> listPorts();

    // LUA helper functions
    static void luaBind(lua_State *s);
    QString toString() const;

    void open();

    int getBaudRate() const;
    
signals:
    void hasOutput(QString txt);
    void dsrChanged(bool status);
    
public slots:
    void onReadyRead();
    void onDsrChanged(bool status);
    
};

#endif // QSERIAL_H
