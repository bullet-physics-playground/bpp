#include "lua_qbutton.h"

static setter_map<QAbstractButton> lqab_set_map;
static setter_map<QCheckBox> lqcb_set_map;
static setter_map<QPushButton> lqpb_set_map;
static setter_map<QRadioButton> lqrb_set_map;
static setter_map<QToolButton> lqtb_set_map;
static setter_map<QButtonGroup> lqbg_set_map;

SIGNAL_PROPERYT(lqab, clicked, QAbstractButton, "()")
SIGNAL_PROPERYT(lqab, pressed, QAbstractButton, "()")
SIGNAL_PROPERYT(lqab, released, QAbstractButton, "()")
SIGNAL_PROPERYT(lqab, toggled, QAbstractButton, "(bool)")



QAbstractButton* lqab_init(QAbstractButton* widget, const object& table)
{
    lq_general_init(widget, table, lqab_set_map);
    lqwidget_init(widget, table);
    if(type(table) == LUA_TTABLE){
        for (iterator i(table), e; i != e; ++i){
            if(type(*i) == LUA_TUSERDATA){
                if(q_cast(*i, &QAbstractButton::setShortcut, widget)){
                    //widget->setShortcut(QKeySequence(QObject::tr("Alt+T")));
                }
            }
        }
    }
    return widget;
}



QCheckBox* lqcb_init(QCheckBox* widget, const object& obj)
{
    lqab_init(widget, obj);
    return widget;
}

template<>
void table_init_general<QCheckBox>(const luabind::argument & arg, const object& obj)
{
    lqcb_init(construct<QCheckBox>(arg), obj);
}

QPushButton* lqpb_init(QPushButton* widget, const object& obj)
{
    lqab_init(widget, obj);
    lq_general_init(widget, obj, lqpb_set_map);
    for(iterator i(obj),e;i!=e;++i){
        if(type(*i) == LUA_TUSERDATA){
            if(q_cast(*i, (void(QPushButton::*)( QMenu*))&QPushButton::setMenu, widget)){
            }
        }
    }
    return widget;
}

template<>
void table_init_general<QPushButton>(const luabind::argument & arg, const object& obj)
{
    lqpb_init(construct<QPushButton>(arg), obj);
}

QRadioButton* lqrb_init(QRadioButton* widget, const object& obj)
{
    lqab_init(widget, obj);
    return lq_general_init(widget, obj, lqrb_set_map);
}

template<>
void table_init_general<QRadioButton>(const luabind::argument & arg, const object& obj)
{
    lqrb_init(construct<QRadioButton>(arg), obj);
}

QToolButton* lqtb_init(QToolButton* widget, const object& obj)
{
    lqab_init(widget, obj);
    return lq_general_init(widget, obj, lqtb_set_map);
}

template<>
void table_init_general<QToolButton>(const luabind::argument & arg, const object& obj)
{
    lqtb_init(construct<QToolButton>(arg), obj);
}

QButtonGroup* lqbg_init(QButtonGroup* widget, const object& obj)
{
    lq_general_init(widget, obj, lqbg_set_map);

    for(iterator i(obj),e;i!=e;++i){
        if(type(*i) == LUA_TUSERDATA){
            QAbstractButton* btn = 0;
            try{ btn = object_cast<QAbstractButton*>(*i); }
            catch(...){}
            if(btn){
                widget->addButton(btn);
            }
        }
    }
    return widget;
}

template<>
void table_init_general<QButtonGroup>(const luabind::argument & arg, const object& obj)
{
    lqbg_init(construct<QButtonGroup>(arg), obj);
}


LQAbstractButton lqabstractbutton()
{
    return
    myclass_<QAbstractButton,QAbstractButtonWrap,QWidget>("QAbstractButton",lqab_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())

    .property("autoExclusive", &QAbstractButton::autoExclusive, &QAbstractButton::setAutoExclusive)
    .property("checkable", &QAbstractButton::isCheckable, &QAbstractButton::setCheckable)
    .property("checked", &QAbstractButton::isChecked, &QAbstractButton::setChecked)
    .property("down", &QAbstractButton::isDown, &QAbstractButton::setDown)
    .property("text", &QAbstractButton::text, &QAbstractButton::setText)
    .sig_prop(lqab,clicked)
    .sig_prop(lqab,pressed)
    .sig_prop(lqab,released)
    .sig_prop(lqab,toggled)
    .property("icon", &QAbstractButton::icon, &QAbstractButton::setIcon)
    .class_<QAbstractButton,QAbstractButtonWrap,QWidget>::property("shortcut",&QAbstractButton::shortcut, &QAbstractButton::setShortcut)
    ;
}


LQCheckBox lqcheckbox()
{
    return
    myclass_<QCheckBox,QAbstractButton>("QCheckBox",lqcb_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&, QWidget*>())
    .def("__call", lqcb_init)
    .def("__init", table_init_general<QCheckBox>)

    .property("tristate", &QCheckBox::isTristate, &QCheckBox::setTristate)
    .class_<QCheckBox,QAbstractButton>::property("checkState", &QCheckBox::checkState, &QCheckBox::setCheckState)
    ;
}

LQPushButton lqpushbutton()
{
    return
    myclass_<QPushButton,QAbstractButton>("QPushButton",lqpb_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&, QWidget*>())
    .def(constructor<const QIcon&, const QString&>())
    .def(constructor<const QIcon&, const QString&, QWidget*>())
    .def("__call", lqpb_init)
    .def("__init", table_init_general<QPushButton>)
    .def("showMenu", &QPushButton::showMenu)
    .def("getMenu", &QPushButton::menu)

    .property("default", &QPushButton::isDefault, &QPushButton::setDefault)
    .property("flat", &QPushButton::isFlat, &QPushButton::setFlat)
    .property("autoDefault", &QPushButton::autoDefault, &QPushButton::setAutoDefault)

    .class_<QPushButton,QAbstractButton>::property("menu", &QPushButton::menu, &QPushButton::setMenu)
    ;
}

LQRadioButton lqradionbutton()
{
    return
    myclass_<QRadioButton,QAbstractButton>("QRadioButton",lqrb_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&, QWidget*>())
    .def("__call", lqrb_init)
    .def("__init", table_init_general<QRadioButton>)
    ;
}

LQToolButton lqtoolbutton()
{
    return
    myclass_<QToolButton,QAbstractButton>("QToolButton",lqtb_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def("__call", lqtb_init)
    .def("__init", table_init_general<QToolButton>)

    .property("autoRaise", &QToolButton::autoRaise, &QToolButton::setAutoRaise)
    ;
}

int lqbuttongroup_button_count(const QButtonGroup* bg)
{
    return bg->buttons().count();
}

QAbstractButton* lqbuttongroup_button_at(const QButtonGroup* bg, int i)
{
    QList<QAbstractButton*> btns = bg->buttons();
    int cnt = btns.count();
    if(i<cnt) return btns.at(i);
    return 0;
}

LQButtonGroup lqbuttongroup()
{
    return
    myclass_<QButtonGroup,QObject>("QButtonGroup",lqbg_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def("__call", lqbg_init)
    .def("__init", table_init_general<QButtonGroup>)

    .def("addButton", (void(QButtonGroup::*)(QAbstractButton*) )&QButtonGroup::addButton)
    .def("addButton", (void(QButtonGroup::*)(QAbstractButton*,int) )&QButtonGroup::addButton)
    .def("removeButton", &QButtonGroup::removeButton)
    .def("button", &QButtonGroup::button)
    .def("buttonCount", lqbuttongroup_button_count)
    .def("buttonAt", lqbuttongroup_button_at)
    .def("checkedButton", &QButtonGroup::checkedButton)
    .def("checkedId", &QButtonGroup::checkedId)
    .def("setId", &QButtonGroup::setId)
    .def("id", &QButtonGroup::id)

    .property("exclusive", &QButtonGroup::exclusive, &QButtonGroup::setExclusive)
    ;
}

LQKeySequence lqkeysequence()
{
    return
    class_<QKeySequence>("QKeySequence")
    .def(constructor<>())
    .def(constructor<const QKeySequence&>())
    .def(constructor<const QString&>())
    .def(constructor<int>())
    .def(constructor<int,int>())
    .def(constructor<int,int,int>())
    .def(constructor<int,int,int,int>())
    .def(constructor<QKeySequence::StandardKey>())
    ;
}

