#include "commandline.h"

#include <QKeyEvent>

CommandLine::CommandLine(QWidget *parent) : QLineEdit(parent) {
  historyPos = -1;
  connect(this, SIGNAL(returnPressed()), this, SLOT(executed()));

  history = new QList<QString>();
}

QList<QString>* CommandLine::getHistory() {
  return history;
}

void CommandLine::executed() {
  QString cmd = text();

  history->push_back(cmd);
  historyPos = -1;

  setText("");

  emit execute(cmd);
}

void CommandLine::keyPressEvent(QKeyEvent *e) {
  if (e->key() == Qt::Key_Up) {
    int n = history->size();
    int pos = historyPos == -1 ? n - 1 : historyPos - 1;
    if ((pos >= 0) && (pos < n)) {
      setText(history->at(pos));
      historyPos = pos;
    }
  } else if (e->key() == Qt::Key_Down) {
    int n = history->size(); 
    int pos = historyPos == -1 ? n : historyPos + 1;
    if((pos >= 0) && (pos < n) ) {
      setText(history->at(pos));
      historyPos = pos;
    } else if (pos >= n) {
      QLineEdit::setText("");
      historyPos = -1;
    }
  } else {
    QLineEdit::keyPressEvent(e);
  }
}

