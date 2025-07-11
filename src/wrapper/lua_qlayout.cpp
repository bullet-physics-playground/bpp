#include "lua_qlayout.h"

#include "lua_qslot.h"

using namespace luabind;

/*
LQLayout lqlayout()
{
    return
    class_<QLayout,QObject>("QLayout")
            .def(constructor<>())
            .def(constructor<QWidget*>())
            .def("activate",&QLayout::activate)
            .def("addWidget", &QLayout::addWidget)
            .def("contentsMargins", &QLayout::contentsMargins)
            .def("contentsRect", &QLayout::contentsRect)
            .def("getContentsMargins", &QLayout::getContentsMargins)
            .def("isEnabled", &QLayout::isEnabled)
            .def("count", &QLayout::count)
            .def("indexOf", &QLayout::indexOf)
            .def("menuBar", &QLayout::menuBar);
}
*/
//*
static setter_map<QLayout> lqlayout_set_map;
static setter_map<QVBoxLayout> lqvboxlayout_set_map;
static setter_map<QHBoxLayout> lqhboxlayout_set_map;
QLayout *lqlayout_init(QLayout *widget, const object &obj) {
  return lq_general_init(widget, obj, lqlayout_set_map);
}

void setLayoutStretch(QBoxLayout *layout, const QString &strech) {
  QStringList res = strech.split(QChar(','));
  int i = 0;
  foreach (const QString &s, res) {
    bool ok = false;
    int stretch = s.toInt(&ok, 10);
    if (ok && i < layout->count()) {
      layout->setStretch(i, stretch);
      i++;
    }
  }
}

QString layoutStretch(QBoxLayout *layout) {
  int cnt = layout->count();
  QString res;
  for (int i = 0; i < cnt; i++) {
    res += QString("%1,").arg(layout->stretch(i));
  }
  return res;
}

template <class T> void addLayoutAndWidget(T *widget, const object &obj) {
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      if (is_class<QLayout>(*i)) {
        widget->addLayout(object_cast<QLayout *>(*i));
      } else if (is_class<QString>(*i)) {
        setLayoutStretch(widget, object_cast<QString>(*i));
      } else {
        QWidget *w = 0;
        try {
          w = object_cast<QWidget *>(*i);
        } catch (...) {
        }
        if (w) {
          widget->addWidget(w);
        }
      }
    }
  }
}

QVBoxLayout *lqvboxlayout_init(QVBoxLayout *widget, const object &obj) {
  lq_general_init(widget, obj, lqvboxlayout_set_map);
  addLayoutAndWidget(widget, obj);
  return widget;
}

QHBoxLayout *lqhboxlayout_init(QHBoxLayout *widget, const object &obj) {
  lq_general_init(widget, obj, lqhboxlayout_set_map);
  addLayoutAndWidget(widget, obj);
  return widget;
}

template <>
void table_init_general<QVBoxLayout>(const luabind::argument &arg,
                                     const object &obj) {
  lqvboxlayout_init(construct<QVBoxLayout>(arg), obj);
}

template <>
void table_init_general<QHBoxLayout>(const luabind::argument &arg,
                                     const object &obj) {
  lqhboxlayout_init(construct<QHBoxLayout>(arg), obj);
}

LQLayout lqlayout() {
  return myclass_<QLayout, QLayoutWarp>("QLayout", lqlayout_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("setContentsMargins",
           (void(QLayout::*)(int, int, int, int)) & QLayout::setContentsMargins)
      .def("addWidget", &QLayout::addWidget)
      .def("__call", lqlayout_init)

      .property("contentsMargins", &QLayout::contentsMargins,
                (void(QLayout::*)(const QMargins &)) &
                    QLayout::setContentsMargins)
      .property("spacing", &QLayout::spacing, &QLayout::setSpacing)
      .property("geometry", &QLayout::geometry, &QLayout::setGeometry);
}

static setter_map<QStackedLayout> lqstacklayout_set_map;
ENUM_FILTER(QStackedLayout, stackingMode, setStackingMode)
SIGNAL_PROPERYT(lqstatckedlayout, currentChanged, QStackedLayout, "(int)")
SIGNAL_PROPERYT(lqstatckedlayout, widgetRemoved, QStackedLayout, "(int)")

QStackedLayout *lqstacklayout_init(QStackedLayout *widget, const object &obj) {
  lq_general_init(widget, obj, lqstacklayout_set_map);
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      {
        QWidget *w = 0;
        try {
          w = object_cast<QWidget *>(*i);
        } catch (...) {
        }
        if (w) {
          widget->addWidget(w);
        }
      }
    }
  }
  return widget;
}

template <>
void table_init_general<QStackedLayout>(const luabind::argument &arg,
                                        const object &obj) {
  lqstacklayout_init(construct<QStackedLayout>(arg), obj);
}

LQStackedLayout lqstatckedlayout() {
  return myclass_<QStackedLayout, QLayout>("QStackedLayout",
                                           lqstacklayout_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def(constructor<QLayout *>())
      .def("__call", lqstacklayout_init)
      .def("__init", table_init_general<QStackedLayout>)
      .def("addWidget", &QStackedLayout::addWidget)
      .def("setCurrentIndex", &QStackedLayout::setCurrentIndex)
      .def("setCurrentWidget", &QStackedLayout::setCurrentWidget)
      .def("insertWidget", &QStackedLayout::insertWidget)
      .def("widget",
           (QWidget * (QStackedLayout::*)(int) const) & QStackedLayout::widget)

      .property("currentIndex", &QStackedLayout::currentIndex,
                &QStackedLayout::setCurrentIndex)
      .property("stackingMode", QStackedLayout_stackingMode,
                QStackedLayout_setStackingMode)
      .sig_prop(lqstatckedlayout, currentChanged)
      .sig_prop(lqstatckedlayout, widgetRemoved)
      .class_<QStackedLayout, QLayout>::property(
          "currentWidget", &QStackedLayout::currentWidget,
          &QStackedLayout::setCurrentWidget);
}

static setter_map<QGridLayout> lqgridlayout_set_map;
QGridLayout *lqgridlayout_init(QGridLayout *widget, const object &obj) {
  lq_general_init(widget, obj, lqgridlayout_set_map);
  int row = 0;
  int col = 0;
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      col = 0;
      if (type(*i) == LUA_TTABLE) {
        for (iterator i2(*i), e2; i2 != e2; ++i2) {
          if (type(*i2) == LUA_TNUMBER && type(i2.key()) == LUA_TNUMBER) {
            int cm = object_cast<int>(*i2);
            widget->setColumnMinimumWidth(col, cm);
          } else if (is_class<QLayout>(*i2)) {
            widget->addLayout(object_cast<QLayout *>(*i2), row, col);
          } else {
            QWidget *w = 0;
            try {
              w = object_cast<QWidget *>(*i2);
            } catch (...) {
            }
            if (w) {
              widget->addWidget(w, row, col);
            }
          }
          col++;
        }
      } else if (type(*i) == LUA_TNUMBER && type(i.key()) == LUA_TNUMBER) {
        int rm = object_cast<int>(*i);
        widget->setRowMinimumHeight(row, rm);
      }
      row++;
    }
  }
  return widget;
}
template <>
void table_init_general<QGridLayout>(const luabind::argument &arg,
                                     const object &obj) {
  lqgridlayout_init(construct<QGridLayout>(arg), obj);
}

void lqgridlayout_addLayout1(QGridLayout *w, QLayout *l, int r, int c) {
  w->addLayout(l, r, c);
}
void lqgridlayout_addLayout2(QGridLayout *w, QLayout *l, int r, int c, int rs,
                             int cs) {
  w->addLayout(l, r, c, rs, cs);
}
void lqgridlayout_addWidget1(QGridLayout *w, QWidget *l, int r, int c) {
  w->addWidget(l, r, c);
}
void lqgridlayout_addWidget2(QGridLayout *w, QWidget *l, int r, int c, int rs,
                             int cs) {
  w->addWidget(l, r, c, rs, cs);
}

LQGridLayout lqgridlayout() {
  return myclass_<QGridLayout, QLayout>("QGridLayout", lqgridlayout_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqgridlayout_init)
      .def("__init", table_init_general<QGridLayout>)
      .def("addLayout",
           (void(QGridLayout::*)(QLayout *, int, int, Qt::Alignment)) &
               QGridLayout::addLayout)
      .def("addLayout", (void(QGridLayout::*)(QLayout *, int, int, int, int,
                                              Qt::Alignment)) &
                            QGridLayout::addLayout)
      .def("addWidget",
           (void(QGridLayout::*)(QWidget *, int, int, Qt::Alignment)) &
               QGridLayout::addWidget)
      .def("addWidget", (void(QGridLayout::*)(QWidget *, int, int, int, int,
                                              Qt::Alignment)) &
                            QGridLayout::addWidget)
      .def("addLayout", lqgridlayout_addLayout1)
      .def("addLayout", lqgridlayout_addLayout2)
      .def("addWidget", lqgridlayout_addWidget1)
      .def("addWidget", lqgridlayout_addWidget2)

      .def("cellRect", &QGridLayout::cellRect)
      .def("columnMinimumWidth", &QGridLayout::columnMinimumWidth)
      .def("setColumnMinimumWidth", &QGridLayout::setColumnMinimumWidth)
      .def("rowMinimumHeight", &QGridLayout::rowMinimumHeight)
      .def("setRowMinimumHeight", &QGridLayout::setRowMinimumHeight)
      .def("columnStretch", &QGridLayout::columnStretch)
      .def("setColumnStretch", &QGridLayout::setColumnStretch)
      .def("rowStretch", &QGridLayout::rowStretch)
      .def("setRowStretch", &QGridLayout::setRowStretch)

      .property("columnCount", &QGridLayout::columnCount)
      .property("rowCount", &QGridLayout::rowCount)
      .property("count", &QGridLayout::count)
      .property("spacing", &QGridLayout::spacing, &QGridLayout::setSpacing)
      .property("horizontalSpacing", &QGridLayout::horizontalSpacing,
                &QGridLayout::setHorizontalSpacing)
      .property("verticalSpacing", &QGridLayout::verticalSpacing,
                &QGridLayout::setVerticalSpacing)
      .property("hSpacing", &QGridLayout::horizontalSpacing,
                &QGridLayout::setHorizontalSpacing)
      .property("vSpacing", &QGridLayout::verticalSpacing,
                &QGridLayout::setVerticalSpacing);
}

static setter_map<QFormLayout> lqformlayout_set_map;
QFormLayout *lqformlayout_init(QFormLayout *widget, const object &obj) {
  lq_general_init(widget, obj, lqformlayout_set_map);
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      if (type(*i) == LUA_TTABLE) {
        object label;
        object field;
        for (iterator i2(*i), e2; i2 != e2; ++i2) {
          if (label) {
            field = *i2;
          } else if (field) {
            break;
          } else {
            label = *i2;
          }
        }
        if (label && field) {
          if (type(label) == LUA_TSTRING) {
            QString l = object_cast<QString>(label);
            if (is_class<QLayout>(field)) {
              widget->addRow(l, object_cast<QLayout *>(field));
            } else {
              QWidget *w = 0;
              try {
                w = object_cast<QWidget *>(field);
              } catch (...) {
              }
              if (w) {
                widget->addRow(l, w);
              }
            }
          } else {
            QWidget *l = 0;
            try {
              l = object_cast<QWidget *>(label);
            } catch (...) {
            }
            if (l) {
              if (is_class<QLayout>(field)) {
                widget->addRow(l, object_cast<QLayout *>(field));
              } else {
                QWidget *w = 0;
                try {
                  w = object_cast<QWidget *>(field);
                } catch (...) {
                }
                if (w) {
                  widget->addRow(l, w);
                }
              }
            }
          }
        }
      } else if (is_class<QLayout>(*i)) {
        widget->addRow(object_cast<QLayout *>(*i));
      } else if (is_class<QString>(*i)) {
        widget->addRow(new QLabel(object_cast<QString>(*i)));
      } else {
        QWidget *w = 0;
        try {
          w = object_cast<QWidget *>(*i);
        } catch (...) {
        }
        if (w) {
          widget->addRow(w);
        }
      }
    }
  }
  return widget;
}

template <>
void table_init_general<QFormLayout>(const luabind::argument &arg,
                                     const object &obj) {
  lqformlayout_init(construct<QFormLayout>(arg), obj);
}
ENUM_FILTER(QFormLayout, rowWrapPolicy, setRowWrapPolicy)
ENUM_FILTER(QFormLayout, labelAlignment, setLabelAlignment)
namespace luabind {
QT_ENUM_CONVERTER(QFormLayout::ItemRole)
}

LQFormLayout lqformlayout() {
  return myclass_<QFormLayout, QLayout>("QFormLayout", lqformlayout_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqformlayout_init)
      .def("__init", table_init_general<QFormLayout>)
      .def("addRow",
           (void(QFormLayout::*)(QWidget *, QWidget *)) & QFormLayout::addRow)
      .def("addRow",
           (void(QFormLayout::*)(QWidget *, QLayout *)) & QFormLayout::addRow)
      .def("addRow", (void(QFormLayout::*)(const QString &, QWidget *)) &
                         QFormLayout::addRow)
      .def("addRow", (void(QFormLayout::*)(const QString &, QLayout *)) &
                         QFormLayout::addRow)
      .def("addRow", (void(QFormLayout::*)(QWidget *)) & QFormLayout::addRow)
      .def("addRow", (void(QFormLayout::*)(QLayout *)) & QFormLayout::addRow)
      .def("insertRow", (void(QFormLayout::*)(int, QWidget *, QWidget *)) &
                            QFormLayout::insertRow)
      .def("insertRow", (void(QFormLayout::*)(int, QWidget *, QLayout *)) &
                            QFormLayout::insertRow)
      .def("insertRow",
           (void(QFormLayout::*)(int, const QString &, QWidget *)) &
               QFormLayout::insertRow)
      .def("insertRow",
           (void(QFormLayout::*)(int, const QString &, QLayout *)) &
               QFormLayout::insertRow)
      .def("insertRow",
           (void(QFormLayout::*)(int, QWidget *)) & QFormLayout::insertRow)
      .def("insertRow",
           (void(QFormLayout::*)(int, QLayout *)) & QFormLayout::insertRow)
      .def("setItem", &QFormLayout::setWidget)
      .def("labelForField", (QWidget * (QFormLayout::*)(QWidget *) const) &
                                QFormLayout::labelForField)
      .def("labelForField", (QWidget * (QFormLayout::*)(QLayout *) const) &
                                QFormLayout::labelForField)

      .property("rowCount", &QFormLayout::rowCount)
      .property("rowWrapPolicy", QFormLayout_rowWrapPolicy,
                QFormLayout_setRowWrapPolicy)
      .property("labelAlignment", QFormLayout_labelAlignment,
                QFormLayout_setLabelAlignment)
      .property("spacing", &QFormLayout::spacing, &QFormLayout::setSpacing)
      .property("verticalSpacing", &QFormLayout::verticalSpacing,
                &QFormLayout::setVerticalSpacing);
}

void lqboxlayout_add_widget(QBoxLayout *layout, QWidget *w) {
  layout->addWidget(w, 0, 0);
}

void lqboxlayout_add_widget2(QBoxLayout *layout, QWidget *w, int stretch) {
  layout->addWidget(w, stretch, 0);
}
void lqboxlayout_add_layout(QBoxLayout *layout, QLayout *l) {
  layout->addLayout(l, 0);
}

void lqboxlayout_init_general(const luabind::argument &arg) {
  construct<QBoxLayout>(arg, QBoxLayout::Direction(0));
}

LQBoxLayout lqboxlayout() {
  return class_<QBoxLayout, QLayout>("QBoxLayout")
      .def("__init", lqboxlayout_init_general)
      .def(constructor<QBoxLayout::Direction>())
      .def(constructor<QBoxLayout::Direction, QWidget *>())
      .def("addLayout", lqboxlayout_add_layout)
      .def("addLayout",
           (void(QBoxLayout::*)(QLayout *, int)) & QBoxLayout::addLayout)
      .def("addWidget", (void(QBoxLayout::*)(QWidget *, int, Qt::Alignment)) &
                            QBoxLayout::addWidget)
      .def("addWidget", lqboxlayout_add_widget2)
      .def("addWidget", lqboxlayout_add_widget)
      .def("setStretch", &QBoxLayout::setStretch)
      .def("stretch", &QBoxLayout::stretch)
      .property("layoutStrech", layoutStretch, setLayoutStretch);
}

LQVBoxLayout lqvboxlayout() {
  return class_<QVBoxLayout, QBoxLayout>("QVBoxLayout")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqvboxlayout_init)
      .def("__init", table_init_general<QVBoxLayout>);
}
LQHBoxLayout lqhboxlayout() {
  return class_<QHBoxLayout, QBoxLayout, lite_ptr<QHBoxLayout>>("QHBoxLayout")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqhboxlayout_init)
      .def("__init", table_init_general<QHBoxLayout>);
}

void lqspaceritem_changeSize1(QSpacerItem *o, int w, int h) {
  o->changeSize(w, h);
}
void lqspaceritem_changeSize2(QSpacerItem *o, int w, int h, int hPolicy) {
  o->changeSize(w, h, QSizePolicy::Policy(hPolicy));
}
void lqspaceritem_changeSize3(QSpacerItem *o, int w, int h, int hPolicy,
                              int vPolicy) {
  o->changeSize(w, h, QSizePolicy::Policy(hPolicy),
                QSizePolicy::Policy(vPolicy));
}

LQSpacerItem lqspaceritem() {
  return class_<QSpacerItem>("QSpacerItem")
      .def(constructor<int, int>())
      .def(constructor<int, int, QSizePolicy::Policy>())
      .def(constructor<int, int, QSizePolicy::Policy, QSizePolicy::Policy>())
      .def("changeSize", lqspaceritem_changeSize1)
      .def("changeSize", lqspaceritem_changeSize2)
      .def("changeSize", lqspaceritem_changeSize3)

      ;
}
