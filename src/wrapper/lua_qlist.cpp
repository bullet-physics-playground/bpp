#include "lua_qlist.h"

#include <boost/bind.hpp>
#include <luabind/luabind.hpp>
#include <luabind/operator.hpp>
#include <luabind/tag_function.hpp>

#include "lua_qslot.h"

#include <luabind/adopt_policy.hpp>

template <class T, class pfnT>
void addItems(T *base, pfnT(T::*addItem), const object &obj) {
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      QVariant v;
      QString key;
      if (type(i.key()) == LUA_TSTRING) {
        key = object_cast<QString>(i.key());
        v.setValue(object(*i));
      } else if (type(*i) == LUA_TSTRING) {
        key = object_cast<QString>(*i);
      } else {
        continue;
      }
      (base->*addItem)(key, v);
    }
  }
}

void lqcombobox_addItem1(QComboBox *combo, const QString &text,
                         const QVariant &userData) {
  combo->addItem(text, userData);
}

void lqcombobox_addItem2(QComboBox *combo, const QIcon &icon,
                         const QString &text, const QVariant &userData) {
  combo->addItem(icon, text, userData);
}

void lqcombobox_addItems(QComboBox *combo, const object &obj) {
  addItems(combo,
           (void(QComboBox::*)(const QString &, const QVariant &)) &
               QComboBox::addItem,
           obj);
  combo->addItems(list_cast<QString>(obj));
}

void lqcombobox_insertItem1(QComboBox *combo, int index, const QString &text,
                            const QVariant &userData) {
  combo->insertItem(index, text, userData);
}

void lqcombobox_insertItem2(QComboBox *combo, int index, const QIcon &icon,
                            const QString &text, const QVariant &userData) {
  combo->insertItem(index, icon, text, userData);
}

void lqcombobox_insertItems(QComboBox *combo, int index, const object &obj) {
  combo->insertItems(index, list_cast<QString>(obj));
}

SIGNAL_PROPERYT(lqcombox, activated, QComboBox, "(int)")
SIGNAL_PROPERYT(lqcombox_str, activated, QComboBox, "(const QString&)")
SIGNAL_PROPERYT(lqcombox, currentIndexChanged, QComboBox, "(int)")
SIGNAL_PROPERYT(lqcombox_str, currentIndexChanged, QComboBox,
                "(const QString&)")
SIGNAL_PROPERYT(lqcombox, highlighted, QComboBox, "(int)")
SIGNAL_PROPERYT(lqcombox_str, highlighted, QComboBox, "(const QString&)")
SIGNAL_PROPERYT(lqcombox, editTextChanged, QComboBox, "(const QString&)")

SIGNAL_PROPERYT(lqlistwidget, currentItemChanged, QListWidget,
                "( QListWidgetItem*,QListWidgetItem*)")
SIGNAL_PROPERYT(lqlistwidget, currentRowChanged, QListWidget, "(int)")
SIGNAL_PROPERYT(lqlistwidget, currentTextChanged, QListWidget,
                "(const QString &)")
SIGNAL_PROPERYT(lqlistwidget, itemActivated, QListWidget, "(QListWidgetItem*)")
SIGNAL_PROPERYT(lqlistwidget, itemChanged, QListWidget, "(QListWidgetItem*)")
SIGNAL_PROPERYT(lqlistwidget, itemClicked, QListWidget, "(QListWidgetItem*)")
SIGNAL_PROPERYT(lqlistwidget, itemDoubleClicked, QListWidget,
                "(QListWidgetItem*)")
SIGNAL_PROPERYT(lqlistwidget, itemEntered, QListWidget, "(QListWidgetItem*)")
SIGNAL_PROPERYT(lqlistwidget, itemPressed, QListWidget, "(QListWidgetItem*)")
SIGNAL_PROPERYT(lqlistwidget, itemSelectionChanged, QListWidget, "()")

SIGNAL_PROPERYT(lqtreewidget, currentItemChanged, QTreeWidget,
                "(QTreeWidgetItem*,QTreeWidgetItem*)")
SIGNAL_PROPERYT(lqtreewidget, itemActivated, QTreeWidget,
                "(QTreeWidgetItem*,int)")
SIGNAL_PROPERYT(lqtreewidget, itemChanged, QTreeWidget,
                "(QTreeWidgetItem*,int)")
SIGNAL_PROPERYT(lqtreewidget, itemClicked, QTreeWidget,
                "(QTreeWidgetItem*,int)")
SIGNAL_PROPERYT(lqtreewidget, itemCollapsed, QTreeWidget, "(QTreeWidgetItem*)")
SIGNAL_PROPERYT(lqtreewidget, itemDoubleClicked, QTreeWidget,
                "(QTreeWidgetItem*,int)")
SIGNAL_PROPERYT(lqtreewidget, itemEntered, QTreeWidget,
                "(QTreeWidgetItem*,int)")
SIGNAL_PROPERYT(lqtreewidget, itemExpanded, QTreeWidget, "(QTreeWidgetItem*)")
SIGNAL_PROPERYT(lqtreewidget, itemPressed, QTreeWidget,
                "(QTreeWidgetItem*,int)")
SIGNAL_PROPERYT(lqtreewidget, itemSelectionChanged, QTreeWidget, "()")

SIGNAL_PROPERYT(lqtablewidget, cellActivated, QTableWidget, "(int,int)")
SIGNAL_PROPERYT(lqtablewidget, cellChanged, QTableWidget, "(int,int)")
SIGNAL_PROPERYT(lqtablewidget, cellClicked, QTableWidget, "(int,int)")
SIGNAL_PROPERYT(lqtablewidget, cellDoubleClicked, QTableWidget, "(int,int)")
SIGNAL_PROPERYT(lqtablewidget, cellEntered, QTableWidget, "(int,int)")
SIGNAL_PROPERYT(lqtablewidget, cellPressed, QTableWidget, "(int,int)")
SIGNAL_PROPERYT(lqtablewidget, currentCellChanged, QTableWidget,
                "(int,int,int,int)")
SIGNAL_PROPERYT(lqtablewidget, currentItemChanged, QTableWidget,
                "(QTableWidgetItem*,QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, currentRowChanged, QTableWidget,
                "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, currentTextChanged, QTableWidget,
                "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, itemActivated, QTableWidget,
                "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, itemChanged, QTableWidget, "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, itemClicked, QTableWidget, "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, itemDoubleClicked, QTableWidget,
                "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, itemEntered, QTableWidget, "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, itemPressed, QTableWidget, "(QTableWidgetItem*)")
SIGNAL_PROPERYT(lqtablewidget, itemSelectionChanged, QTableWidget, "()")

static setter_map<QComboBox> lqcombobox_set_map;
static setter_map<QListWidgetItem> lqlistwidgetitem_set_map;
static setter_map<QListWidget> lqlistwidget_set_map;
static setter_map<QTreeWidgetItem> lqtreewidgetitem_set_map;
static setter_map<QTreeWidget> lqtreewidget_set_map;
static setter_map<QTableWidgetItem> lqtablewidgetitem_set_map;
static setter_map<QTableWidget> lqtablewidget_set_map;

QComboBox *lqcombobox_init(QComboBox *widget, const object &obj) {
  lqwidget_init(widget, obj);
  for (iterator i(obj), e; i != e; ++i) {
    if (type(*i) == LUA_TTABLE) {
      addItems(widget,
               (void(QComboBox::*)(const QString &, const QVariant &)) &
                   QComboBox::addItem,
               *i);
      // widget->addItems(list_cast<QString>(*i));
    }
  }
  return lq_general_init(widget, obj, lqcombobox_set_map);
}

template <>
void table_init_general<QComboBox>(const luabind::argument &arg,
                                   const object &obj) {
  lqcombobox_init(construct<QComboBox>(arg), obj);
}

LQComboBox lqcombobox() {
  return myclass_<QComboBox, QWidget>("QComboBox", lqcombobox_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqcombobox_init)
      .def("__init", table_init_general<QComboBox>)
      .def("addItem", tag_function<void(QComboBox *, const QString &)>(
                          boost::bind(lqcombobox_addItem1, _1, _2, QVariant())))
      .def("addItem", lqcombobox_addItem1)
      .def("addItem",
           tag_function<void(QComboBox *, const QIcon &, const QString &)>(
               boost::bind(lqcombobox_addItem2, _1, _2, _3, QVariant())))
      .def("addItem", lqcombobox_addItem2)
      .def("addItems", lqcombobox_addItems)

      .def("insertItem",
           tag_function<void(QComboBox *, int, const QString &)>(
               boost::bind(lqcombobox_insertItem1, _1, _2, _3, QVariant())))
      .def("insertItem", lqcombobox_insertItem1)
      .def("insertItem",
           tag_function<void(QComboBox *, int, const QIcon &, const QString &)>(
               boost::bind(lqcombobox_insertItem2, _1, _2, _3, _4, QVariant())))
      .def("insertItem", lqcombobox_insertItem2)
      .def("insertItems", lqcombobox_insertItems)

      .def("itemText", &QComboBox::itemText)
      .def("itemIcon", &QComboBox::itemIcon)
      .def("itemData", tag_function<QVariant(QComboBox *, int)>(boost::bind(
                           &QComboBox::itemData, _1, _2, Qt::UserRole)))
      .def("itemData", &QComboBox::itemData)
      .def("setItemData",
           tag_function<void(QComboBox *, int, const QVariant &)>(
               boost::bind(&QComboBox::setItemData, _1, _2, _3, Qt::UserRole)))
      .def("setItemData", &QComboBox::setItemData)

      .def("clear", &QComboBox::clear)
      .def("clearEditText", &QComboBox::clearEditText)
      .def("setCurrentIndex", &QComboBox::setCurrentIndex)
      .def("setEditText", &QComboBox::setEditText)

      .def("findText", &QComboBox::findText)
      .def("findText",
           tag_function<int(QComboBox *, const QString &)>(
               boost::bind(&QComboBox::findText, _1, _2,
                           Qt::MatchExactly | Qt::MatchCaseSensitive)))

      .def("findData", &QComboBox::findData)
      .def("findData",
           tag_function<int(QComboBox *, const QVariant &, int)>(
               boost::bind(&QComboBox::findData, _1, _2, _3,
                           Qt::MatchExactly | Qt::MatchCaseSensitive)))
      .def("findData",
           tag_function<int(QComboBox *, const QVariant &)>(
               boost::bind(&QComboBox::findData, _1, _2, Qt::UserRole,
                           Qt::MatchExactly | Qt::MatchCaseSensitive)))

      .property("count", &QComboBox::count)
      .property("editable", &QComboBox::isEditable, &QComboBox::setEditable)
      .property("currentIndex", &QComboBox::currentIndex,
                &QComboBox::setCurrentIndex)
      .property("currentText", &QComboBox::currentText, &QComboBox::setEditText)
      .property("activated", lqcombox_get_activated, lqcombox_set_activated)
      .property("activatedString", lqcombox_str_get_activated,
                lqcombox_str_set_activated)
      .property("currentIndexChanged", lqcombox_get_currentIndexChanged,
                lqcombox_set_currentIndexChanged)
      .property("currentIndexChangedString", lqcombox_str_get_activated,
                lqcombox_str_set_activated)
      .property("highlighted", lqcombox_get_highlighted,
                lqcombox_set_highlighted)
      .property("highlightedString", lqcombox_str_get_highlighted,
                lqcombox_str_set_highlighted)
      .property("editTextChanged", lqcombox_get_editTextChanged,
                lqcombox_set_editTextChanged)

      .class_<QComboBox, QWidget>::property("lineEdit", &QComboBox::lineEdit,
                                            &QComboBox::setLineEdit)

      ;
}

QListWidgetItem *lqlistwidgetitem_init(QListWidgetItem *widget,
                                       const object &obj) {
  //    for(iterator i(obj),e; i!=e; ++i){
  //        if(type(*i) == LUA_TTABLE){
  //            addItems(widget, (void(QComboBox::*)(const QString&,const
  //            QVariant&))&QComboBox::addItem, *i);
  //            //widget->addItems(list_cast<QString>(*i));
  //        }
  //    }
  return lq_general_init(widget, obj, lqlistwidgetitem_set_map);
}

template <>
void table_init_general<QListWidgetItem>(const luabind::argument &arg,
                                         const object &obj) {
  lqlistwidgetitem_init(construct<QListWidgetItem>(arg), obj);
}

QListWidget *lqlistwidget_init(QListWidget *widget, const object &obj) {
  lqwidget_init(widget, obj);
  for (iterator i(obj), e; i != e; ++i) {
    if (type(*i) == LUA_TTABLE) {
      // addItems(widget, (void(QComboBox::*)(const QString&,const
      // QVariant&))&QComboBox::addItem, *i);
      widget->addItems(list_cast<QString>(*i));
    }
  }
  return lq_general_init(widget, obj, lqlistwidget_set_map);
}

template <>
void table_init_general<QListWidget>(const luabind::argument &arg,
                                     const object &obj) {
  lqlistwidget_init(construct<QListWidget>(arg), obj);
}

void lqlistwidgetitem_set_check_state(QListWidgetItem *w, int state) {
  w->setCheckState(Qt::CheckState(state));
}

void lqlistwidgetitem_set_flags(QListWidgetItem *w, int flag) {
  w->setFlags(Qt::ItemFlags(flag));
}

int lqlistwidgetitem_row(QListWidgetItem *i) {
  QListWidget *l = i->listWidget();
  return l ? l->row(i) : -1;
}

LQListWidgetItem lqlistwidgetitem() {
  (void)self;
  (void)const_self;
  return myclass_<QListWidgetItem, QListWidgetItem_wrap>(
             "QListWidgetItem", lqlistwidgetitem_set_map)
      .def(constructor<>())
      .def(constructor<const QListWidgetItem &>())
      .def(constructor<QListWidget *>())
      .def(constructor<QListWidget *, int>())
      .def(constructor<const QString &>())
      .def(constructor<const QString &, QListWidget *>())
      .def(constructor<const QString &, QListWidget *, int>())
      .def(constructor<const QIcon &, const QString &>())
      .def(constructor<const QIcon &, const QString &, QListWidget *>())
      .def(constructor<const QIcon &, const QString &, QListWidget *, int>())

      .def("__call", lqlistwidgetitem_init)
      .def("__init", table_init_general<QListWidgetItem>)
      //.def("data", &QListWidgetItem::data, &QListWidgetItem::data)
      //.def("setData", &QListWidgetItem::setData, &QListWidgetItem::setData)
      //.def("__lt", &QListWidgetItem::operator <)
      .def("data", &QListWidgetItem::data, &QListWidgetItem_wrap::def_data)
      .def("setData", &QListWidgetItem::setData,
           &QListWidgetItem_wrap::def_setData)
      .def("__lt", &QListWidgetItem::operator<, &QListWidgetItem_wrap::def_lt)

      .property("listWidget", &QListWidgetItem::listWidget)
      .property("background", &QListWidgetItem::background,
                &QListWidgetItem::setBackground)
      .property("backgroundColor", &QListWidgetItem::backgroundColor,
                &QListWidgetItem::setBackgroundColor)
      .property("checkState", &QListWidgetItem::checkState,
                lqlistwidgetitem_set_check_state)
      .property("flags", &QListWidgetItem::flags, lqlistwidgetitem_set_flags)
      .property("font", &QListWidgetItem::font, &QListWidgetItem::setFont)
      .property("foreground", &QListWidgetItem::foreground,
                &QListWidgetItem::setForeground)
      .property("hidden", &QListWidgetItem::isHidden,
                &QListWidgetItem::setHidden)
      .property("icon", &QListWidgetItem::icon, &QListWidgetItem::setIcon)
      .property("selected", &QListWidgetItem::isSelected,
                &QListWidgetItem::setSelected)
      .property("statusTip", &QListWidgetItem::statusTip,
                &QListWidgetItem::setStatusTip)
      .property("text", &QListWidgetItem::text, &QListWidgetItem::setText)
      .property("textAlignment", &QListWidgetItem::textAlignment,
                &QListWidgetItem::setTextAlignment)
      .property("textColor", &QListWidgetItem::textColor,
                &QListWidgetItem::setTextColor)
      .property("toolTip", &QListWidgetItem::toolTip,
                &QListWidgetItem::setToolTip)
      .property("whatsThis", &QListWidgetItem::whatsThis,
                &QListWidgetItem::setWhatsThis)
      .property("type", &QListWidgetItem::type)
      .property("row", lqlistwidgetitem_row)

      //    .scope
      //    [
      //            class_<QListItem>("QListItem2")
      //              .def(constructor<>())
      //              .def(constructor<const QString&>())
      //              .def("data", &QListItem::_data, &QListItem::_data)
      //              .def("setData", &QListItem::_setData)
      //    ]
      ;
}

void lqlistwidget_sortItems(QListWidget *w) { w->sortItems(); }

void lqlistwidget_sortItems2(QListWidget *w, int order) {
  w->sortItems(Qt::SortOrder(order));
}

void lqlistwidget_addItems(QListWidget *w, const object &obj) {
  w->addItems(list_cast<QString>(obj));
}

void lqlistwidget_addItemsx(QListWidget *w,
                            const QList<QListWidgetItem *> &obj) {
  foreach (QListWidgetItem *i, obj) {
    w->addItem(i);
  }
}

void lqlistwidget_insertItems(QListWidget *w, int row, const object &obj) {
  w->insertItems(row, list_cast<QString>(obj));
}

void lqlistwidget_set_cur_row(QListWidget *w, int row) {
  w->setCurrentRow(row);
}

void lqlistwidget_scrollToItem(QListWidget *w, QListWidgetItem *i, int hint) {
  w->scrollToItem(i, QAbstractItemView::ScrollHint(hint));
}

void lqlistwidget_scrollToItem2(QListWidget *w, QListWidgetItem *i) {
  w->scrollToItem(i);
}

object lqlistwidget_finditems(QListWidget *w, const QString &text, int f) {
  object obj(luabind::newtable(__pL));
  QList<QListWidgetItem *> r = w->findItems(text, Qt::MatchFlags(f));
  for (int i = 0; i < r.count(); i++) {
    obj[i + 1] = r.at(i);
  }
  return obj;
}

object lqlistwidget_selecteditems(QListWidget *w) {
  object obj(luabind::newtable(__pL));
  QList<QListWidgetItem *> list = w->selectedItems();
  for (int i = 0; i < list.count(); i++) {
    obj[i + 1] = list.at(i);
  }
  return obj;
}

LQListWidget lqlistwidget() {
  return myclass_<QListWidget, QFrame>("QListWidget", lqlistwidget_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqlistwidget_init)
      .def("__init", table_init_general<QListWidget>)
      .def("addItem",
           (void(QListWidget::*)(const QString &)) & QListWidget::addItem)
      .def("addItem",
           (void(QListWidget::*)(QListWidgetItem *)) & QListWidget::addItem,
           adopt(_2))
      .def("addItems", &QListWidget::addItems)
      //.def("addItems", lqlistwidget_addItemsx)
      .def("insertItem", (void(QListWidget::*)(int, const QString &)) &
                             QListWidget::insertItem)
      .def("insertItem",
           (void(QListWidget::*)(int, QListWidgetItem *)) &
               QListWidget::insertItem,
           adopt(_3))
      .def("insertItems", &QListWidget::insertItems)

      .def("sortItems", lqlistwidget_sortItems)
      .def("sortItems", lqlistwidget_sortItems2)
      .def("row", &QListWidget::row)
      .def("item", &QListWidget::item)
      .def("itemAt", (QListWidgetItem * (QListWidget::*)(int, int) const) &
                         QListWidget::itemAt)
      .def("itemAt",
           (QListWidgetItem * (QListWidget::*)(const QPoint &) const) &
               QListWidget::itemAt)
      .def("itemWidget", &QListWidget::itemWidget)
      .def("setItemWidget", &QListWidget::setItemWidget)
      .def("takeItem", &QListWidget::takeItem)
      .def("findItems", &QListWidget::findItems)
      .def("selectedItems", &QListWidget::selectedItems)
      .def("clear", &QListWidget::clear)
      .def("scrollToItem", lqlistwidget_scrollToItem)
      .def("scrollToItem", lqlistwidget_scrollToItem2)

      .property("count", &QListWidget::count)
      .property("sortingEnabled", &QListWidget::isSortingEnabled,
                &QListWidget::setSortingEnabled)
      .property("currentRow", &QListWidget::currentRow,
                lqlistwidget_set_cur_row)

      .sig_prop(lqlistwidget, currentItemChanged)
      .sig_prop(lqlistwidget, currentRowChanged)
      .sig_prop(lqlistwidget, currentTextChanged)
      .sig_prop(lqlistwidget, itemActivated)
      .sig_prop(lqlistwidget, itemChanged)
      .sig_prop(lqlistwidget, itemClicked)
      .sig_prop(lqlistwidget, itemDoubleClicked)
      .sig_prop(lqlistwidget, itemEntered)
      .sig_prop(lqlistwidget, itemPressed)
      .sig_prop(lqlistwidget, itemSelectionChanged);
}

QTreeWidgetItem *lqtreewidgetitem_init(QTreeWidgetItem *widget,
                                       const object &obj) {
  //    for(iterator i(obj),e; i!=e; ++i){
  //        if(type(*i) == LUA_TTABLE){
  //            addItems(widget, (void(QTreeWidget::*)(const QString&,const
  //            QVariant&))&QComboBox::addItem, *i);
  //            //widget->addItems(list_cast<QString>(*i));
  //        }
  //    }
  return lq_general_init(widget, obj, lqtreewidgetitem_set_map);
}

template <>
void table_init_general<QTreeWidgetItem>(const luabind::argument &arg,
                                         const object &obj) {
  lqtreewidgetitem_init(construct<QTreeWidgetItem>(arg), obj);
}

void lqtreewidgetitem_addChildren(QTreeWidgetItem *i, const object &obj) {
  QList<QTreeWidgetItem *> children;
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      if (obj_name(*i) == "QTreeWidgetItem") {
        children.append(object_cast<QTreeWidgetItem *>(*i));
      }
    }
  }
  i->addChildren(children);
}

void lqtreewidgetitem_set_check_state(QTreeWidgetItem *i, int column,
                                      int state) {
  i->setCheckState(column, Qt::CheckState(state));
}

void lqtreewidgetitem_set_flags(QTreeWidgetItem *i, int flag) {
  i->setFlags(Qt::ItemFlags(flag));
}

object lqtreewidgetitem_takeChildren(QTreeWidgetItem *i) {
  object obj(luabind::newtable(__pL));
  QList<QTreeWidgetItem *> children = i->takeChildren();
  for (int i = 0; i < children.count(); i++) {
    obj[i + 1] = children.at(i);
  }
  return obj;
}

void lqtreewidgetitem_insertChildren(QTreeWidgetItem *i, int index,
                                     const object &obj) {
  QList<QTreeWidgetItem *> children;
  if (type(obj) == LUA_TTABLE) {
    for (iterator i(obj), e; i != e; ++i) {
      if (obj_name(*i) == "QTreeWidgetItem") {
        children.append(object_cast<QTreeWidgetItem *>(*i));
      }
    }
  }
  i->insertChildren(index, children);
}

template <class B, class R> bool is_prop(R(B *)) { return true; }

template <class B, class R> bool is_prop(R (B::*)()) { return true; }

template <class B, class R> bool is_prop(R (B::*)() const) { return true; }

template <class B> bool is_prop(B f) { return false; }

template <class Getter> int test_func(Getter f) { return is_prop(f); }
LQTreeWidgetItem lqtreewidgetitem() {
  return myclass_<QTreeWidgetItem, QTreeWidgetItem_wrap>(
             "QTreeWidgetItem", lqtreewidgetitem_set_map)
      .def(constructor<>())
      .def(constructor<int>())
      .def(constructor<const QStringList &>())
      .def(constructor<const QStringList &, int>())
      .def(constructor<QTreeWidget *>())
      .def(constructor<QTreeWidget *, int>())
      .def(constructor<QTreeWidget *, const QStringList &>())
      .def(constructor<QTreeWidget *, const QStringList &, int>())
      .def(constructor<QTreeWidget *, QTreeWidgetItem *>())
      .def(constructor<QTreeWidget *, QTreeWidgetItem *, int>())
      .def(constructor<QTreeWidgetItem *>())
      .def(constructor<QTreeWidgetItem *, int>())
      .def(constructor<QTreeWidgetItem *, const QStringList &>())
      .def(constructor<QTreeWidgetItem *, const QStringList &, int>())
      .def(constructor<QTreeWidgetItem *, QTreeWidgetItem *>())
      .def(constructor<QTreeWidgetItem *, QTreeWidgetItem *, int>())
      .def(constructor<const QTreeWidgetItem &>())

      .def("__call", lqtreewidgetitem_init)
      .def("__init", table_init_general<QTreeWidgetItem>)
      .def("addChild", &QTreeWidgetItem::addChild, adopt(_2))
      .def("addChildren", &QTreeWidgetItem::addChildren)
      .def("child", &QTreeWidgetItem::child)
      .def("childCount", &QTreeWidgetItem::childCount)
      .def("columnCount", &QTreeWidgetItem::columnCount)
      .def("takeChild", &QTreeWidgetItem::takeChild, adopt(result))
      .def("takeChildren", lqtreewidgetitem_takeChildren)
      .def("indexOfChild", &QTreeWidgetItem::indexOfChild)
      .def("insertChild", &QTreeWidgetItem::insertChild, adopt(_3))
      .def("insertChildren", lqtreewidgetitem_insertChildren)

      //    .def("data", &QTreeWidgetItem::data, &QTreeWidgetItem::data)
      //    .def("setData", &QTreeWidgetItem::setData,
      //    &QTreeWidgetItem::setData) .def("__lt", &QTreeWidgetItem::operator
      //    <)
      .def("data", &QTreeWidgetItem::data, &QTreeWidgetItem_wrap::def_data)
      .def("setData", &QTreeWidgetItem::setData,
           &QTreeWidgetItem_wrap::def_setData)
      .def("__lt", &QTreeWidgetItem::operator<, &QTreeWidgetItem_wrap::def_lt)

      .property("expanded", &QTreeWidgetItem::isExpanded,
                &QTreeWidgetItem::setExpanded)
      .property("firstColumnSpanned", &QTreeWidgetItem::isFirstColumnSpanned,
                &QTreeWidgetItem::setFirstColumnSpanned)
      .property("treeWidget", &QTreeWidgetItem::treeWidget)
      .property("selected", &QTreeWidgetItem::isSelected,
                &QTreeWidgetItem::setSelected)
      .property("hidden", &QTreeWidgetItem::isHidden,
                &QTreeWidgetItem::setHidden)
      .property("disabled", &QTreeWidgetItem::isDisabled,
                &QTreeWidgetItem::setDisabled)
      .property("flags", &QTreeWidgetItem::flags, lqtreewidgetitem_set_flags)

      .property("background", &QTreeWidgetItem::background,
                &QTreeWidgetItem::setBackground)
      .property("backgroundColor", &QTreeWidgetItem::backgroundColor,
                &QTreeWidgetItem::setBackgroundColor)
      .property("checkState", &QTreeWidgetItem::checkState,
                lqtreewidgetitem_set_check_state)
      .property("font", &QTreeWidgetItem::font, &QTreeWidgetItem::setFont)
      .property("foreground", &QTreeWidgetItem::foreground,
                &QTreeWidgetItem::setForeground)
      .property("icon", &QTreeWidgetItem::icon, &QTreeWidgetItem::setIcon)
      .property("statusTip", &QTreeWidgetItem::statusTip,
                &QTreeWidgetItem::setStatusTip)
      .property("text", &QTreeWidgetItem::text, &QTreeWidgetItem::setText)
      .property("textAlignment", &QTreeWidgetItem::textAlignment,
                &QTreeWidgetItem::setTextAlignment)
      .property("textColor", &QTreeWidgetItem::textColor,
                &QTreeWidgetItem::setTextColor)
      .property("toolTip", &QTreeWidgetItem::toolTip,
                &QTreeWidgetItem::setToolTip)
      .property("whatsThis", &QTreeWidgetItem::whatsThis,
                &QTreeWidgetItem::setWhatsThis)

      .property("type", &QTreeWidgetItem::type)
      //.class_<QTreeWidgetItem>::def(smp.find(sp)->first.c_str(),
      //&QTreeWidgetItem::setIcon)
      ;
}

QTreeWidget *lqtreewidget_init(QTreeWidget *widget, const object &obj) {
  lqwidget_init(widget, obj);
  lq_general_init(widget, obj, lqtreewidget_set_map);
  for (iterator i(obj), e; i != e; ++i) {
    if (type(i.key()) == LUA_TSTRING && type(*i) == LUA_TTABLE) {
      QString k = object_cast<QString>(i.key());
      if (k.compare("header", Qt::CaseInsensitive) == 0) {
        widget->setHeaderLabels(list_cast<QString>(*i));
      }
    }
  }
  return widget;
}

template <>
void table_init_general<QTreeWidget>(const luabind::argument &arg,
                                     const object &obj) {
  lqtreewidget_init(construct<QTreeWidget>(arg), obj);
}

void lqtreewidget_scrollToItem(QTreeWidget *w, QTreeWidgetItem *i, int hint) {
  w->scrollToItem(i, QAbstractItemView::ScrollHint(hint));
}

void lqtreewidget_scrollToItem2(QTreeWidget *w, QTreeWidgetItem *i) {
  w->scrollToItem(i);
}

void lqtreewidget_test(QTreeWidget *w) { (void)w; }
namespace luabind {
QT_ENUM_CONVERTER(QItemSelectionModel::SelectionFlags)
QT_ENUM_CONVERTER(Qt::SortOrder)
QT_ENUM_CONVERTER(Qt::ItemFlags)
} // namespace luabind
LQTreeWidget lqtreewidget() {
  return myclass_<QTreeWidget, QFrame>("QTreeWidget", lqtreewidget_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqtreewidget_init)
      .def("__init", table_init_general<QTreeWidget>)
      .def("addTopLevelItem", &QTreeWidget::addTopLevelItem, adopt(_2))
      .def("addTopLevelItems", &QTreeWidget::addTopLevelItems)
      .def("clear", &QTreeWidget::clear)
      .def("collapseItem", &QTreeWidget::collapseItem)
      .def("expandItem", &QTreeWidget::expandItem)
      .def("scrollToItem", lqtreewidget_scrollToItem)
      .def("scrollToItem", lqtreewidget_scrollToItem2)
      .def("selectedItems", &QTreeWidget::selectedItems)
      .def("findItems", &QTreeWidget::findItems)
      .def("findItems",
           tag_function<QList<QTreeWidgetItem *>(QTreeWidget *, const QString &,
                                                 Qt::MatchFlags)>(
               boost::bind(&QTreeWidget::findItems, _1, _2, _3, 0)))
      .def("indexOfTopLevelItem",
           (int(QTreeWidget::*)(QTreeWidgetItem *) const) &
               QTreeWidget::indexOfTopLevelItem)
      .def("insertTopLevelItem", &QTreeWidget::insertTopLevelItem, adopt(_3))
      .def("insertTopLevelItems", &QTreeWidget::insertTopLevelItems)
      .def("itemAbove", &QTreeWidget::itemAbove)
      .def("itemAt",
           (QTreeWidgetItem * (QTreeWidget::*)(const QPoint &) const) &
               QTreeWidget::itemAt)
      .def("itemAt", (QTreeWidgetItem * (QTreeWidget::*)(int, int) const) &
                         QTreeWidget::itemAt)
      .def("itemBelow", &QTreeWidget::itemBelow)
      .def("itemWidget", &QTreeWidget::itemWidget)
      .def("setItemWidget", &QTreeWidget::setItemWidget)
      .def("removeItemWidget", &QTreeWidget::removeItemWidget)
      .def("setCurrentItem", (void(QTreeWidget::*)(QTreeWidgetItem *)) &
                                 QTreeWidget::setCurrentItem)
      .def("setCurrentItem", (void(QTreeWidget::*)(QTreeWidgetItem *, int)) &
                                 QTreeWidget::setCurrentItem)
      .def("setCurrentItem",
           (void(QTreeWidget::*)(QTreeWidgetItem *, int,
                                 QItemSelectionModel::SelectionFlags)) &
               QTreeWidget::setCurrentItem)
      .def("setHeaderItem", &QTreeWidget::setHeaderItem)
      .def("setHeaderLabel", &QTreeWidget::setHeaderLabel)
      .def("setHeaderLabels", &QTreeWidget::setHeaderLabels)
      .def("sortColumn", &QTreeWidget::sortColumn)
      .def("sortItems", &QTreeWidget::sortItems)
      .def("takeTopLevelItem", &QTreeWidget::takeTopLevelItem, adopt(result))
      .def("topLevelItemCount", &QTreeWidget::topLevelItemCount)
      .def("topLevelItem", &QTreeWidget::topLevelItem)
      .def("visualItemRect", &QTreeWidget::visualItemRect)

      .property("columnCount", &QTreeWidget::columnCount,
                &QTreeWidget::setColumnCount)
      .property("currentColumn", &QTreeWidget::currentColumn)
      .property("currentItem", &QTreeWidget::currentItem)
      .property("invisibleRootItem", &QTreeWidget::invisibleRootItem)
      .sig_prop(lqtreewidget, currentItemChanged)
      .sig_prop(lqtreewidget, itemActivated)
      .sig_prop(lqtreewidget, itemChanged)
      .sig_prop(lqtreewidget, itemClicked)
      .sig_prop(lqtreewidget, itemCollapsed)
      .sig_prop(lqtreewidget, itemDoubleClicked)
      .sig_prop(lqtreewidget, itemEntered)
      .sig_prop(lqtreewidget, itemExpanded)
      .sig_prop(lqtreewidget, itemPressed)
      .sig_prop(lqtreewidget, itemSelectionChanged)
      .class_<QTreeWidget, QFrame>::property(
          "headerItem", &QTreeWidget::headerItem, &QTreeWidget::setHeaderItem)
      .property("header", &QTreeWidget::headerItem,
                &QTreeWidget::setHeaderLabels);
}

QTableWidgetItem *lqtablewidgetitem_init(QTableWidgetItem *widget,
                                         const object &obj) {
  //    for(iterator i(obj),e; i!=e; ++i){
  //        if(type(*i) == LUA_TTABLE){
  //            addItems(widget, (void(QComboBox::*)(const QString&,const
  //            QVariant&))&QComboBox::addItem, *i);
  //            //widget->addItems(table_cast<QString>(*i));
  //        }
  //    }
  return lq_general_init(widget, obj, lqtablewidgetitem_set_map);
}

template <>
void table_init_general<QTableWidgetItem>(const luabind::argument &arg,
                                          const object &obj) {
  lqtablewidgetitem_init(construct<QTableWidgetItem>(arg), obj);
}

void lqtablewidgetitem_setCheckState(QTableWidgetItem *i, int s) {
  i->setCheckState(Qt::CheckState(s));
}

void lqtablewidgetitem_setFlags(QTableWidgetItem *i, int s) {
  i->setFlags(Qt::ItemFlags(s));
}
LQTableWidgetItem lqtablewidgetitem() {
  return myclass_<QTableWidgetItem, QTableWidgetItem_wrap>(
             "QTableWidgetItem", lqtablewidgetitem_set_map)
      .def(constructor<>())
      .def(constructor<int>())
      .def(constructor<const QString &>())
      .def(constructor<const QString &, int>())
      .def(constructor<const QIcon &, const QString &>())
      .def(constructor<const QIcon &, const QString &, int>())
      .def(constructor<const QTableWidgetItem &>())

      .def("__call", lqtablewidgetitem_init)
      .def("__init", table_init_general<QTableWidgetItem>)
      //    .def("data", &QTableWidgetItem::data, &QTableWidgetItem::data)
      //    .def("setData", &QTableWidgetItem::setData,
      //    &QTableWidgetItem::setData) .def("__lt", &QTableWidgetItem::operator
      //    <)
      .def("data", &QTableWidgetItem::data, &QTableWidgetItem_wrap::def_data)
      .def("setData", &QTableWidgetItem::setData,
           &QTableWidgetItem_wrap::def_setData)
      .def("__lt", &QTableWidgetItem::operator<, &QTableWidgetItem_wrap::def_lt)

      .property("tableWidget", &QTableWidgetItem::tableWidget)
      .property("background", &QTableWidgetItem::background,
                &QTableWidgetItem::setBackground)
      .property("backgroundColor", &QTableWidgetItem::backgroundColor,
                &QTableWidgetItem::setBackgroundColor)
      .property("checkState", &QTableWidgetItem::checkState,
                lqtablewidgetitem_setCheckState)
      .property("flags", &QTableWidgetItem::flags, lqtablewidgetitem_setFlags)
      .property("font", &QTableWidgetItem::font, &QTableWidgetItem::setFont)
      .property("foreground", &QTableWidgetItem::foreground,
                &QTableWidgetItem::setForeground)
      .property("icon", &QTableWidgetItem::icon, &QTableWidgetItem::setIcon)
      .property("selected", &QTableWidgetItem::isSelected,
                &QTableWidgetItem::setSelected)
      .property("statusTip", &QTableWidgetItem::statusTip,
                &QTableWidgetItem::setStatusTip)
      .property("text", &QTableWidgetItem::text, &QTableWidgetItem::setText)
      .property("textAlignment", &QTableWidgetItem::textAlignment,
                &QTableWidgetItem::setTextAlignment)
      .property("textColor", &QTableWidgetItem::textColor,
                &QTableWidgetItem::setTextColor)
      .property("toolTip", &QTableWidgetItem::toolTip,
                &QTableWidgetItem::setToolTip)
      .property("whatsThis", &QTableWidgetItem::whatsThis,
                &QTableWidgetItem::setWhatsThis)
      .property("type", &QTableWidgetItem::type)
      .property("row", &QTableWidgetItem::row)
      .property("column", &QTableWidgetItem::column);
}

QTableWidget *lqtablewidget_init(QTableWidget *widget, const object &obj) {
  lqwidget_init(widget, obj);
  lq_general_init(widget, obj, lqtablewidget_set_map);
  for (iterator i(obj), e; i != e; ++i) {
    if (type(i.key()) == LUA_TSTRING && type(*i) == LUA_TTABLE) {
      QString k = object_cast<QString>(i.key());
      if (k.compare("vHeader", Qt::CaseInsensitive) == 0) {
        widget->setVerticalHeaderLabels(list_cast<QString>(*i));
      } else if (k.compare("verticalHeader", Qt::CaseInsensitive) == 0) {
        widget->setVerticalHeaderLabels(list_cast<QString>(*i));
      } else if (k.compare("hHeader", Qt::CaseInsensitive) == 0) {
        widget->setHorizontalHeaderLabels(list_cast<QString>(*i));
      } else if (k.compare("vorizontalHeader", Qt::CaseInsensitive) == 0) {
        widget->setHorizontalHeaderLabels(list_cast<QString>(*i));
      }
    }
  }
  return widget;
}

template <>
void table_init_general<QTableWidget>(const luabind::argument &arg,
                                      const object &obj) {
  lqtablewidget_init(construct<QTableWidget>(arg), obj);
}

LQTableWidgetSelectionRange lqtablewidgetselectionrange() {
  return class_<QTableWidgetSelectionRange>("QTableWidgetSelectionRange")
      .def(constructor<>())
      .def(constructor<int, int, int, int>())
      .def(constructor<const QTableWidgetSelectionRange &>())
      .def("topRow", &QTableWidgetSelectionRange::topRow)
      .def("bottomRow", &QTableWidgetSelectionRange::bottomRow)
      .def("leftColumn", &QTableWidgetSelectionRange::leftColumn)
      .def("rightColumn", &QTableWidgetSelectionRange::rightColumn)
      .def("columnCount", &QTableWidgetSelectionRange::columnCount)
      .def("rowCount", &QTableWidgetSelectionRange::rowCount)

      .property("top", &QTableWidgetSelectionRange::topRow)
      .property("bottom", &QTableWidgetSelectionRange::bottomRow)
      .property("left", &QTableWidgetSelectionRange::leftColumn)
      .property("right", &QTableWidgetSelectionRange::rightColumn)
      .property("column", &QTableWidgetSelectionRange::columnCount)
      .property("row", &QTableWidgetSelectionRange::rowCount);
}

void lqtablewidget_scrollToItem(QTableWidget *w, QTableWidgetItem *i,
                                int hint) {
  w->scrollToItem(i, QAbstractItemView::ScrollHint(hint));
}

void lqtablewidget_scrollToItem2(QTableWidget *w, QTableWidgetItem *i) {
  w->scrollToItem(i);
}

QStringList lqtablewidget_get_h_header(QTableWidget *w) {
  QStringList list;
  for (int i = 0; i < w->columnCount(); i++) {
    list.append(w->horizontalHeaderItem(i)->text());
  }
  return list;
}

QStringList lqtablewidget_get_v_header(QTableWidget *w) {
  QStringList list;
  for (int i = 0; i < w->rowCount(); i++) {
    list.append(w->verticalHeaderItem(i)->text());
  }
  return list;
}

LQTableWidget lqtablewidget() {
  return myclass_<QTableWidget, QFrame>("QTableWidget", lqtablewidget_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def(constructor<int, int>())
      .def(constructor<int, int, QWidget *>())
      .def("__call", lqtablewidget_init)
      .def("__init", table_init_general<QTableWidget>)

      .def("cellWidget", &QTableWidget::cellWidget)
      .def("setCellWidget", &QTableWidget::setCellWidget)
      .def("column", &QTableWidget::column)
      .def("currentItem", &QTableWidget::currentItem)
      .def("setCurrentItem", (void(QTableWidget::*)(QTableWidgetItem *)) &
                                 QTableWidget::setCurrentItem)
      .def("setCurrentItem",
           (void(QTableWidget::*)(QTableWidgetItem *,
                                  QItemSelectionModel::SelectionFlags)) &
               QTableWidget::setCurrentItem)

      .def("currentRow", &QTableWidget::currentRow)
      .def("findItems", &QTableWidget::findItems)
      .def("selectedItems", &QTableWidget::selectedItems)
      .def("selectedRanges", &QTableWidget::selectedRanges)

      .def("horizontalHeaderItem", &QTableWidget::horizontalHeaderItem)
      .def("setHorizontalHeaderItem", &QTableWidget::setHorizontalHeaderItem,
           adopt(_3))
      .def("setHorizontalHeaderLabels",
           &QTableWidget::setHorizontalHeaderLabels)
      .def("takeHorizontalHeaderItem", &QTableWidget::takeHorizontalHeaderItem,
           adopt(result))

      .def("verticalHeaderItem", &QTableWidget::verticalHeaderItem)
      .def("setVerticalHeaderItem", &QTableWidget::setVerticalHeaderItem,
           adopt(_3))
      .def("setVerticalHeaderLabels", &QTableWidget::setVerticalHeaderLabels)
      .def("takeVerticalHeaderItem", &QTableWidget::takeVerticalHeaderItem,
           adopt(result))

      .def("item", &QTableWidget::item)
      .def("itemAt", (QTableWidgetItem * (QTableWidget::*)(int, int) const) &
                         QTableWidget::itemAt)
      .def("itemAt",
           (QTableWidgetItem * (QTableWidget::*)(const QPoint &) const) &
               QTableWidget::itemAt)

      .def("removeCellWidget", &QTableWidget::removeCellWidget)
      .def("setCellWidget", &QTableWidget::setCellWidget)
      .def("row", &QTableWidget::row)
      .def("setCurrentCell",
           (void(QTableWidget::*)(int, int,
                                  QItemSelectionModel::SelectionFlags)) &
               QTableWidget::setCurrentCell)
      .def("setCurrentCell",
           (void(QTableWidget::*)(int, int)) & QTableWidget::setCurrentCell)
      .def("setCurrentItem",
           (void(QTableWidget::*)(QTableWidgetItem *,
                                  QItemSelectionModel::SelectionFlags)) &
               QTableWidget::setCurrentItem)
      .def("setCurrentItem", (void(QTableWidget::*)(QTableWidgetItem *)) &
                                 QTableWidget::setCurrentItem)

      .def("setItem", &QTableWidget::setItem, adopt(_4))
      .def("takeItem", &QTableWidget::takeItem, adopt(result))
      .def("setRangeSelected", &QTableWidget::setRangeSelected)
      .def("visualColumn", &QTableWidget::visualColumn)
      .def("visualRow", &QTableWidget::visualRow)
      .def("visualRect", &QTableWidget::visualRect)

      .def("clear", &QTableWidget::clear)
      .def("clearContents", &QTableWidget::clearContents)
      .def("insertColumn", &QTableWidget::insertColumn)
      .def("insertRow", &QTableWidget::insertRow)
      .def("removeColumn", &QTableWidget::removeColumn)
      .def("removeRow", &QTableWidget::removeRow)
      .def("scrollToItem", lqtablewidget_scrollToItem)
      .def("scrollToItem", lqtablewidget_scrollToItem2)

      .property("columnCount", &QTableWidget::columnCount,
                &QTableWidget::setColumnCount)
      .property("rowCount", &QTableWidget::rowCount, &QTableWidget::setRowCount)
      .property("currentColumn", &QTableWidget::currentColumn)

      .property("currentRow", &QTableWidget::currentRow)

      .sig_prop(lqtablewidget, cellActivated)
      .sig_prop(lqtablewidget, cellChanged)
      .sig_prop(lqtablewidget, cellClicked)
      .sig_prop(lqtablewidget, cellDoubleClicked)
      .sig_prop(lqtablewidget, cellEntered)
      .sig_prop(lqtablewidget, cellPressed)
      .sig_prop(lqtablewidget, currentCellChanged)
      .sig_prop(lqtablewidget, currentItemChanged)
      .sig_prop(lqtablewidget, currentRowChanged)
      .sig_prop(lqtablewidget, currentTextChanged)
      .sig_prop(lqtablewidget, itemActivated)
      .sig_prop(lqtablewidget, itemChanged)
      .sig_prop(lqtablewidget, itemClicked)
      .sig_prop(lqtablewidget, itemDoubleClicked)
      .sig_prop(lqtablewidget, itemEntered)
      .sig_prop(lqtablewidget, itemPressed)
      .sig_prop(lqtablewidget, itemSelectionChanged)

      .class_<QTableWidget, QFrame>::property("itemPrototype",
                                              &QTableWidget::itemPrototype,
                                              &QTableWidget::setItemPrototype)
      .property("horizontalHeader", lqtablewidget_get_h_header,
                &QTableWidget::setHorizontalHeaderLabels)
      .property("verticalHeader", lqtablewidget_get_v_header,
                &QTableWidget::setVerticalHeaderLabels)
      .property("hHeader", lqtablewidget_get_h_header,
                &QTableWidget::setHorizontalHeaderLabels)
      .property("vHeader", lqtablewidget_get_v_header,
                &QTableWidget::setVerticalHeaderLabels);
}
