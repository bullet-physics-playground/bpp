#include <QDebug>

#include "MidiIO.h"

#ifdef HAS_MIDI

#include "RtMidi.h"

MidiIO::MidiIO()
{
  mmcNames[0x01] = "Stop";
  mmcNames[0x02] = "Play";
  mmcNames[0x03] = "Deferred Play";
  mmcNames[0x04] = "Fast Forward";
  mmcNames[0x05] = "Rewind";
  mmcNames[0x06] = "Record Strobe (Punch In)";
  mmcNames[0x07] = "Record Exit (Punch out)";
  mmcNames[0x08] = "Record Ready";
  mmcNames[0x09] = "Pause";
  mmcNames[0x0A] = "Eject";
  mmcNames[0x0B] = "Chase";
  mmcNames[0x0C] = "Error Reset";
  mmcNames[0x0D] = "MMC Reset";
  mmcNames[0x20] = "Jog Start";
  mmcNames[0x21] = "Jog Stop";
  mmcNames[0x40] = "Write";
  mmcNames[0x41] = "Masked Write";
  mmcNames[0x42] = "Read";
  mmcNames[0x43] = "Update";
  mmcNames[0x44] = "Locate/Go to";
  mmcNames[0x45] = "Variable Play";
  mmcNames[0x46] = "Search";
  mmcNames[0x47] = "Shuttle";
  mmcNames[0x48] = "Step";
  mmcNames[0x49] = "Assign system master";
  mmcNames[0x4A] = "Generator Command";
  mmcNames[0x4B] = "MTC Command";
  mmcNames[0x4C] = "Move";
  mmcNames[0x4D] = "Add";
  mmcNames[0x4E] = "Subtract";
  mmcNames[0x4F] = "Drop frame adjust";
  mmcNames[0x50] = "Procedure";
  mmcNames[0x51] = "Event";
  mmcNames[0x52] = "Group";
  mmcNames[0x53] = "Command Segment";
  mmcNames[0x54] = "Deferred variable play";
  mmcNames[0x55] = "Record strobe variable";
  mmcNames[0x7C] = "Wait";
  mmcNames[0x7F] = "Resume";

  m_stop = 0;

  try {
    midiin = new RtMidiIn();

#ifndef __WINDOWS_MM__
    if (midiin != NULL)
      midiin->openVirtualPort("input");
#endif

    midiout = new RtMidiOut();

#ifndef __WINDOWS_MM__
    if (midiout != NULL)
      midiout->openVirtualPort("output");
#endif
  }
  catch ( RtError &error ) {
    error.printMessage();
    exit( EXIT_FAILURE );
  }

  lastOpenPort = -1;
}

MidiIO::~MidiIO()
{
  // if (midiin != NULL)
  //  delete midiin;

  // if (midiout != NULL)
  //  delete midiout;
}

void MidiIO::sig_handler(int)
{
  m_stop = 1;
}

void MidiIO::stop()
{
  m_stop = 1;
}

void MidiIO::openPort(int nr)
{
  if (lastOpenPort != -1 && midiin != NULL) {
    midiin->closePort();
  }

  if (nr != -1 && midiin != NULL) {
    midiin->openPort(nr);
  }

  lastOpenPort = nr;
}

void MidiIO::openInputPortByName(QString portName)
{
  openPort(getInputPorts().indexOf(portName));
}

QStringList MidiIO::getInputPorts()
{
  QStringList ports;

  if (midiin != NULL) {
    for ( unsigned int i=0; i<midiin->getPortCount(); ++i ) {
      try {
	ports.append(QString(midiin->getPortName(i).c_str()));
      }
      catch ( RtError &error ) {
	error.printMessage();
	break;
      }
    }
  }

  return ports;
}

QStringList MidiIO::getOutputPorts()
{
  QStringList ports;

  if (midiout != NULL) {
    for ( unsigned int i=0; i<midiout->getPortCount(); ++i ) {
      try {
	ports.append(QString(midiout->getPortName(i).c_str()));
      }
      catch ( RtError &error ) {
	error.printMessage();
	break;
      }
    }
  }

  return ports;
}

void midiRecivedCallback( double, std::vector< unsigned char > *message, void *userData)
{
  QString m;
  std::vector< unsigned char >::const_iterator i;
  for(i=message->begin(); i!=message->end(); ++i){
    m.append(*i);
  }

  ((MidiIO *) userData)->sendMidiRecived(new MidiEvent(m));
}

void MidiIO::send(QString message)
{
  std::vector< unsigned char > msg;

  for(int i=0; i<message.size(); ++i){
    msg.push_back(message.at(i).toAscii());
  }

  if (midiout != NULL)
    midiout->sendMessage(&msg);
}

void MidiIO::sendMidiRecived(MidiEvent *e)
{
  QString m = QString(e->message);
  emit midiRecived(e);
}

void MidiIO::run()
{
  if (midiin != NULL) {
    midiin->setCallback(&midiRecivedCallback, this);
    midiin->ignoreTypes( false, false, false );
  }
}

QString MidiIO::getMMCName(int cmd) const
{
  return mmcNames.value(cmd);
}

#endif
