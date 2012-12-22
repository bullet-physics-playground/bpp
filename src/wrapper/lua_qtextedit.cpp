#include "lua_qtextedit.h"
#include <luabind/adopt_policy.hpp>
#include <luabind/dependency_policy.hpp>

static setter_map<QLabel> lqlabel_set_map;
static setter_map<QTextEdit> lqtextedit_set_map;
static setter_map<QPlainTextEdit> lqplaintextedit_set_map;
static setter_map<QLineEdit> lqlineedit_set_map;

namespace luabind{
    QT_EMUN_CONVERTER(QTextDocument::FindFlags)
}

QLabel* lqlabel_init(QLabel* widget, const object& obj)
{
    lqwidget_init(widget,obj);
    return lq_general_init(widget, obj, lqlabel_set_map);
}

QTextEdit* lqtextedit_init(QTextEdit* widget, const object& obj)
{
    lqwidget_init(widget,obj);
    lq_general_init(widget, obj, lqtextedit_set_map);
    return widget;
}

QPlainTextEdit* lqplaintextedit_init(QPlainTextEdit* widget, const object& obj)
{
    lqwidget_init(widget,obj);
    lq_general_init(widget, obj, lqplaintextedit_set_map);
    return widget;
}

QLineEdit* lqlineedit_init(QLineEdit* widget, const object& obj)
{
    lqwidget_init(widget,obj);
    return lq_general_init(widget, obj, lqlineedit_set_map);
}

template<>
void table_init_general<QLabel>(const luabind::argument & arg, const object& obj)
{
    lqlabel_init(construct<QLabel>(arg), obj);
}

template<>
void table_init_general<QTextEdit>(const luabind::argument & arg, const object& obj)
{
    lqtextedit_init(construct<QTextEdit>(arg), obj);
}

template<>
void table_init_general<QPlainTextEdit>(const luabind::argument & arg, const object& obj)
{
    lqplaintextedit_init(construct<QPlainTextEdit>(arg), obj);
}

template<>
void table_init_general<QLineEdit>(const luabind::argument & arg, const object& obj)
{
    lqlineedit_init(construct<QLineEdit>(arg), obj);
}

int lqlabel_textFormat(QLabel* l)
{
    return l->textFormat();
}
void lqlabel_setTextFormat(QLabel* l, int format)
{
    l->setTextFormat(Qt::TextFormat(format));
}

SIGNAL_PROPERYT(lqlabel, linkActivated, QLabel, "(const QString&)")
SIGNAL_PROPERYT(lqlabel, linkHovered, QLabel, "(const QString&)")

LQLabel lqlabel()
{
    return
    myclass_<QLabel,QFrame>("QLabel",lqlabel_set_map)
    .def(constructor<>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&,QWidget*>())
    .def("__call", lqlabel_init)
    .def("__init", table_init_general<QLabel>)
    .def("setText", &QLabel::setText)
    .def("clear", &QLabel::clear)
    .def("setPixmap", &QLabel::setPixmap)
    .def("setNum", (void(QLabel::*)(double))&QLabel::setNum)

    .property("text", &QLabel::text, &QLabel::setText)
    .property("indent", &QLabel::indent, &QLabel::setIndent)
    .property("margin", &QLabel::margin, &QLabel::setMargin)
    .property("textFormat", lqlabel_textFormat, lqlabel_setTextFormat)
    .property("scaledContents", &QLabel::hasScaledContents, &QLabel::setScaledContents)
    .property("wordWrap", &QLabel::wordWrap, &QLabel::setWordWrap)
    .property("openExternalLinks", &QLabel::openExternalLinks, &QLabel::setOpenExternalLinks)
    .sig_prop(lqlabel, linkActivated)
    .sig_prop(lqlabel, linkHovered)

    .class_<QLabel,QFrame>::property("buddy", &QLabel::buddy, &QLabel::setBuddy)
    .property("pixmap", &QLabel::pixmap, &QLabel::setPixmap)
    ;
}

int lqtextedit_v_scroll_bar(QTextEdit* edit)
{
    return edit->verticalScrollBarPolicy();
}

void lqtextedit_set_v_scroll_bar(QTextEdit* edit, int p)
{
    return edit->setVerticalScrollBarPolicy(Qt::ScrollBarPolicy(p));
}

int lqtextedit_h_scroll_bar(QTextEdit* edit)
{
    return edit->horizontalScrollBarPolicy();
}

void lqtextedit_set_h_scroll_bar(QTextEdit* edit, int p)
{
    return edit->setHorizontalScrollBarPolicy(Qt::ScrollBarPolicy(p));
}

int lqtextedit_lineWrapMode(QTextEdit* edit)
{
    return edit->lineWrapMode();
}

void lqtextedit_set_lineWrapMode(QTextEdit* edit, int p)
{
    return edit->setLineWrapMode(QTextEdit::LineWrapMode(p));
}

void look_text_corlor(QTextEdit* w, const object& fun)
{
    QColor color;
    QTextCursor tc = w->textCursor();
    int pos = tc.position();
    int ach = tc.anchor();
    tc.movePosition(QTextCursor::Start);
    color = w->textColor();
    while(tc.movePosition(QTextCursor::NextCharacter, QTextCursor::KeepAnchor)){
        QColor color2 = w->textColor();
        if(color2 != color){
            tc.movePosition(QTextCursor::PreviousCharacter, QTextCursor::KeepAnchor);
            call_function<void>(fun,w, tc.selectedText() ,color);
            color = color2;
            tc.movePosition(QTextCursor::NextCharacter);
            tc.movePosition(QTextCursor::PreviousCharacter);
        }
    }
    call_function<void>(fun,w, tc.selectedText() ,color);
    tc.setPosition(ach);
    tc.setPosition(pos, QTextCursor::KeepAnchor);
}

void QTextEdit_zoomIn(QTextEdit* w){ w->zoomIn(); }
void QTextEdit_zoomOut(QTextEdit* w){ w->zoomOut(); }
bool lqtextedit_find(QTextEdit* w, const QString& str) { return w->find(str);}
ENUM_FILTER(QTextEdit, lineWrapMode, setLineWrapMode)
ENUM_FILTER(QTextEdit, wordWrapMode, setWordWrapMode)

SIGNAL_PROPERYT(lqtextedit, textChanged, QTextEdit, "()")
SIGNAL_PROPERYT(lqtextedit, copyAvailable, QTextEdit, "(bool)")
SIGNAL_PROPERYT(lqtextedit, cursorPositionChanged, QTextEdit, "()")
SIGNAL_PROPERYT(lqtextedit, redoAvailable, QTextEdit, "(bool)")
SIGNAL_PROPERYT(lqtextedit, undoAvailable, QTextEdit, "(bool)")
SIGNAL_PROPERYT(lqtextedit, selectionChanged, QTextEdit, "()")

QString lqtextedit_selected_text(QTextEdit* w)
{
    return w->textCursor().selectedText();
}
LQTextEdit lqtextedit()
{
    return
    myclass_<QTextEdit,QAbstractScrollArea>("QTextEdit",lqtextedit_set_map)
    .def(constructor<>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&,QWidget*>())
    .def("__call", lqtextedit_init)
    .def("__init", table_init_general<QTextEdit>)
    .def("clear", &QTextEdit::clear)
    .def("append", &QTextEdit::append)
    .def("copy", &QTextEdit::copy)
    .def("cut", &QTextEdit::cut)
    .def("find", &QTextEdit::find)
    .def("find", lqtextedit_find)
    .def("insertHtml", &QTextEdit::insertHtml)
    .def("insertPlainText", &QTextEdit::insertPlainText)
    .def("paste", &QTextEdit::paste)
    .def("redo", &QTextEdit::redo)
    .def("scrollToAnchor", &QTextEdit::scrollToAnchor)
    .def("selectAll", &QTextEdit::selectAll)
    .def("setAlignment", &QTextEdit::setAlignment)
    .def("setCurrentFont", &QTextEdit::setCurrentFont)
    .def("setFontFamily", &QTextEdit::setFontFamily)
    .def("setFontItalic", &QTextEdit::setFontItalic)
    .def("setFontPointSize", &QTextEdit::setFontPointSize)
    .def("setFontUnderline", &QTextEdit::setFontUnderline)
    .def("setFontWeight", &QTextEdit::setFontWeight)
    .def("setHtml", &QTextEdit::setHtml)
    .def("setPlainText", &QTextEdit::setPlainText)
    .def("setText", &QTextEdit::setText)
    .def("setTextBackgroundColor", &QTextEdit::setTextBackgroundColor)
    .def("setTextColor", &QTextEdit::setTextColor)
    .def("undo", &QTextEdit::undo)
    .def("zoomIn", &QTextEdit::zoomIn)
    .def("zoomOut", &QTextEdit::zoomOut)
    .def("zoomIn", &QTextEdit_zoomIn)
    .def("zoomOut", &QTextEdit_zoomOut)
    .def("lookColor", look_text_corlor)
    .def("ensureCursorVisible", &QTextEdit::ensureCursorVisible)

    .property("selectedText", lqtextedit_selected_text)

    .property("text", &QTextEdit::toPlainText, &QTextEdit::setPlainText)
    .property("plainText", &QTextEdit::toPlainText, &QTextEdit::setPlainText)
    .property("html", &QTextEdit::toHtml, &QTextEdit::setHtml)
    .property("readOnly", &QTextEdit::isReadOnly, &QTextEdit::setReadOnly)
    .property("undoRedoEnabled", &QTextEdit::isUndoRedoEnabled, &QTextEdit::setUndoRedoEnabled)
    .property("lineWrapMode", QTextEdit_lineWrapMode, QTextEdit_setLineWrapMode)
    .property("documentTitle", &QTextEdit::documentTitle ,&QTextEdit::setDocumentTitle)
    .property("overwriteMode", &QTextEdit::overwriteMode, &QTextEdit::setOverwriteMode)
    .property("cursorWidth", &QTextEdit::cursorWidth, &QTextEdit::setCursorWidth)
    .property("tabChangesFocus", &QTextEdit::tabChangesFocus, &QTextEdit::setTabChangesFocus)
    .property("tabStopWidth", &QTextEdit::tabStopWidth, &QTextEdit::setTabStopWidth)
    .property("wordWrapMode", QTextEdit_wordWrapMode, QTextEdit_setWordWrapMode)
    //.property("verticalScrollBarPolicy", lqtextedit_v_scroll_bar, lqtextedit_set_v_scroll_bar)
    //.property("horizontalScrollBarPolicy", lqtextedit_h_scroll_bar, lqtextedit_set_h_scroll_bar)
    //.property("vScrollBarPolicy", lqtextedit_v_scroll_bar, lqtextedit_set_v_scroll_bar)
    //.property("hScrollBarPolicy", lqtextedit_h_scroll_bar, lqtextedit_set_h_scroll_bar)
    //.property("lineWrapMode", lqtextedit_lineWrapMode, lqtextedit_set_lineWrapMode)
    .sig_prop(lqtextedit,textChanged)
    .sig_prop(lqtextedit, copyAvailable)
    .sig_prop(lqtextedit, cursorPositionChanged)
    .sig_prop(lqtextedit, redoAvailable)
    .sig_prop(lqtextedit, undoAvailable)
    .sig_prop(lqtextedit, selectionChanged)
    ;
}

ENUM_FILTER(QPlainTextEdit, lineWrapMode, setLineWrapMode)
ENUM_FILTER(QPlainTextEdit, wordWrapMode, setWordWrapMode)
bool lqplaintextedit_find(QPlainTextEdit* w, const QString& str) { return w->find(str);}
SIGNAL_PROPERYT(lqplaintextedit, textChanged, QPlainTextEdit, "()")
SIGNAL_PROPERYT(lqplaintextedit, copyAvailable, QPlainTextEdit, "(bool)")
SIGNAL_PROPERYT(lqplaintextedit, cursorPositionChanged, QPlainTextEdit, "()")
SIGNAL_PROPERYT(lqplaintextedit, redoAvailable, QPlainTextEdit, "(bool)")
SIGNAL_PROPERYT(lqplaintextedit, undoAvailable, QPlainTextEdit, "(bool)")
SIGNAL_PROPERYT(lqplaintextedit, selectionChanged, QPlainTextEdit, "()")
SIGNAL_PROPERYT(lqplaintextedit, blockCountChanged, QPlainTextEdit, "(int)")

QString lqplaintextedit_selected_text(QPlainTextEdit* w)
{
    return w->textCursor().selectedText();
}
LQPlainTextEdit lqplaintextedit()
{
    return
    myclass_<QPlainTextEdit,QAbstractScrollArea>("QPlainTextEdit",lqplaintextedit_set_map)
    .def(constructor<>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&,QWidget*>())
    .def("__call", lqplaintextedit_init)
    .def("__init", table_init_general<QPlainTextEdit>)
    .def("createStandardContextMenu", &QPlainTextEdit::createStandardContextMenu)
    .def("ensureCursorVisible", &QPlainTextEdit::ensureCursorVisible)
    .def("appendHtml", &QPlainTextEdit::appendHtml)
    .def("appendPlainText", &QPlainTextEdit::appendPlainText)
    .def("append", &QPlainTextEdit::appendPlainText)
    .def("centerCursor", &QPlainTextEdit::centerCursor)
    .def("clear", &QPlainTextEdit::clear)
    .def("copy", &QPlainTextEdit::copy)
    .def("cut", &QPlainTextEdit::cut)
    .def("insertPlainText", &QPlainTextEdit::insertPlainText)
    .def("paste", &QPlainTextEdit::paste)
    .def("redo", &QPlainTextEdit::redo)
    .def("selectAll", &QPlainTextEdit::selectAll)
    .def("setPlainText", &QPlainTextEdit::setPlainText)
    .def("undo", &QPlainTextEdit::undo)
    .def("find", &QPlainTextEdit::find)
    .def("find", lqplaintextedit_find)


    .property("selectedText", lqplaintextedit_selected_text)

    .property("backgroundVisible", &QPlainTextEdit::backgroundVisible, &QPlainTextEdit::setBackgroundVisible)
    .property("blockCount", &QPlainTextEdit::blockCount)
    .property("canPaste", &QPlainTextEdit::canPaste)
    .property("centerOnScroll", &QPlainTextEdit::centerOnScroll, &QPlainTextEdit::setCenterOnScroll)
    .property("documentTitle", &QPlainTextEdit::documentTitle ,&QPlainTextEdit::setDocumentTitle)
    .property("readOnly", &QPlainTextEdit::isReadOnly, &QPlainTextEdit::setReadOnly)
    .property("undoRedoEnabled", &QPlainTextEdit::isUndoRedoEnabled, &QPlainTextEdit::setUndoRedoEnabled)
    .property("lineWrapMode", QPlainTextEdit_lineWrapMode, QPlainTextEdit_setLineWrapMode)
    .property("maximumBlockCount", &QPlainTextEdit::maximumBlockCount, &QPlainTextEdit::setMaximumBlockCount)
    .property("overwriteMode", &QPlainTextEdit::overwriteMode, &QPlainTextEdit::setOverwriteMode)
    .property("cursorWidth", &QPlainTextEdit::cursorWidth, &QPlainTextEdit::setCursorWidth)
    .property("tabChangesFocus", &QPlainTextEdit::tabChangesFocus, &QPlainTextEdit::setTabChangesFocus)
    .property("tabStopWidth", &QPlainTextEdit::tabStopWidth, &QPlainTextEdit::setTabStopWidth)
    .property("wordWrapMode", QPlainTextEdit_wordWrapMode, QPlainTextEdit_setWordWrapMode)
    .property("plainText", &QPlainTextEdit::toPlainText, &QPlainTextEdit::setPlainText)
    .sig_prop(lqplaintextedit,textChanged)
    .sig_prop(lqplaintextedit, copyAvailable)
    .sig_prop(lqplaintextedit, cursorPositionChanged)
    .sig_prop(lqplaintextedit, redoAvailable)
    .sig_prop(lqplaintextedit, undoAvailable)
    .sig_prop(lqplaintextedit, selectionChanged)
    .sig_prop(lqplaintextedit, blockCountChanged)
    ;
}

ENUM_FILTER(QLineEdit, echoMode, setEchoMode)
SIGNAL_PROPERYT(lqlineedit, textChanged, QLineEdit, "(const QString&)")
SIGNAL_PROPERYT(lqlineedit, textEdited, QLineEdit, "(const QString&)")
SIGNAL_PROPERYT(lqlineedit, cursorPositionChanged, QLineEdit, "(int,int)")
SIGNAL_PROPERYT(lqlineedit, editingFinished, QLineEdit, "()")
SIGNAL_PROPERYT(lqlineedit, returnPressed, QLineEdit, "()")
SIGNAL_PROPERYT(lqlineedit, selectionChanged, QLineEdit, "()")

LQLineEdit lqlineedit()
{
    return
    myclass_<QLineEdit,QWidget>("QLineEdit",lqlineedit_set_map)
    .def(constructor<>())
    .def(constructor<const QString&>())
    .def(constructor<const QString&,QWidget*>())
    .def("__call", lqlineedit_init)
    .def("__init", table_init_general<QLineEdit>)
    .def("clear", &QLineEdit::clear)
    .def("cut", &QLineEdit::cut)
    .def("copy", &QLineEdit::copy)
    .def("paste", &QLineEdit::paste)
    .def("undo", &QLineEdit::undo)
    .def("redo", &QLineEdit::redo)
    .def("selectAll", &QLineEdit::selectAll)
    .def("setText", &QLineEdit::setText)

    .property("text", &QLineEdit::text, &QLineEdit::setText)
    .property("inputMask", &QLineEdit::inputMask, &QLineEdit::setInputMask)
    .property("hasSelectedText", &QLineEdit::hasSelectedText)
    .property("selectedText", &QLineEdit::selectedText)
    .property("modified", &QLineEdit::isModified, &QLineEdit::setModified)
    .property("readOnly", &QLineEdit::isReadOnly, &QLineEdit::setReadOnly)
    .property("echoMode", QLineEdit_echoMode, QLineEdit_setEchoMode)
#if (QT_VERSION >= 0x040700) || defined(Q_WS_MAEMO_5)
    .property("placeholderText", &QLineEdit::placeholderText, &QLineEdit::setPlaceholderText)
#endif
    .sig_prop(lqlineedit, textChanged)
    .sig_prop(lqlineedit, textEdited)
    .sig_prop(lqlineedit, cursorPositionChanged)
    .sig_prop(lqlineedit, editingFinished)
    .sig_prop(lqlineedit, returnPressed)
    .sig_prop(lqlineedit, selectionChanged)
    ;
}

