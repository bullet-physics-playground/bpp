#include "lua_qpainter.h"
#include "luabind/tag_function.hpp"
#include "luabind/out_value_policy.hpp"
namespace luabind{
template <>
struct default_converter<QPolygon>
  : native_converter_base<QPolygon>
{
    static int compute_score(lua_State* L, int index)
    {
        return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
    }

    QPolygon from(lua_State* L, int index)
    {
        object obj(luabind::from_stack(L,index));
        QPolygon arr;
        for(iterator i(obj),e; i!=e; ++i){
            QPoint v;
            if(is_class<QPoint>(*i)){
                v = object_cast<QPoint>(*i);
                arr.append(v);
            }
        }
        return arr;
    }

    void to(lua_State* L, QPolygon const& arr)
    {
        object obj = luabind::newtable(L);
        for(int i=0;i<arr.count();i++){
            obj[i+1] = arr.at(i);
        }
        obj.push(L);
    }
};

template <>
struct default_converter<QPolygon const&>
  : default_converter<QPolygon>
{};
}

bool lqpainter_begin(QPainter* p, QWidget* w)
{
    return p->begin(w);
}

bool lqpainter_begin2(QPainter* p, QImage* w)
{
    return p->begin(w);
}

bool lqpainter_begin3(QPainter* p, QPixmap* w)
{
    return p->begin(w);
}

namespace luabind{
    QT_EMUN_CONVERTER(Qt::BGMode)
    QT_EMUN_CONVERTER(Qt::BrushStyle)
    QT_EMUN_CONVERTER(Qt::PenStyle)
    QT_EMUN_CONVERTER(QPainter::RenderHint)
    QT_EMUN_CONVERTER(QPainter::RenderHints)
    QT_EMUN_CONVERTER(Qt::SizeMode)
    QT_EMUN_CONVERTER(Qt::GlobalColor)
    QT_EMUN_CONVERTER(Qt::ImageConversionFlags)
    QT_EMUN_CONVERTER(Qt::MaskMode)
    QT_EMUN_CONVERTER(Qt::AspectRatioMode)
    QT_EMUN_CONVERTER(Qt::TransformationMode)
}


#define _r const QRect&
#define _ri int,int,int,int
#define _i int
#define _p const QPoint&
#define _pi int,int
#define _s const QString&
#define _g const QPolygon&
#define _l const QLine&
#define _vl const QVector<QLine>&
#define _vp const QVector<QPoint>&
#define _vr const QVector<QRect>&
#define _m const QImage&
#define _mc Qt::ImageConversionFlags
#define _x const QPixmap&
#define _d qreal
#define _CT(a,arg...)        (void(QPainter::*)(a, ## arg))
#define _CF(a,arg...)        void(QPainter*, a, ## arg)

LQPainter lqpainter()
{
    return
    class_<QPainter>("QPainter")
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<QImage*>())
    .def(constructor<QPixmap*>())
    .def("begin", lqpainter_begin)
    .def("begin", lqpainter_begin2)
    .def("begin", lqpainter_begin3)
    //.def("end", &QPainter::end) /* end is a keyword in lua*/
    .def("done", &QPainter::end)
    .def("save", &QPainter::save)
    .def("restore", &QPainter::restore)
    .def("boundingRect", (QRect(QPainter::*)(int,int,int,int,int,const QString&))&QPainter::boundingRect)
    .def("boundingRect", (QRect(QPainter::*)(const QRect&,int,const QString&))&QPainter::boundingRect)
    .def("scale", &QPainter::scale)
    .def("setPen", (void (QPainter::*)(const QPen&))&QPainter::setPen)
    .def("setPen", (void (QPainter::*)(const QColor&))&QPainter::setPen)
    .def("setPen", (void (QPainter::*)(Qt::PenStyle))&QPainter::setPen)
    .def("setBrush", (void (QPainter::*)(const QBrush&))&QPainter::setBrush)
    .def("setBrush", (void (QPainter::*)(Qt::BrushStyle))&QPainter::setBrush)
    .def("setBrushOrigin", (void (QPainter::*)(const QPoint&))&QPainter::setBrushOrigin)
    .def("setBrushOrigin", (void (QPainter::*)(int,int))&QPainter::setBrushOrigin)
    .def("setRenderHints", &QPainter::setRenderHints)
    .def("setRenderHint", &QPainter::setRenderHint)
    .def("setRenderHint", tag_function<void(QPainter*, QPainter::RenderHint)>(boost::bind(&QPainter::setRenderHint, _1, _2, true)))

    .property("brush", &QPainter::brush, (void (QPainter::*)(const QBrush&))&QPainter::setBrush)
    .property("brushOrigin", &QPainter::brushOrigin, (void (QPainter::*)(const QPoint&))&QPainter::setBrushOrigin)
    .property("font", &QPainter::font, &QPainter::setFont)
    .property("pen", &QPainter::pen, (void (QPainter::*)(const QPen&))&QPainter::setPen)
    .property("background", &QPainter::background, &QPainter::setBackground)
    .property("backgroundMode", &QPainter::backgroundMode, &QPainter::setBackgroundMode)
    .property("opacity", &QPainter::opacity, &QPainter::setOpacity)
    .property("renderHints", &QPainter::renderHints, tag_function<void(QPainter*, QPainter::RenderHints)>(boost::bind(&QPainter::setRenderHints, _1, _2, true)))

    .def("drawArc", _CT(_r,_i,_i)&QPainter::drawArc)
    .def("drawArc", _CT(_ri,_i,_i)&QPainter::drawArc)
    .def("drawChord", _CT(_r,_i,_i)&QPainter::drawChord)
    .def("drawChord", _CT(_ri,_i,_i)&QPainter::drawChord)
    .def("drawConvexPolygon", _CT(_g)&QPainter::drawConvexPolygon)
    .def("drawEllipse", _CT(_r)&QPainter::drawEllipse)
    .def("drawEllipse", _CT(_ri)&QPainter::drawEllipse)
    .def("drawEllipse", _CT(_p,_i,_i)&QPainter::drawEllipse)
    .def("drawLine", _CT(_l)&QPainter::drawLine)
    .def("drawLine", _CT(_p,_p)&QPainter::drawLine)
    .def("drawLine", _CT(_pi,_pi)&QPainter::drawLine)
    .def("drawLines", _CT(_vp)&QPainter::drawLines)
    .def("drawLines", _CT(_vl)&QPainter::drawLines)
    .def("drawPie", _CT(_r,_i,_i)&QPainter::drawPie)
    .def("drawPie", _CT(_ri,_i,_i)&QPainter::drawPie)
    .def("drawPoint", _CT(_p)&QPainter::drawPoint)
    .def("drawPoint", _CT(_pi)&QPainter::drawPoint)
    .def("drawPoints", _CT(_g)&QPainter::drawPoints)
    .def("drawPolygon", _CT(_g, Qt::FillRule)&QPainter::drawPolygon)
    .def("drawPolygon", tag_function<_CF(_g)>(boost::bind(_CT(_g, Qt::FillRule)&QPainter::drawPolygon,_1,_2, Qt::OddEvenFill) ) )
    .def("drawPolyline", _CT(_g)&QPainter::drawPolyline)
    .def("drawRect", _CT(_r)&QPainter::drawRect)
    .def("drawRect", _CT(_ri)&QPainter::drawRect)
    .def("drawRects", _CT(_vr)&QPainter::drawRects)
    .def("drawRoundedRect", _CT(_r,_d,_d,Qt::SizeMode)&QPainter::drawRoundedRect)
    .def("drawRoundedRect", _CT(_ri,_d,_d,Qt::SizeMode)&QPainter::drawRoundedRect)
    .def("drawRoundedRect", tag_function<_CF(_r,_d,_d)>(boost::bind(_CT(_r,_d,_d,Qt::SizeMode)&QPainter::drawRoundedRect,_1,_2,_3,_4,Qt::AbsoluteSize) ) )
    .def("drawRoundedRect", tag_function<_CF(_ri,_d,_d)>(boost::bind(_CT(_ri,_d,_d,Qt::SizeMode)&QPainter::drawRoundedRect,_1,_2,_3,_4,_5,_6,_7,Qt::AbsoluteSize) ) )
    .def("drawText", _CT(_p,_s)&QPainter::drawText)
    .def("drawText", _CT(_pi,_s)&QPainter::drawText)
    .def("drawText", _CT(_r,_i,_s,QRect*)&QPainter::drawText, pure_out_value(_5))
    .def("drawText", _CT(_ri,_i,_s,QRect*)&QPainter::drawText, pure_out_value(_8))
    .def("eraseRect", _CT(_r)&QPainter::eraseRect)
    .def("eraseRect", _CT(_ri)&QPainter::eraseRect)
    .def("fillRect", _CT(_r,const QBrush&)&QPainter::fillRect)
    .def("fillRect", _CT(_r,const QColor&)&QPainter::fillRect)
    .def("fillRect", _CT(_r,Qt::GlobalColor)&QPainter::fillRect)
    .def("fillRect", _CT(_r,Qt::BrushStyle)&QPainter::fillRect)
    .def("fillRect", _CT(_ri,const QBrush&)&QPainter::fillRect)
    .def("fillRect", _CT(_ri,const QColor&)&QPainter::fillRect)
    .def("fillRect", _CT(_ri,Qt::GlobalColor)&QPainter::fillRect)
    .def("fillRect", _CT(_ri,Qt::BrushStyle)&QPainter::fillRect)


    .def("drawImage", _CT(_r,_m)&QPainter::drawImage)
    .def("drawImage", _CT(_p,_m)&QPainter::drawImage)
    .def("drawImage", _CT(_r,_m,_r, _mc)&QPainter::drawImage)
    .def("drawImage", tag_function<_CF(_r,_m,_r)>(boost::bind(_CT(_r,_m,_r, _mc)&QPainter::drawImage,_1,_2,_3,_4,Qt::AutoColor) ) )
    .def("drawImage", _CT(_p,_m,_r, _mc)&QPainter::drawImage)
    .def("drawImage", tag_function<_CF(_p,_m,_r)>(boost::bind(_CT(_p,_m,_r, _mc)&QPainter::drawImage,_1,_2,_3,_4,Qt::AutoColor) ) )
    .def("drawImage", _CT(_pi,_m,_ri, _mc)&QPainter::drawImage)
    .def("drawImage", tag_function<_CF(_pi,_m,_ri)>(boost::bind(_CT(_pi,_m,_ri, _mc)&QPainter::drawImage,_1,_2,_3,_4,_5,_6,_7,_8,Qt::AutoColor) ) )
    .def("drawImage", tag_function<_CF(_pi,_m,_pi,_i)>(boost::bind(_CT(_pi,_m,_ri, _mc)&QPainter::drawImage,_1,_2,_3,_4,_5,_6,_7,-1,Qt::AutoColor) ) )
    .def("drawImage", tag_function<_CF(_pi,_m,_pi)>(boost::bind(_CT(_pi,_m,_ri, _mc)&QPainter::drawImage,_1,_2,_3,_4,_5,_6,-1,-1,Qt::AutoColor) ) )
    .def("drawImage", tag_function<_CF(_pi,_m,_i)>(boost::bind(_CT(_pi,_m,_ri, _mc)&QPainter::drawImage,_1,_2,_3,_4,_5,0,-1,-1,Qt::AutoColor) ) )
    .def("drawImage", tag_function<_CF(_pi,_m)>(boost::bind(_CT(_pi,_m,_ri, _mc)&QPainter::drawImage,_1,_2,_3,_4,0,0,-1,-1,Qt::AutoColor) ) )


    .def("drawPixmap", _CT(_r,_x,_r)&QPainter::drawPixmap)
    .def("drawPixmap", _CT(_p,_x,_r)&QPainter::drawPixmap)
    .def("drawPixmap", _CT(_p,_x)&QPainter::drawPixmap)
    .def("drawPixmap", _CT(_pi,_x)&QPainter::drawPixmap)
    .def("drawPixmap", _CT(_r,_x)&QPainter::drawPixmap)
    .def("drawPixmap", _CT(_ri,_x)&QPainter::drawPixmap)
    .def("drawPixmap", _CT(_ri,_x,_ri)&QPainter::drawPixmap)
    .def("drawPixmap", _CT(_pi,_x,_ri)&QPainter::drawPixmap)
    ;
}
namespace luabind{
    QT_EMUN_CONVERTER(QImage::Format)
    QT_EMUN_CONVERTER(QImage::InvertMode)
}

struct QMyByteArray : public QByteArray
{
    operator const uchar*() const
    {
        return (const uchar*)data();
    }
};
namespace luabind{
template <>
struct default_converter<QMyByteArray>
  : native_converter_base<QMyByteArray>
{
    static int compute_score(lua_State* L, int index)
    {
        return lua_type(L, index) == LUA_TTABLE ? 0 : -1;
    }

    QMyByteArray from(lua_State* L, int index)
    {
        object obj(luabind::from_stack(L,index));
        QMyByteArray arr;
        for(iterator i(obj),e; i!=e; ++i){
            int v = 0;
            if(type(*i) == LUA_TNUMBER){
                v = object_cast<int>(*i);
            }
            arr.append((char)v);
        }
        return arr;
    }

    void to(lua_State* L, QMyByteArray const& arr)
    {
        object obj = luabind::newtable(L);
        for(int i=0;i<arr.length();i++){
            obj[i+1] = (int)arr.at(i);
        }
        obj.push(L);
    }
};
template<>
struct default_converter<const QMyByteArray&>
  : default_converter<QMyByteArray>
{};
}
QByteArray lqimage_bits(QImage* w)
{
    return QByteArray::fromRawData(
            (const char*)((const QImage*)w)->bits(),
    w->byteCount());
}

QByteArray lqimage_scanline(QImage* w, int i)
{
    return QByteArray::fromRawData(
            (const char*)((const QImage*)w)->scanLine(i),
    w->bytesPerLine());
}

void lqimage_set_scanLine(QImage* w, int i, const QByteArray& arr)
{
    uchar* p = w->scanLine(i);
    int len = arr.length();
    if(len > w->bytesPerLine()){
        len = w->bytesPerLine();
    }
    memcpy(p,arr.data(), len);
}

QImage lqimage_convertToFormat1(QImage* w, QImage::Format f)
{
    return w->convertToFormat(f);
}
QImage lqimage_convertToFormat2(QImage* w,QImage::Format f, const QVector<QRgb>& t)
{
    return w->convertToFormat(f,t);
}

QImage lqimage_scaled1(QImage* w, const QSize & size){ return w->scaled(size);}
QImage lqimage_scaled2(QImage* w, const QSize & size, Qt::AspectRatioMode arm){ return w->scaled(size,arm);}
QImage lqimage_scaled3(QImage* w, const QSize & size, Qt::AspectRatioMode arm,Qt::TransformationMode tm){ return w->scaled(size,arm,tm);}
QImage lqimage_scaled4(QImage* W, int w, int h){ return W->scaled(w,h);}
QImage lqimage_scaled5(QImage* W, int w, int h, Qt::AspectRatioMode arm){ return W->scaled(w,h,arm);}
QImage lqimage_scaled6(QImage* W, int w, int h, Qt::AspectRatioMode arm,Qt::TransformationMode tm){ return W->scaled(w,h,arm,tm);}


void lqimage_init1(const luabind::argument & arg, const QByteArray& data, int w,int h,QImage::Format f)
{
    QImage* r = construct<QImage>(arg,w,h,f);
    uchar* p = r->bits();
    int len = data.length();
    if(len > r->byteCount()){
        len = r->byteCount();
    }
    memcpy(p,data.data(), len);
}

void lqimage_init2(const luabind::argument & arg, const QByteArray& data, int w,int h,int bpl,QImage::Format f)
{
    QImage* r = construct<QImage>(arg,w,h,f);
    int bpl2 = r->byteCount()/r->height();
    uchar* p = r->bits();
    int len = data.length();
    if(len > r->byteCount()){
        len = r->byteCount();
    }
    if(bpl2 == bpl){
        memcpy(p,data.data(), len);
    }else{
        len = bpl;
        if(len>bpl2) len = bpl2;
        const char* pdata = data.data();
        for(int i=0;i<r->height();++i){
            if(bpl*i+len<data.length()){
                memcpy(r->scanLine(i),pdata+bpl*i,len);
            }
        }
    }
}

LQImage lqimage()
{
    return
    class_<QImage>("QImage")
    .def(constructor<>())
    .def(constructor<const QSize&,QImage::Format>())
    .def(constructor<int,int,QImage::Format>())
    .def(constructor<const QString&,const char*>())
    .def(constructor<const QString&>())
    .def(constructor<const QImage&>())
    .def("__init", lqimage_init1)
    .def("__init", lqimage_init2)
    //.def(constructor<const QMyByteArray&, int,int,QImage::Format>())
    //.def(constructor<const QMyByteArray&, int,int,int,QImage::Format>())

    .def("isNull", &QImage::isNull)
    .def("isAllGray", &QImage::allGray)
    .def("getBits", lqimage_bits)
    .def("getByteCount", &QImage::byteCount)
    .def("color", &QImage::color)
    .def("convertToFormat", (QImage(QImage::*)(QImage::Format,Qt::ImageConversionFlags)const)&QImage::convertToFormat)
    .def("convertToFormat", (QImage(QImage::*)(QImage::Format,const QVector<QRgb>&,Qt::ImageConversionFlags)const)&QImage::convertToFormat)
    .def("convertToFormat",lqimage_convertToFormat1)
    .def("convertToFormat",lqimage_convertToFormat2)
    .def("copy", (QImage(QImage::*)(const QRect&) const)&QImage::copy)
    .def("copy", (QImage(QImage::*)(int,int,int,int) const)&QImage::copy)
    .def("copy", tag_function<QImage(QImage*)>(boost::bind((QImage(QImage::*)(const QRect&) const)&QImage::copy,_1, QRect())))
    .def("createAlphaMask", &QImage::createAlphaMask)
    .def("createAlphaMask", tag_function<QImage(QImage*)>(boost::bind(&QImage::createAlphaMask,_1,  Qt::AutoColor)))
    .def("createHeuristicMask", &QImage::createHeuristicMask)
    .def("createHeuristicMask", tag_function<QImage(QImage*)>(boost::bind(&QImage::createHeuristicMask,_1,true)))
    .def("createMaskFromColor", &QImage::createMaskFromColor)
    .def("createMaskFromColor", tag_function<QImage(QImage*,QRgb)>(boost::bind(&QImage::createMaskFromColor,_1,_2,Qt::MaskInColor)))
    .def("fill", (void (QImage::*)(uint))&QImage::fill)
    .def("fill", (void (QImage::*)(const QColor&))&QImage::fill)
    .def("invertPixels", &QImage::invertPixels)
    .def("invertPixels", tag_function<void(QImage*)>(boost::bind(&QImage::invertPixels,_1,QImage::InvertRgb)))
    .def("load", (bool(QImage::*)(const QString&,const char*))&QImage::load)
    .def("load", tag_function<bool(QImage*,const QString&)>(boost::bind((bool(QImage::*)(const QString&,const char*))&QImage::load,_1,_2,(const char*)0)))
    .def("loadFromData", (bool(QImage::*)(const QByteArray&,const char*))&QImage::loadFromData)
    .def("loadFromData", tag_function<bool(QImage*,const QByteArray&)>(boost::bind((bool(QImage::*)(const QByteArray&,const char*))&QImage::loadFromData,_1,_2,(const char*)0)))
    .def("mirrored", &QImage::mirrored)
    .def("mirrored", tag_function<QImage(QImage*,bool)>(boost::bind(&QImage::mirrored,_1,_2,true)))
    .def("mirrored", tag_function<QImage(QImage*)>(boost::bind(&QImage::mirrored,_1,false,true)))
    .def("pixel", (QRgb	(QImage::*)(const QPoint&) const)&QImage::pixel)
    .def("pixel", (QRgb	(QImage::*)(int,int) const)&QImage::pixel)
    .def("pixelIndex", (int(QImage::*)(const QPoint&) const)&QImage::pixelIndex)
    .def("pixelIndex", (int(QImage::*)(int,int) const)&QImage::pixelIndex)
    .def("rgbSwapped", &QImage::rgbSwapped)
    .def("save", (bool(QImage::*)(const QString &,const char*,int)const)&QImage::save)
    .def("save", tag_function<bool(QImage*,const QString &,const char*)>(boost::bind((bool(QImage::*)(const QString &,const char*,int)const)&QImage::save,_1,_2,_3,-1)))
    .def("save", tag_function<bool(QImage*,const QString &)>(boost::bind((bool(QImage::*)(const QString &,const char*,int)const)&QImage::save,_1,_2,(const char*)0,-1)))
    .def("scaled", lqimage_scaled1)
    .def("scaled", lqimage_scaled2)
    .def("scaled", lqimage_scaled3)
    .def("scaled", lqimage_scaled4)
    .def("scaled", lqimage_scaled5)
    .def("scaled", lqimage_scaled6)
    .def("scaledToHeight", &QImage::scaledToHeight)
    .def("scaledToHeight", tag_function<QImage(QImage*,int)>(boost::bind(&QImage::scaledToHeight,_1,_2,Qt::FastTransformation)))
    .def("scaledToWidth", &QImage::scaledToWidth)
    .def("scaledToWidth", tag_function<QImage(QImage*,int)>(boost::bind(&QImage::scaledToWidth,_1,_2,Qt::FastTransformation)))
    .def("scanLine", lqimage_scanline)
    .def("setScanLine", lqimage_set_scanLine)
    .def("setColor", &QImage::setColor)
    .def("setPixel", (void (QImage::*)(const QPoint &, uint))&QImage::setPixel)
    .def("setPixel", (void (QImage::*)(int,int, uint))&QImage::setPixel)
    .def("setText", ( void (QImage::*)(const QString &, const QString &))&QImage::setText)
    .def("text", ( QString (QImage::*)(const QString &)const)&QImage::text)
    .def("text", tag_function<QString(QImage*)>(boost::bind((QString (QImage::*)(const QString &)const)&QImage::text,_1,QString())))
    .def("valid", ( bool (QImage::*)(const QPoint &) const)&QImage::valid)
    .def("valid", ( bool (QImage::*)(int,int) const)&QImage::valid)


    .property("null", &QImage::isNull)
    .property("allGray", &QImage::allGray)
    .property("bits", lqimage_bits)
    .property("byteCount", &QImage::byteCount)
    .property("bytesPerLine", &QImage::bytesPerLine)
    .property("cacheKey", &QImage::cacheKey)
    .property("colorCount", &QImage::colorCount, &QImage::setColorCount)
    .property("colorTable", &QImage::colorTable, &QImage::setColorTable)
    .property("depth", &QImage::depth)
    .property("dotsPerMeterX", &QImage::dotsPerMeterX, &QImage::setDotsPerMeterX)
    .property("dotsPerMeterY", &QImage::dotsPerMeterY, &QImage::setDotsPerMeterY)
    .property("format", &QImage::format)
    .property("hasAlphaChannel", &QImage::hasAlphaChannel)
    .property("height", &QImage::height)
    .property("isGrayscale", &QImage::isGrayscale)
    .property("offset", &QImage::offset, &QImage::setOffset)
    .property("rect", &QImage::rect)
    .property("textKeys", &QImage::textKeys)
    .property("width", &QImage::width)
    .scope[
            def("fromData", (QImage(*)(const QByteArray&, const char*))&QImage::fromData),
            def("fromData", tag_function<QImage(const QByteArray&)>(boost::bind(  (QImage(*)(const QByteArray&, const char*))&QImage::fromData,_1,(const char*)0)) )
    ]
    ;
}

QPixmap lqpixmap_scaled1(QPixmap* w, const QSize & size){ return w->scaled(size);}
QPixmap lqpixmap_scaled2(QPixmap* w, const QSize & size, Qt::AspectRatioMode arm){ return w->scaled(size,arm);}
QPixmap lqpixmap_scaled3(QPixmap* w, const QSize & size, Qt::AspectRatioMode arm,Qt::TransformationMode tm){ return w->scaled(size,arm,tm);}
QPixmap lqpixmap_scaled4(QPixmap* W, int w, int h){ return W->scaled(w,h);}
QPixmap lqpixmap_scaled5(QPixmap* W, int w, int h, Qt::AspectRatioMode arm){ return W->scaled(w,h,arm);}
QPixmap lqpixmap_scaled6(QPixmap* W, int w, int h, Qt::AspectRatioMode arm,Qt::TransformationMode tm){ return W->scaled(w,h,arm,tm);}
void lqpixmap_scroll1(QPixmap* W, int dx,int dy,int x, int y, int w, int h){ W->scroll(dx,dy,x,y,w,h);}
void lqpixmap_scroll2(QPixmap* W, int dx,int dy,const QRect& rect){ W->scroll(dx,dy,rect);}

LQPixmap lqpixmap()
{
    return
    class_<QPixmap>("QPixmap")
    .def(constructor<>())
    .def(constructor<const QSize&>())
    .def(constructor<int,int>())
    .def(constructor<const QString&,const char*,Qt::ImageConversionFlags>())
    .def(constructor<const QString&,const char*>())
    .def(constructor<const QString&>())
    .def(constructor<const QPixmap&>())
    .def("copy", (QPixmap(QPixmap::*)(const QRect&) const)&QPixmap::copy)
    .def("copy", (QPixmap(QPixmap::*)(int,int,int,int) const)&QPixmap::copy)
    .def("copy", tag_function<QPixmap(QPixmap*)>(boost::bind((QPixmap(QPixmap::*)(const QRect&) const)&QPixmap::copy,_1, QRect())))
    .def("createHeuristicMask", &QPixmap::createHeuristicMask)
    .def("createHeuristicMask", tag_function<QPixmap(QPixmap*)>(boost::bind(&QPixmap::createHeuristicMask,_1,true)))
    .def("createMaskFromColor", (QBitmap (QPixmap::*)(const QColor &, Qt::MaskMode)const)&QPixmap::createMaskFromColor)
    .def("createMaskFromColor", (QBitmap (QPixmap::*)(const QColor &)const)&QPixmap::createMaskFromColor)
    .def("detach", &QPixmap::detach)
    .def("fill", (void (QPixmap::*)(const QColor &))&QPixmap::fill)
    .def("fill", tag_function<void(QPixmap*)>(boost::bind((void (QPixmap::*)(const QColor &))&QPixmap::fill,_1,Qt::white)))
    .def("fill", (void (QPixmap::*)(const QWidget*,const QPoint&))&QPixmap::fill)
    .def("fill", (void (QPixmap::*)(const QWidget*,int,int))&QPixmap::fill)
    .def("load", &QPixmap::load)
    .def("load", tag_function<bool(QPixmap*,const QString&,const char*)>(boost::bind(&QPixmap::load,_1,_2,_3, Qt::AutoColor)))
    .def("load", tag_function<bool(QPixmap*,const QString&)>(boost::bind(&QPixmap::load,_1,_2,(const char*)0, Qt::AutoColor)))
    .def("loadFromData", (bool(QPixmap::*)(const QByteArray&,const char*,Qt::ImageConversionFlags))&QPixmap::loadFromData)
    .def("loadFromData", tag_function<bool(QPixmap*,const QByteArray&,const char*)>(boost::bind((bool(QPixmap::*)(const QByteArray&,const char*,Qt::ImageConversionFlags))&QPixmap::loadFromData,_1,_2,_3,Qt::AutoColor)))
    .def("loadFromData", tag_function<bool(QPixmap*,const QByteArray&)>(boost::bind((bool(QPixmap::*)(const QByteArray&,const char*,Qt::ImageConversionFlags))&QPixmap::loadFromData,_1,_2,(const char*)0,Qt::AutoColor)))
    .def("save", (bool(QPixmap::*)(const QString &,const char*,int)const)&QPixmap::save)
    .def("save", tag_function<bool(QPixmap*,const QString &,const char*)>(boost::bind((bool(QPixmap::*)(const QString &,const char*,int)const)&QPixmap::save,_1,_2,_3,-1)))
    .def("save", tag_function<bool(QPixmap*,const QString &)>(boost::bind((bool(QPixmap::*)(const QString &,const char*,int)const)&QPixmap::save,_1,_2,(const char*)0,-1)))
    .def("scaled", lqpixmap_scaled1)
    .def("scaled", lqpixmap_scaled2)
    .def("scaled", lqpixmap_scaled3)
    .def("scaled", lqpixmap_scaled4)
    .def("scaled", lqpixmap_scaled5)
    .def("scaled", lqpixmap_scaled6)
    .def("scaledToHeight", &QPixmap::scaledToHeight)
    .def("scaledToHeight", tag_function<QPixmap(QPixmap*,int)>(boost::bind(&QPixmap::scaledToHeight,_1,_2,Qt::FastTransformation)))
    .def("scaledToWidth", &QPixmap::scaledToWidth)
    .def("scaledToWidth", tag_function<QPixmap(QPixmap*,int)>(boost::bind(&QPixmap::scaledToWidth,_1,_2,Qt::FastTransformation)))
    .def("scroll", lqpixmap_scroll1)
    .def("scroll", lqpixmap_scroll2)
    .def("toImage", &QPixmap::toImage)

    .property("cacheKey", &QPixmap::cacheKey)
    .property("depth", &QPixmap::depth)
    .property("hasAlpha", &QPixmap::hasAlpha)
    .property("hasAlphaChannel", &QPixmap::hasAlphaChannel)
    .property("height", &QPixmap::height)
    .property("isNull", &QPixmap::isNull)
    .property("isQBitmap", &QPixmap::isQBitmap)
    .property("mask", &QPixmap::mask, &QPixmap::setMask)
    .property("rect", &QPixmap::rect)
    .property("size", &QPixmap::size)
    .scope[
            def("defaultDepth", &QPixmap::defaultDepth),
            def("fromImage", &QPixmap::fromImage),
            def("fromImage", tag_function<QPixmap(const QImage &)>(boost::bind( &QPixmap::fromImage,_1,Qt::AutoColor))),
            def("grabWidget", (QPixmap(*)(QWidget*,const QRect&))&QPixmap::grabWidget),
            def("grabWidget", (QPixmap(*)(QWidget*,int,int,int,int))&QPixmap::grabWidget),
            def("grabWidget", tag_function<QPixmap(QWidget*,int,int,int)>(boost::bind( (QPixmap(*)(QWidget*,int,int,int,int))&QPixmap::grabWidget,_1,_2,_3,_4,-1)) ),
            def("grabWidget", tag_function<QPixmap(QWidget*,int,int)>(boost::bind( (QPixmap(*)(QWidget*,int,int,int,int))&QPixmap::grabWidget,_1,_2,_3,-1,-1)) ),
            def("grabWidget", tag_function<QPixmap(QWidget*,int)>(boost::bind( (QPixmap(*)(QWidget*,int,int,int,int))&QPixmap::grabWidget,_1,_2,0,-1,-1)) ),
            def("grabWidget", tag_function<QPixmap(QWidget*)>(boost::bind( (QPixmap(*)(QWidget*,int,int,int,int))&QPixmap::grabWidget,_1,0,0,-1,-1)) )
    ]

    ;
}

QBitmap lqbitmap_fromData1(const QSize & size, const QByteArray& arr)
{
    return QBitmap::fromData(size, (const uchar*)arr.data());
}

QBitmap lqbitmap_fromData2(const QSize & size, const QByteArray& arr,QImage::Format f)
{
    return QBitmap::fromData(size, (const uchar*)arr.data(),f);
}

QBitmap lqbitmap_fromImage2(const QImage & image)
{
    return QBitmap::fromImage(image);
}

LQBitmap lqbitmap()
{
    return
    class_<QBitmap,QPixmap>("QBitmap")
    .def(constructor<>())
    .def(constructor<const QPixmap&>())
    .def(constructor<const QSize&>())
    .def(constructor<int,int>())
    .def(constructor<const QString&,const char*>())
    .def(constructor<const QString&>())
    .def("clear", &QBitmap::clear)
    .scope[
        def("fromData", lqbitmap_fromData1),
        def("fromData", lqbitmap_fromData2),
        def("fromImage", &QBitmap::fromImage),
        def("fromImage", lqbitmap_fromImage2)
    ]
            ;
}
