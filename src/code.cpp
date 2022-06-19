#include "code.h"

#include <Qsci/qscilexerlua.h>
#include <Qsci/qsciapis.h>

#include <QAction>
#include <QFileDialog>
#include <QTextStream>
#include <QMessageBox>
#include <QKeyEvent>
#include <QDebug>

Code::Code(QSettings *s, QWidget *parent)
    : QsciScintilla(parent)
{
    QString family = s->value("editor/fontfamily", "Courier").toString();
    uint size = s->value("editor/fontsize", 10).toUInt();

    QsciLexerLua *l = new QsciLexerLua(this);

    QsciAPIs* api = new QsciAPIs(l);

    //l->setColor(Qt::blue, QsciLexerLua::Keyword);
    //l->setColor(QColor(0xff, 0x80, 0x00), QsciLexerLua::Number);
    //l->setColor(QColor(0xff, 0x80, 0x00), QsciLexerLua::);
    //l->setPaper(QColor(0x0, 0x0, 128));

    QFont font = QFont();
    font.setFamily(family);
    //font.setFixedPitch(true);
    font.setPointSize(size);

    api->prepare();
    l->setDefaultFont(font);
    setLexer(l);

    QsciScintilla::setFont(font);
    setMarginsFont(font);

    // Line Highlight
    setCaretLineVisible(true);
    //setCaretForegroundColor(QColor("yellow"));
    //setCaretLineBackgroundColor(QColor("blue"));

    // # Margin 0 is used for line numbers
    QFontMetrics fontmetrics = QFontMetrics(font);
    setMarginsFont(font);
    setMarginWidth(0, fontmetrics.width("0000") + 6);
    setMarginLineNumbers(0, true);
    //setMarginsBackgroundColor(QColor("blue"));

    // setEdgeMode(QsciScintilla::EdgeLine); setEdgeColumn(80); setEdgeColor(QColor("#FF0000"));

    setFolding(QsciScintilla::BoxedTreeFoldStyle);
    setBraceMatching(QsciScintilla::SloppyBraceMatch);

    setFoldMarginColors(QColor("#99CC66"), QColor("#333300"));

    SendScintilla(SCI_SETHSCROLLBAR, 0);
    setBraceMatching(SloppyBraceMatch);

    QAction* a = new QAction(tr("Open a file"), this);
    a->setShortcut(tr("Ctrl+1"));
    a->setShortcutContext(Qt::WidgetShortcut);
    addAction(a);
    connect(a, SIGNAL(triggered()), this, SLOT(load()));

    a = new QAction(tr("Save file"), this);
    a->setShortcut(tr("Ctrl+2"));
    a->setShortcutContext(Qt::WidgetShortcut);
    addAction(a);
    connect(a, SIGNAL(triggered()), this, SLOT(save()));

    a = new QAction(tr("Save to file"), this);
    a->setShortcut(tr("Ctrl+3"));
    a->setShortcutContext(Qt::WidgetShortcut);
    addAction(a);
    connect(a, SIGNAL(triggered()), this, SLOT(saveAs()));
}

bool Code::load(QString filename) {
    if (filename.isEmpty()) {
        filename = QString(".lua");
        filename = QFileDialog::getOpenFileName(this, "Open a script",
                                                script_filename, "Lua source (*.lua);;All files (*)");
        if (filename.isEmpty())
            return false;
    }

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly)) {

        /*
        QMessageBox::warning(this, tr("Application error"),
                             tr("Cannot read file %1\n").arg(filename));
        */
        return false;
    }

    QTextStream os(&file);
    QString p = os.readAll();
    file.close();

    setText(p);

    script_filename = filename;
    emit scriptLoaded();

    return true;
}

bool Code::saveAs(QString filename) {
    if (filename.isEmpty()) {
        QFileDialog dialog(this, tr("Save a script"), script_filename,
                           tr("Lua source (*.lua);;All files (*)"));
        dialog.setAcceptMode(QFileDialog::AcceptSave);
        dialog.setDefaultSuffix("lua");
        dialog.selectFile(script_filename);

        if (dialog.exec())
            filename = dialog.selectedFiles().first();
        else
            return false;
    }

    QFile file(filename);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QMessageBox::warning(this, tr("Application error"),
                             tr("Cannot write file %1\n").arg(filename))	\
                ;
        return false;
    }
    QTextStream os(&file);
    os << toPlainText();
    file.close();
    script_filename = filename;

    emit scriptSaved();

    return true;
}

bool Code::save() {
    if (QString("no_name") == script_filename) {
        return saveAs("");
    } else {
        return saveAs(script_filename);
    }
}

QString Code::toPlainText() {
    return text();
}

void Code::appendLine(QString line) {
    append("\n" + line);
    SendScintilla(QsciScintilla::SCI_GOTOLINE, toPlainText().lastIndexOf("\n") + 1);
}

void Code::setFont(QString family, int size) {
    //  qDebug() << " setFont " << family << size;
    //XXX set Lexer font here, too.
    QFont *f = new QFont(family, size);
    //f->setFixedPitch(true);
    QsciScintilla::setFont(*f);
    QWidget::setFont(*f);
}

void Code::keyPressEvent(QKeyEvent *e) {
    QsciScintilla::keyPressEvent(e);

    if (e->isAccepted()) {
        return;
    }

    int keyInt = e->key();
    Qt::Key key = static_cast<Qt::Key>(keyInt);

    if (key == Qt::Key_unknown) {
        qDebug() << "Unknown key from a macro probably";
        return;
    }

    // the user have clicked just and only the special keys Ctrl, Shift, Alt, Meta.
    if (key == Qt::Key_Control ||
            key == Qt::Key_Shift ||
            key == Qt::Key_Alt ||
            key == Qt::Key_Meta)
    {
        // qDebug() << "Single click of special key: Ctrl, Shift, Alt or Meta";
        // qDebug() << "New KeySequence:" << QKeySequence(keyInt).toString(QKeySequence::NativeText);
        // return;
    }

    // check for a combination of user clicks
    Qt::KeyboardModifiers modifiers = e->modifiers();
    QString keyText = e->text();
    // if the keyText is empty than it's a special key like F1, F5, ...
    //  qDebug() << "Pressed Key:" << keyText;

    QList<Qt::Key> modifiersList;
    if (modifiers & Qt::ShiftModifier)
        keyInt += Qt::SHIFT;
    if (modifiers & Qt::ControlModifier)
        keyInt += Qt::CTRL;
    if (modifiers & Qt::AltModifier)
        keyInt += Qt::ALT;
    if (modifiers & Qt::MetaModifier)
        keyInt += Qt::META;

    QString seq = QKeySequence(keyInt).toString(QKeySequence::NativeText);

    // qDebug() << "CodeEditor::keyPressed(" << seq << ")";

    emit keyPressed(e);
}
