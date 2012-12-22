#include "lua_qaction.h"
#include "luabind/tag_function.hpp"
bool sigfunc_connect(QObject* sender, const char* signal, object func);
QLuaSlot* get_slot(const QObject* obj, const char* member);

SIGNAL_PROPERYT(lqaction, changed, QAction, "()")
SIGNAL_PROPERYT(lqaction, hovered, QAction, "()")
SIGNAL_PROPERYT(lqaction, toggled, QAction, "(bool)")
SIGNAL_PROPERYT(lqaction, triggered, QAction, "()")

static setter_map<QAction> lqaction_set_map;
static setter_map<QMenu> lqmenu_set_map;

QAction* lqaction_init(QAction* widget, const object& table)
{
    if(type(table) == LUA_TTABLE){
        for (iterator i(table), e; i != e; ++i){
            if(type(i.key()) == LUA_TSTRING){
                QString key = object_cast<QString>(i.key());
                if(lqaction_set_map.find(key) != lqaction_set_map.end()){
                    lqaction_set_map[key](widget,*i);
                }/*else if(key.compare("triggered", Qt::CaseInsensitive) == 0){
                    lqaction_set_triggered(widget, *i);
                }*/
            }

            if(type(*i) == LUA_TUSERDATA){
                if(q_cast(*i, (void(QAction::*)( const QIcon &))&QAction::setIcon, widget)){
                }else if(q_cast(*i, &QAction::setShortcut, widget)){
                }else if(q_cast(*i, &QAction::setMenu, widget)){
                }
            }/*else if(type(*i)== LUA_TSTRING){
                if(q_cast(*i, (QAction*(QToolBar::*)(const QString&))&QToolBar::addAction, widget)){
                }
            }*/
            //qDebug()<<"key:"<<toString(i.key())<<"val:"<<toString(*i);
        }
    }
    return widget;
}

void null_action_init(const argument& arg)
{
    construct<QAction, QObject*>(arg, 0);
}

void string_action_init(const argument& arg, const QString& text)
{
    construct<QAction,const QString&, QObject*>(arg,text, 0);
}

void table_action_init(const argument& arg, const object& table)
{
    lqaction_init(construct<QAction,QObject*>(arg,0), table);
}

void lqaction_seShortcuts(QAction* w, int s)
{
    w->setShortcuts(QKeySequence::StandardKey(s));
}
LQAction lqaction()
{
    return
    myclass_<QAction,QObject>("QAction",lqaction_set_map)
        .def(constructor<QObject*>())
        .def(constructor<const QString &, QObject*>())
        .def(constructor<const QIcon &, const QString &, QObject* >())
        .def("__call", &lqaction_init)
        .def("__init", &table_action_init)
        .def("__init", &string_action_init)
        .def("__init", &null_action_init)
        .def("setShortcuts", lqaction_seShortcuts)
        .def("hover", &QAction::hover)
        .def("setChecked", &QAction::setChecked)
        .def("setDisabled", &QAction::setDisabled)
        .def("setEnabled", &QAction::setEnabled)
        .def("setVisible", &QAction::setVisible)
        .def("toggle", &QAction::toggle)
        .def("trigger", &QAction::trigger)

        .property("text",&QAction::text, &QAction::setText)
        .property("toolTip",&QAction::toolTip, &QAction::setToolTip)
        .property("checkable",&QAction::isCheckable, &QAction::setCheckable)
        .property("checked",&QAction::isChecked, &QAction::setChecked)
        .property("enabled",&QAction::isEnabled, &QAction::setEnabled)
        .property("visible",&QAction::isVisible, &QAction::setVisible)
        .property("iconVisibleInMenu",&QAction::isIconVisibleInMenu, &QAction::setIconVisibleInMenu)
        .property("separator",&QAction::isSeparator, &QAction::setSeparator)
        .property("statusTip",&QAction::statusTip, &QAction::setStatusTip)
        .property("iconText",&QAction::iconText, &QAction::setIconText)
        .property("autoRepeat",&QAction::autoRepeat, &QAction::setAutoRepeat)
        .property("icon",&QAction::icon, &QAction::setIcon)
        .property("font", &QAction::font, &QAction::setFont)
        .sig_prop(lqaction,triggered)
        .sig_prop(lqaction,hovered)
        .sig_prop(lqaction,toggled)
        .sig_prop(lqaction,changed)
        .class_<QAction,QObject>::property("shortcut",&QAction::shortcut, &QAction::setShortcut)
        .property("shortcuts",&QAction::shortcuts, (void(QAction::*)( const QList<QKeySequence>&))&QAction::setShortcuts)
        .property("menu", &QAction::menu, &QAction::setMenu)
        .property("data", &QAction::data, &QAction::setData)
        ;
}

static setter_map<QMenuBar> lqmenubar_set_map;
QAction* lqmenubar_insert_menu(QMenuBar* menuBar, int pos, QMenu* menu)
{
    const QList<QAction*>& list = menuBar->actions();
    if(pos>=0 && pos< list.count()){
        return menuBar->insertMenu(list.at(pos), menu);
    }
    return menuBar->addMenu(menu);
}

QMenu* lqmenubar_insert_menu(QMenuBar* menuBar, int pos, const QString& title)
{
    QMenu* menu = new QMenu(title,menuBar);
    lqmenubar_insert_menu(menuBar,pos,menu);
    return menu;
}

QMenuBar* lqmenubar_init(QMenuBar* widget, const object& table)
{
    if(type(table) == LUA_TTABLE){
        for (iterator i(table), e; i != e; ++i){
            if(type(*i) == LUA_TUSERDATA){
                if(q_cast(*i, (void(QMenuBar::*)( QAction*))&QMenuBar::addAction, widget)){
                    QAction* act = object_cast<QAction*>(*i);
                    act->setParent(widget);
                }else if(q_cast(*i, (QAction* (QMenuBar::*)( QMenu*))&QMenuBar::addMenu, widget)){
                    //QMenu* act = object_cast<QMenu*>(*i);
                    //act->setParent(widget);
                }
            }else if(type(*i)== LUA_TSTRING){
                if(q_cast(*i, (QMenu*(QMenuBar::*)(const QString&))&QMenuBar::addMenu, widget)){
                }
            }else if(type(i.key()) == LUA_TSTRING){
                QString key = object_cast<QString>(i.key());
                if(lqmenubar_set_map.find(key) != lqmenubar_set_map.end()){
                    lqmenubar_set_map[key](widget,*i);
                }
            }
        }
    }
    return widget;
}

void table_menubar_init(const argument& arg, const object& table)
{
    lqmenubar_init(construct<QMenuBar>(arg), table);
}

SIGNAL_PROPERYT(lqmenubar, hovered, QMenuBar, "(QAction*)")
SIGNAL_PROPERYT(lqmenubar, triggered, QMenuBar, "(QAction*)")
LQMenuBar lqmenubar()
{
    return
    myclass_<QMenuBar,QWidget>("QMenuBar",lqmenubar_set_map)
        .def(constructor<>())
        .def("addMenu", (QAction* (QMenuBar::*)(QMenu*))&QMenuBar::addMenu)
        .def("addMenu",(QMenu* (QMenuBar::*)(const QString &))&QMenuBar::addMenu)
        .def("addAction", (void (QMenuBar::*)(QAction *action))&QMenuBar::addAction)
        .def("addAction", (QAction* (QMenuBar::*)(const QString&))&QMenuBar::addAction)

        .def("insertMenu", ( QAction*(QMenuBar::*)(QAction *, QMenu *))&QMenuBar::insertMenu)
        .def("insertMenu", (QAction* (*)(QMenuBar*, int, QMenu*))&lqmenubar_insert_menu)
        .def("insertMenu", (QMenu* (*)(QMenuBar*, int, const QString&))&lqmenubar_insert_menu)

        .def("__call", &lqmenubar_init)
        .def("__init", &table_menubar_init)
        .def("clear", &QMenuBar::clear)
        .def("addSeparator", &QMenuBar::addSeparator)
        .def("setVisible", &QMenuBar::setVisible)

        .sig_prop(lqmenubar, hovered)
        .sig_prop(lqmenubar, triggered)

        .property("defaultUp", &QMenuBar::isDefaultUp, &QMenuBar::setDefaultUp)
        .property("nativeMenuBar", &QMenuBar::isNativeMenuBar, &QMenuBar::setNativeMenuBar)
        //.class_<QMenuBar,QWidget>::property("defaultAction", &QMenuBar::defaultAction, &QMenuBar::setDefaultAction)
        ;
}


QMenu* lqmenu_init(QMenu* widget, const object& table)
{
    lq_general_init(widget,table,lqmenu_set_map);
    if(type(table) == LUA_TTABLE){
        for (iterator i(table), e; i != e; ++i){
            if(type(*i) == LUA_TUSERDATA){
                if(q_cast(*i, (void(QMenu::*)( QAction*))&QMenu::addAction, widget)){
                    QAction* act = object_cast<QAction*>(*i);
                    act->setParent(widget);
                }else if(q_cast(*i, (QAction* (QMenu::*)( QMenu*))&QMenu::addMenu, widget)){
                    //QMenu* act = object_cast<QMenu*>(*i);
                    //act->setParent(widget);
                }
            }else if(type(*i)== LUA_TSTRING){
                if(q_cast(*i, (QAction*(QMenu::*)(const QString&))&QMenu::addAction, widget)){
                }
            }
            //qDebug()<<"key:"<<toString(i.key())<<"val:"<<toString(*i);
        }
    }
    return widget;
}

void table_menu_init(const argument& arg, const object& table)
{
    lqmenu_init(construct<QMenu>(arg), table);
}

SIGNAL_PROPERYT(lqmenu, aboutToHide, QMenu, "()")
SIGNAL_PROPERYT(lqmenu, aboutToShow, QMenu, "()")
SIGNAL_PROPERYT(lqmenu, hovered, QMenu, "(QAction*)")
SIGNAL_PROPERYT(lqmenu, triggered, QMenu, "(QAction*)")
LQMenu  lqmenu()
{
    return
    myclass_<QMenu, QWidget>("QMenu",lqmenu_set_map)
        .def(constructor<>())
        .def(constructor<QWidget *>())
        .def(constructor<const QString&, QWidget *>())
        .def(constructor<const QString&>())
        .def("__call", &lqmenu_init)
        .def("__init", &table_menu_init)

        .def("addAction", (QAction*(QMenu::*)(const QString &))&QMenu::addAction)
        .def("addAction", (QAction*(QMenu::*)(const QIcon &, const QString &))&QMenu::addAction)
        .def("addAction", (void(QMenu::*)(QAction*))&QMenu::addAction)
        .def("addMenu", (QAction*(QMenu::*)(QMenu*))&QMenu::addMenu)
        .def("addMenu", (QMenu*(QMenu::*)(const QString&))&QMenu::addMenu)
        .def("addMenu", (QMenu*(QMenu::*)(const QIcon&,const QString&))&QMenu::addMenu)
        .def("addSeparator", &QMenu::addSeparator)
        .def("exec", (QAction*(QMenu::*)())&QMenu::exec)
        .def("exec", (QAction*(QMenu::*)(const QPoint &,QAction*))&QMenu::exec)
        .def("exec", tag_function<QAction*(QMenu*,const QPoint &)>(boost::bind((QAction*(QMenu::*)(const QPoint &,QAction*))&QMenu::exec, _1,_2, (QAction*)0) ))
        .def("insertMenu", &QMenu::insertMenu)
        .def("insertSeparator", &QMenu::insertSeparator)
        .def("menuAction", &QMenu::menuAction)
        .def("popup", &QMenu::popup)
        .def("popup", tag_function<void(QMenu*,const QPoint &)>(boost::bind(&QMenu::popup, _1,_2, (QAction*)0) ))
        .def("clear", &QMenu::clear)

        .property("title", &QMenu::title, &QMenu::setTitle)
        .property("icon", &QMenu::icon, &QMenu::setIcon)
        .property("isEmpty", &QMenu::isEmpty)
        .sig_prop(lqmenu, aboutToHide)
        .sig_prop(lqmenu, aboutToShow)
        .sig_prop(lqmenu, hovered)
        .sig_prop(lqmenu, triggered)
        .class_<QMenu, QWidget>::property("activeAction", &QMenu::activeAction, &QMenu::setActiveAction)
        .property("defaultAction", &QMenu::defaultAction, &QMenu::setDefaultAction)

        .scope[
            def("exec", (QAction*(*)(QList<QAction*>,const QPoint&,QAction*,QWidget*))&QMenu::exec),
            def("exec", (QAction*(*)(QList<QAction*>,const QPoint&,QAction*))&QMenu::exec),
            def("exec", tag_function<QAction*(QList<QAction*>,const QPoint&)>(boost::bind((QAction*(*)(QList<QAction*>,const QPoint&,QAction*))&QMenu::exec, _1,_2, (QAction*)0) ))
        ]
        ;
}

QToolBar* lqtoolbar_init(QToolBar* widget, const object& table)
{
    if(type(table) == LUA_TTABLE){
        for (iterator i(table), e; i != e; ++i){
            if(type(*i) == LUA_TUSERDATA){
                if(q_cast(*i, (void(QToolBar::*)( QAction*))&QToolBar::addAction, widget)){
                    QAction* act = object_cast<QAction*>(*i);
                    act->setParent(widget);
                }
            }else if(type(*i)== LUA_TSTRING){
                if(q_cast(*i, (QAction*(QToolBar::*)(const QString&))&QToolBar::addAction, widget)){
                }
            }
            //qDebug()<<"key:"<<toString(i.key())<<"val:"<<toString(*i);
        }
    }
    return widget;
}

void table_toolbar_init(const argument& arg, const object& table)
{
    lqtoolbar_init(construct<QToolBar>(arg), table);
}

SIGNAL_PROPERYT(lqtoolbar, actionTriggered, QToolBar, "(QAction*)")
SIGNAL_PROPERYT(lqtoolbar, allowedAreasChanged, QToolBar, "(Qt::ToolBarAreas)")
SIGNAL_PROPERYT(lqtoolbar, iconSizeChanged, QToolBar, "(const QSize&)")
SIGNAL_PROPERYT(lqtoolbar, movableChanged, QToolBar, "(bool)")
SIGNAL_PROPERYT(lqtoolbar, orientationChanged, QToolBar, "(Qt::Orientation)")
SIGNAL_PROPERYT(lqtoolbar, toolButtonStyleChanged, QToolBar, "(Qt::ToolButtonStyle)")
SIGNAL_PROPERYT(lqtoolbar, topLevelChanged, QToolBar, "(bool)")

LQToolBar lqtoolbar()
{
    return
    class_<QToolBar, QWidget>("QToolBar")
         .def(constructor<>())
         .def(constructor<const QString&>())
         .def("addAction", (void(QToolBar::*)( QAction*))&QToolBar::addAction)
         .def("addAction", (QAction*(QToolBar::*)( const QString&))&QToolBar::addAction)
         .def("addAction", (QAction*(QToolBar::*)(const QIcon&,const QString&))&QToolBar::addAction)
         .def("toggleViewAction", &QToolBar::toggleViewAction)
         .def("__call", &lqtoolbar_init)
         .def("__init", &table_toolbar_init)
         .def("clear", &QToolBar::clear)
         .def("insertSeparator", &QToolBar::insertSeparator)
         .def("addSeparator", &QToolBar::addSeparator)
         .def("addWidget", &QToolBar::addWidget)

         .property("allowedAreas", &QToolBar::allowedAreas, &QToolBar::setAllowedAreas)
         .property("floatable", &QToolBar::isFloatable, &QToolBar::setFloatable)
         .property("floating", &QToolBar::isFloating)
         .property("movable", &QToolBar::isMovable, &QToolBar::setMovable)
         .property("allowedAreas", &QToolBar::allowedAreas, &QToolBar::setAllowedAreas)
         .property("orientation", &QToolBar::orientation, &QToolBar::setOrientation)
         .property("toolButtonStyle", &QToolBar::toolButtonStyle, &QToolBar::setToolButtonStyle)
         .property("iconSize", &QToolBar::iconSize, &QToolBar::setIconSize)

         .sig_prop(lqtoolbar, actionTriggered)
         .sig_prop(lqtoolbar, allowedAreasChanged)
         .sig_prop(lqtoolbar, iconSizeChanged)
         .sig_prop(lqtoolbar, movableChanged)
         .sig_prop(lqtoolbar, orientationChanged)
         .sig_prop(lqtoolbar, toolButtonStyleChanged)
         .sig_prop(lqtoolbar, topLevelChanged)
         ;
}


#define _r const QRect&
#define _p QPainter*
#define _ri int,int,int,int
#define  _R  (void (QIcon::*)(QPainter *, const QRect &, Qt::Alignment,QIcon::Mode,QIcon::State)const)
#define  _RI (void (QIcon::*)(QPainter *, int,int,int,int, Qt::Alignment,QIcon::Mode,QIcon::State)const)
#define _F(a, arg...) void (QIcon*,a, ## arg)
#define _m1 (QPixmap(QIcon::*)(const QSize&, QIcon::Mode, QIcon::State) const)
#define _m2 (QPixmap(QIcon::*)(int,int, QIcon::Mode, QIcon::State) const)
#define _m3 (QPixmap(QIcon::*)(int, QIcon::Mode, QIcon::State) const)

namespace luabind{
    QT_EMUN_CONVERTER(QIcon::Mode)
    QT_EMUN_CONVERTER(QIcon::State)
}
LQIcon lqicon()
{
    return
    class_<QIcon>("QIcon")
        .def(constructor<>())
        .def(constructor<const QIcon&>())
        .def(constructor<const QString&>())
        .def("actualSize", &QIcon::actualSize)
        .def("actualSize", tag_function<QSize(QIcon*,const QSize&,QIcon::Mode)>(boost::bind( &QIcon::actualSize,_1,_2,_3,QIcon::Off)))
        .def("actualSize", tag_function<QSize(QIcon*,const QSize&)>(boost::bind( &QIcon::actualSize,_1,_2,QIcon::Normal,QIcon::Off)))
        .def("addFile", &QIcon::addFile)
        .def("addFile", tag_function<void(QIcon*,const QString&,const QSize&,QIcon::Mode)>(boost::bind( &QIcon::addFile,_1,_2,_3,_4,QIcon::Off)))
        .def("addFile", tag_function<void(QIcon*,const QString&,const QSize&)>(boost::bind( &QIcon::addFile,_1,_2,_3,QIcon::Normal,QIcon::Off)))
        .def("addFile", tag_function<void(QIcon*,const QString&)>(boost::bind( &QIcon::addFile,_1,_2,QSize(),QIcon::Normal,QIcon::Off)))
        .def("addPixmap", &QIcon::addPixmap)
        .def("addPixmap", tag_function<void(QIcon*,const QPixmap&,QIcon::Mode)>(boost::bind( &QIcon::addPixmap,_1,_2,_3,QIcon::Off)))
        .def("addPixmap", tag_function<void(QIcon*,const QPixmap&)>(boost::bind( &QIcon::addPixmap,_1,_2,QIcon::Normal,QIcon::Off)))
        .def("availableSizes", &QIcon::availableSizes)
        .def("availableSizes", tag_function<QList<QSize>(QIcon*,QIcon::Mode)>(boost::bind( &QIcon::availableSizes,_1,_2,QIcon::Off)))
        .def("availableSizes", tag_function<QList<QSize>(QIcon*)>(boost::bind( &QIcon::availableSizes,_1,QIcon::Normal,QIcon::Off)))
        .def("getCacheKey", &QIcon::cacheKey)
        .property("cacheKey", &QIcon::cacheKey)
        .def("isNull", &QIcon::isNull)
        .property("null", &QIcon::isNull)

        .def("pixmap", _m1 &QIcon::pixmap)
        .def("pixmap", tag_function<QPixmap(QIcon*,const QSize&,QIcon::Mode)>(boost::bind( _m1 &QIcon::pixmap,_1,_2,_3,QIcon::Off)))
        .def("pixmap", tag_function<QPixmap(QIcon*,const QSize&)>(boost::bind( _m1 &QIcon::pixmap,_1,_2,QIcon::Normal,QIcon::Off)))

        .def("pixmap", _m2 &QIcon::pixmap)
        .def("pixmap", tag_function<QPixmap(QIcon*,int,int,QIcon::Mode)>(boost::bind( _m2 &QIcon::pixmap,_1,_2,_3,_4,QIcon::Off)))
        .def("pixmap", tag_function<QPixmap(QIcon*,int,int)>(boost::bind( _m2 &QIcon::pixmap,_1,_2,_3,QIcon::Normal,QIcon::Off)))

        .def("pixmap", _m3 &QIcon::pixmap)
        .def("pixmap", tag_function<QPixmap(QIcon*,int)>(boost::bind( _m3 &QIcon::pixmap,_1,_2,QIcon::Normal,QIcon::Off)))

        .def("paint", _R &QIcon::paint)
        .def("paint", _RI &QIcon::paint)
        .def("paint", tag_function<_F(_p,_r)>(boost::bind(_R &QIcon::paint, _1,_2,_3,Qt::AlignCenter,QIcon::Normal,QIcon::Off) ))
        .def("paint", tag_function<_F(_p,_r,Qt::Alignment)>(boost::bind(_R &QIcon::paint, _1,_2,_3,_4,QIcon::Normal,QIcon::Off) ))
        .def("paint", tag_function<_F(_p,_r,Qt::Alignment,QIcon::Mode)>(boost::bind(_R &QIcon::paint, _1,_2,_3,_4,_5,QIcon::Off) ))
        .def("paint", tag_function<_F(_p,_ri)>(boost::bind(_RI &QIcon::paint, _1,_2,_3,_4,_5,_6,Qt::AlignCenter,QIcon::Normal,QIcon::Off) ))
        .def("paint", tag_function<_F(_p,_ri,Qt::Alignment)>(boost::bind(_RI &QIcon::paint, _1,_2,_3,_4,_5,_6,_7,QIcon::Normal,QIcon::Off) ))
        .def("paint", tag_function<_F(_p,_ri,Qt::Alignment,QIcon::Mode)>(boost::bind(_RI &QIcon::paint, _1,_2,_3,_4,_5,_6,_7,_8,QIcon::Off) ))
        ;
}
namespace luabind{
    QT_EMUN_CONVERTER(Qt::CursorShape)
}
LQCursor lqcursor()
{
    return
    class_<QCursor>("QCursor")
    .def(constructor<Qt::CursorShape>())
    .def(constructor< const QBitmap &,const QBitmap &>())
    .def(constructor< const QBitmap &,const QBitmap &,int>())
    .def(constructor< const QBitmap &,const QBitmap &,int,int>())
    .def(constructor< const QPixmap &>())
    .def(constructor< const QPixmap &,int>())
    .def(constructor< const QPixmap &,int,int>())
    .def(constructor< const QCursor &>())
    .property("bitmap", &QCursor::bitmap)
    .property("mask", &QCursor::mask)
    .property("pixmap", &QCursor::pixmap)
    .property("shape", &QCursor::shape, &QCursor::setShape)
    .scope[
            def("pos", &QCursor::pos),
            def("setPos", (void (*)(const QPoint&))&QCursor::setPos),
            def("setPos", (void (*)(int,int))&QCursor::setPos)
    ]
    ;
}
