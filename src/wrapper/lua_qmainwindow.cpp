#include "lua_qmainwindow.h"

#include <luabind/tag_function.hpp>

#include "lua_qslot.h"

using namespace luabind;

QString toString(const object &obj) {
  switch (type(obj)) {
  case LUA_TNUMBER:
    return QString("%1").arg(object_cast<int>(obj));
  case LUA_TSTRING:
    return object_cast<QString>(obj);
  case LUA_TUSERDATA:
  case LUA_TFUNCTION: {
    detail::object_rep *p = detail::get_instance(obj.interpreter(), 0);
    if (p) {
      qDebug() << "raw: " << p->crep()->name();
    }
  }
    return QString::fromLocal8Bit(
        get_class_info(argument(from_stack(obj.interpreter(), 0)))
            .name.c_str());
  }
  return QString::fromLocal8Bit("Unkonwn?");
}

QMainWindow *lqmainwindow_init(QMainWindow *widget, const object &init_table) {
  lqwidget_init(widget, init_table);
  if (type(init_table) == LUA_TTABLE) {
    for (iterator i(init_table), e; i != e; ++i) {
      if (is_class<QDockWidget>(*i)) {
        Qt::DockWidgetArea area = Qt::BottomDockWidgetArea;
        if (type(i.key()) == LUA_TSTRING) {
          QString key = object_cast<QString>(i.key());
          if (key.compare("leftdock", Qt::CaseInsensitive) == 0) {
            area = Qt::LeftDockWidgetArea;
          } else if (key.compare("rightdock", Qt::CaseInsensitive) == 0) {
            area = Qt::RightDockWidgetArea;
          } else if (key.compare("topdock", Qt::CaseInsensitive) == 0) {
            area = Qt::TopDockWidgetArea;
          } else if (key.compare("bottomdock", Qt::CaseInsensitive) == 0) {
            area = Qt::BottomDockWidgetArea;
          }
        }
        widget->addDockWidget(area, object_cast<QDockWidget *>(*i));
      } else

          if (type(*i) == LUA_TUSERDATA) {
        // qDebug()<<"type:"<<toString(*i);
        if (q_cast(*i, &QMainWindow::setMenuBar, widget)) {
        } else if (q_cast(*i,
                          (void(QMainWindow::*)(QToolBar *)) &
                              QMainWindow::addToolBar,
                          widget)) {
        } else if (q_cast(*i,
                          (QAction * (QMenuBar::*)(QMenu *)) &
                              QMenuBar::addMenu,
                          widget->menuBar())) {
        } else if (q_cast(*i,
                          (void(QMenuBar::*)(QAction *)) & QMenuBar::addAction,
                          widget->menuBar())) {
        } else if (q_cast(*i,
                          (void(QMainWindow::*)(QStatusBar *)) &
                              QMainWindow::setStatusBar,
                          widget)) {
          // widget->addDockWidget(Qt::TopDockWidgetArea, new
          // QDockWidget("123"));
        } else {
          q_cast(*i, &QMainWindow::setCentralWidget, widget);
        }
      }
      // qDebug()<<"key:"<<toString(i.key())<<"val:"<<toString(*i);
    }
  }
  return widget;
}

void table_init_qmainwindow(const luabind::argument &arg, const object &obj) {
  lqmainwindow_init(construct<QMainWindow>(arg), obj);
}

QByteArray get_state(QMainWindow *w) { return w->saveState(); }

void set_state(QMainWindow *w, const QByteArray &arr) { w->restoreState(arr); }
namespace luabind {
QT_ENUM_CONVERTER(Qt::DockWidgetArea)
QT_ENUM_CONVERTER(Qt::ToolBarArea)
QT_ENUM_CONVERTER(Qt::Corner)
QT_ENUM_CONVERTER(QMainWindow::DockOption)
QT_ENUM_CONVERTER(QMainWindow::DockOptions)
QT_ENUM_CONVERTER(Qt::ToolButtonStyle)
} // namespace luabind

void lqmainwindow_addToolBarBreak(QMainWindow *w) { w->addToolBarBreak(); }

SIGNAL_PROPERYT(lqmainwindow, iconSizeChanged, QMainWindow, "(const QSize&)")
SIGNAL_PROPERYT(lqmainwindow, toolButtonStyleChanged, QMainWindow,
                "(Qt::ToolButtonStyle)")
LQMainWindow lqmainwindow() {
  return class_<QMainWindow, QWidget>("QMainWindow")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def(constructor<QWidget *, Qt::WindowFlags>())
      .def("__call", &lqmainwindow_init)
      .def("__init", &table_init_qmainwindow)

      .def("addToolBar", (QToolBar * (QMainWindow::*)(const QString &)) &
                             QMainWindow::addToolBar)
      .def("addToolBar", (void(QMainWindow::*)(Qt::ToolBarArea, QToolBar *)) &
                             QMainWindow::addToolBar)
      .def("addToolBar",
           (void(QMainWindow::*)(QToolBar *)) & QMainWindow::addToolBar)
      .def("insertToolBar", &QMainWindow::insertToolBar)
      .def("removeToolBar", &QMainWindow::removeToolBar)
      .def("removeToolBarBreak", &QMainWindow::removeToolBarBreak)
      .def("addDockWidget",
           (void(QMainWindow::*)(Qt::DockWidgetArea, QDockWidget *,
                                 Qt::Orientation)) &
               QMainWindow::addDockWidget)
      .def("addDockWidget",
           (void(QMainWindow::*)(Qt::DockWidgetArea, QDockWidget *)) &
               QMainWindow::addDockWidget)
      .def("splitDockWidget", &QMainWindow::splitDockWidget)
      .def("tabifyDockWidget", &QMainWindow::tabifyDockWidget)
      .def("tabifiedDockWidgets", &QMainWindow::tabifiedDockWidgets)
      .def("removeDockWidget", &QMainWindow::removeDockWidget)
      .def("restoreDockWidget", &QMainWindow::restoreDockWidget)

      .def("addToolBarBreak", &QMainWindow::addToolBarBreak)
      .def("addToolBarBreak", lqmainwindow_addToolBarBreak)
      .def("insertToolBarBreak", &QMainWindow::insertToolBarBreak)
      .def("corner", &QMainWindow::corner)
      .def("setCorner", &QMainWindow::setCorner)
      .def("tabPosition", &QMainWindow::tabPosition)
      .def("setTabPosition", &QMainWindow::setTabPosition)

      .property("menuBar", &QMainWindow::menuBar, &QMainWindow::setMenuBar)
      .property("centralWidget", &QMainWindow::centralWidget,
                &QMainWindow::setCentralWidget)
      .property("state", get_state, set_state)
      .property("statusBar", &QMainWindow::statusBar,
                &QMainWindow::setStatusBar)
      .property("dockOptions", &QMainWindow::dockOptions,
                &QMainWindow::setDockOptions)
      .property("iconSize", &QMainWindow::iconSize, &QMainWindow::setIconSize)
      .property("documentMode", &QMainWindow::documentMode,
                &QMainWindow::setDocumentMode)
      .property("menuWidget", &QMainWindow::menuWidget,
                &QMainWindow::setMenuWidget)
      .property("animated", &QMainWindow::isAnimated, &QMainWindow::setAnimated)
      .property("dockNestingEnabled", &QMainWindow::isDockNestingEnabled,
                &QMainWindow::setDockNestingEnabled)
      .property("toolButtonStyle", &QMainWindow::toolButtonStyle,
                &QMainWindow::setToolButtonStyle)
      .property("tabShape", &QMainWindow::tabShape, &QMainWindow::setTabShape)
      .sig_prop(lqmainwindow, iconSizeChanged)
      .sig_prop(lqmainwindow, toolButtonStyleChanged);
}

QDockWidget *lqdockwidget_init(QDockWidget *widget, const object &init_table) {
  if (type(init_table) == LUA_TTABLE) {
    for (iterator i(init_table), e; i != e; ++i) {

      if (type(i.key()) == LUA_TSTRING) {
        QString key = object_cast<QString>(i.key());
        if (key.compare("widget", Qt::CaseInsensitive) == 0) {
          q_cast(*i, &QDockWidget::setWidget, widget);
        } else if (key.compare("titleBarWidget", Qt::CaseInsensitive) == 0) {
          q_cast(*i, &QDockWidget::setTitleBarWidget, widget);
        } else if (key.compare("titlebar", Qt::CaseInsensitive) == 0) {
          q_cast(*i, &QDockWidget::setTitleBarWidget, widget);
        }
      } else {
        q_cast(*i, &QDockWidget::setWidget, widget);
      }
    }
  }
  return widget;
}

void table_init_qdockwidget(const luabind::argument &arg, const object &obj) {
  lqdockwidget_init(construct<QDockWidget>(arg), obj);
}

SIGNAL_PROPERYT(lqdockwidget, allowedAreasChanged, QDockWidget,
                "(Qt::DockWidgetAreas)")
SIGNAL_PROPERYT(lqdockwidget, dockLocationChanged, QDockWidget,
                "(Qt::DockWidgetArea)")
SIGNAL_PROPERYT(lqdockwidget, featuresChanged, QDockWidget,
                "(QDockWidget::DockWidgetFeatures)")
SIGNAL_PROPERYT(lqdockwidget, topLevelChanged, QDockWidget, "(bool)")
SIGNAL_PROPERYT(lqdockwidget, visibilityChanged, QDockWidget, "(bool)")

LQDockWidget lqdockwidget() {
  return class_<QDockWidget, QWidget>("QDockWidget")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def(constructor<const QString &>())
      .def(constructor<const QString &, QWidget *>())
      .def("__call", &lqdockwidget_init)
      .def("__init", &table_init_qdockwidget)

      .property("floating", &QDockWidget::isFloating, &QDockWidget::setFloating)
      .property("windowTitle", &QDockWidget::windowTitle,
                &QDockWidget::setWindowTitle)
      .property("widget", &QDockWidget::widget, &QDockWidget::setWidget)
      .property("titleBarWidget", &QDockWidget::titleBarWidget,
                &QDockWidget::setTitleBarWidget)
      .property("allowedAreas", &QDockWidget::allowedAreas,
                &QDockWidget::setAllowedAreas)
      .property("features", &QDockWidget::features, &QDockWidget::setFeatures)
      .property("toggleViewAction", &QDockWidget::toggleViewAction)
      .sig_prop(lqdockwidget, allowedAreasChanged)
      .sig_prop(lqdockwidget, dockLocationChanged)
      .sig_prop(lqdockwidget, featuresChanged)
      .sig_prop(lqdockwidget, topLevelChanged)
      .sig_prop(lqdockwidget, visibilityChanged);
}

void lqstatusbar_showMessage(QStatusBar *w, const QString &msg) {
  w->showMessage(msg);
}
void lqstatusbar_addPermanentWidget(QStatusBar *w, QWidget *c) {
  w->addPermanentWidget(c);
}
void lqstatusbar_addWidget(QStatusBar *w, QWidget *c) { w->addWidget(c); }
void lqstatusbar_insertPermanentWidget(QStatusBar *w, int idx, QWidget *c) {
  w->insertPermanentWidget(idx, c);
}
void lqstatusbar_insertWidget(QStatusBar *w, int idx, QWidget *c) {
  w->insertWidget(idx, c);
}
SIGNAL_PROPERYT(lqstatusbar, messageChanged, QStatusBar, "(const QString&)")

LQStatusBar lqstatusbar() {
  return class_<QStatusBar, QWidget>("QStatusBar")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("addWidget", &QStatusBar::addWidget)
      .def("addWidget", lqstatusbar_addWidget)
      .def("addPermanentWidget", &QStatusBar::addPermanentWidget)
      .def("addPermanentWidget", lqstatusbar_addPermanentWidget)
      .def("insertPermanentWidget", &QStatusBar::insertPermanentWidget)
      .def("insertPermanentWidget", lqstatusbar_insertPermanentWidget)
      .def("insertWidget", &QStatusBar::insertWidget)
      .def("insertWidget", lqstatusbar_insertWidget)
      .def("removeWidget", &QStatusBar::removeWidget)
      .def("clearMessage", &QStatusBar::clearMessage)
      .def("showMessage", &QStatusBar::showMessage)
      .def("showMessage", lqstatusbar_showMessage)

      .property("sizeGripEnabled", &QStatusBar::isSizeGripEnabled,
                &QStatusBar::setSizeGripEnabled)
      .property("currentMessage", &QStatusBar::currentMessage)
      .sig_prop(lqstatusbar, messageChanged);
}

LQAbstractScrollArea lqabstractscrollarea() {
  return class_<QAbstractScrollArea, QFrame>("QAbstractScrollArea")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("addScrollBarWidget", &QAbstractScrollArea::addScrollBarWidget)

      .property("verticalScrollBar", &QAbstractScrollArea::verticalScrollBar,
                &QAbstractScrollArea::setVerticalScrollBar)
      .property("verticalScrollBarPolicy",
                &QAbstractScrollArea::verticalScrollBarPolicy,
                &QAbstractScrollArea::setVerticalScrollBarPolicy)
      .property("horizontalScrollBar",
                &QAbstractScrollArea::horizontalScrollBar,
                &QAbstractScrollArea::setHorizontalScrollBar)
      .property("horizontalScrollBarPolicy",
                &QAbstractScrollArea::horizontalScrollBarPolicy,
                &QAbstractScrollArea::setHorizontalScrollBarPolicy)
      .property("cornerWidget", &QAbstractScrollArea::cornerWidget,
                &QAbstractScrollArea::setCornerWidget)
      .property("viewport", &QAbstractScrollArea::viewport,
                &QAbstractScrollArea::setViewport)
      .property("maximumViewportSize",
                &QAbstractScrollArea::maximumViewportSize);
}

SIGNAL_PROPERYT(lqmdiarea, subWindowActivated, QMdiArea, "(QMdiSubWindow*)")
LQMdiArea lqmdiarea() {
  return class_<QMdiArea, QAbstractScrollArea>("QMdiArea")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("addSubWindow", &QMdiArea::addSubWindow)
      .def("addSubWindow",
           tag_function<QMdiSubWindow *(QMdiArea *, QWidget *)>(boost::bind(
               &QMdiArea::addSubWindow, _1, _2, Qt::WindowFlags(0))))

      .def("removeSubWindow", &QMdiArea::removeSubWindow)
      .def("setOption", &QMdiArea::setOption)
      .def("setOption", tag_function<void(QMdiArea *, QMdiArea::AreaOption)>(
                            boost::bind(&QMdiArea::setOption, _1, _2, true)))
      .def("testOption", &QMdiArea::testOption)

      .def("setActiveSubWindow", &QMdiArea::setActiveSubWindow)
      .def("activateNextSubWindow", &QMdiArea::activateNextSubWindow)
      .def("activatePreviousSubWindow", &QMdiArea::activatePreviousSubWindow)
      .def("tileSubWindows", &QMdiArea::tileSubWindows)
      .def("cascadeSubWindows", &QMdiArea::cascadeSubWindows)
      .def("closeActiveSubWindow", &QMdiArea::closeActiveSubWindow)
      .def("closeAllSubWindows", &QMdiArea::closeAllSubWindows)
      .def("subWindowList", &QMdiArea::subWindowList)
      .def("subWindowList",
           tag_function<QList<QMdiSubWindow *>(QMdiArea *)>(boost::bind(
               &QMdiArea::subWindowList, _1, QMdiArea::CreationOrder)))

      .property("background", &QMdiArea::background, &QMdiArea::setBackground)
      .property("activationOrder", &QMdiArea::activationOrder,
                &QMdiArea::setActivationOrder)
      .property("activeSubWindow", &QMdiArea::activeSubWindow,
                &QMdiArea::setActiveSubWindow)
      .property("currentSubWindow", &QMdiArea::currentSubWindow)
      .property("documentMode", &QMdiArea::documentMode,
                &QMdiArea::setDocumentMode)
      .property("tabPosition", &QMdiArea::tabPosition,
                &QMdiArea::setTabPosition)
      .property("tabShape", &QMdiArea::tabShape, &QMdiArea::setTabShape)
      .property("viewMode", &QMdiArea::viewMode, &QMdiArea::setViewMode)
      .sig_prop(lqmdiarea, subWindowActivated);
}

LQMdiSubWindow lqmdisubwindow() {
  return class_<QMdiSubWindow, QWidget>("QMdiSubWindow")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("setOption", &QMdiSubWindow::setOption)
      .def("setOption",
           tag_function<void(QMdiSubWindow *, QMdiSubWindow::SubWindowOption)>(
               boost::bind(&QMdiSubWindow::setOption, _1, _2, true)))
      .def("testOption", &QMdiSubWindow::testOption)
      .def("showShaded", &QMdiSubWindow::showShaded)
      .def("showSystemMenu", &QMdiSubWindow::showSystemMenu)

      .property("widget", &QMdiSubWindow::widget, &QMdiSubWindow::setWidget)
      .property("mdiArea", &QMdiSubWindow::mdiArea)
      .property("systemMenu", &QMdiSubWindow::systemMenu,
                &QMdiSubWindow::setSystemMenu);
}

namespace luabind {
QT_ENUM_CONVERTER(QSystemTrayIcon::MessageIcon)
}
SIGNAL_PROPERYT(lqsystemtrayicon, activated, QSystemTrayIcon,
                "(QSystemTrayIcon::ActivationReason)")
SIGNAL_PROPERYT(lqsystemtrayicon, messageClicked, QSystemTrayIcon, "()")

static setter_map<QSystemTrayIcon> lqsystemtrayicon_set_map;
QSystemTrayIcon *lqsystemtrayicon_init(QSystemTrayIcon *widget,
                                       const object &obj) {
  for (iterator i(obj), e; i != e; ++i) {
    if (type(*i) == LUA_TUSERDATA) {
      if (q_cast(*i, &QSystemTrayIcon::setContextMenu, widget)) {
      }
    }
  }
  return lq_general_init(widget, obj, lqsystemtrayicon_set_map);
}

template <>
void table_init_general<QSystemTrayIcon>(const luabind::argument &arg,
                                         const object &obj) {
  lqsystemtrayicon_init(construct<QSystemTrayIcon>(arg), obj);
}

LQSystemTrayIcon lqsystemtrayicon() {
  return myclass_<QSystemTrayIcon, QObject>("QSystemTrayIcon",
                                            lqsystemtrayicon_set_map)
      .def(constructor<>())
      .def(constructor<QObject *>())
      .def(constructor<const QIcon &>())
      .def(constructor<const QIcon &, QObject *>())
      .def("__call", lqsystemtrayicon_init)
      .def("__init", table_init_general<QSystemTrayIcon>)

      .def("setVisible", &QSystemTrayIcon::setVisible)
      .def("show", &QSystemTrayIcon::show)
      .def("hide", &QSystemTrayIcon::hide)
      .def("showMessage", &QSystemTrayIcon::showMessage)
      .def("showMessage",
           tag_function<void(QSystemTrayIcon *, const QString &,
                             const QString &, QSystemTrayIcon::MessageIcon)>(
               boost::bind(&QSystemTrayIcon::showMessage, _1, _2, _3, _4,
                           10000)))
      .def("showMessage",
           tag_function<void(QSystemTrayIcon *, const QString &,
                             const QString &)>(
               boost::bind(&QSystemTrayIcon::showMessage, _1, _2, _3,
                           QSystemTrayIcon::Information, 10000)))

      .property("icon", &QSystemTrayIcon::icon, &QSystemTrayIcon::setIcon)
      .property("geometry", &QSystemTrayIcon::geometry)
      .property("visible", &QSystemTrayIcon::isVisible,
                &QSystemTrayIcon::setVisible)
      .property("toolTip", &QSystemTrayIcon::toolTip,
                &QSystemTrayIcon::setToolTip)
      .property("activated", lqsystemtrayicon_get_activated,
                lqsystemtrayicon_set_activated)
      .sig_prop(lqsystemtrayicon, messageClicked)
      .class_<QSystemTrayIcon, QObject>::property(
          "contextMenu", &QSystemTrayIcon::contextMenu,
          &QSystemTrayIcon::setContextMenu)

      .scope[def("isSystemTrayAvailable",
                 &QSystemTrayIcon::isSystemTrayAvailable),
             def("supportsMessages", &QSystemTrayIcon::supportsMessages)];
}

class QTestType {
public:
  QTestType() { qDebug() << "QTestType()"; }
  QTestType(const object &obj) {
    (void)obj;
    qDebug() << "QTestType";
  }
  void showText() { qDebug() << "showText"; }

  QString text() { return "test"; }

  void setText(const QString &t) { (void)t; }
};

QTestType *init_test_type(QTestType *x, const object &init_table) {
  (void)init_table;
  return x;
}

void init_tp(const luabind::argument &arg, const object &obj) {
  init_test_type(construct<QTestType>(arg), obj);
}

LQTestType lqtesttype() {
  return class_<QTestType>("QTestType")
      .def(constructor<>())
      //.def(constructor<const object&>())
      .def("__call", init_test_type)
      .def("__init", init_tp)
      .def("showText", &QTestType::showText)
      .property("showText", &QTestType::text, &QTestType::setText);
}
