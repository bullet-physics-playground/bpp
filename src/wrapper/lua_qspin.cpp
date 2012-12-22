#include "lua_qspin.h"

#include "lua_qslot.h"

#include <luabind/operator.hpp>
#include <luabind/tag_function.hpp>

static setter_map<QAbstractSpinBox> lqabstractspinbox_set_map;

QAbstractSpinBox* lqabstractspinbox_init(QAbstractSpinBox* widget, const object& obj)
{
    lqwidget_init(widget, obj);
    return lq_general_init(widget, obj, lqabstractspinbox_set_map);
}
template<>
void table_init_general<QAbstractSpinBox>(const luabind::argument & arg, const object& obj)
{
    lqabstractspinbox_init(construct<QAbstractSpinBox>(arg), obj);
}

ENUM_FILTER(QAbstractSpinBox,alignment,setAlignment)
ENUM_FILTER(QAbstractSpinBox,buttonSymbols,setButtonSymbols)
ENUM_FILTER(QAbstractSpinBox,correctionMode,setCorrectionMode)
SIGNAL_PROPERYT(lqabstractspinbox, editingFinished , QAbstractSpinBox,"()")
LQAbstractSpinBox lqabstractspinbox()
{
    return
    myclass_<QAbstractSpinBox, QWidget>("QAbstractSpinBox",lqabstractspinbox_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def("__init", table_init_general<QAbstractSpinBox>)
    .def("__call", lqabstractspinbox_init)
    .def("setSpecialValueText", &QAbstractSpinBox::setSpecialValueText)
    .def("clear", &QAbstractSpinBox::clear)
    .def("selectAll", &QAbstractSpinBox::selectAll)
    .def("stepUp", &QAbstractSpinBox::stepUp)
    .def("stepDown", &QAbstractSpinBox::stepDown)
    .def("stepBy", &QAbstractSpinBox::stepBy)

    .property("alignment", QAbstractSpinBox_alignment, QAbstractSpinBox_setAlignment)
    .property("buttonSymbols", QAbstractSpinBox_buttonSymbols, QAbstractSpinBox_setButtonSymbols)
    .property("correctionMode", QAbstractSpinBox_correctionMode, QAbstractSpinBox_setCorrectionMode)
    .property("frame", &QAbstractSpinBox::hasFrame, &QAbstractSpinBox::setFrame)
    .property("readOnly", &QAbstractSpinBox::isReadOnly, &QAbstractSpinBox::setReadOnly)
    .property("accelerated", &QAbstractSpinBox::isAccelerated, &QAbstractSpinBox::setAccelerated)
    .property("keyboardTracking", &QAbstractSpinBox::keyboardTracking, &QAbstractSpinBox::setKeyboardTracking)
    .property("wrapping", &QAbstractSpinBox::wrapping, &QAbstractSpinBox::setWrapping)
    .property("text", &QAbstractSpinBox::text)
    .sig_prop(lqabstractspinbox, editingFinished)
    ;
}

static setter_map<QSpinBox> lqspinbox_set_map;
QSpinBox* lqspinbox_init(QSpinBox* widget, const object& obj)
{
    lqabstractspinbox_init(widget, obj);
    return lq_general_init(widget, obj, lqspinbox_set_map);
}
template<>
void table_init_general<QSpinBox>(const luabind::argument & arg, const object& obj)
{
    lqspinbox_init(construct<QSpinBox>(arg), obj);
}
SIGNAL_PROPERYT(lqspinbox, valueChanged , QSpinBox,"(int)")
LQSpinBox lqspinbox()
{
    return
    myclass_<QSpinBox, QAbstractSpinBox>("QSpinBox",lqspinbox_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def("__init", table_init_general<QSpinBox>)
    .def("__call", lqspinbox_init)
    .def("setRange", &QSpinBox::setRange)
    .def("setValue", &QSpinBox::setValue)

    .property("cleanText", &QSpinBox::cleanText)
    .property("maximum", &QSpinBox::maximum, &QSpinBox::setMaximum)
    .property("minimum", &QSpinBox::minimum, &QSpinBox::setMinimum)
    .property("max", &QSpinBox::maximum, &QSpinBox::setMaximum)
    .property("min", &QSpinBox::minimum, &QSpinBox::setMinimum)
    .property("prefix", &QSpinBox::prefix, &QSpinBox::setPrefix)
    .property("singleStep", &QSpinBox::singleStep, &QSpinBox::setSingleStep)
    .property("suffix", &QSpinBox::suffix, &QSpinBox::setSuffix)
    .property("value", &QSpinBox::value, &QSpinBox::setValue)
    .sig_prop(lqspinbox, valueChanged)
    ;
}


static setter_map<QDoubleSpinBox> lqdoublespinbox_set_map;
QDoubleSpinBox* lqdoublespinbox_init(QDoubleSpinBox* widget, const object& obj)
{
    lqabstractspinbox_init(widget, obj);
    return lq_general_init(widget, obj, lqdoublespinbox_set_map);
}
template<>
void table_init_general<QDoubleSpinBox>(const luabind::argument & arg, const object& obj)
{
    lqdoublespinbox_init(construct<QDoubleSpinBox>(arg), obj);
}
SIGNAL_PROPERYT(lqdoublespinbox, valueChanged , QDoubleSpinBox,"(double)")
LQDoubleSpinBox lqdoublespinbox()
{
    return
    myclass_<QDoubleSpinBox, QAbstractSpinBox>("QDoubleSpinBox",lqdoublespinbox_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def("__init", table_init_general<QDoubleSpinBox>)
    .def("__call", lqdoublespinbox_init)
    .def("setRange", &QDoubleSpinBox::setRange)
    .def("setValue", &QDoubleSpinBox::setValue)

    .property("cleanText", &QDoubleSpinBox::cleanText)
    .property("decimals", &QDoubleSpinBox::decimals, &QDoubleSpinBox::setDecimals)
    .property("maximum", &QDoubleSpinBox::maximum, &QDoubleSpinBox::setMaximum)
    .property("minimum", &QDoubleSpinBox::minimum, &QDoubleSpinBox::setMinimum)
    .property("max", &QDoubleSpinBox::maximum, &QDoubleSpinBox::setMaximum)
    .property("min", &QDoubleSpinBox::minimum, &QDoubleSpinBox::setMinimum)
    .property("prefix", &QDoubleSpinBox::prefix, &QDoubleSpinBox::setPrefix)
    .property("singleStep", &QDoubleSpinBox::singleStep, &QDoubleSpinBox::setSingleStep)
    .property("suffix", &QDoubleSpinBox::suffix, &QDoubleSpinBox::setSuffix)
    .property("value", &QDoubleSpinBox::value, &QDoubleSpinBox::setValue)
    .sig_prop(lqdoublespinbox, valueChanged)
    ;
}

namespace luabind{
QT_EMUN_CONVERTER(Qt::DateFormat)
QT_EMUN_CONVERTER(Qt::TimeSpec)
}
LQDate lqdate()
{
    (void)self;
    return
    class_<QDate>("QDate")
    .def(constructor<>())
    .def(constructor<int,int,int>())
    .def(const_self == const_self)
    .def(const_self < const_self)
    .def(const_self <= const_self)
    .def("addDays", &QDate::addDays)
    .def("addMonths", &QDate::addMonths)
    .def("addYears", &QDate::addYears)
    .property("day", &QDate::day)
    .property("month", &QDate::month)
    .property("year", &QDate::year)
    .property("isNull", &QDate::isNull)
    .def("isValid", (bool(QDate::*)()const)&QDate::isValid)
    .def("dayOfWeek", &QDate::dayOfWeek)
    .def("dayOfYear", &QDate::dayOfYear)
    .def("daysInMonth", &QDate::daysInMonth)
    .def("daysInYear", &QDate::daysInYear)
    .def("daysTo", &QDate::daysTo)
    .def("setDate", &QDate::setDate)
    .def("toJulianDay", &QDate::toJulianDay)
    .def("toString", (QString (QDate::*)(const QString &) const)&QDate::toString)
    .def("toString", (QString (QDate::*)(Qt::DateFormat) const)&QDate::toString)
    .def("toString", tag_function<QString(QDate*)>(boost::bind((QString (QDate::*)(Qt::DateFormat) const)&QDate::toString, _1, Qt::TextDate)))
    .def("__tostring", tag_function<QString(QDate*)>(boost::bind((QString (QDate::*)(Qt::DateFormat) const)&QDate::toString, _1, Qt::TextDate)))
    .scope[
        def("currentDate", &QDate::currentDate),
        def("isLeapYear", &QDate::isLeapYear),
        def("isValid", (bool(*)(int,int,int))&QDate::isValid),
        def("fromJulianDay", &QDate::fromJulianDay),
        def("fromString", (QDate(*)(const QString&,const QString&))&QDate::fromString),
        def("fromString", (QDate(*)(const QString&,Qt::DateFormat))&QDate::fromString),
        def("fromString", tag_function<QDate(const QString&)>(boost::bind((QDate(*)(const QString&,Qt::DateFormat))&QDate::fromString, _1, Qt::TextDate))),
        def("longDayName", (QString(*)(int))&QDate::longDayName),
        def("shortDayName", (QString(*)(int))&QDate::shortDayName),
        def("longMonthName", (QString(*)(int))&QDate::longMonthName),
        def("shortMonthName", (QString(*)(int))&QDate::shortMonthName)
    ]
    ;
}

LQTime lqtime()
{
    return
    class_<QTime>("QTime")
    .def(constructor<>())
    .def(constructor<int,int>())
    .def(constructor<int,int,int>())
    .def(constructor<int,int,int,int>())
    .def(const_self == const_self)
    .def(const_self < const_self)
    .def(const_self <= const_self)
    .def("addMSecs", &QTime::addMSecs)
    .def("addSecs", &QTime::addSecs)
    .property("elapsed", &QTime::elapsed)
    .property("hour", &QTime::hour)
    .property("minute", &QTime::minute)
    .property("second", &QTime::second)
    .property("msec", &QTime::msec)
    .property("isNull", &QTime::isNull)
    .def("isValid", (bool(QTime::*)()const)&QTime::isValid)
    .def("secsTo", &QTime::secsTo)
    .def("msecsTo", &QTime::msecsTo)
    .def("start", &QTime::start)
    .def("restart", &QTime::restart)
    .def("setHMS", &QTime::setHMS)
    .def("setHMS", tag_function<void(QTime*,int,int,int)>(boost::bind(&QTime::setHMS, _1,_2,_3,_4,0)))
    .def("toString", (QString(QTime::*)(const QString&)const)&QTime::toString)
    .def("toString", (QString(QTime::*)(Qt::DateFormat)const)&QTime::toString)
    .def("toString", tag_function<QString(QTime*)>(boost::bind((QString (QTime::*)(Qt::DateFormat) const)&QTime::toString, _1, Qt::TextDate)))
    .def("__tostring", tag_function<QString(QTime*)>(boost::bind((QString (QTime::*)(Qt::DateFormat) const)&QTime::toString, _1, Qt::TextDate)))
    .scope[
        def("currentTime", &QTime::currentTime),
        def("isValid", (bool(*)(int,int,int,int))&QTime::isValid),
        def("isValid", tag_function<bool(int,int,int)>(boost::bind((bool(*)(int,int,int,int))&QTime::isValid, _1,_2,_3,0))),
        def("currentTime", (QTime(*)(const QString&,const QString&))&QTime::fromString),
        def("currentTime", (QTime(*)(const QString&,Qt::DateFormat))&QTime::fromString),
        def("currentTime", tag_function<QTime(const QString&)>(boost::bind((QTime(*)(const QString&,Qt::DateFormat))&QTime::fromString, _1,Qt::TextDate))),
        def("fromString", (QTime(*)(const QString&,const QString&))&QTime::fromString),
        def("fromString", (QTime(*)(const QString&,Qt::DateFormat))&QTime::fromString),
        def("fromString", tag_function<QTime(const QString&)>(boost::bind((QTime(*)(const QString&,Qt::DateFormat))&QTime::fromString, _1, Qt::TextDate)))
    ]
    ;
}

LQDateTime lqdatetime()
{
    return
    class_<QDateTime>("QDateTime")
    .def(constructor<>())
    .def(constructor<const QDate &>())
    .def(constructor<const QDate &,const QTime&>())
    .def(constructor<const QDate &,const QTime&, Qt::TimeSpec>())
    .def(constructor<const QDateTime &>())
    .def(const_self == const_self)
    .def(const_self < const_self)
    .def(const_self <= const_self)
    .def("addMSecs", &QDateTime::addMSecs)
    .def("addSecs", &QDateTime::addSecs)
    .def("addDays", &QDateTime::addDays)
    .def("addMonths", &QDateTime::addMonths)
    .def("addYears", &QDateTime::addYears)
    .def("daysTo", &QDateTime::daysTo)
    .def("secsTo", &QDateTime::secsTo)
    .def("setTimeSpec", &QDateTime::setTimeSpec)
    .def("setTime_t", &QDateTime::setTime_t)
    .def("toTime_t", &QDateTime::toTime_t)
    .def("toLocalTime", &QDateTime::toLocalTime)
    .def("toTimeSpec", &QDateTime::toTimeSpec)
    .def("toUTC", &QDateTime::toUTC)
    .def("toString", ( QString (QDateTime::*)(const QString&) const)&QDateTime::toString)
    .def("toString", ( QString (QDateTime::*)(Qt::DateFormat) const)&QDateTime::toString)
    .def("toString", tag_function<QString(QDateTime*)>(boost::bind(( QString (QDateTime::*)(Qt::DateFormat) const)&QDateTime::toString, _1,Qt::TextDate)))
    .def("__tostring", tag_function<QString(QDateTime*)>(boost::bind(( QString (QDateTime::*)(Qt::DateFormat) const)&QDateTime::toString, _1,Qt::TextDate)))
    .property("isNull", &QDateTime::isNull)
    .property("isValid", &QDateTime::isValid)
    .property("date", &QDateTime::date, &QDateTime::setDate)
    .property("time", &QDateTime::time, &QDateTime::setTime)
    .property("timeSpec", &QDateTime::timeSpec, &QDateTime::setTimeSpec)
    .scope[
        def("currentDateTime", &QDateTime::currentDateTime),
        def("fromTime_t", &QDateTime::fromTime_t),
        def("fromString", (QDateTime(*)(const QString&,const QString&))&QDateTime::fromString),
        def("fromString", (QDateTime(*)(const QString&,Qt::DateFormat))&QDateTime::fromString),
        def("fromString", tag_function<QDateTime(const QString&)>(boost::bind((QDateTime(*)(const QString&,Qt::DateFormat))&QDateTime::fromString, _1,Qt::TextDate)))
    ]
    ;
}


static setter_map<QDateTimeEdit> lqdatetimeedit_set_map;
QDateTimeEdit* lqdatetimeedit_init(QDateTimeEdit* widget, const object& obj)
{
    lqabstractspinbox_init(widget, obj);
    return lq_general_init(widget, obj, lqdatetimeedit_set_map);
}
template<>
void table_init_general<QDateTimeEdit>(const luabind::argument & arg, const object& obj)
{
    lqdatetimeedit_init(construct<QDateTimeEdit>(arg), obj);
}

ENUM_FILTER(QDateTimeEdit,currentSection,setCurrentSection)
ENUM_FILTER(QDateTimeEdit,timeSpec,setTimeSpec)
SIGNAL_PROPERYT(lqdatetimeedit, dateChanged , QDateTimeEdit,"(const QDate&)")
SIGNAL_PROPERYT(lqdatetimeedit, dateTimeChanged , QDateTimeEdit,"(const QDateTime&)")
SIGNAL_PROPERYT(lqdatetimeedit, timeChanged , QDateTimeEdit,"(const QTime&)")
LQDateTimeEdit lqdatetimeedit()
{
    return
    myclass_<QDateTimeEdit, QAbstractSpinBox>("QDateTimeEdit",lqdatetimeedit_set_map)
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<const QDateTime&>())
    .def(constructor<const QDateTime&, QWidget*>())
    .def(constructor<const QDate&>())
    .def(constructor<const QDate&, QWidget*>())
    .def(constructor<const QTime&>())
    .def(constructor<const QTime&, QWidget*>())
    .def("__init", table_init_general<QDateTimeEdit>)
    .def("__call", lqdatetimeedit_init)
    .def("sectionAt", &QDateTimeEdit::sectionAt)
    .def("sectionText", &QDateTimeEdit::sectionText)
    .def("setDateRange", &QDateTimeEdit::setDateRange)
    .def("setTimeRange", &QDateTimeEdit::setTimeRange)
    .def("setDateTimeRange", &QDateTimeEdit::setDateTimeRange)

    .property("calendarPopup", &QDateTimeEdit::calendarPopup, &QDateTimeEdit::setCalendarPopup)
    .property("currentSection", QDateTimeEdit_currentSection, QDateTimeEdit_setCurrentSection)
    .property("currentSectionIndex", &QDateTimeEdit::currentSectionIndex, &QDateTimeEdit::setCurrentSectionIndex)

    .property("displayFormat", &QDateTimeEdit::displayFormat, &QDateTimeEdit::setDisplayFormat)
    .property("timeSpec", QDateTimeEdit_timeSpec, QDateTimeEdit_setTimeSpec)
    .sig_prop(lqdatetimeedit, dateChanged)
    .sig_prop(lqdatetimeedit, dateTimeChanged)
    .sig_prop(lqdatetimeedit, timeChanged)

    .class_<QDateTimeEdit, QAbstractSpinBox>::property("displayedSections", &QDateTimeEdit::displayedSections)
    .property("sectionCount", &QDateTimeEdit::sectionCount)
    .property("date", &QDateTimeEdit::date, &QDateTimeEdit::setDate)
    .property("maximumDate", &QDateTimeEdit::maximumDate, &QDateTimeEdit::setMaximumDate)
    .property("minimumDate", &QDateTimeEdit::minimumDate, &QDateTimeEdit::setMinimumDate)
    .def("clearMaximumDate", &QDateTimeEdit::clearMaximumDate)
    .def("clearMinimumDate", &QDateTimeEdit::clearMinimumDate)
    .property("maxDate", &QDateTimeEdit::maximumDate, &QDateTimeEdit::setMaximumDate)
    .property("minDate", &QDateTimeEdit::minimumDate, &QDateTimeEdit::setMinimumDate)
    .def("clearMaxDate", &QDateTimeEdit::clearMaximumDate)
    .def("clearMinDate", &QDateTimeEdit::clearMinimumDate)

    .property("time", &QDateTimeEdit::time, &QDateTimeEdit::setTime)
    .property("maximumTime", &QDateTimeEdit::maximumTime, &QDateTimeEdit::setMaximumTime)
    .property("minimumTime", &QDateTimeEdit::minimumTime, &QDateTimeEdit::setMinimumTime)
    .def("clearMaximumTime", &QDateTimeEdit::clearMaximumTime)
    .def("clearMinimumTime", &QDateTimeEdit::clearMinimumTime)
    .property("maxTime", &QDateTimeEdit::maximumTime, &QDateTimeEdit::setMaximumTime)
    .property("minTime", &QDateTimeEdit::minimumTime, &QDateTimeEdit::setMinimumTime)
    .def("clearMaxTime", &QDateTimeEdit::clearMaximumTime)
    .def("clearMinTime", &QDateTimeEdit::clearMinimumTime)

    .property("dateTime", &QDateTimeEdit::dateTime, &QDateTimeEdit::setDateTime)
    .property("maximumDateTime", &QDateTimeEdit::maximumDateTime, &QDateTimeEdit::setMaximumDateTime)
    .property("minimumDateTime", &QDateTimeEdit::minimumDateTime, &QDateTimeEdit::setMinimumDateTime)
    .def("clearMaximumDateTime", &QDateTimeEdit::clearMaximumDateTime)
    .def("clearMinimumDateTime", &QDateTimeEdit::clearMinimumDateTime)
    .property("maxDateTime", &QDateTimeEdit::maximumDateTime, &QDateTimeEdit::setMaximumDateTime)
    .property("minDateTime", &QDateTimeEdit::minimumDateTime, &QDateTimeEdit::setMinimumDateTime)
    .def("clearMaxDateTime", &QDateTimeEdit::clearMaximumDateTime)
    .def("clearMinDateTime", &QDateTimeEdit::clearMinimumDateTime)
    ;
}

QDateEdit* lqdateedit_init(QDateEdit* widget, const object& obj)
{
    lqdatetimeedit_init(widget, obj);
    return widget;
}
template<>
void table_init_general<QDateEdit>(const luabind::argument & arg, const object& obj)
{
    lqdatetimeedit_init(construct<QDateEdit>(arg), obj);
}

QTimeEdit* lqtimeedit_init(QTimeEdit* widget, const object& obj)
{
    lqdatetimeedit_init(widget, obj);
    return widget;
}
template<>
void table_init_general<QTimeEdit>(const luabind::argument & arg, const object& obj)
{
    lqdatetimeedit_init(construct<QTimeEdit>(arg), obj);
}

LQDateEdit lqdateedit()
{
    return
    class_<QDateEdit,QDateTimeEdit>("QDateEdit")
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<const QDate&>())
    .def(constructor<const QDate&, QWidget*>())
    .def("__init", table_init_general<QDateEdit>)
    .def("__call", lqdateedit_init)
    ;
}

LQTimeEdit lqtimeedit()
{
    return
    class_<QTimeEdit,QDateTimeEdit>("QTimeEdit")
    .def(constructor<>())
    .def(constructor<QWidget*>())
    .def(constructor<const QTime&>())
    .def(constructor<const QTime&, QWidget*>())
    .def("__init", table_init_general<QTimeEdit>)
    .def("__call", lqtimeedit_init)
    ;
}

static setter_map<QTimer> lqtimer_set_map;
QTimer* lqtimer_init(QTimer* widget, const object& obj)
{
    return lq_general_init(widget, obj, lqtimer_set_map);
}
template<>
void table_init_general<QTimer>(const luabind::argument & arg, const object& obj)
{
    lqtimer_init(construct<QTimer>(arg), obj);
}

SIGNAL_PROPERYT(lqtimer, timeout , QTimer,"()")
void lqtimer_singleShot(int msec, const object& obj)
{
    QLuaSlot *s = new QLuaSlot(obj, "lqtimer_singleShot", true);
    QTimer::singleShot(msec, s, SLOT(general_slot()));
}

LQTimer lqtimer()
{
    return
    myclass_<QTimer,QObject>("QTimer",lqtimer_set_map)
    .def(constructor<>())
    .def(constructor<QObject*>())
    .def("start", (void(QTimer::*)(int))&QTimer::start)
    .def("start", (void(QTimer::*)())&QTimer::start)
    .def("stop", &QTimer::stop)
    .def(constructor<QObject*>())
    .def(constructor<QObject*>())
    .property("interval", &QTimer::interval, &QTimer::setInterval)
    .property("isActive", &QTimer::isActive)
    .property("isSingleShot", &QTimer::isSingleShot, &QTimer::setSingleShot)
    .property("timerId", &QTimer::timerId)
    .sig_prop(lqtimer, timeout)
    .scope[
        def("singleShot", lqtimer_singleShot)
    ]
    ;
}
