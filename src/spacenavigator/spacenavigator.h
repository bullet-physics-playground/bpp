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
     * \var Axes::x      translation along the X axis (delta)
     * \var Axes::y      translation along the Y axis (delta)
     * \var Axes::z      translation along the Z axis (delta)
     * \var Axes::rx     rotation around the X axis (delta)
     * \var Axes::ry     rotation around the Y axis (delta)
     * \var Axes::rz     rotation around the Z axis (delta)
     */
    struct Axes
    {
        int x = 0, y = 0, z = 0;
        int rx = 0, ry = 0, rz = 0;
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
        double x = 0.0, y = 0.0, z = 0.0;
        double rx = 0.0, ry = 0.0, rz = 0.0;
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
    bool openAuto();
    bool openPath(const QString &path);
    void closePlatform();
    void resetState();
    void handleAxisDelta(int index, int delta);
    void handleAxisAbsolute(int index, int value);
    void handleButton(int button, bool pressed);
    void emitAxes();
    void onReadyRead();
    void onReadComplete();
    void setNormalized(int index, double deflection);
#if defined(Q_OS_LINUX)
    void updateAxisRanges(int fd);
#endif
#if defined(Q_OS_WIN)
    void startWindowsRead();
    void parseWindowsReport(const unsigned char *data, int len);
    void parseWindowsReportRaw(const unsigned char *data, int len);
    void updateWindowsAxisRanges();
#endif
#if defined(Q_OS_MACOS)
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
