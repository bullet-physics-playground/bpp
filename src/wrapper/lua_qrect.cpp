#include "lua_qrect.h"
#include "luabind/operator.hpp"
static setter_map<QPoint> lqpoint_set_map;
static setter_map<QLine> lqline_set_map;
static setter_map<QRect> lqrect_set_map;
static setter_map<QSize> lqsize_set_map;
static setter_map<QMargins> lqmargins_set_map;
static setter_map<QColor> lqcolor_set_map;
static setter_map<QBrush> lqbrush_set_map;
static setter_map<QPen> lqpen_set_map;
static setter_map<QFont> lqfont_set_map;

template<>
void table_init_general<QPoint>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QPoint>(arg), obj, lqpoint_set_map);
}
template<>
void table_init_general<QLine>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QLine>(arg), obj, lqline_set_map);
}
template<>
void table_init_general<QRect>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QRect>(arg), obj, lqrect_set_map);
}

template<>
void table_init_general<QSize>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QSize>(arg), obj, lqsize_set_map);
}

template<>
void table_init_general<QMargins>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QMargins>(arg), obj, lqmargins_set_map);
}

template<>
void table_init_general<QColor>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QColor>(arg), obj, lqcolor_set_map);
}

template<>
void table_init_general<QBrush>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QBrush>(arg), obj, lqbrush_set_map);
}

template<>
void table_init_general<QPen>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QPen>(arg), obj, lqpen_set_map);
}

template<>
void table_init_general<QFont>(const luabind::argument & arg, const object& obj)
{
    lq_general_init(construct<QFont>(arg), obj, lqfont_set_map);
}

QPoint* lqpoint_init(QPoint* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqpoint_set_map);
}
QLine* lqline_init(QLine* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqline_set_map);
}
QRect* lqrect_init(QRect* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqrect_set_map);
}
QSize* lqsize_init(QSize* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqsize_set_map);
}
QMargins* lqmargins_init(QMargins* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqmargins_set_map);
}
QColor* lqcolor_init(QColor* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqcolor_set_map);
}

QBrush* lqbrush_init(QBrush* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqbrush_set_map);
}

QPen* lqpen_init(QPen* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqpen_set_map);
}

QFont* lqfont_init(QFont* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqfont_set_map);
}

namespace luabind{
    QT_EMUN_CONVERTER(Qt::BrushStyle)
    QT_EMUN_CONVERTER(Qt::GlobalColor)
}

LQPoint lqpoint()
{
    return
    myclass_<QPoint>("QPoint", lqpoint_set_map)
    .def(constructor<>())
    .def(constructor<int,int>())
    .def("__call", lqpoint_init)
    .def("__init", table_init_general<QPoint>)

    .property("x", &QPoint::x, &QPoint::setX)
    .property("y", &QPoint::y, &QPoint::setY)
    ;
}

LQLine lqline()
{
    return
    myclass_<QLine>("QLine", lqline_set_map)
    .def(constructor<>())
    .def(constructor<const QPoint &,const QPoint &>())
    .def(constructor<int,int,int,int>())
    .def("__call", &lqline_init)
    .def("__init", table_init_general<QLine>)
    .def("setLine", &QLine::setLine)
    .def("setPoints", &QLine::setPoints)
    .def("translate", (void(QLine::*)(int,int))&QLine::translate)
    .def("translate", (void(QLine::*)(const QPoint&))&QLine::translate)
    .def("translated", (QLine(QLine::*)(int,int)const)&QLine::translated)
    .def("translated", (QLine(QLine::*)(const QPoint&)const)&QLine::translated)

    .property("isNull", &QLine::isNull)
    .property("x1", &QLine::x1)
    .property("x2", &QLine::x2)
    .property("y1", &QLine::y1)
    .property("y2", &QLine::y2)
    .property("dx", &QLine::dx)
    .property("dy", &QLine::dy)
    .property("p1", &QLine::p1, &QLine::setP1)
    .property("p2", &QLine::p2, &QLine::setP2)
    ;
}
int lqpolygon_count(QPolygon* p)
{
    return p->count();
}
int lqpolygon_count2(QPolygon* p, const QPoint& pt)
{
    return p->count(pt);
}
LQPolygon lqpolygon()
{
    return
    class_<QPolygon>("QPolygon")
    .def(constructor<>())
    .def(constructor<int>())
    .def(constructor<const QVector<QPoint>&>())
    .def(constructor<const QPolygon &>())
    .def(constructor<const QRect &>())
    .def(constructor<const QRect &,bool>())

    .def("boundingRect", &QPolygon::boundingRect)
    .def("containsPoint", &QPolygon::containsPoint)
    .def("intersected", &QPolygon::intersected)
    .def("subtracted", &QPolygon::subtracted)
    .def("united", &QPolygon::united)
    .def("point", (QPoint (QPolygon::*)(int) const)&QPolygon::point)
    .def("point", (void (QPolygon::*)(int,const QPoint&))&QPolygon::setPoint)
    .def("point", (void (QPolygon::*)(int,int,int))&QPolygon::setPoint)

    .def("translate", (void(QPolygon::*)(int,int))&QPolygon::translate)
    .def("translate", (void(QPolygon::*)(const QPoint&))&QPolygon::translate)
    .def("translated", (QPolygon(QPolygon::*)(int,int)const)&QPolygon::translated)
    .def("translated", (QPolygon(QPolygon::*)(const QPoint&)const)&QPolygon::translated)
    .def("append", &QPolygon::append )
    .def("push_back", &QPolygon::push_back )
    .def("push_front", &QPolygon::push_front )
    .def("count", lqpolygon_count)
    .def("count", lqpolygon_count2)
    ;
}

LQRect  lqrect()
{
    return
    myclass_<QRect>("QRect", lqrect_set_map)
    .def(constructor<>())
    .def(constructor<const QPoint &,const QPoint &>())
    .def(constructor<const QPoint &,const QSize &>())
    .def(constructor<int,int,int,int>())
    .def("__call", &lqrect_init)
    .def("__init", &table_init_general<QRect>)
    .def("intersect", &QRect::intersect)
    .def("intersected", &QRect::intersected)
    .def("intersects", &QRect::intersects)
    .def("contains", (bool (QRect::*)(int, int, bool) const)&QRect::contains)
    .def("contains", (bool (QRect::*)(int, int) const)&QRect::contains)
    .def("contains", (bool (QRect::*)(const QPoint&, bool) const)&QRect::contains)
    .def("contains", (bool (QRect::*)(const QRect&, bool) const)&QRect::contains)

    .property("x", &QRect::x, &QRect::setX)
    .property("y", &QRect::y, &QRect::setY)
    .property("left", &QRect::left, &QRect::setLeft)
    .property("right", &QRect::right, &QRect::setRight)
    .property("width", &QRect::width, &QRect::setWidth)
    .property("height", &QRect::height, &QRect::setHeight)
    .property("w", &QRect::width, &QRect::setWidth)
    .property("h", &QRect::height, &QRect::setHeight)
    .property("top", &QRect::top, &QRect::setTop)
    .property("bottom", &QRect::bottom, &QRect::setBottom)
    .property("topLeft", &QRect::topLeft, &QRect::setTopLeft)
    .property("topRight", &QRect::topRight, &QRect::setTopRight)
    .property("bottomLeft", &QRect::bottomLeft, &QRect::setBottomLeft)
    .property("bottomRight", &QRect::bottomRight, &QRect::setBottomRight)
    .property("size", &QRect::size, &QRect::setSize)
    .property("center", &QRect::center)

    ;
}
LQSize  lqsize()
{
    return
    myclass_<QSize>("QSize", lqsize_set_map)
    .def(constructor<>())
    .def(constructor<int,int>())
    .def("__call", &lqsize_init)
    .def("__init", &table_init_general<QSize>)

    .property("width", &QSize::width, &QSize::setWidth)
    .property("height", &QSize::height, &QSize::setHeight)
    .property("w", &QSize::width, &QSize::setWidth)
    .property("h", &QSize::height, &QSize::setHeight)
    ;
}

LQMargins lqmargins()
{
    return
    myclass_<QMargins>("QMargins", lqmargins_set_map)
    .def(constructor<>())
    .def(constructor<int,int,int,int>())
    .def("__call", &lqmargins_init)
    .def("__init", &table_init_general<QMargins>)

    .property("left", &QMargins::left, &QMargins::setLeft)
    .property("right", &QMargins::right, &QMargins::setRight)
    .property("top", &QMargins::top, &QMargins::setTop)
    .property("bottom", &QMargins::bottom, &QMargins::setBottom)
    ;
}
namespace luabind{
    QT_EMUN_CONVERTER(QRegion::RegionType)
}

void lqregion_setRects(QRegion* w, const QVector<QRect>& rects)
{
    QRect* rs = new QRect[rects.count()];
    for(int i=0;i<rects.count();++i){
        rs[i] = rects[i];
    }
    w->setRects(rs, rects.count());
    delete [] rs;
}

LQRegion lqregion()
{
    return
    class_<QRegion>("QRegion")
    .def(constructor<int,int,int,int>())
    .def(constructor<int,int,int,int,QRegion::RegionType>())
    .def(constructor<const QPolygon&>())
    .def(constructor<const QPolygon&, Qt::FillRule>())
    .def(constructor<const QRegion&>())
    .def(constructor<const QBitmap&>())
    .def(constructor<const QRect&>())
    .def(constructor<const QRect&,QRegion::RegionType>())

    .property("boundingRect", &QRegion::boundingRect)
    .def("contains", (bool(QRegion::*)(const QPoint&)const)&QRegion::contains)
    .def("contains", (bool(QRegion::*)(const QRect&)const)&QRegion::contains)
    .def("intersected", (QRegion(QRegion::*)(const QRegion&)const)&QRegion::intersected)
    .def("intersected", (QRegion(QRegion::*)(const QRect&)const)&QRegion::intersected)
    .def("intersects", (bool(QRegion::*)(const QRegion&)const)&QRegion::intersects)
    .def("intersects", (bool(QRegion::*)(const QRect&)const)&QRegion::intersects)
    .def("isEmpty", &QRegion::isEmpty)
    .property("rectCount", &QRegion::rectCount)
    .property("rects", &QRegion::rects)
    .def("setRects", lqregion_setRects)
    .def("subtracted", &QRegion::subtracted)
    .def("translate", (void(QRegion::*)(int,int))&QRegion::translate)
    .def("translate", (void(QRegion::*)(const QPoint&))&QRegion::translate)
    .def("translated", (QRegion(QRegion::*)(int,int)const)&QRegion::translated)
    .def("translated", (QRegion(QRegion::*)(const QPoint&)const)&QRegion::translated)
    .def("united", (QRegion(QRegion::*)(const QRect&)const)&QRegion::united)
    .def("united", (QRegion(QRegion::*)(const QRegion&)const)&QRegion::united)
    .def("xored", &QRegion::xored)
    .def(const_self == const_self)
    .def(self + const_self)
    .def(self - const_self)
    .def(self + other<const QRect&>())
    .def(self - other<const QRect&>())
    ;
}

LQColor lqcolor()
{
    return
    myclass_<QColor>("QColor", lqcolor_set_map)
    .def(constructor<>())
    .def(constructor<Qt::GlobalColor>())
    .def(constructor<int,int,int>())
    .def(constructor<int,int,int,int>())
    .def(constructor<const QString&>())
    .def(constructor<const QColor&>())
    .def("__call", &lqcolor_init)
    .def("__init", &table_init_general<QColor>)
    .def("__tostring", &QColor::name)

    .property("red", &QColor::red, &QColor::setRed)
    .property("green", &QColor::green, &QColor::setGreen)
    .property("blue", &QColor::blue, &QColor::setBlue)
    .property("r", &QColor::red, &QColor::setRed)
    .property("g", &QColor::green, &QColor::setGreen)
    .property("b", &QColor::blue, &QColor::setBlue)
    .property("name", &QColor::name, &QColor::setNamedColor)
    ;
}


void lqbursh_set_style(QBrush* f, int s)
{
    f->setStyle(Qt::BrushStyle(s));
}

int lqbursh_get_style(QBrush* f)
{
    return f->style();
}

LQBrush  lqbrush()
{
    return
    myclass_<QBrush>("QBrush", lqbrush_set_map)
    .def(constructor<>())
    .def(constructor<Qt::BrushStyle>())
    .def(constructor<const QColor &>())
    .def(constructor<const QColor &, Qt::BrushStyle>())
    .def(constructor<Qt::GlobalColor>())
    .def(constructor<Qt::GlobalColor, Qt::BrushStyle>())
    .def(constructor<const QPixmap&>())
    .def(constructor<const QImage&>())
    .def(constructor<const QBrush&>())
    .def("__call", &lqbrush_init)
    .def("__init", &table_init_general<QBrush>)
    .def("setColor", (void(QBrush::*)(Qt::GlobalColor))&QBrush::setColor)

    .property("color", &QBrush::color, (void(QBrush::*)(const QColor&))&QBrush::setColor)
    .property("style", lqbursh_get_style, lqbursh_set_style)
    ;
}

namespace luabind{
QT_EMUN_CONVERTER(Qt::PenStyle)
}

ENUM_FILTER(QPen,capStyle,setCapStyle)
ENUM_FILTER(QPen,style,setStyle)
ENUM_FILTER(QPen,joinStyle,setJoinStyle)
LQPen lqpen()
{
    return
    myclass_<QPen>("QPen",lqpen_set_map)
    .def(constructor<>())
    .def(constructor<Qt::PenStyle>())
    .def(constructor<const QColor&>())
    .def(constructor<const QPen&>())
    .def(constructor<const QBrush&, qreal>())
    .def(constructor<const QBrush&, qreal, Qt::PenStyle>())
    .def(constructor<const QBrush&, qreal, Qt::PenStyle, Qt::PenCapStyle>())
    .def(constructor<const QBrush&, qreal, Qt::PenStyle, Qt::PenCapStyle, Qt::PenJoinStyle>())
    .property("isSolid", &QPen::isSolid)
    .property("color", &QPen::color, &QPen::setColor)
    .property("width", &QPen::width, &QPen::setWidth)
    .property("capStyle", QPen_capStyle, QPen_setCapStyle)
    .property("style", QPen_style, QPen_setStyle)
    .property("joinStyle", QPen_joinStyle, QPen_setJoinStyle)
    .property("dashOffset", &QPen::dashOffset, &QPen::setDashOffset)
    .class_<QPen>::property("dashPattern", &QPen::dashPattern, &QPen::setDashPattern)
    ;
}

void lqfont_set_cap(QFont* f, int cap)
{
    f->setCapitalization(QFont::Capitalization( cap));
}

int lqfont_get_cap(QFont* f)
{
    return f->capitalization();
}

void lqfont_set_style(QFont* f, int s)
{
    f->setStyle(QFont::Style(s));
}

int lqfont_get_style(QFont* f)
{
    return f->style();
}

LQFont lqfont()
{
    return
    myclass_<QFont>("QFont", lqfont_set_map)
    .def(constructor<>())
    .def(constructor<const QFont &>())
    .def(constructor<const QString &>())
    .def(constructor<const QString &,int>())
    .def(constructor<const QString &,int,int>())
    .def(constructor<const QString &,int,int,bool>())
    .def("__call", &lqfont_init)
    .def("__init", &table_init_general<QFont>)

    .property("family", &QFont::family, &QFont::setFamily)
    .property("bold", &QFont::bold, &QFont::setBold)
    .property("capitalization", lqfont_get_cap, lqfont_set_cap)
    .property("fixedPitch", &QFont::fixedPitch, &QFont::setFixedPitch)
    .property("italic", &QFont::italic, &QFont::setItalic)
    .property("kerning", &QFont::kerning, &QFont::setKerning)
    .property("overline", &QFont::overline, &QFont::setOverline)
    .property("pixelSize", &QFont::pixelSize, &QFont::setPixelSize)
    .property("pointSize", &QFont::pointSize, &QFont::setPointSize)
    .property("stretch", &QFont::stretch, &QFont::setStretch)
    .property("strikeOut", &QFont::strikeOut, &QFont::setStrikeOut)
    .property("style", lqfont_get_style, lqfont_set_style)
    .property("underline", &QFont::underline, &QFont::setUnderline)
    .property("weight", &QFont::weight, &QFont::setWeight)
    .property("wordSpacing", &QFont::wordSpacing, &QFont::setWordSpacing)
    ;
}
