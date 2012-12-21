#include "cmd.h"

#include <QDebug>

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

  if (e->isAccepted()) {
    return;
  }

  // if the key press was not accepted, it probably is a user defindes shortcut

  int keyInt = e->key();
  Qt::Key key = static_cast<Qt::Key>(keyInt);

  if (key == Qt::Key_unknown) {
    qDebug() << "Unknown key from a macro probably";
    return;
  }

  // the user have clicked just and only the special keys Ctrl, Shift, Alt, Meta.
  if(key == Qt::Key_Control ||
     key == Qt::Key_Shift ||
     key == Qt::Key_Alt ||
     key == Qt::Key_Meta)
    {
      // qDebug() << "Single click of special key: Ctrl, Shift, Alt or Meta";
      // qDebug() << "New KeySequence:" << QKeySequence(keyInt).toString(QKeySequence::NativeText);
      return;
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

