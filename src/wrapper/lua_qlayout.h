#ifndef LUA_QLAYOUT_H
#define LUA_QLAYOUT_H

#include "lua_qt.h"

#include "lua_liteptr.h"

struct QLayoutWarp : public QLayout, public luabind::wrap_base
{
    QLayoutWarp(QWidget* w):QLayout(w){}
    QLayoutWarp(){}
    virtual void addItem ( QLayoutItem * item ) {
            call_member<void>(this, "addItem", item);
    }
    virtual int	count () const {return call_member<int>(this, "count");}
    virtual int	indexOf ( QWidget * widget ) const{return call_member<int>(this, "indexOf", widget);}
    virtual QLayoutItem * itemAt ( int index ) const { return call_member<QLayoutItem*>(this, "itemAt", index);}
    virtual QLayoutItem *	takeAt ( int index ) {return call_member<QLayoutItem*>(this, "takeAt", index);}
    virtual QSize sizeHint() const {return call_member<QSize>(this, "sizeHint");}
    virtual QSize minimumSize() const {return call_member<QSize>(this, "minimumSize");}
    virtual QSize maximumSize() const {return call_member<QSize>(this, "maximumSize");}
    virtual Qt::Orientations expandingDirections() {return call_member<Qt::Orientations>(this, "expandingDirections");}
    //virtual void setGeometry(const QRect& rect) { call_member<void>(this, "setGeometry", rect); }
    //virtual QRect geometry() const { return call_member<QRect>(this, "geometry"); }
    virtual bool isEmpty() const {return call_member<bool>(this, "isEmpty");}
    virtual bool hasHeightForWidth() const{ return call_member<bool>(this, "hasHeightForWidth");}
    virtual int heightForWidth(int h) const{ return call_member<int>(this, "heightForWidth", h);}
    virtual int minimumHeightForWidth(int h) const{ return call_member<int>(this, "minimumHeightForWidth", h);}
    virtual void invalidate(){ call_member<void>(this, "invalidate"); }

    virtual QWidget *widget(){ return call_member<QWidget*>(this, "widget"); }
    virtual QLayout *layout(){ return call_member<QLayout*>(this, "layout");}
    virtual QSpacerItem *spacerItem(){ return call_member<QSpacerItem*>(this, "spacerItem");}
};

typedef class_<QLayout, QLayoutWarp>        LQLayout;
typedef class_<QStackedLayout, QLayout>     LQStackedLayout;
typedef class_<QGridLayout, QLayout>        LQGridLayout;
typedef class_<QFormLayout, QLayout>        LQFormLayout;
typedef class_<QBoxLayout, QLayout>         LQBoxLayout;
typedef class_<QVBoxLayout, QBoxLayout>     LQVBoxLayout;
typedef class_<QHBoxLayout, QBoxLayout, lite_ptr<QHBoxLayout> >     LQHBoxLayout;
typedef class_<QSpacerItem> LQSpacerItem;

inline QHBoxLayout* get_pointer(lite_ptr<QHBoxLayout>& l)
{
    return l.get();
}

LQLayout lqlayout();
LQStackedLayout lqstatckedlayout();
LQGridLayout lqgridlayout();
LQFormLayout lqformlayout();
LQBoxLayout  lqboxlayout();
LQVBoxLayout lqvboxlayout();
LQHBoxLayout lqhboxlayout();
LQSpacerItem lqspaceritem();

#endif
