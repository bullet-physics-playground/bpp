#include "lua_network.h"

#include "lua_qslot.h"

namespace luabind{
QT_ENUM_CONVERTER(QHostAddress::SpecialAddress)
QT_ENUM_CONVERTER(QAbstractSocket::NetworkLayerProtocol)
QT_ENUM_CONVERTER(QAbstractSocket::SocketError)
QT_ENUM_CONVERTER(QNetworkProxy::ProxyType)
QT_ENUM_CONVERTER(QNetworkProxy::Capability)
QT_ENUM_CONVERTER(QNetworkProxy::Capabilities)
QT_ENUM_CONVERTER(QAbstractSocket::SocketType)
QT_ENUM_CONVERTER(QAbstractSocket::SocketState)
QT_ENUM_CONVERTER(QAbstractSocket::SocketOption)
QT_ENUM_CONVERTER(QHostInfo::HostInfoError)
QT_ENUM_CONVERTER(QNetworkInterface::InterfaceFlag)
QT_ENUM_CONVERTER(QNetworkInterface::InterfaceFlags)
QT_ENUM_CONVERTER(QUdpSocket::BindFlag)
QT_ENUM_CONVERTER(QUdpSocket::BindMode)
}

void lqhostaddress_setAddr_ipv6(QHostAddress* w, const QByteArray& arr)
{
    Q_IPV6ADDR v6;
    memcpy(v6.c, arr.data(), 16);
    w->setAddress(v6);
}

QByteArray lqhostaddress_to_ipv6(QHostAddress* w)
{
    Q_IPV6ADDR addr = w->toIPv6Address();
    return QByteArray::fromRawData((const char*)addr.c, sizeof(addr.c));
}

void lqhostaddress_init(const luabind::argument & arg, const QByteArray& arr)
{
    QHostAddress* r = construct<QHostAddress>(arg);
    Q_IPV6ADDR v6;
    memcpy(v6.c, arr.data(), 16);
    r->setAddress(v6);
}

LQHostAddress lqhostaddress()
{
    return
    class_<QHostAddress>("QHostAddress")
    .def(constructor<>())
    .def(constructor<const QString&>())
    .def(constructor<const QHostAddress&>())
    .def(constructor<QHostAddress::SpecialAddress>())
    .def("__init", lqhostaddress_init)
    .def("clear", &QHostAddress::clear)
    .def("isNull", &QHostAddress::isNull)
    .def("__tostring", &QHostAddress::toString)
    .def("toString", &QHostAddress::toString)
    .def("setAddress", (bool(QHostAddress::*)(const QString &))&QHostAddress::setAddress)
    .def("setAddress", (void(QHostAddress::*)(quint32))&QHostAddress::setAddress)
    .def("setAddress", lqhostaddress_setAddr_ipv6)
    .def("toIPv4Address", &QHostAddress::toIPv4Address)
    .def("toIPv6Address", lqhostaddress_to_ipv6)

    .property("scopeId", &QHostAddress::scopeId, &QHostAddress::setScopeId)
    .property("protocol", &QHostAddress::protocol)
    ;
}

static setter_map<QNetworkProxy> lqnp_set_map;
QNetworkProxy* lqnp_init(QNetworkProxy* widget, const object& table)
{
    lq_general_init(widget, table, lqnp_set_map);
    return widget;
}
template<>
void table_init_general<QNetworkProxy>(const luabind::argument & arg, const object& obj)
{
    lqnp_init(construct<QNetworkProxy>(arg), obj);
}

ENUM_FILTER(QNetworkProxy,type,setType)
ENUM_FILTER(QNetworkProxy,port,setPort)
ENUM_FILTER(QNetworkProxy,capabilities,setCapabilities)
LQNetworkProxy lqnetworkproxy()
{
    return
    myclass_<QNetworkProxy>("QNetworkProxy",lqnp_set_map)
    .def(constructor<>())
    .def(constructor<QNetworkProxy::ProxyType>())
    .def(constructor<QNetworkProxy::ProxyType,const QString&>())
    .def(constructor<QNetworkProxy::ProxyType,const QString&, quint16>())
    .def(constructor<QNetworkProxy::ProxyType,const QString&, quint16, const QString&>())
    .def(constructor<QNetworkProxy::ProxyType,const QString&, quint16, const QString&, const QString&>())
    .def("__call", lqnp_init)
    .def("__init", table_init_general<QNetworkProxy>)

    .property("hostName", &QNetworkProxy::hostName, &QNetworkProxy::setHostName)
    .property("isCachingProxy", &QNetworkProxy::isCachingProxy)
    .property("isTransparentProxy", &QNetworkProxy::isTransparentProxy)
    .property("capabilities", QNetworkProxy_capabilities, QNetworkProxy_setCapabilities)
    .property("password", &QNetworkProxy::password, &QNetworkProxy::setPassword)
    .property("port", QNetworkProxy_port, QNetworkProxy_setPort)
    .property("type", QNetworkProxy_type, QNetworkProxy_setType)
    .property("user", &QNetworkProxy::user, &QNetworkProxy::setUser)

    .scope[
            def("applicationProxy", &QNetworkProxy::applicationProxy),
            def("setApplicationProxy", &QNetworkProxy::setApplicationProxy)
    ]
    ;
}

bool lqtcpserver_listen1(QTcpServer* w)
{
    return w->listen();
}
bool lqtcpserver_listen2(QTcpServer* w, const QHostAddress& a)
{
    return w->listen(a);
}

bool lqtcpserver_waitForNewConnection1(QTcpServer* w)
{
    return w->waitForNewConnection();
}

bool lqtcpserver_waitForNewConnection2(QTcpServer* w, int ms)
{
    return w->waitForNewConnection(ms);
}

static setter_map<QTcpServer> lqtcpserver_set_map;
QTcpServer* lqtcpserver_init(QTcpServer* widget, const object& table)
{
    lq_general_init(widget, table, lqtcpserver_set_map);
    return widget;
}
template<>
void table_init_general<QTcpServer>(const luabind::argument & arg, const object& obj)
{
    lqtcpserver_init(construct<QTcpServer>(arg), obj);
}

SIGNAL_PROPERYT(lqtcpserver, newConnection, QTcpServer, "()")
LQTcpServer lqtcpserver()
{
    return
    myclass_<QTcpServer,QObject>("QTcpServer",lqtcpserver_set_map)
    .def(constructor<>())
    .def(constructor<QObject*>())
    .def("__call", lqtcpserver_init)
    .def("__init", table_init_general<QTcpServer>)
    .def("close", &QTcpServer::close)
    .def("listen", &QTcpServer::listen)
    .def("listen", lqtcpserver_listen1)
    .def("listen", lqtcpserver_listen2)
    .def("waitForNewConnection", lqtcpserver_waitForNewConnection1)
    .def("waitForNewConnection", lqtcpserver_waitForNewConnection2)
    .def("setSocketDescriptor", &QTcpServer::setSocketDescriptor)

    .property("hasPendingConnections", &QTcpServer::hasPendingConnections)
    .property("isListening", &QTcpServer::isListening)
    .property("maxPendingConnections", &QTcpServer::maxPendingConnections, &QTcpServer::setMaxPendingConnections)    
    .property("errorString", &QTcpServer::errorString)
    .property("socketDescriptor", &QTcpServer::socketDescriptor)
    .sig_prop(lqtcpserver, newConnection)

    .class_<QTcpServer,QObject>::property("serverError", &QTcpServer::serverError)
    .property("proxy", &QTcpServer::proxy, &QTcpServer::setProxy)
    .property("nextPendingConnection", &QTcpServer::nextPendingConnection)
    ;
}

void lqabstractsocket_connectToHost1(QAbstractSocket* w, const QString& a,quint16 port)
{
    w->connectToHost(a,port);
}
void lqabstractsocket_connectToHost2(QAbstractSocket* w, const QHostAddress& a,quint16 port)
{
    w->connectToHost(a,port);
}

void lqabstractsocket_setSocketDescriptor1(QAbstractSocket* w, int d)
{
    w->setSocketDescriptor(d);
}
void lqabstractsocket_setSocketDescriptor2(QAbstractSocket* w, int d,QAbstractSocket::SocketState s)
{
    w->setSocketDescriptor(d,s);
}
bool QAbstractSocket_waitForConnected(QAbstractSocket* w){return w->waitForConnected();}
bool QAbstractSocket_waitForDisconnected(QAbstractSocket* w){return w->waitForDisconnected();}
bool QAbstractSocket_waitForBytesWritten(QAbstractSocket* w){return w->waitForBytesWritten();}
bool QAbstractSocket_waitForReadyRead(QAbstractSocket* w){return w->waitForReadyRead();}

SIGNAL_PROPERYT(lqabstractsocket, aboutToClose, QAbstractSocket, "()")
SIGNAL_PROPERYT(lqabstractsocket, bytesWritten, QAbstractSocket, "(qint64)")
SIGNAL_PROPERYT(lqabstractsocket, readChannelFinished, QAbstractSocket, "()")
SIGNAL_PROPERYT(lqabstractsocket, readyRead, QAbstractSocket, "()")
SIGNAL_PROPERYT(lqabstractsocket, connected, QAbstractSocket, "()")
SIGNAL_PROPERYT(lqabstractsocket, disconnected, QAbstractSocket, "()")
SIGNAL_PROPERYT(lqabstractsocket, error, QAbstractSocket, "(QAbstractSocket::SocketError)")
SIGNAL_PROPERYT(lqabstractsocket, hostFound, QAbstractSocket, "()")
SIGNAL_PROPERYT(lqabstractsocket, stateChanged, QAbstractSocket, "(QAbstractSocket::SocketState)")

static setter_map<QAbstractSocket> lqabs_set_map;
QAbstractSocket* lqabs_init(QAbstractSocket* widget, const object& table)
{
    lq_general_init(widget, table, lqabs_set_map);
    return widget;
}

LQAbstractSocket lqabstractsocket()
{
    return
    myclass_<QAbstractSocket,QObject>("QAbstractSocket",lqabs_set_map)
    .def(constructor<QAbstractSocket::SocketType,QObject*>())
    .def("__call", lqabs_init)
    .def("abort", &QAbstractSocket::abort)
    .def("connectToHost", (void (QAbstractSocket::*)(const QString &,quint16,QIODevice::OpenMode))&QAbstractSocket::connectToHost)
    .def("connectToHost", (void (QAbstractSocket::*)(const QHostAddress&,quint16,QIODevice::OpenMode))&QAbstractSocket::connectToHost)
    .def("connectToHost",lqabstractsocket_connectToHost1)
    .def("connectToHost",lqabstractsocket_connectToHost2)
    .def("disconnectFromHost",&QAbstractSocket::disconnectFromHost)
    .def("flush",&QAbstractSocket::flush)
    .def("setSocketDescriptor",lqabstractsocket_setSocketDescriptor2)
    .def("setSocketDescriptor",&QAbstractSocket::setSocketDescriptor)
    .def("socketOption",&QAbstractSocket::socketOption)
    .def("setSocketOption",&QAbstractSocket::setSocketOption)
    .def("waitForConnected",&QAbstractSocket::waitForConnected)
    .def("waitForConnected",QAbstractSocket_waitForConnected)
    .def("waitForDisconnected",&QAbstractSocket::waitForDisconnected)
    .def("waitForDisconnected",QAbstractSocket_waitForDisconnected)

    .def("close",&QAbstractSocket::close)
    .def("waitForBytesWritten",&QAbstractSocket::waitForBytesWritten)
    .def("waitForBytesWritten",QAbstractSocket_waitForBytesWritten)
    .def("waitForReadyRead",&QAbstractSocket::waitForReadyRead)
    .def("waitForReadyRead",QAbstractSocket_waitForReadyRead)
    .def("flush", &QAbstractSocket::flush)
    .def("readAll", &QAbstractSocket::readAll)
    .def("read", (QByteArray (QAbstractSocket::*)(qint64))&QAbstractSocket::read)
    .def("write", (qint64 (QAbstractSocket::*)(const char *,qint64))&QAbstractSocket::write)
    .def("write", (qint64 (QAbstractSocket::*)(const char *))&QAbstractSocket::write)
    .def("write", (qint64 (QAbstractSocket::*)(const QByteArray&))&QAbstractSocket::write)


    .property("atEnd", &QAbstractSocket::atEnd)
    .property("bytesAvailable", &QAbstractSocket::bytesAvailable)
    .property("bytesToWrite", &QAbstractSocket::bytesToWrite)
    .property("canReadLine", &QAbstractSocket::canReadLine)
    .property("isSequential", &QAbstractSocket::isSequential)
    .property("isOpen", &QAbstractSocket::isOpen)
    .property("isReadable", &QAbstractSocket::isReadable)
    .property("isWritable", &QAbstractSocket::isWritable)

    .property("error",(QAbstractSocket::SocketError (QAbstractSocket::*)() const)&QAbstractSocket::error)
    .property("errorString",&QAbstractSocket::errorString)
    .property("isValid",&QAbstractSocket::isValid)
    .property("localAddress",&QAbstractSocket::localAddress)
    .property("localPort",&QAbstractSocket::localPort)
    .property("peerAddress",&QAbstractSocket::peerAddress)
    .property("peerName",&QAbstractSocket::peerName)
    .property("peerPort",&QAbstractSocket::peerPort)

    .property("socketDescriptor",&QAbstractSocket::socketDescriptor, lqabstractsocket_setSocketDescriptor1)

    .property("socketType",&QAbstractSocket::socketType)
    .property("state",&QAbstractSocket::state)

    .sig_prop(lqabstractsocket, aboutToClose)
    .sig_prop(lqabstractsocket, bytesWritten)
    .sig_prop(lqabstractsocket, readChannelFinished)
    .sig_prop(lqabstractsocket, readyRead)
    .sig_prop(lqabstractsocket, connected)
    .sig_prop(lqabstractsocket, disconnected)
    .sig_prop(lqabstractsocket, error)
    .sig_prop(lqabstractsocket, hostFound)
    .sig_prop(lqabstractsocket, stateChanged)

    .class_<QAbstractSocket,QObject>::property("proxy",&QAbstractSocket::proxy, &QAbstractSocket::setProxy)
    .property("readBufferSize",&QAbstractSocket::readBufferSize, &QAbstractSocket::setReadBufferSize)
    ;
}

static setter_map<QTcpSocket> lqtcps_set_map;
QTcpSocket* lqtcps_init(QTcpSocket* widget, const object& table)
{
    lqabs_init(widget,table);
    lq_general_init(widget, table, lqtcps_set_map);
    return widget;
}
template<>
void table_init_general<QTcpSocket>(const luabind::argument & arg, const object& obj)
{
    lqtcps_init(construct<QTcpSocket>(arg), obj);
}
LQTcpSocket lqtcpsocket()
{
    return
    myclass_<QTcpSocket,QAbstractSocket>("QTcpSocket",lqtcps_set_map)
    .def(constructor<>())
    .def(constructor<QObject*>())
    .def("__call", lqtcps_init)
    .def("__init", table_init_general<QTcpSocket>)
    ;
}


static setter_map<QUdpSocket> lqudps_set_map;
QUdpSocket* lqudps_init(QUdpSocket* widget, const object& table)
{
    lqabs_init(widget,table);
    lq_general_init(widget, table, lqudps_set_map);
    return widget;
}
template<>
void table_init_general<QUdpSocket>(const luabind::argument & arg, const object& obj)
{
    lqudps_init(construct<QUdpSocket>(arg), obj);
}
bool lqudpsocket_bind(QUdpSocket* w){ return w->bind(); }

extern lua_State* __pL;
void lqudpsocket_readDatagram(QUdpSocket* w, qint64 max)
{
    QByteArray res;
    QHostAddress addr;
    quint16 port;
    char* p = new char[max];
    qint64 len = w->readDatagram(p,max,&addr,&port);
    if(len>=0){
        res = QByteArray::fromRawData(p,len);
    }
    object obj = luabind::newtable(__pL);
    for(int i=0;i<len;i++){
        obj[i+1] = p[i];
    }
    obj.push(__pL);
    luabind::detail::make_pointee_instance(__pL, addr, boost::mpl::true_());
    ::lua_pushnumber(__pL,port);
    delete[] p;
}

void lqudpsocket_readDatagram2(qint64 max)
{
    QByteArray res;
    QHostAddress addr("192.168.0.195");
    quint16 port = 23234;
    char* p = new char[max];
    memset(p,37,max);
    res = QByteArray::fromRawData(p,max);
    delete[] p;
    object obj = luabind::newtable(__pL);
    for(int i=0;i<res.length();i++){
        obj[i+1] = (int)res.at(i);
    }
    obj.push(__pL);
    luabind::detail::make_pointee_instance(__pL, addr, boost::mpl::true_());
    ::lua_pushnumber(__pL,port);
    //return res;
}

LQUdpSocket lqudpsocket()
{
    return
    myclass_<QUdpSocket,QAbstractSocket>("QUdpSocket",lqudps_set_map)
    .def(constructor<>())
    .def(constructor<QObject*>())
    .def("bind", (bool (QUdpSocket::*)(quint16))&QUdpSocket::bind)
    .def("bind", lqudpsocket_bind)
    .def("bind", (bool (QUdpSocket::*)(quint16,QUdpSocket::BindMode))&QUdpSocket::bind)
    .def("bind", (bool (QUdpSocket::*)(const QHostAddress &,quint16,QUdpSocket::BindMode))&QUdpSocket::bind)
    .def("bind", (bool (QUdpSocket::*)(const QHostAddress &,quint16))&QUdpSocket::bind)
    .def("readDatagram", lqudpsocket_readDatagram)
    .def("writeDatagram", (qint64(QUdpSocket::*)( const QByteArray&,const QHostAddress&, quint16))&QUdpSocket::writeDatagram)

    .property("hasPendingDatagrams", &QUdpSocket::hasPendingDatagrams)
    .property("pendingDatagramSize", &QUdpSocket::pendingDatagramSize)
    .scope[
            def("test", lqudpsocket_readDatagram2)
    ]
    ;
}

int lqhostinfo_lookupHost(const QString& name, const object& obj)
{
    QLuaSlot* p = new QLuaSlot(obj,"dummy");
    return QHostInfo::lookupHost(name,p,SLOT(general_slot(QHostInfo)));
}

LQHostInfo lqhostinfo()
{
    return
    class_<QHostInfo>("QHostInfo")
    .def(constructor<>())
    .def(constructor<int>())
    .def(constructor<const QHostInfo&>())
    .property("addresses", &QHostInfo::addresses, &QHostInfo::setAddresses)
    .property("error", &QHostInfo::error, &QHostInfo::setError)
    .property("errorString", &QHostInfo::errorString, &QHostInfo::setErrorString)
    .property("hostName", &QHostInfo::hostName, &QHostInfo::setHostName)
    .property("lookupId", &QHostInfo::lookupId, &QHostInfo::setLookupId)
    .scope[
            def("abortHostLookup", &QHostInfo::abortHostLookup),
            def("fromName", &QHostInfo::fromName),
            def("localDomainName", &QHostInfo::localDomainName),
            def("localHostName", &QHostInfo::localHostName),
            def("lookupHost", lqhostinfo_lookupHost)
    ]
    ;
}

LQNetworkInterface lqnetworkinterface()
{
    return
    class_<QNetworkInterface>("QNetworkInterface")
    .def(constructor<>())
    .def(constructor<const QNetworkInterface&>())
    .property("addressEntries", &QNetworkInterface::addressEntries)
    .property("flags", &QNetworkInterface::flags)
    .property("hardwareAddress", &QNetworkInterface::hardwareAddress)
    .property("humanReadableName", &QNetworkInterface::humanReadableName)
    .property("index", &QNetworkInterface::index)
    .property("isValid", &QNetworkInterface::isValid)
    .property("name", &QNetworkInterface::name)
    .scope[
            def("allAddresses", &QNetworkInterface::allAddresses),
            def("allInterfaces", &QNetworkInterface::allInterfaces),
            def("interfaceFromIndex", &QNetworkInterface::interfaceFromIndex),
            def("interfaceFromName", &QNetworkInterface::interfaceFromName)
    ]
    ;
}

LQNetworkAddressEntry lqnetworkaddressentry()
{
    return
    class_<QNetworkAddressEntry>("QNetworkAddressEntry")
    .property("broadcast", &QNetworkAddressEntry::broadcast , &QNetworkAddressEntry::setBroadcast)
    .property("ip", &QNetworkAddressEntry::ip , &QNetworkAddressEntry::setIp)
    .property("netmask", &QNetworkAddressEntry::netmask , &QNetworkAddressEntry::setNetmask)
    .property("prefixLength", &QNetworkAddressEntry::prefixLength , &QNetworkAddressEntry::setPrefixLength)
    ;
}

