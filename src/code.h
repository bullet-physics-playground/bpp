#ifndef CODEEDITOR_H
#define CODEEDITOR_H

#include <QDebug>

#include <QPlainTextEdit>
#include <QObject>
#include <QWidget>
#include <QVarLengthArray>

#include "high.h"

class QPaintEvent;
class QResizeEvent;
class QSize;

class LineNumberArea;

class CodeEditor : public QPlainTextEdit {
 Q_OBJECT;
	
 public:
  CodeEditor(QWidget *parent = 0);
  
  void lineNumberAreaPaintEvent(QPaintEvent *event);
  int lineNumberAreaWidth();

  QString script_filename;
 public slots:
  void clear();
  bool save();
  bool load(QString filename=QString());
  bool saveAs(QString filename=QString());
  QString scriptFile() const;

  void setFont(QString family, uint size);

  void appendLine(QString l) {
	lines.append(l);
	set_text();
  }

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

 protected:
  void set_text() {
	QString text;
	for (int n = 0; n < lines.size(); n++) {
	  text += lines[n];
	  if (n < lines.size() - 1) text += "\n";
	}

	setPlainText(text);

	QTextCursor c = textCursor();
	c.movePosition(QTextCursor::End);
	setTextCursor(c);
  }

  void resizeEvent(QResizeEvent *event);
  
 private slots:
  void updateLineNumberAreaWidth(int newBlockCount);
  void highlightCurrentLine();
  void updateLineNumberArea(const QRect &, int);
  
 private:
  QWidget *lineNumberArea;

  QVarLengthArray<QString> lines;

  Highlighter *highlighter;
};


class LineNumberArea : public QWidget {
 Q_OBJECT;

 public:
  LineNumberArea(CodeEditor *editor) : QWidget(editor) { codeEditor = editor; }
  QSize sizeHint() const {return QSize(codeEditor->lineNumberAreaWidth(), 0); }
  
 protected:
  void paintEvent(QPaintEvent *event) {
	codeEditor->lineNumberAreaPaintEvent(event);
  }
  
 private:
  CodeEditor *codeEditor;
};

#endif
