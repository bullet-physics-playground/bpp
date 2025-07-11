#include "lua_util.h"
#include <luabind/adopt_policy.hpp>

static const char *toString(const QByteArray &arr) { return arr.data(); }

static QByteArray toBase64(const QByteArray &arr) { return arr.toBase64(); }

static QByteArray fromBase64(const QByteArray &arr) {
  return QByteArray::fromBase64(arr);
}

static QByteArray fromString(const QString &str) { return str.toAscii(); }

static int my_and(int x, int y) { return x & y; }
static int my_or(int x, int y) { return x | y; }
static int my_xor(int x, int y) { return x ^ y; }

template <typename T> static T toT(const QByteArray &arr) {
  T v = 0;
  if (arr.size() >= (int)sizeof(T)) {
    memcpy(&v, arr.data(), sizeof(T));
  }
  return v;
}

template <typename T> static T toT2(const QByteArray &arr, int from) {
  T v = 0;
  from--;
  if (arr.size() + from >= (int)sizeof(T)) {
    memcpy(&v, arr.data() + from, sizeof(T));
  }
  return v;
}

static inline void swap(void *pa, void *pb, uint32_t len) {
  if (len > 1) {
    uint8_t *p1 = (uint8_t *)pa;
    uint8_t *p2 = (uint8_t *)pb;
    uint8_t t = *p1;
    *p1 = *p2;
    *p2 = t;
    swap(p1 + 1, p2 - 1, len - 2);
  }
}

template <typename T> static T swap_bytes(T v) {
  T r = v;
  uint8_t *p = (uint8_t *)&r;
  swap(p, p + sizeof(T) - 1, sizeof(T));
  return r;
}

template <typename T> static T toTE(const QByteArray &arr, bool bigEndian) {
  return bigEndian ? swap_bytes(toT<T>(arr)) : toT<T>(arr);
}

template <typename T>
static T toTE2(const QByteArray &arr, int from, bool bigEndian) {
  return bigEndian ? swap_bytes(toT2<T>(arr, from)) : toT2<T>(arr, from);
}

template <typename T> static QByteArray fromT(T v) {
  QByteArray arr;
  T s = v;
  arr.resize(sizeof(T));
  memcpy(arr.data(), &s, sizeof(T));
  return arr;
}

template <typename T> static QByteArray fromTE(T v, bool bigEndian) {
  return bigEndian ? fromT(swap_bytes(v)) : fromT(v);
}

template <typename T> static QByteArray fromT1(const QByteArray &arr, T v) {
  QByteArray res(arr);
  res.append(fromT(v));
  return res;
}
template <typename T>
static QByteArray fromTE1(const QByteArray &arr, T v, bool bigEndian) {
  return bigEndian ? fromT1(arr, swap_bytes(v)) : fromT1(arr, v);
}

template <typename T>
static QByteArray fromT2(const QByteArray &arr, T v, int from) {
  from--;
  if (from >= arr.size()) {
    return fromT1(arr, v);
  }
  QByteArray res(arr);
  int newSize = from + sizeof(T);
  if (newSize > res.size()) {
    res.resize(newSize);
  }
  T s = v;
  memcpy(res.data() + from, &s, sizeof(T));
  return res;
}
template <typename T>
static QByteArray fromTE2(const QByteArray &arr, T v, int from,
                          bool bigEndian) {
  return bigEndian ? fromT2(arr, swap_bytes(v), from) : fromT2(arr, v, from);
}

static QString show_bytes(const QByteArray &arr, int base, int bytes_per_line,
                          QString delimer, QString newline) {
  QString res;
  int cnt = 0;
  for (int i = 0; i < arr.size(); i++) {
    res += QString("%1%2").arg(arr.at(i), 2, base, QChar('0')).arg(delimer);
    cnt++;
    if (cnt == bytes_per_line) {
      res += newline;
    }
  }
  return res;
}

static QString show_bytes1(const QByteArray &arr, int base, int bytes_per_line,
                           QString delimer) {
  return show_bytes(arr, base, bytes_per_line, delimer, QString("\r\n"));
}

static QString show_bytes2(const QByteArray &arr, int base,
                           int bytes_per_line) {
  return show_bytes1(arr, base, bytes_per_line, QString(" "));
}

static QString show_bytes3(const QByteArray &arr, int base) {
  return show_bytes2(arr, base, 32);
}

static QString show_bytes4(const QByteArray &arr) {
  return show_bytes3(arr, 16);
}

LQUtil lqutil() {
  return class_<QUtil>("QUtil").scope
      [def("toUint32", toT<uint32_t>), def("toUint16", toT<uint16_t>),
       def("toUint8", toT<uint8_t>), def("toInt32", toT<int32_t>),
       def("toInt16", toT<int16_t>), def("toInt8", toT<int8_t>),
       def("toFloat", toT<float>), def("toDouble", toT<double>),

       def("toUint32", toT2<uint32_t>), def("toUint16", toT2<uint16_t>),
       def("toUint8", toT2<uint8_t>), def("toInt32", toT2<int32_t>),
       def("toInt16", toT2<int16_t>), def("toInt8", toT2<int8_t>),
       def("toFloat", toT2<float>), def("toDouble", toT2<double>),

       def("fromUint32", fromT<uint32_t>), def("fromUint16", fromT<uint16_t>),
       def("fromUint8", fromT<uint8_t>), def("fromInt32", fromT<int32_t>),
       def("fromInt16", fromT<int16_t>), def("fromInt8", fromT<int8_t>),
       def("fromFloat", fromT<float>), def("fromDouble", fromT<double>),

       def("fromUint32", fromT1<uint32_t>), def("fromUint16", fromT1<uint16_t>),
       def("fromUint8", fromT1<uint8_t>), def("fromInt32", fromT1<int32_t>),
       def("fromInt16", fromT1<int16_t>), def("fromInt8", fromT1<int8_t>),
       def("fromFloat", fromT1<float>), def("fromDouble", fromT1<double>),

       def("fromUint32", fromT2<uint32_t>), def("fromUint16", fromT2<uint16_t>),
       def("fromUint8", fromT2<uint8_t>), def("fromInt32", fromT2<int32_t>),
       def("fromInt16", fromT2<int16_t>), def("fromInt8", fromT2<int8_t>),
       def("fromFloat", fromT2<float>), def("fromDouble", fromT2<double>),

       // support for bigendian
       def("toUint32", toTE<uint32_t>), def("toUint16", toTE<uint16_t>),
       def("toUint8", toTE<uint8_t>), def("toInt32", toTE<int32_t>),
       def("toInt16", toTE<int16_t>), def("toInt8", toTE<int8_t>),
       def("toFloat", toTE<float>), def("toDouble", toTE<double>),

       def("toUint32", toTE2<uint32_t>), def("toUint16", toTE2<uint16_t>),
       def("toUint8", toTE2<uint8_t>), def("toInt32", toTE2<int32_t>),
       def("toInt16", toTE2<int16_t>), def("toInt8", toTE2<int8_t>),
       def("toFloat", toTE2<float>), def("toDouble", toTE2<double>),

       def("fromUint32", fromTE<uint32_t>), def("fromUint16", fromTE<uint16_t>),
       def("fromUint8", fromTE<uint8_t>), def("fromInt32", fromTE<int32_t>),
       def("fromInt16", fromTE<int16_t>), def("fromInt8", fromTE<int8_t>),
       def("fromFloat", fromTE<float>), def("fromDouble", fromTE<double>),

       def("fromUint32", fromTE1<uint32_t>),
       def("fromUint16", fromTE1<uint16_t>), def("fromUint8", fromTE1<uint8_t>),
       def("fromInt32", fromTE1<int32_t>), def("fromInt16", fromTE1<int16_t>),
       def("fromInt8", fromTE1<int8_t>), def("fromFloat", fromTE1<float>),
       def("fromDouble", fromTE1<double>),

       def("fromUint32", fromTE2<uint32_t>),
       def("fromUint16", fromTE2<uint16_t>), def("fromUint8", fromTE2<uint8_t>),
       def("fromInt32", fromTE2<int32_t>), def("fromInt16", fromTE2<int16_t>),
       def("fromInt8", fromTE2<int8_t>), def("fromFloat", fromTE2<float>),
       def("fromDouble", fromTE2<double>),

       def("showBytes", show_bytes), def("showBytes", show_bytes1),
       def("showBytes", show_bytes2), def("showBytes", show_bytes3),
       def("showBytes", show_bytes4)];
}
