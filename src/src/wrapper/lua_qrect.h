#ifndef LUA_QRECT_H
#define LUA_QRECT_H

#include "lua_qt.h"

typedef class_<QPoint>                      LQPoint;
typedef class_<QLine>                       LQLine;
typedef class_<QPolygon>                    LQPolygon;
typedef class_<QRect>                       LQRect;
typedef class_<QSize>                       LQSize;
typedef class_<QMargins>                    LQMargins;
typedef class_<QColor>                      LQColor;
typedef class_<QBrush>                      LQBrush;
typedef class_<QPen>                        LQPen;
typedef class_<QFont>                       LQFont;
typedef class_<QRegion>                     LQRegion;

LQPoint lqpoint();
LQLine lqline();
LQPolygon lqpolygon();
LQRect  lqrect();
LQSize  lqsize();
LQMargins lqmargins();
LQColor lqcolor();

LQBrush  lqbrush();
LQPen lqpen();
LQFont lqfont();
LQRegion lqregion();

#endif
