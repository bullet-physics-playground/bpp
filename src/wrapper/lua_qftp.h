#ifndef LUA_QFTP_H
#define LUA_QFTP_H

#include "lua_qt.h"

#include <QFtp>

typedef class_<QFtp, QObject> LQFtp;
typedef class_<QUrlInfo> LQUrlInfo;

struct QTextCodec_wrap : public QTextCodec, wrap_base {
  QByteArray name() const { return call_member<QByteArray>(this, "name"); }
  static QByteArray def_name(QTextCodec *) {
    return QByteArray::fromRawData("wrong name", 10);
  }
  int mibEnum() const { return call_member<int>(this, "mibEnum"); }
  static int def_mibEnum(QTextCodec *) { return -1; }
};

typedef class_<QTextCodec, QTextCodec_wrap> LQTextCodec;
typedef class_<QTextDecoder> LQTextDecoder;
typedef class_<QTextEncoder> LQTextEncoder;

LQFtp lqftp();
LQUrlInfo lqurlinfo();
LQTextCodec lqtextcodec();
LQTextDecoder lqtextdecoder();
LQTextEncoder lqtextencoder();

#endif // LUA_QFTP_H
