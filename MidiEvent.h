#ifndef MIDIEVENT_H
#define MIDIEVENT_H

#include <QEvent>
#include <QString>

class MidiEvent : public QEvent
{
 public:
  MidiEvent(QString message);

  QString message;
};

#endif
