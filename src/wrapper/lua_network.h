#ifndef LUA_NETWORK_H
#define LUA_NETWORK_H

#include "lua_qt.h"

#include <QtNetwork>

typedef class_<QHostAddress>  LQHostAddress;
typedef class_<QNetworkProxy> LQNetworkProxy;
typedef class_<QTcpServer,QObject>  LQTcpServer;
typedef class_<QAbstractSocket,QObject>  LQAbstractSocket;
typedef class_<QTcpSocket,QAbstractSocket>  LQTcpSocket;
typedef class_<QUdpSocket,QAbstractSocket>  LQUdpSocket;
typedef class_<QHostInfo>   LQHostInfo;
typedef class_<QNetworkInterface> LQNetworkInterface;
typedef class_<QNetworkAddressEntry> LQNetworkAddressEntry;

LQHostAddress lqhostaddress();
LQNetworkProxy lqnetworkproxy();
LQTcpServer lqtcpserver();
LQAbstractSocket lqabstractsocket();
LQTcpSocket lqtcpsocket();
LQUdpSocket lqudpsocket();
LQHostInfo lqhostinfo();
LQNetworkInterface lqnetworkinterface();
LQNetworkAddressEntry lqnetworkaddressentry();

#endif // LUA_NETWORK_H
