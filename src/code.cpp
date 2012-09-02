#include <QtGui>

#include <QDebug>

#include "code.h"

CodeEditor::CodeEditor(QWidget *parent) : QPlainTextEdit(parent) {
  QSettings s;

  QString family = s.value("editor/fontfamily", "Courier").toString();
  uint size = s.value("editor/fontsize", 10).toUInt();

  setFont(family, size);

  highlighter = new Highlighter(document());

  lineNumberArea = new LineNumberArea(this);
  
  connect(this, SIGNAL(blockCountChanged(int)),
		  this, SLOT(updateLineNumberAreaWidth(int)));
  connect(this, SIGNAL(updateRequest(QRect,int)),
		  this, SLOT(updateLineNumberArea(QRect,int)));
  connect(this, SIGNAL(cursorPositionChanged()),
		  this, SLOT(highlightCurrentLine()));

  updateLineNumberAreaWidth(0);
  highlightCurrentLine();

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

bool CodeEditor::load(QString filename) {
  if (filename.isEmpty()) {
	filename = QString(".lua");
	filename = QFileDialog::getOpenFileName(this, "Open a script",
					script_filename, "lua source (*.lua);;All files (*)");
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
  setPlainText(p);
  script_filename = filename;
  emit scriptLoaded();

  return true;
}

bool CodeEditor::saveAs(QString filename) {
  if (filename.isEmpty()) {
	QFileDialog dialog(this, tr("Save a script"), script_filename,
					   tr("lua source (*.lua);;All files (*)"));
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

bool CodeEditor::save() {
  return saveAs(script_filename);
}

QString CodeEditor::scriptFile() const {
  return script_filename;
}

void CodeEditor::setFont(QString family, uint size) {
  
  //  qDebug() << " setFont " << family << size;

  QFont font;
  font.setFamily(family);
  font.setFixedPitch(true);
  font.setPointSize(size);

  QPlainTextEdit::setFont(font);
}

int CodeEditor::lineNumberAreaWidth() {
  int digits = 1;
  int max = qMax(1, blockCount());
  while (max >= 10) {
	max /= 10;
	++digits;
  }
  
  int space = 3 + fontMetrics().width(QLatin1Char('9')) * digits;
  
  return space;
}

void CodeEditor::updateLineNumberAreaWidth(int /* newBlockCount */) {
  setViewportMargins(lineNumberAreaWidth(), 0, 0, 0);
}

void CodeEditor::updateLineNumberArea(const QRect &rect, int dy) {
  if (dy)
	lineNumberArea->scroll(0, dy);
  else
	lineNumberArea->update(0, rect.y(),
						   lineNumberArea->width(), rect.height());

  if (rect.contains(viewport()->rect()))
	updateLineNumberAreaWidth(0);
}

void CodeEditor::resizeEvent(QResizeEvent *e) {
  QPlainTextEdit::resizeEvent(e);
  
  QRect cr = contentsRect();
  lineNumberArea->setGeometry(QRect(cr.left(), cr.top(),
									lineNumberAreaWidth(), cr.height()));
}

void CodeEditor::highlightCurrentLine() {
  QList<QTextEdit::ExtraSelection> extraSelections;
  
  if (!isReadOnly()) {
	QTextEdit::ExtraSelection selection;
	
	QColor lineColor = QColor(Qt::yellow).lighter(160);
	
	selection.format.setBackground(lineColor);
	selection.format.setProperty(QTextFormat::FullWidthSelection, true);
	selection.cursor = textCursor();
	selection.cursor.clearSelection();
	extraSelections.append(selection);
  }

  setExtraSelections(extraSelections);
}

void CodeEditor::lineNumberAreaPaintEvent(QPaintEvent *event) {
  QPainter painter(lineNumberArea);
  painter.fillRect(event->rect(), Qt::lightGray);

  QTextBlock block = firstVisibleBlock();
  int blockNumber = block.blockNumber();
  int top = (int) blockBoundingGeometry(block).translated(contentOffset()).top();
  int bottom = top + (int) blockBoundingRect(block).height();

  while (block.isValid() && top <= event->rect().bottom()) {
	if (block.isVisible() && bottom >= event->rect().top()) {
	  QString number = QString::number(blockNumber + 1);
	  painter.setPen(Qt::black);
	  painter.drawText(0, top, lineNumberArea->width(), fontMetrics().height(),
					   Qt::AlignRight, number);
	}
	
	block = block.next();
	top = bottom;
	bottom = top + (int) blockBoundingRect(block).height();
	++blockNumber;
  }
}
