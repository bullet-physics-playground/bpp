/*!
 * \file spacenavigator.h
 * \brief Qt5 class for 3Dconnexion SpaceNavigator 3D mice.
 *
 * Port of the HAVE_SPACENAV code from rm501.c
 * (Mitsubishi RM-501 Movemaster II Robot Simulator) to a reusable,
 * event-driven Qt5/C++ class.
 *
 * \section backends Platform backends
 *   - Linux   : evdev (/dev/input/event*), watched with QSocketNotifier
 *   - macOS   : IOKit HID Manager, values delivered on the main run loop
 *   - Windows : raw HID (SetupAPI + HidP) with overlapped I/O + QWinEventNotifier
 *
 * No polling thread is needed on any platform.  Drop
 * spacenavigator.{h,cpp} into your project, add both files to your
 * build, and connect to the signals.
 *
 * Copyright (C) 2013-2026 Jakob Flierl <jakob.flierl@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef SPACENAVIGATOR_H
#define SPACENAVIGATOR_H

#include <QObject>
#include <QString>

struct PlatformData;
struct __IOHIDValue;

/*!
 * \brief Event-driven Qt5 interface to a 3Dconnexion/L3D SpaceNavigator.
 *
 * Reads the six axes (X Y Z RX RY RZ) and the two buttons (BTN_0,
 * BTN_1) reported by 3D mice on Linux (evdev), macOS (IOKit HID) and
 * Windows (raw HID).
 *
 * The device is opened and closed with the open() overloads and
 * close().  All events are delivered through signals, driven by Qt's
 * event loop, so no explicit polling is required (poll() is provided
 * for compatibility on Linux).
 *
 * \note axesChanged() reports the incremental movement since the
 *       previous event, i.e. a delta.  On absolute devices (macOS,
 *       Windows, Linux EV_ABS) the delta is the difference to the
 *       previous reading; on relative devices (Linux EV_REL) it is the
 *       event value.  This is the quantity a jogging consumer should
 *       multiply by a speed constant.
 *
 * \sa buttonChanged(), deviceOpened(), deviceClosed(), error()
 */
class SpaceNavigator : public QObject
{
    Q_OBJECT

public:
    /*!
     * \brief Raw axis values, ordered X Y Z RX RY RZ.
     *
     * Every component is a delta, as documented in the class description.
     */
    struct Axes
    {
        int x = 0,  //!< Translation along the X axis (delta).
            y = 0,  //!< Translation along the Y axis (delta).
            z = 0;  //!< Translation along the Z axis (delta).
        int rx = 0, //!< Rotation around the X axis (delta).
            ry = 0, //!< Rotation around the Y axis (delta).
            rz = 0; //!< Rotation around the Z axis (delta).
    };

    /*!
     * \brief Axis deflections normalised to the range [-1, 1].
     *
     * Computed from the absolute readings and the device's actual axis
     * range (queried on Linux via EVIOCGABS), so that one device report
     * can be treated as a velocity: the camera keeps moving while the
     * cap is deflected, proportional to the deflection.
     */
    struct AxesNorm
    {
        double x = 0.0,  //!< Translation along the X axis, in [-1, 1].
               y = 0.0,  //!< Translation along the Y axis, in [-1, 1].
               z = 0.0;  //!< Translation along the Z axis, in [-1, 1].
        double rx = 0.0, //!< Rotation around the X axis, in [-1, 1].
               ry = 0.0, //!< Rotation around the Y axis, in [-1, 1].
               rz = 0.0; //!< Rotation around the Z axis, in [-1, 1].
    };

    /// Number of reportable axes (X Y Z RX RY RZ).
    static const int NUM_AXES = 6;

    /// Number of reportable buttons (BTN_0, BTN_1).
    static const int NUM_BUTTONS = 2;

    /// Minimum absolute axis value that counts as movement (dead zone).
    static const int JOG_MIN = 15;

    /*!
     * \brief Constructs a SpaceNavigator with the given \a parent.
     *
     * No device is opened until one of the open() overloads is called.
     */
    explicit SpaceNavigator(QObject *parent = nullptr);

    /*!
     * \brief Destructor; closes the device if it is still open.
     */
    ~SpaceNavigator() override;

    /*!
     * \brief Auto-detect and open a supported 3D mouse.
     *
     * \return true on success, false if no supported device was found.
     *
     * \sa open(int), open(const QString &)
     */
    bool open();

    /*!
     * \brief Open a device selected by \a index.
     *
     * The meaning of \a index depends on the platform:
     *   - Linux:   /dev/input/event<index>
     *   - Windows: the index-th 3D mouse found during enumeration
     *   - macOS:   ignored, auto-detect is performed
     *
     * \return true on success.
     */
    bool open(int index);

    /*!
     * \brief Open the device given by \a path.
     *
     * The meaning of \a path depends on the platform:
     *   - Linux:   a device node, e.g. "/dev/input/event5"
     *   - Windows: an HID device interface path
     *   - macOS:   ignored, auto-detect is performed
     *
     * \return true on success.
     */
    bool open(const QString &path);

    /*!
     * \brief Close the device if open.
     *
     * Emits deviceClosed().  Calling this on a closed device is safe.
     */
    void close();

    /*!
     * \brief Returns true if a device is currently open.
     */
    bool isOpen() const;

    /*!
     * \brief Returns a platform-specific description of the open device
     *        (device node on Linux, HID path on Windows, product name on
     *        macOS), or an empty string if closed.
     *
     * This is the string open(const QString &) expects, not something to put
     * in front of a user; deviceName() is the readable one.
     */
    QString devicePath() const;

    /*!
     * \brief Returns the product name the device reports, for display.
     *
     * Taken from the USB product string (EVIOCGNAME on Linux,
     * HidD_GetProductString on Windows, kIOHIDProductKey on macOS), for
     * example "3Dconnexion Universal Receiver".  Falls back to devicePath()
     * when the device reports no name, and is empty when closed.
     */
    QString deviceName() const;

    /*!
     * \brief Read all currently pending events.
     *
     * Only meaningful on Linux (the socket notifier calls this
     * automatically); no-op on macOS and Windows.
     */
    void poll();

    /*!
     * \brief Last absolute axis readings.
     *
     * Only meaningful on absolute devices (macOS, Windows, Linux
     * EV_ABS); all zero on relative devices.
     */
    Axes absolute() const;

    /*!
     * \brief Current axis deflections normalised to [-1, 1].
     *
     * \sa AxesNorm, axesNormChanged()
     */
    AxesNorm normalized() const;

signals:
    /*!
     * \brief Emitted whenever one of the six axes changes.
     *
     * \param axes delta since the previous event, as documented in the
     *             class description.
     */
    void axesChanged(const SpaceNavigator::Axes &axes);

    /*!
     * \brief Emitted whenever one of the six axes changes.
     *
     * \param axes normalised deflections in [-1, 1], suitable for
     *             velocity-style camera control.
     */
    void axesNormChanged(const SpaceNavigator::AxesNorm &axes);

    /*!
     * \brief Emitted when a button state changes.
     *
     * \param button  button number, 0 or 1 (BTN_0, BTN_1).
     * \param pressed true when pressed, false when released.
     */
    void buttonChanged(int button, bool pressed);

    /*!
     * \brief Emitted when a device has been opened successfully.
     */
    void deviceOpened();

    /*!
     * \brief Emitted when the device has been closed.
     */
    void deviceClosed();

    /*!
     * \brief Emitted on errors (open failures, read failures).
     *
     * \param message human-readable error description.
     */
    void error(const QString &message);

private:
    /*!
     * \brief Find and open the first supported 3D mouse.
     *
     * Platform-specific: scans the evdev nodes on Linux, enumerates the HID
     * interfaces on Windows, and matches on vendor id on macOS.
     *
     * \return true if a device was opened.
     */
    bool openAuto();

    /*!
     * \brief Open one named device and start delivering its events.
     *
     * Checks that the device really is a 3D mouse, resets the axis state,
     * learns the axis ranges from it and hooks it into the event loop.
     * Emits error() and returns false if any of that fails.
     *
     * \param path platform-specific device identifier, as for
     *             open(const QString &).
     * \return true on success.
     */
    bool openPath(const QString &path);

    /*!
     * \brief Release the platform handles and emit deviceClosed().
     *
     * Safe to call when nothing is open.
     */
    void closePlatform();

    /*!
     * \brief Zero the axis and button state and restore the nominal ranges.
     *
     * The scale factors are the SpaceNavigator's nominal ranges, about +-512
     * for translation and +-900 for rotation; where the platform can report
     * the real range it is queried afterwards and overwrites these.
     */
    void resetState();

    /*!
     * \brief Record a relative axis reading and publish it.
     *
     * For devices that report movement rather than position (Linux EV_REL).
     *
     * \param index axis index, 0 to \c NUM_AXES-1; out of range is ignored.
     * \param delta movement since the previous event.
     */
    void handleAxisDelta(int index, int delta);

    /*!
     * \brief Record an absolute axis reading.
     *
     * Stores the reading, derives the delta from the previous one and
     * normalises the deflection about the axis centre. Does not publish
     * anything; the caller emits once the whole report has been decoded.
     *
     * \param index axis index, 0 to \c NUM_AXES-1; out of range is ignored.
     * \param value the absolute reading.
     */
    void handleAxisAbsolute(int index, int value);

    /*!
     * \brief Record a button state and emit buttonChanged() if it changed.
     *
     * \param button  button number; out of range is ignored.
     * \param pressed true when pressed.
     */
    void handleButton(int button, bool pressed);

    /*!
     * \brief Emit axesChanged() and axesNormChanged() with the current state.
     */
    void emitAxes();

    /*!
     * \brief Slot for the socket notifier; reads whatever is pending.
     *
     * Linux only; a no-op on the other platforms, which are driven by their
     * own callbacks.
     */
    void onReadyRead();

    /*!
     * \brief Handle a completed overlapped read and start the next one.
     *
     * Windows only.
     */
    void onReadComplete();

    /*!
     * \brief Scale one axis deflection into [-1, 1] and store it.
     *
     * \param index      axis index, 0 to \c NUM_AXES-1; out of range is
     *                   ignored.
     * \param deflection raw deflection from the axis centre; the result is
     *                   clamped to the range.
     */
    void setNormalized(int index, double deflection);
#if defined(Q_OS_LINUX)
    /*!
     * \brief Learn the real axis ranges from the driver.
     *
     * Queries EVIOCGABS for each axis and derives the centre and scale used
     * by setNormalized(), replacing the nominal values from resetState().
     * Axes the driver does not describe keep those defaults.
     *
     * \param fd open file descriptor of the device node.
     */
    void updateAxisRanges(int fd);
#endif
#if defined(Q_OS_WIN)
    /*!
     * \brief Queue the next overlapped read from the HID device.
     *
     * The buffer is cleared first, because a short report - the button report
     * is shorter than the axis report - would otherwise leave the tail of the
     * previous one in place.
     */
    void startWindowsRead();

    /*!
     * \brief Decode one HID input report.
     *
     * The byte layout differs between models: the wired SpaceNavigator splits
     * the axes over report 1 (translation) and report 2 (rotation), while the
     * SpaceMouse Wireless packs all six into report 1 and puts the buttons in
     * report 3. Rather than hard-coding any of that, the HidP_* functions are
     * asked which usages this particular report carries, which works for every
     * 3Dconnexion model. Falls back to parseWindowsReportRaw() when the report
     * descriptor is unavailable.
     *
     * \param data report bytes, starting with the report id.
     * \param len  number of bytes.
     */
    void parseWindowsReport(const unsigned char *data, int len);

    /*!
     * \brief Fallback decoder for the standard 3Dconnexion report layout.
     *
     * Used only when the report descriptor is unavailable, so the usages
     * cannot be looked up.
     *
     * \param data report bytes, starting with the report id.
     * \param len  number of bytes.
     */
    void parseWindowsReportRaw(const unsigned char *data, int len);

    /*!
     * \brief Take the axis centre and scale from the HID report descriptor.
     *
     * The nominal ranges guessed in resetState() are wrong for most models -
     * a SpaceMouse Wireless reports +-350, not +-512 - which would keep the
     * deflections short of full scale, so the descriptor is asked for the real
     * logical range.
     */
    void updateWindowsAxisRanges();
#endif
#if defined(Q_OS_MACOS)
    /*!
     * \brief IOKit callback delivering one changed HID element.
     *
     * Runs on the main run loop, so it can update the state and emit signals
     * directly.
     *
     * \param context the SpaceNavigator the callback was registered for.
     * \param result  IOKit result code; unused.
     * \param sender  IOKit sender; unused.
     * \param value   the HID value that changed.
     */
    static void macInputValueCallback(void *context, int result, void *sender,
                                      struct __IOHIDValue *value);
#endif

    /// Platform-specific state (evdev fd, IOHIDManager, HID handle...).
    PlatformData *m_platform;

    /// Current axis deltas, indexed as X Y Z RX RY RZ.
    int m_pos[NUM_AXES];

    /// Current button states, 0 or 1 per button.
    int m_key[NUM_BUTTONS];

    /// Last absolute axis readings.
    Axes m_abs;

    /// Previous absolute axis readings, used to compute deltas.
    int m_lastAxis[NUM_AXES];

    /// Normalised axis deflections in [-1, 1].
    AxesNorm m_norm;

    /// Axis centre values (zero for symmetric devices).
    int m_axisCenter[NUM_AXES];

    /// Scale factors mapping raw axis values to [-1, 1].
    double m_axisScale[NUM_AXES];
};

#endif // SPACENAVIGATOR_H
