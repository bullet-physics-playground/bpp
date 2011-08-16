#include "MidiEvent.h"

MidiEvent::MidiEvent(QString iMessage) :
  QEvent((QEvent::Type)(QEvent::User + 1))
{
  message = iMessage;
}
