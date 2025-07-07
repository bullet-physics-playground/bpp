#include "lua_qdialog.h"

#include "lua_qslot.h"

#include <luabind/out_value_policy.hpp>

static setter_map<QDialog> lqdialog_set_map;
QDialog* lqdialog_init(QDialog* widget, const object& obj)
{
    lqwidget_init(widget, obj);
    return lq_general_init(widget, obj, lqdialog_set_map);
}

template<>
void table_init_general<QDialog>(const luabind::argument & arg, const object& obj)
{
    lqdialog_init(construct<QDialog>(arg), obj);
}


QFrame* lqframe_init(QFrame* widget, const object& obj)
{
    lqwidget_init(widget, obj);
    return widget;
}

template<>
void table_init_general<QFrame>(const luabind::argument & arg, const object& obj)
{
    lqframe_init(construct<QFrame>(arg), obj);
}

static setter_map<QGroupBox> lqgroupbox_set_map;
QGroupBox* lqgroupbox_init(QGroupBox* widget, const object& obj)
{
    lqwidget_init(widget, obj);
    return lq_general_init(widget, obj, lqgroupbox_set_map);
}

template<>
void table_init_general<QGroupBox>(const luabind::argument & arg, const object& obj)
{
    lqgroupbox_init(construct<QGroupBox>(arg), obj);
}

SIGNAL_PROPERYT(lqdialog, accepted, QDialog, "()" )
SIGNAL_PROPERYT(lqdialog, finished, QDialog, "(int)" )
SIGNAL_PROPERYT(lqdialog, rejected, QDialog, "()" )

LQDialog  lqdialog()
{
    return
    myclass_<QDialog, QWidget>("QDialog",lqdialog_set_map)
        .def(constructor<>())
        .def(constructor<QWidget*>())
        .def(constructor<QWidget*,Qt::WindowFlags>())
        .def("__call", lqdialog_init)
        .def("__init", table_init_general<QDialog>)
        .def("exec", &QDialog::exec)
        .def("accept", &QDialog::accept)
        .def("done", &QDialog::done)
        .def("reject", &QDialog::reject)
        .def("open", &QDialog::open)
        .property("result", &QDialog::result, &QDialog::setResult)
        .property("modal", &QDialog::isModal, &QDialog::setModal)
        .property("sizeGripEnabled", &QDialog::isSizeGripEnabled, &QDialog::setSizeGripEnabled)
        .sig_prop(lqdialog, accepted)
        .sig_prop(lqdialog, finished)
        .sig_prop(lqdialog, rejected)
    ;
}

LQFrame lqframe()
{
    return
    class_<QFrame, QWidget>("QFrame")
        .def(constructor<>())
        .def(constructor<QWidget*>())
        .def(constructor<QWidget*,Qt::WindowFlags>())
        .def("__call", lqframe_init)
        .def("__init", table_init_general<QFrame>)
    ;
}

SIGNAL_PROPERYT(lqgroupbox, clicked, QGroupBox, "(bool)" )
SIGNAL_PROPERYT(lqgroupbox, toggled, QGroupBox, "(bool)" )

LQGroupBox lqgroupbox()
{
    return
    myclass_<QGroupBox, QWidget>("QGroupBox",lqgroupbox_set_map)
        .def(constructor<>())
        .def(constructor<QWidget*>())
        .def(constructor<const QString&>())
        .def(constructor<const QString&, QWidget*>())
        .def("__call", lqgroupbox_init)
        .def("__init", table_init_general<QGroupBox>)
        .property("flat", &QGroupBox::isFlat ,&QGroupBox::setFlat)
        .property("checkable", &QGroupBox::isCheckable,&QGroupBox::setCheckable)
        .property("checked", &QGroupBox::isChecked ,&QGroupBox::setChecked)
        .property("title", &QGroupBox::title,&QGroupBox::setTitle)
        .sig_prop(lqgroupbox, clicked)
        .sig_prop(lqgroupbox, toggled)
    ;
}


static setter_map<QSplitter> lqsplitter_set_map;
QSplitter* lqsplitter_init(QSplitter* widget, const object& obj)
{
    lqwidget_init(widget, obj);
    if(type(obj) == LUA_TTABLE){
        for (iterator i(obj), e; i != e; ++i){
            if(type(*i) == LUA_TUSERDATA){
                if(q_cast(*i, &QSplitter::addWidget, widget)){
                }
            }
        }
    }
    return lq_general_init(widget, obj, lqsplitter_set_map);
}

template<>
void table_init_general<QSplitter>(const luabind::argument & arg, const object& obj)
{
    lqsplitter_init(construct<QSplitter>(arg), obj);
}

int lqsplitter_get_range(QSplitter* w, int i, int* max)
{
    int min = 0;
    w->getRange(i,&min,max);
    return min;
}

void lqsplitter_setOpaqueResize(QSplitter* w)
{
    w->setOpaqueResize();
}

ENUM_FILTER(QSplitter, orientation ,setOrientation)
SIGNAL_PROPERYT(lqsplitter, splitterMoved, QSplitter, "(int,int)" )
LQSplitter lqsplitter()
{
    return
    myclass_<QSplitter, QFrame>("QSplitter",lqsplitter_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<Qt::Orientation, QWidget*>())
    .def(constructor<Qt::Orientation>())
    .def("__call", lqsplitter_init)
    .def("__init", table_init_general<QSplitter>)
    .def("getRange", lqsplitter_get_range,pure_out_value(_3))
    .def("indexOf", &QSplitter::indexOf)
    .def("insertWidget", &QSplitter::insertWidget)
    .def("isCollapsible", &QSplitter::isCollapsible)
    .def("setCollapsible", &QSplitter::setCollapsible)
    .def("refresh", &QSplitter::refresh)
    .def("restoreState", &QSplitter::restoreState)
    .def("saveState", &QSplitter::saveState)
    .def("setOpaqueResize", &QSplitter::setOpaqueResize)
    .def("setOpaqueResize", lqsplitter_setOpaqueResize)
    .def("widget", &QSplitter::widget)
    .def("addWidget", &QSplitter::addWidget)

    .property("childrenCollapsible",&QSplitter::childrenCollapsible, &QSplitter::setChildrenCollapsible)
    .property("count", &QSplitter::count)
    .property("handleWidth", &QSplitter::handleWidth, &QSplitter::setHandleWidth)
    .property("orientation", QSplitter_orientation, QSplitter_setOrientation)
    .property("state", &QSplitter::restoreState, &QSplitter::saveState)
    .property("opaqueResize", &QSplitter::opaqueResize, &QSplitter::setOpaqueResize)
    .sig_prop(lqsplitter, splitterMoved)
    .class_<QSplitter, QFrame>::property("sizes", &QSplitter::sizes, &QSplitter::setSizes)
    ;
}










