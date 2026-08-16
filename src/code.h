#ifndef CODEEDITOR_H
#define CODEEDITOR_H

#include <QDebug>
#include <QSettings>

#include <QObject>
#include <QPlainTextEdit>
#include <QVarLengthArray>
#include <QWidget>

#include "high.h"

class QPaintEvent;
class QResizeEvent;
class QSize;

class LineNumberArea;

class CodeEditor : public QPlainTextEdit {
  Q_OBJECT;

public:
  CodeEditor(QSettings *settings, QWidget *parent = nullptr);
  ~CodeEditor() override; // Add destructor declaration

  void lineNumberAreaPaintEvent(QPaintEvent *event);
  int lineNumberAreaWidth();

  QString scriptFile() const;

public slots:
  void clear();
  bool save();
  bool load(QString filename = QString());
  bool saveAs(QString filename = QString());

  void setFont(QString family, uint size);

  void appendLine(QString l) { appendPlainText(l); }

  void replaceText(QString txt) {
    int pos = textCursor().position();

    setPlainText(txt);

    QTextCursor cursor = this->textCursor();
    cursor.setPosition(pos, QTextCursor::MoveAnchor);
    setTextCursor(cursor);
  }

signals:
  void scriptLoaded();
  void scriptSaved();
  void keyPressed(QKeyEvent *e);
  void savePressed();

protected:
  void keyPressEvent(QKeyEvent *e) override;
  void resizeEvent(QResizeEvent *event) override;

private slots:
  void updateLineNumberAreaWidth(int newBlockCount);
  void highlightCurrentLine();
  void updateLineNumberArea(const QRect &, int);

private:
  QWidget *lineNumberArea;

  LuaHighlighter *highlighter;

  QString script_filename;
};

class LineNumberArea : public QWidget {
  Q_OBJECT;

public:
  LineNumberArea(CodeEditor *editor) : QWidget(editor) { codeEditor = editor; }
  QSize sizeHint() const { return QSize(codeEditor->lineNumberAreaWidth(), 0); }

protected:
  void paintEvent(QPaintEvent *event) {
    codeEditor->lineNumberAreaPaintEvent(event);
  }

private:
  CodeEditor *codeEditor;
};

#endif
