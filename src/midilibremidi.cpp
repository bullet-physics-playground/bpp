/**
 * @file midilibremidi.cpp
 * @brief libremidi backend for MidiInterface.
 *
 * Only compiled when USE_LIBREMIDI=1; see bpp.pro.
 */

#include "midilibremidi.h"

#if USE_LIBREMIDI

#include <cstring>

MidiInterfaceLibremidi::MidiInterfaceLibremidi(QObject *parent)
    : MidiInterface(parent)
{
    // Deliver incoming messages to onMessage(), which emits messageReceived().
    _conf.on_message = [this](libremidi::message &&msg) {
        onMessage(std::move(msg));
    };
}

MidiInterfaceLibremidi::~MidiInterfaceLibremidi()
{
    close();
}

bool MidiInterfaceLibremidi::open()
{
#if USE_LIBREMIDI
    if (!_midiIns.empty())
        return true;

    try {
        libremidi::observer observer;
        const std::vector<libremidi::input_port> ports =
            observer.get_input_ports();
        if (ports.empty())
            return false;

        // Open every available input port so all MIDI devices are connected
        // by default. Individual ports can later be toggled from the MIDI
        // menu via openPort()/closePort().
        int index = 0;
        for (const libremidi::input_port &port : ports) {
            auto midiIn = std::make_unique<libremidi::midi_in>(_conf);
            const stdx::error err = midiIn->open_port(port);
            if (err == stdx::error{})
                _midiIns[index] = std::move(midiIn);
            ++index;
        }
    } catch (...) {
        _midiIns.clear();
        return false;
    }
    return !_midiIns.empty();
#else
    return true;
#endif
}

void MidiInterfaceLibremidi::close()
{
#if USE_LIBREMIDI
    for (auto &kv : _midiIns) {
        kv.second.reset();
    }
    _midiIns.clear();
#endif
}

bool MidiInterfaceLibremidi::isOpen() const
{
#if USE_LIBREMIDI
    return !_midiIns.empty();
#else
    return false;
#endif
}

QStringList MidiInterfaceLibremidi::portNames() const
{
    QStringList names;
#if USE_LIBREMIDI
    try {
        libremidi::observer observer;
        for (const libremidi::input_port &port :
             observer.get_input_ports())
            names << QString::fromStdString(port.port_name);
    } catch (...) {
        // Ignore: port enumeration is best effort.
    }
#endif
    return names;
}

bool MidiInterfaceLibremidi::openPort(int index)
{
#if USE_LIBREMIDI
    if (_midiIns.count(index))
        return true;

    try {
        libremidi::observer observer;
        const std::vector<libremidi::input_port> ports =
            observer.get_input_ports();
        if (index < 0 || index >= (int)ports.size())
            return false;

        auto midiIn = std::make_unique<libremidi::midi_in>(_conf);
        const stdx::error err = midiIn->open_port(ports[index]);
        if (err != stdx::error{})
            return false;

        _midiIns[index] = std::move(midiIn);
        return true;
    } catch (...) {
        return false;
    }
#else
    return false;
#endif
}

void MidiInterfaceLibremidi::closePort(int index)
{
#if USE_LIBREMIDI
    auto it = _midiIns.find(index);
    if (it != _midiIns.end()) {
        it->second.reset();
        _midiIns.erase(it);
    }
#endif
}

bool MidiInterfaceLibremidi::isPortOpen(int index) const
{
#if USE_LIBREMIDI
    return _midiIns.count(index) > 0 &&
           _midiIns.at(index)->is_port_open();
#else
    return false;
#endif
}

void MidiInterfaceLibremidi::onMessage(libremidi::message &&msg)
{
    QByteArray data;
    if (!msg.bytes.empty()) {
        data.resize(msg.bytes.size());
        std::memcpy(data.data(), msg.bytes.data(), msg.bytes.size());
    }
    emit messageReceived(data);
}

#endif // USE_LIBREMIDI
