#ifndef MIDIIO_H
#define MIDIIO_H

#include <QThread>
#include <QHash>
#include <QStringList>

#include "RtMidi.h"

#include "MidiEvent.h"

void midiRecivedCallback( double deltatime, std::vector< unsigned char > *message, void *userData);

class MidiIO : public QThread
{
  Q_OBJECT
    
 public:
  enum ControlType {None = 0, MidiCC = 1, MidiMMC = 2};

  MidiIO();
  ~MidiIO();
  void run();
  void stop();
  void sig_handler(int dummy);
  int getLastMovedControllerNr() const;
  int getLastMMCCmd() const;
  ControlType getLastMovedControllerType() const;
  void sendMidiRecived(MidiEvent *);
  void openInputPortByName(QString);

  void send(QString);

  QStringList getInputPorts();
  QStringList getOutputPorts();

  QString getMMCName(int cmd) const;

 private:
  void openPort(int);

 signals:
  void midiRecived(MidiEvent *);

 protected:
  int m_stop;

  int lastOpenPort;
  
  RtMidiIn  *midiin;
  RtMidiOut *midiout;

  QHash<int, QString> mmcNames;
};

#endif
