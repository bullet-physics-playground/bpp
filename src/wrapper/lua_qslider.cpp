#include "lua_qslider.h"

#include "lua_qslot.h"

static setter_map<QAbstractSlider> lqas_set_map;

QAbstractSlider *lqas_init(QAbstractSlider *widget, const object &table) {
  lqwidget_init(widget, table);
  lq_general_init(widget, table, lqas_set_map);
  return widget;
}

template <>
void table_init_general<QAbstractSlider>(const luabind::argument &arg,
                                         const object &obj) {
  lqas_init(construct<QAbstractSlider>(arg), obj);
}
namespace luabind {
QT_ENUM_CONVERTER(QAbstractSlider::SliderAction)
}

ENUM_FILTER(QAbstractSlider, orientation, setOrientation)
SIGNAL_PROPERYT(lqabstractslider, actionTriggered, QAbstractSlider, "(int)")
SIGNAL_PROPERYT(lqabstractslider, rangeChanged, QAbstractSlider, "(int,int)")
SIGNAL_PROPERYT(lqabstractslider, sliderMoved, QAbstractSlider, "(int)")
SIGNAL_PROPERYT(lqabstractslider, sliderPressed, QAbstractSlider, "()")
SIGNAL_PROPERYT(lqabstractslider, sliderReleased, QAbstractSlider, "()")
SIGNAL_PROPERYT(lqabstractslider, valueChanged, QAbstractSlider, "(int)")

LQAbstractSlider lqabstractslider() {
  return myclass_<QAbstractSlider, QWidget>("QAbstractSlider", lqas_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqas_init)
      .def("__init", table_init_general<QAbstractSlider>)

      .def("triggerAction", &QAbstractSlider::triggerAction)
      .def("setValue", &QAbstractSlider::setValue)
      .def("setOrientation", &QAbstractSlider::setOrientation)
      .def("setMaximum", &QAbstractSlider::setMaximum)
      .def("setMax", &QAbstractSlider::setMaximum)
      .def("setMinimum", &QAbstractSlider::setMinimum)
      .def("setMin", &QAbstractSlider::setMinimum)
      .def("setRange", &QAbstractSlider::setRange)

      .property("invertedAppearance", &QAbstractSlider::invertedAppearance,
                &QAbstractSlider::setInvertedAppearance)
      .property("invertedControls", &QAbstractSlider::invertedControls,
                &QAbstractSlider::setInvertedControls)
      .property("maximum", &QAbstractSlider::maximum,
                &QAbstractSlider::setMaximum)
      .property("minimum", &QAbstractSlider::minimum,
                &QAbstractSlider::setMinimum)
      .property("max", &QAbstractSlider::maximum, &QAbstractSlider::setMaximum)
      .property("min", &QAbstractSlider::minimum, &QAbstractSlider::setMinimum)
      .property("orientation", QAbstractSlider_orientation,
                QAbstractSlider_setOrientation)
      .property("pageStep", &QAbstractSlider::pageStep,
                &QAbstractSlider::setPageStep)
      .property("singleStep", &QAbstractSlider::singleStep,
                &QAbstractSlider::setSingleStep)
      .property("sliderPosition", &QAbstractSlider::sliderPosition,
                &QAbstractSlider::setSliderPosition)
      .property("sliderDown", &QAbstractSlider::isSliderDown,
                &QAbstractSlider::setSliderDown)
      .property("tracking", &QAbstractSlider::hasTracking,
                &QAbstractSlider::setTracking)
      .property("value", &QAbstractSlider::value, &QAbstractSlider::setValue)
      .sig_prop(lqabstractslider, actionTriggered)
      .sig_prop(lqabstractslider, rangeChanged)
      .sig_prop(lqabstractslider, sliderMoved)
      .sig_prop(lqabstractslider, sliderPressed)
      .sig_prop(lqabstractslider, sliderReleased)
      .sig_prop(lqabstractslider, valueChanged);
}

static setter_map<QSlider> lqslider_set_map;
QSlider *lqslider_init(QSlider *widget, const object &table) {
  lqas_init(widget, table);
  lq_general_init(widget, table, lqslider_set_map);
  return widget;
}
template <>
void table_init_general<QSlider>(const luabind::argument &arg,
                                 const object &obj) {
  lqslider_init(construct<QSlider>(arg), obj);
}

ENUM_FILTER(QSlider, tickPosition, setTickPosition)
LQSlider lqslider() {
  return myclass_<QSlider, QAbstractSlider>("QSlider")
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def(constructor<Qt::Orientation, QWidget *>())
      .def(constructor<Qt::Orientation>())
      .def("__call", lqslider_init)
      .def("__init", table_init_general<QSlider>)

      .property("tickInterval", &QSlider::tickInterval,
                &QSlider::setTickInterval)
      .property("tickPosition", QSlider_tickPosition, QSlider_setTickPosition);
}

static setter_map<QScrollBar> lqscroll_set_map;
QScrollBar *lqscroll_init(QScrollBar *widget, const object &table) {
  lqas_init(widget, table);
  lq_general_init(widget, table, lqscroll_set_map);
  return widget;
}
template <>
void table_init_general<QScrollBar>(const luabind::argument &arg,
                                    const object &obj) {
  lqscroll_init(construct<QScrollBar>(arg), obj);
}
LQScrollBar lqscrollbar() {
  return myclass_<QScrollBar, QAbstractSlider>("QScrollBar", lqscroll_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def(constructor<Qt::Orientation, QWidget *>())
      .def(constructor<Qt::Orientation>())
      .def("__call", lqscroll_init)
      .def("__init", table_init_general<QScrollBar>);
}

static setter_map<QDial> lqdial_set_map;
QDial *lqdial_init(QDial *widget, const object &table) {
  lqas_init(widget, table);
  lq_general_init(widget, table, lqdial_set_map);
  return widget;
}
template <>
void table_init_general<QDial>(const luabind::argument &arg,
                               const object &obj) {
  lqdial_init(construct<QDial>(arg), obj);
}
LQDial lqdial() {
  return myclass_<QDial, QAbstractSlider>("QDial", lqdial_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqdial_init)
      .def("__init", table_init_general<QDial>)
      .def("setNotchesVisible", &QDial::setNotchesVisible)
      .def("setWrapping", &QDial::setWrapping)

      .property("notchSize", &QDial::notchSize)
      .property("notchTarget", &QDial::notchTarget, &QDial::setNotchTarget)
      .property("notchesVisible", &QDial::notchesVisible,
                &QDial::setNotchesVisible)
      .property("wrapping", &QDial::wrapping, &QDial::setWrapping);
}

static setter_map<QProgressBar> lqprogressbar_set_map;
QProgressBar *lqprogressbar_init(QProgressBar *widget, const object &table) {
  lqwidget_init(widget, table);
  lq_general_init(widget, table, lqprogressbar_set_map);
  return widget;
}
template <>
void table_init_general<QProgressBar>(const luabind::argument &arg,
                                      const object &obj) {
  lqprogressbar_init(construct<QProgressBar>(arg), obj);
}

ENUM_FILTER(QProgressBar, alignment, setAlignment)
ENUM_FILTER(QProgressBar, orientation, setOrientation)
// ENUM_FILTER(QProgressBar, textDirection, setTextDirection)
int QProgressBar_textDirection(QProgressBar *w) { return w->textDirection(); }
void QProgressBar_setTextDirection(QProgressBar *w, int f) {
  return w->setTextDirection(QProgressBar::Direction(f));
}

SIGNAL_PROPERYT(lqprogressbar, valueChanged, QProgressBar, "(int)")
LQProgressBar lqprogressbar() {
  return myclass_<QProgressBar, QWidget>("QProgressBar", lqprogressbar_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def("__call", lqprogressbar_init)
      .def("__init", table_init_general<QProgressBar>)

      .def("reset", &QProgressBar::reset)
      .def("setMaximum", &QProgressBar::setMaximum)
      .def("setMax", &QProgressBar::setMaximum)
      .def("setMinimum", &QProgressBar::setMinimum)
      .def("setMin", &QProgressBar::setMinimum)
      .def("setOrientation", &QProgressBar::setOrientation)
      .def("setRange", &QProgressBar::setRange)
      .def("setValue", &QProgressBar::setValue)

      .property("alignment", QProgressBar_alignment, QProgressBar_setAlignment)
      .property("format", &QProgressBar::format, &QProgressBar::setFormat)
      .property("invertedAppearance",
                (bool(QProgressBar::*)() const) &
                    QProgressBar::invertedAppearance,
                &QProgressBar::setInvertedAppearance)
      .property("maximum", &QProgressBar::maximum, &QProgressBar::setMaximum)
      .property("max", &QProgressBar::maximum, &QProgressBar::setMaximum)
      .property("minimum", &QProgressBar::minimum, &QProgressBar::setMinimum)
      .property("min", &QProgressBar::minimum, &QProgressBar::setMinimum)
      .property("orientation", QProgressBar_orientation,
                QProgressBar_setOrientation)
      .property("text", &QProgressBar::text)
      .property("textDirection", QProgressBar_textDirection,
                QProgressBar_setTextDirection)
      .property("textVisible", &QProgressBar::isTextVisible,
                &QProgressBar::setTextVisible)
      .property("value", &QProgressBar::value, &QProgressBar::setValue)
      .sig_prop(lqprogressbar, valueChanged);
}

QDialog *lqdialog_init(QDialog *widget, const object &obj);
static setter_map<QProgressDialog> lqprogressdlg_set_map;
QProgressDialog *lqprogressdialog_init(QProgressDialog *widget,
                                       const object &table) {
  lqdialog_init(widget, table);
  lq_general_init(widget, table, lqprogressdlg_set_map);
  return widget;
}
template <>
void table_init_general<QProgressDialog>(const luabind::argument &arg,
                                         const object &obj) {
  lqprogressdialog_init(construct<QProgressDialog>(arg), obj);
}

SIGNAL_PROPERYT(lqprogressdialog, canceled, QProgressDialog, "()")

LQProgressDialog lqprogressdialog() {
  return myclass_<QProgressDialog, QDialog>("QProgressDialog",
                                            lqprogressdlg_set_map)
      .def(constructor<>())
      .def(constructor<QWidget *>())
      .def(constructor<QWidget *, Qt::WindowFlags>())
      .def(constructor<const QString &, const QString &, int, int, QWidget *,
                       Qt::WindowFlags>())
      .def(constructor<const QString &, const QString &, int, int, QWidget *>())
      .def(constructor<const QString &, const QString &, int, int>())
      .def("__call", lqprogressdialog_init)
      .def("__init", table_init_general<QProgressDialog>)

      .property("autoClose", &QProgressDialog::autoClose,
                &QProgressDialog::setAutoClose)
      .property("autoReset", &QProgressDialog::autoReset,
                &QProgressDialog::setAutoReset)
      .property("labelText", &QProgressDialog::labelText,
                &QProgressDialog::setLabelText)
      .property("maximum", &QProgressDialog::maximum,
                &QProgressDialog::setMaximum)
      .property("max", &QProgressDialog::maximum, &QProgressDialog::setMaximum)
      .property("minimum", &QProgressDialog::minimum,
                &QProgressDialog::setMinimum)
      .property("min", &QProgressDialog::minimum, &QProgressDialog::setMinimum)
      .property("minimumDuration", &QProgressDialog::minimumDuration,
                &QProgressDialog::setMinimumDuration)
      .property("minDuration", &QProgressDialog::minimumDuration,
                &QProgressDialog::setMinimumDuration)
      .property("value", &QProgressDialog::value, &QProgressDialog::setValue)
      .property("wasCanceled", &QProgressDialog::wasCanceled)
      .sig_prop(lqprogressdialog, canceled);
}
