#include "qserial.h"

#include <QDebug>

#include <lua.hpp>
#include <luabind/luabind.hpp>
#include <luabind/function.hpp>
#include <luabind/class.hpp>

using namespace std;

std::ostream& operator<<(std::ostream& ostream, const QSerial& s) {
    ostream << s.toString().toAscii().data();
    return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const QextPortInfo& p) {
  ostream << p.portName.toAscii().data() << " (" << p.vendorID << ":" << p.productID << ")";
    return ostream;
}

QSerial::QSerial() : QextSerialPort()
{
}

QSerial::QSerial(const QString& port) : QextSerialPort()
{
  setPortName(port);
  open();
}

QList<QextPortInfo> QSerial::listPorts() {
  return QextSerialEnumerator::getPorts();
}

QString QSerial::toString() const {
  return tr("Serial: port %1 %2 baud (%3)").arg(portName()).arg(getBaudRate()).arg(isOpen() ? "open" : "closed");
}

void QSerial::luaBind(lua_State *s) {
  using namespace luabind;

  luabind::open(s);

  module(s)
  [
    class_<QSerial>("Serial")
    .def(constructor<>(), adopt(result))
    .def(constructor<const QString&>(), adopt(result))
    .def("open", &QSerial::open)
    .def("close", &QSerial::close)
    .def("flush", &QSerial::flush)
    .def("listPorts", &QSerial::listPorts)
    .def(tostring(const_self))
  ];

  module(s)
  [
    class_<QextPortInfo>("QextPortInfo")
    .def_readonly("enumName", &QextPortInfo::enumName)
    .def_readonly("friendName",  &QextPortInfo::friendName)
    .def_readonly("physname", &QextPortInfo::physName)
    .def_readonly("portName", &QextPortInfo::portName)
    .def_readonly("productID", &QextPortInfo::productID)
    .def_readonly("vendorID", &QextPortInfo::vendorID)
    .def(tostring(const_self))
  ];
}

void QSerial::open() {
  if (QextSerialPort::open(QIODevice::ReadWrite)) {
    connect(this, SIGNAL(readyRead()), this, SLOT(onReadyRead()));
    connect(this, SIGNAL(dsrChanged(bool)), this, SLOT(onDsrChanged(bool)));

    setBaudRate(BAUD9600);
    setFlowControl(FLOW_OFF);
    setParity(PAR_NONE);
    setDataBits(DATA_8);
    setStopBits(STOP_1);

    emit hasOutput("Serial: listening for data on " + portName() + ".");

    if (!(lineStatus() & LS_DSR)) {
      emit hasOutput("Serial: warning, device is not turned on.");
    }

  } else {
    emit hasOutput("Serial: failed to open " + errorString() + ".");
  }
}

void QSerial::onReadyRead() {
  QByteArray bytes;
  int a = bytesAvailable();

  bytes.resize(a);
  read(bytes.data(), bytes.size());

  emit hasOutput(QString(bytes));
}

void QSerial::onDsrChanged(bool status) {
  if (status)
    qDebug() << "device was turned on";
  else
    qDebug() << "device was turned off";

  emit dsrChanged(status);
}

int QSerial::getBaudRate() const {
  switch (baudRate()) {
  case BAUD50:
    return 50;
  case BAUD75:
    return 75;
  case BAUD110:
    return 110;
  case BAUD134:
    return 134;
  case BAUD150:
    return 150;
  case BAUD200:
    return 200;
  case BAUD300:
    return 300;
  case BAUD600:
    return 600;
  case BAUD1200:
    return 1200;
  case BAUD1800:
    return 1800;
  case BAUD2400:
    return 2400;
  case BAUD4800:
    return 4800;
  case BAUD9600:
    return 9600;
  case BAUD14400:
    return 14400;
  case BAUD19200:
    return 19200;
  case BAUD38400:
    return 38400;
  case BAUD56000:
    return 56000;
  case BAUD57600:
    return 57600;
  case BAUD76800:
    return 76800;
  case BAUD115200:
    return 115200;
  default:
    return 0;
  }
}
