#include "lua_qtabwidget.h"

#include <luabind/tag_function.hpp>

#include "lua_qslot.h"

namespace luabind{
QT_EMUN_CONVERTER(Qt::Corner)
}

SIGNAL_PROPERYT(lqtabwidget, currentChanged, QTabWidget, "(int)")
SIGNAL_PROPERYT(lqtabwidget, tabCloseRequested, QTabWidget, "(int)")
SIGNAL_PROPERYT(lqtoolbox, currentChanged, QToolBox, "(int)")

static setter_map<QTabWidget> lqtabwidget_set_map;
static setter_map<QToolBox> lqtoolbox_set_map;

QTabWidget* lqtabwidget_init(QTabWidget* widget, const object& obj)
{
    lqwidget_init(widget, obj);
    for(iterator i(obj),e; i!=e; ++i){
        if(type(i.key()) == LUA_TSTRING && type(*i) == LUA_TUSERDATA){
            QString k = object_cast<QString> (i.key());
            try{
                if(k.compare("leftcorner",Qt::CaseInsensitive) == 0){
                    widget->setCornerWidget(object_cast<QWidget*>(*i), Qt::TopLeftCorner);
                }else if(k.compare("rightcorner",Qt::CaseInsensitive) == 0){
                    widget->setCornerWidget(object_cast<QWidget*>(*i), Qt::TopRightCorner);
                }
            }catch(...){
            }
        }
    }
    return lq_general_init(widget, obj, lqtabwidget_set_map);
}

template<>
void table_init_general<QTabWidget>(const luabind::argument & arg, const object& obj)
{
    lqtabwidget_init(construct<QTabWidget>(arg), obj);
}


void lqtabwidget_setElideMode(QTabWidget* w, int s)
{
    w->setElideMode(Qt::TextElideMode(s));
}

void lqtabwidget_setTabPosition(QTabWidget* w, int s)
{
    w->setTabPosition(QTabWidget::TabPosition(s));
}

void lqtabwidget_setTabShape(QTabWidget* w, int s)
{
    w->setTabShape(QTabWidget::TabShape(s));
}

LQTabWidget lqtabwidget()
{
    return
    myclass_<QTabWidget, QWidget>("QTabWidget", lqtabwidget_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def("__init", table_init_general<QTabWidget>)
    .def("__call", lqtabwidget_init)
    .def("addTab", (int (QTabWidget::*)(QWidget *,const QString &))&QTabWidget::addTab)
    .def("addTab", (int (QTabWidget::*)(QWidget *,const QIcon&, const QString &))&QTabWidget::addTab)
    .def("clear", &QTabWidget::clear)
    .def("cornerWidget", &QTabWidget::cornerWidget)
    .def("cornerWidget",tag_function<QWidget* (QTabWidget*) >(boost::bind(&QTabWidget::cornerWidget, _1, Qt::TopRightCorner)) )
    .def("setCurrentIndex", &QTabWidget::setCurrentIndex)
    .def("setCurrentWidget", &QTabWidget::setCurrentWidget)
    .def("indexOf", &QTabWidget::indexOf)
    .def("insertTab", (int (QTabWidget::*)(int, QWidget *,const QString &))&QTabWidget::insertTab)
    .def("insertTab", (int (QTabWidget::*)(int, QWidget *,const QIcon&, const QString &))&QTabWidget::insertTab)
    .def("removeTab", &QTabWidget::removeTab)
    .def("setCornerWidget", &QTabWidget::setCornerWidget)
    .def("setCornerWidget", tag_function<void (QTabWidget*,QWidget*) >(boost::bind(&QTabWidget::setCornerWidget, _1, _2, Qt::TopRightCorner)))
    .def("widget", &QTabWidget::widget)

    .property("documentMode", &QTabWidget::documentMode, &QTabWidget::setDocumentMode)
    .property("elideMode", &QTabWidget::elideMode, lqtabwidget_setElideMode)
    .property("iconSize", &QTabWidget::iconSize, &QTabWidget::setIconSize)
    .property("movable", &QTabWidget::isMovable, &QTabWidget::setMovable)
    .property("tabEnabled", &QTabWidget::isTabEnabled, &QTabWidget::setTabEnabled)
    .property("tabIcon", &QTabWidget::tabIcon, &QTabWidget::setTabIcon)
    .property("tabPosition", &QTabWidget::tabPosition, lqtabwidget_setTabPosition)
    .property("tabShape", &QTabWidget::tabShape, lqtabwidget_setTabShape)
    .property("tabsClosable", &QTabWidget::tabsClosable, &QTabWidget::setTabsClosable)
    .property("tabText", &QTabWidget::tabText, &QTabWidget::setTabText)
    .property("tabToolTip", &QTabWidget::tabToolTip, &QTabWidget::setTabToolTip)
    .property("tabWhatsThis", &QTabWidget::tabWhatsThis, &QTabWidget::setTabWhatsThis)
    .property("usesScrollButtons", &QTabWidget::usesScrollButtons, &QTabWidget::setUsesScrollButtons)
    .sig_prop(lqtabwidget, currentChanged)
    .sig_prop(lqtabwidget, tabCloseRequested)

    .class_<QTabWidget, QWidget>::property("count", &QTabWidget::count)
    .property("currentIndex", &QTabWidget::currentIndex, &QTabWidget::setCurrentIndex)
    .property("currentWidget", &QTabWidget::currentWidget, &QTabWidget::setCurrentWidget)
    .property("topLeftCorner",
              tag_function<QWidget* (QTabWidget*) >(boost::bind(&QTabWidget::cornerWidget, _1, Qt::TopLeftCorner)),
              tag_function<void (QTabWidget*,QWidget*) >(boost::bind(&QTabWidget::setCornerWidget, _1, _2, Qt::TopLeftCorner)))
    .property("topRightCorner",
              tag_function<QWidget* (QTabWidget*) >(boost::bind(&QTabWidget::cornerWidget, _1, Qt::TopRightCorner)),
              tag_function<void (QTabWidget*,QWidget*) >(boost::bind(&QTabWidget::setCornerWidget, _1, _2, Qt::TopRightCorner)))
    .property("bottomLeftCorner",
              tag_function<QWidget* (QTabWidget*) >(boost::bind(&QTabWidget::cornerWidget, _1, Qt::BottomLeftCorner)),
              tag_function<void (QTabWidget*,QWidget*) >(boost::bind(&QTabWidget::setCornerWidget, _1, _2, Qt::BottomLeftCorner)))
    .property("bottomRightCorner",
              tag_function<QWidget* (QTabWidget*) >(boost::bind(&QTabWidget::cornerWidget, _1, Qt::BottomRightCorner)),
              tag_function<void (QTabWidget*,QWidget*) >(boost::bind(&QTabWidget::setCornerWidget, _1, _2, Qt::BottomRightCorner)))
    .property("leftCorner",
              tag_function<QWidget* (QTabWidget*) >(boost::bind(&QTabWidget::cornerWidget, _1, Qt::TopLeftCorner)),
              tag_function<void (QTabWidget*,QWidget*) >(boost::bind(&QTabWidget::setCornerWidget, _1, _2, Qt::TopLeftCorner)))
    .property("rightCorner",
              tag_function<QWidget* (QTabWidget*) >(boost::bind(&QTabWidget::cornerWidget, _1, Qt::TopRightCorner)),
              tag_function<void (QTabWidget*,QWidget*) >(boost::bind(&QTabWidget::setCornerWidget, _1, _2, Qt::TopRightCorner)))
    ;
}


QToolBox* lqtoolbox_init(QToolBox* widget, const object& obj)
{
    lqwidget_init(widget, obj);
    return lq_general_init(widget, obj, lqtoolbox_set_map);
}

template<>
void table_init_general<QToolBox>(const luabind::argument & arg, const object& obj)
{
    lqtoolbox_init(construct<QToolBox>(arg), obj);
}

LQToolBox lqtoolbox()
{
    return
    myclass_<QToolBox, QFrame>("QToolBox", lqtoolbox_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def("__init", table_init_general<QToolBox>)
    .def("__call", lqtoolbox_init)
    .def("addItem", (int (QToolBox::*)(QWidget *,const QString &))&QToolBox::addItem)
    .def("addItem", (int (QToolBox::*)(QWidget *,const QIcon &,const QString &))&QToolBox::addItem)
    .def("setCurrentIndex", &QToolBox::setCurrentIndex)
    .def("setCurrentWidget", &QToolBox::setCurrentWidget)
    .def("indexOf", &QToolBox::indexOf)
    .def("insertItem", (int (QToolBox::*)(int, QWidget *, const QIcon &, const QString &))&QToolBox::insertItem)
    .def("insertItem", (int (QToolBox::*)(int, QWidget *,const QString &))&QToolBox::insertItem)

    .def("removeItem", &QToolBox::removeItem)
    .def("widget", &QToolBox::widget)

    .property("itemEnabled", &QToolBox::isItemEnabled, &QToolBox::setItemEnabled)
    .property("itemText", &QToolBox::itemText, &QToolBox::setItemText)
    .property("itemIcon", &QToolBox::itemIcon, &QToolBox::setItemIcon)
    .property("itemToolTip", &QToolBox::itemToolTip, &QToolBox::setItemToolTip)
    .sig_prop(lqtoolbox, currentChanged)

    .class_<QToolBox, QFrame>::property("count", &QToolBox::count)
    .property("currentIndex", &QToolBox::currentIndex, &QToolBox::setCurrentIndex)
    .property("currentWidget", &QToolBox::currentWidget, &QToolBox::setCurrentWidget)
    ;
}
