#ifndef MIDILIBREMIDI_H
#define MIDILIBREMIDI_H

#include "midi.h"

#if USE_LIBREMIDI
#include <libremidi/libremidi.hpp>
#include <map>
#include <memory>
#endif

/**
 * @brief MIDI input backend backed by libremidi.
 *
 * Only compiled when USE_LIBREMIDI=1. Enumerates the available MIDI input
 * ports and lets the GUI open/close each one individually, forwarding every
 * incoming message to the messageReceived() signal (which the Viewer relays
 * to v:onMIDIReceived).
 */
class MidiInterfaceLibremidi : public MidiInterface
{
public:
    explicit MidiInterfaceLibremidi(QObject *parent = nullptr);
    ~MidiInterfaceLibremidi() override;

    bool open() override;
    void close() override;
    bool isOpen() const override;
    QStringList portNames() const override;
    bool openPort(int index) override;
    void closePort(int index) override;
    bool isPortOpen(int index) const override;

private:
#if USE_LIBREMIDI
    void onMessage(libremidi::message &&msg);
    libremidi::input_configuration _conf;
    std::map<int, std::unique_ptr<libremidi::midi_in>> _midiIns;
#endif
};

#endif // MIDILIBREMIDI_H
