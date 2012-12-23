#include "qserial.h"

#include <luabind/luabind.hpp>
#include "luabind/tag_function.hpp"
#include <luabind/out_value_policy.hpp>

#include "lua_qt.h"

#include "lua_qslot.h"

QextSerialEnumerator* QSerialPort::enumerator = 0;

static setter_map<QSerialPort> lqserialport_set_map;

SIGNAL_PROPERYT(lqserialport, connected, QSerialPort, "(const QextPortInfo&)")
SIGNAL_PROPERYT(lqserialport, disconnected, QSerialPort, "(const QextPortInfo&)")
SIGNAL_PROPERYT(lqserialport, readyRead, QSerialPort, "()")
SIGNAL_PROPERYT(lqserialport, bytesWritten, QSerialPort, "(qint64)")
SIGNAL_PROPERYT(lqserialport, aboutToClose, QSerialPort, "()")
SIGNAL_PROPERYT(lqserialport, readChannelFinished, QSerialPort, "()")
SIGNAL_PROPERYT(lqserialport, dsrChanged, QSerialPort, "(bool)")
SIGNAL_PROPERYT(lqserialport, settingChange, QSerialPort, "(const QString&)")
SIGNAL_PROPERYT(lqserialport, lineChanged, QSerialPort, "(int)")


void QSerialPort::initial()
{
    if(!enumerator){
        enumerator = new QextSerialEnumerator();
        enumerator->setUpNotifications();
    }
    connect(enumerator, SIGNAL(deviceDiscovered(QextPortInfo)), this, SIGNAL(connected(QextPortInfo)));
    connect(enumerator, SIGNAL(deviceRemoved(QextPortInfo)), this, SIGNAL(disconnected(QextPortInfo)));
}

void QSerialPort::deinitial()
{
    disconnect(enumerator, SIGNAL(deviceDiscovered(QextPortInfo)), this, SIGNAL(connected(QextPortInfo)));
    disconnect(enumerator, SIGNAL(deviceRemoved(QextPortInfo)), this, SIGNAL(disconnected(QextPortInfo)));
}

LQextPortInfo lqextportinfo()
{
    return
    class_<QextPortInfo>("QSerialInfo")
    .def(constructor<>())
    .def_readwrite("portName", &QextPortInfo::portName)
    .def_readwrite("friendName", &QextPortInfo::friendName)
    .def_readwrite("physName", &QextPortInfo::physName)
    .def_readwrite("enumName", &QextPortInfo::enumName)
    .def_readwrite("productID", &QextPortInfo::productID)
    .def_readwrite("vendorID", &QextPortInfo::vendorID)
    ;
}

LQPortSetting lqportsetting()
{
    return
    class_<PortSettings>("QPortSetting")
    .def(constructor<>())
    .def_readwrite("baudRate", &PortSettings::BaudRate)
    .def_readwrite("dataBits", &PortSettings::DataBits)
    .def_readwrite("flowControl", &PortSettings::FlowControl)
    .def_readwrite("parity", &PortSettings::Parity)
    .def_readwrite("stopBits", &PortSettings::StopBits)
    .def_readwrite("timeout", &PortSettings::Timeout_Millisec)
    ;
}

QSerialPort* lqserialport_init(QSerialPort* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqserialport_set_map);
}

template<>
void table_init_general<QSerialPort>(const luabind::argument & arg, const object& obj)
{
    lqserialport_init(construct<QSerialPort>(arg), obj);
}

QStringList validBaud()
{
    return validValues<BaudRateType>();
}

LQextSerialPort lqextserialport()
{
    return
    myclass_<QSerialPort>("QSerialPort",lqserialport_set_map)
    .def(constructor<>())
    .def(constructor<QObject*>())
    .def(constructor<QObject*,int>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&, QObject*>())
    .def(constructor<const QString&, QObject*, int>())
    .def(constructor<const QString&, const PortSettings&>())
    .def(constructor<const QString&, const PortSettings&, QObject*>())
    .def(constructor<const QString&, const PortSettings&, QObject*, int>())
    .def("__tostring", &QSerialPort::settingString)
    .def("__init", table_init_general<QSerialPort>)
    .def("__call", lqserialport_init)
    .def("setDtr", &QSerialPort::setDtr)
    .def("setDtr", tag_function<void(QSerialPort*)>(boost::bind(&QSerialPort::setDtr, _1, true)))
    .def("setRts", &QSerialPort::setRts)
    .def("setRts", tag_function<void(QSerialPort*)>(boost::bind(&QSerialPort::setRts, _1, true)))
    .def("lineStatus", &QSerialPort::lineStatus)
    .def("open", &QSerialPort::open)
    .def("open", tag_function<bool(QSerialPort*)>(boost::bind(&QSerialPort::open, _1, QSerialPort::ReadWrite)))

    .def("close", &QSerialPort::close)
    .def("flush", &QSerialPort::flush)
    .def("errorString", &QSerialPort::errorString)
    .def("setTimeout", &QSerialPort::setTimeout)
    .def("size", &QSerialPort::size)
    .def("bytesAvailable", &QSerialPort::bytesAvailable)
    .def("readAll", &QSerialPort::readAll)
    .def("bytesToWrite", &QSerialPort::bytesToWrite)
    .def("read", (QByteArray (QSerialPort::*)(qint64))&QSerialPort::read)
    .def("write", (qint64 (QSerialPort::*)(const char *,qint64))&QSerialPort::write)
//    .def("write", (qint64 (QSerialPort::*)(const char *))&QSerialPort::write)
    .def("write", &QSerialPort::writeDoh)
    .def("write", (qint64 (QSerialPort::*)(const QByteArray&))&QSerialPort::write)
//        .def("write", (qint64 (QSerialPort::*)(const QByteArray&))&QSerialPort::write)

    .def("setPortName", &QSerialPort::setPortName)
    .def("setQueryMode", &QSerialPort::setQueryMode)
    .def("setBaudRate", &QSerialPort::setBaudRate)
    .def("setDataBits", &QSerialPort::setDataBits)
    .def("setParity", &QSerialPort::setParity)
    .def("setFlowControl",  &QSerialPort::setFlowControl)
    .def("setStopBits",  &QSerialPort::setStopBits)

    .property("settingString", &QSerialPort::settingString)
    .property("portName", &QSerialPort::portName, &QSerialPort::setPortName)
    .property("queryMode", &QSerialPort::queryMode, &QSerialPort::setQueryMode)
    .property("baudRate", &QSerialPort::baudRate, &QSerialPort::setBaudRate)
    .property("dataBits", &QSerialPort::dataBits, &QSerialPort::setDataBits)
    .property("parity", &QSerialPort::parity, &QSerialPort::setParity)
    .property("stopBits", &QSerialPort::stopBits, &QSerialPort::setStopBits)
    .property("flowControl", &QSerialPort::flowControl, &QSerialPort::setFlowControl)
    .property("lineStatus", &QSerialPort::lineStatus)
    .property("CTS", &QSerialPort::CTS)
    .property("DSR", &QSerialPort::DSR)
    .property("DCD", &QSerialPort::DCD)
    .property("RI", &QSerialPort::RI)
    .property("RTS", &QSerialPort::RTS)
    .property("DTR", &QSerialPort::DTR)

    .sig_prop(lqserialport, connected)
    .sig_prop(lqserialport, disconnected)
    .sig_prop(lqserialport, readyRead)
    .sig_prop(lqserialport, bytesWritten)
    .sig_prop(lqserialport, aboutToClose)
    .sig_prop(lqserialport, readChannelFinished)
    .sig_prop(lqserialport, dsrChanged)
    .sig_prop(lqserialport, settingChange)
    .sig_prop(lqserialport, lineChanged)

    .class_<QSerialPort>::property("portSetting", &QSerialPort::portSetting, &QSerialPort::setPortSetting)
    .property("isOpen", &QSerialPort::isOpen)
    .property("isReadable", &QSerialPort::isReadable)
    .property("isWritable", &QSerialPort::isWritable)
    //.property("lastError", &QSerialPort::lastError)
    .property("errorString", &QSerialPort::errorString)
    .scope[
        def("enumPort", &QextSerialEnumerator::getPorts),
        def("ValidBaudRate", validBaud),
        def("ValidDataBits", validValues<DataBitsType>),
        def("ValidParity", validValues<ParityType>),
        def("ValidStopBits", validValues<StopBitsType>),
        def("ValidFlow", validValues<FlowType>)
    ]

    .enum_("QueryMode")[
        value("Polling", QSerialPort::Polling),
        value("EventDriven", QSerialPort::EventDriven)
    ]
    .enum_("BaudRateType")
    [
        value("BAUD50",BAUD50),                //POSIX ONLY
        value("BAUD75",BAUD75),                //POSIX ONLY
        value("BAUD110",BAUD110),
        value("BAUD134",BAUD134),               //POSIX ONLY
        value("BAUD150",BAUD150),               //POSIX ONLY
        value("BAUD200",BAUD200),               //POSIX ONLY
        value("BAUD300",BAUD300),
        value("BAUD600",BAUD600),
        value("BAUD1200",BAUD1200),
        value("BAUD1800",BAUD1800),              //POSIX ONLY
        value("BAUD2400",BAUD2400),
        value("BAUD4800",BAUD4800),
        value("BAUD9600",BAUD9600),
        value("BAUD14400",BAUD14400),             //WINDOWS ONLY
        value("BAUD19200",BAUD19200),
        value("BAUD38400",BAUD38400),
        value("BAUD56000",BAUD56000),             //WINDOWS ONLY
        value("BAUD57600",BAUD57600),
        value("BAUD76800",BAUD76800),             //POSIX ONLY
        value("BAUD115200",BAUD115200),
        value("BAUD128000",BAUD128000),            //WINDOWS ONLY
        value("BAUD256000",BAUD256000),            //WINDOWS ONLY
        value("BAUDLAST",BAUDLAST)
    ]
    .enum_("DataBitsType")
    [
        value("DATA_5",DATA_5),
        value("DATA_6",DATA_6),
        value("DATA_7",DATA_7),
        value("DATA_8",DATA_8)
    ]
    .enum_("ParityType")
    [
        value("PAR_NONE",PAR_NONE),
        value("PAR_ODD",PAR_ODD),
        value("PAR_EVEN",PAR_EVEN),
        value("PAR_MARK",PAR_MARK),               //WINDOWS ONLY
        value("PAR_SPACE",PAR_SPACE)
    ]
    .enum_("StopBitsType")
    [
        value("STOP_1",STOP_1),
        value("STOP_1_5",STOP_1_5),               //WINDOWS ONLY
        value("STOP_2",STOP_2)
    ]
    .enum_("FlowType")
    [
        value("FLOW_OFF",FLOW_OFF),
        value("FLOW_HARDWARE",FLOW_HARDWARE),
        value("FLOW_XONXOFF",FLOW_XONXOFF)
    ]
    .enum_("LineStatus")
    [
            value("LS_CTS",LS_CTS),
            value("LS_DSR",LS_DSR),
            value("LS_DCD",LS_DCD),
            value("LS_RI",LS_RI),
            value("LS_RTS",LS_RTS),
            value("LS_DTR",LS_DTR),
            value("LS_ST",LS_ST),
            value("LS_SR",LS_SR)
    ]
    ;
}

void QSerialPort::luaBind(lua_State *L) {
  luabind::open(L);
  luabind::module(L)
  [
      lqextserialport(),
      lqextportinfo(),
      lqportsetting()
  ];
}

qint64 QSerialPort::writeDoh(QString data) {
  return write(QByteArray(data.toAscii().constData()));
}
