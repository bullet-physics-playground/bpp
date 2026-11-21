#ifndef MIDI_H
#define MIDI_H

/**
 * @file midi.h
 * @brief MIDI input, independent of any particular backend.
 *
 * MidiInterface is the backend-agnostic handle the Viewer uses to receive
 * MIDI data. A concrete subclass (libremidi, or the no-op MidiInterfaceNull
 * used when libremidi is not enabled) owns the device and emits
 * messageReceived() whenever bytes arrive.
 *
 * The Viewer connects messageReceived() to its onMidiData() slot and forwards
 * the bytes to the script's v:onMIDIReceived(frameNum, data) hook.
 */

#include <QByteArray>
#include <QObject>
#include <QStringList>

class MidiInterface : public QObject
{
    Q_OBJECT

public:
    explicit MidiInterface(QObject *parent = nullptr);
    virtual ~MidiInterface();

    /** @brief Opens the default MIDI input port. False if none is available. */
    virtual bool open() = 0;
    /** @brief Closes all ports. Safe to call when already closed. */
    virtual void close() = 0;
    /** @brief True while any port is open. */
    virtual bool isOpen() const = 0;
    /** @brief Human-readable names of the available input ports. */
    virtual QStringList portNames() const = 0;
    /** @brief Opens the input port at the given index. False on failure. */
    virtual bool openPort(int index) = 0;
    /** @brief Closes the input port at the given index. Safe when already closed. */
    virtual void closePort(int index) = 0;
    /** @brief True while the port at the given index is open. */
    virtual bool isPortOpen(int index) const = 0;

signals:
    /** @brief Emitted when MIDI bytes arrive, on whichever thread the backend uses. */
    void messageReceived(const QByteArray &data);
};

/**
 * @brief No-op MIDI backend, used when libremidi is not enabled.
 *
 * open() reports failure, so no port is ever opened and messageReceived() is
 * never emitted. A script can still set v:onMIDIReceived; it simply never
 * hears of any MIDI data.
 */
class MidiInterfaceNull : public MidiInterface
{
public:
    using MidiInterface::MidiInterface;

    bool open() override { return false; }
    void close() override {}
    bool isOpen() const override { return false; }
    QStringList portNames() const override { return {}; }
    bool openPort(int) override { return false; }
    void closePort(int) override {}
    bool isPortOpen(int) const override { return false; }
};

#endif // MIDI_H
