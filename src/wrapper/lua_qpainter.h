#ifndef LUA_QPAINTER_H
#define LUA_QPAINTER_H

#include "lua_qt.h"

typedef class_<QPainter> LQPainter;
typedef class_<QImage> LQImage;
typedef class_<QPixmap> LQPixmap;
typedef class_<QBitmap,QPixmap> LQBitmap;

LQPainter lqpainter();
LQImage lqimage();
LQPixmap lqpixmap();
LQBitmap lqbitmap();

#endif // LUA_QPAINTER_H
