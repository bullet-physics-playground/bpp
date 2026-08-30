/*
 * spacenavigator.cpp - Qt5 class for 3Dconnexion SpaceNavigator 3D mice
 *
 * Port of the HAVE_SPACENAV code from rm501.c to a reusable, event-driven
 * Qt5/C++ class.
 *
 *   Linux   : evdev (/dev/input/event*)  via QSocketNotifier
 *   macOS   : IOKit HID Manager          via main run loop callback
 *   Windows : raw HID (SetupAPI + HidP)  via overlapped I/O + QWinEventNotifier
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

#include "spacenavigator.h"

#include <QStringList>
#include <cstdint>
#include <cstring>

#if defined(Q_OS_LINUX)
#include <QSocketNotifier>
#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <cerrno>
#include <cstdio>
#endif

#if defined(Q_OS_MACOS)
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDUsageTables.h>
#include <vector>
#endif

#if defined(Q_OS_WIN)
#include <QWinEventNotifier>
#include <windows.h>
#include <hidsdi.h>
#include <setupapi.h>
#include <algorithm>
#include <string>
#include <vector>
#endif

#if defined(Q_OS_LINUX)
struct PlatformData
{
  int fd;
  QString path;
  QString name;
  QSocketNotifier *notifier;
};
#elif defined(Q_OS_MACOS)
struct PlatformData
{
  IOHIDManagerRef manager;
  QString path;
  QString name;
};
#elif defined(Q_OS_WIN)
struct PlatformData
{
  HANDLE file;
  QString path;
  QString name;
  HANDLE readEvent;
  OVERLAPPED ov;
  QWinEventNotifier *notifier;
  std::vector<unsigned char> buffer;

  /// Report descriptor of the open collection, kept for HidP_* decoding.
  PHIDP_PREPARSED_DATA preparsed;
  HIDP_CAPS caps;

  /// Bit width and signedness of each axis, from the report descriptor.
  int axisBits[SpaceNavigator::NUM_AXES];
  bool axisSigned[SpaceNavigator::NUM_AXES];

  /// Buffer size HidP_GetUsages() needs for the button page.
  ULONG buttonListLength;
};
#else
struct PlatformData
{
};
#endif

namespace
{

const quint16 USB_VENDOR_ID_LOGITECH = 0x046d;
const quint16 USB_DEVICE_ID_SPACENAVIGATOR = 0xc626;
const quint16 USB_DEVICE_ID_SPACETRAVELLER = 0xc623;
const quint16 USB_DEVICE_ID_SPACEBALL_5000 = 0xc603;
const quint16 USB_VENDOR_ID_3DCONNEXION = 0x256f;

const int MAX_DEVICES = 64;

#if defined(Q_OS_WIN)
void winEnumerate3DMice(QStringList &out);
#endif

} // namespace

SpaceNavigator::SpaceNavigator(QObject *parent)
  : QObject(parent)
  , m_platform(nullptr)
{
  resetState();
}

SpaceNavigator::~SpaceNavigator()
{
  close();
}

void SpaceNavigator::resetState()
{
  std::memset(m_pos, 0, sizeof(m_pos));
  std::memset(m_key, 0, sizeof(m_key));
  m_abs = Axes();
  std::memset(m_lastAxis, 0, sizeof(m_lastAxis));
  m_norm = AxesNorm();
  for (int i = 0; i < NUM_AXES; i++)
  {
    m_axisCenter[i] = 0;
    // SpaceNavigator nominal ranges: ~±512 for translation, ~±900 for
    // rotation.  Real ranges are queried on Linux (updateAxisRanges).
    m_axisScale[i] = (i < 3) ? 1.0 / 512.0 : 1.0 / 900.0;
  }
}

bool SpaceNavigator::isOpen() const
{
  return m_platform != nullptr;
}

QString SpaceNavigator::devicePath() const
{
  return m_platform ? m_platform->path : QString();
}

QString SpaceNavigator::deviceName() const
{
  if (!m_platform)
  {
    return QString();
  }
  // Not every device fills its product string in; the path is at least
  // something the user can act on.
  return m_platform->name.isEmpty() ? m_platform->path : m_platform->name;
}

SpaceNavigator::Axes SpaceNavigator::absolute() const
{
  return m_abs;
}

SpaceNavigator::AxesNorm SpaceNavigator::normalized() const
{
  return m_norm;
}

bool SpaceNavigator::open()
{
  close();
  return openAuto();
}

bool SpaceNavigator::open(int index)
{
  close();
#if defined(Q_OS_LINUX)
  if (index < 0 || index >= MAX_DEVICES)
  {
    return false;
  }
  return openPath(QStringLiteral("/dev/input/event%1").arg(index));
#elif defined(Q_OS_WIN)
  QStringList devices;
  winEnumerate3DMice(devices);
  if (index < 0 || index >= devices.size())
  {
    return false;
  }
  return openPath(devices.at(index));
#else
  Q_UNUSED(index);
  return openAuto();
#endif
}

bool SpaceNavigator::open(const QString &path)
{
  close();
#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
  return openPath(path);
#else
  Q_UNUSED(path);
  return openAuto();
#endif
}

void SpaceNavigator::close()
{
  if (m_platform)
  {
    closePlatform();
  }
}

void SpaceNavigator::closePlatform()
{
  if (!m_platform)
  {
    return;
  }

#if defined(Q_OS_LINUX)
  if (m_platform->notifier)
  {
    m_platform->notifier->setEnabled(false);
    delete m_platform->notifier;
    m_platform->notifier = nullptr;
  }
  if (m_platform->fd >= 0)
  {
    ::close(m_platform->fd);
    m_platform->fd = -1;
  }
#elif defined(Q_OS_MACOS)
  if (m_platform->manager)
  {
    IOHIDManagerUnscheduleFromRunLoop(m_platform->manager,
                                      CFRunLoopGetMain(),
                                      kCFRunLoopCommonModes);
    IOHIDManagerClose(m_platform->manager, kIOHIDOptionsTypeNone);
    CFRelease(m_platform->manager);
    m_platform->manager = nullptr;
  }
#elif defined(Q_OS_WIN)
  if (m_platform->notifier)
  {
    // close() runs from the notifier's own activated() handler when a read
    // fails, so the notifier must outlive the emission.
    m_platform->notifier->setEnabled(false);
    m_platform->notifier->disconnect(this);
    m_platform->notifier->deleteLater();
    m_platform->notifier = nullptr;
  }
  if (m_platform->file != INVALID_HANDLE_VALUE)
  {
    // Wait for the pending read to finish unwinding: the OVERLAPPED lives in
    // m_platform, which is freed a few lines below.
    CancelIoEx(m_platform->file, &m_platform->ov);
    DWORD transferred = 0;
    GetOverlappedResult(m_platform->file, &m_platform->ov, &transferred, TRUE);
    CloseHandle(m_platform->file);
    m_platform->file = INVALID_HANDLE_VALUE;
  }
  if (m_platform->preparsed)
  {
    HidD_FreePreparsedData(m_platform->preparsed);
    m_platform->preparsed = nullptr;
  }
  if (m_platform->readEvent)
  {
    CloseHandle(m_platform->readEvent);
    m_platform->readEvent = nullptr;
  }
#endif

  delete m_platform;
  m_platform = nullptr;
  emit deviceClosed();
}

void SpaceNavigator::handleAxisDelta(int index, int delta)
{
  if (index < 0 || index >= NUM_AXES)
  {
    return;
  }
  m_pos[index] = delta;
  setNormalized(index, static_cast<double>(delta));
  emitAxes();
}

void SpaceNavigator::handleAxisAbsolute(int index, int value)
{
  if (index < 0 || index >= NUM_AXES)
  {
    return;
  }
  const int delta = value - m_lastAxis[index];
  m_lastAxis[index] = value;
  switch (index)
  {
  case 0: m_abs.x = value; break;
  case 1: m_abs.y = value; break;
  case 2: m_abs.z = value; break;
  case 3: m_abs.rx = value; break;
  case 4: m_abs.ry = value; break;
  case 5: m_abs.rz = value; break;
  }
  m_pos[index] = delta;
  setNormalized(index, static_cast<double>(value - m_axisCenter[index]));
}

void SpaceNavigator::setNormalized(int index, double deflection)
{
  if (index < 0 || index >= NUM_AXES)
  {
    return;
  }
  double v = deflection * m_axisScale[index];
  if (v > 1.0) v = 1.0;
  else if (v < -1.0) v = -1.0;
  switch (index)
  {
  case 0: m_norm.x = v; break;
  case 1: m_norm.y = v; break;
  case 2: m_norm.z = v; break;
  case 3: m_norm.rx = v; break;
  case 4: m_norm.ry = v; break;
  case 5: m_norm.rz = v; break;
  }
}

void SpaceNavigator::handleButton(int button, bool pressed)
{
  if (button < 0 || button >= NUM_BUTTONS)
  {
    return;
  }
  const int value = pressed ? 1 : 0;
  if (m_key[button] == value)
  {
    return;
  }
  m_key[button] = value;
  emit buttonChanged(button, pressed);
}

void SpaceNavigator::emitAxes()
{
  Axes axes;
  axes.x = m_pos[0];
  axes.y = m_pos[1];
  axes.z = m_pos[2];
  axes.rx = m_pos[3];
  axes.ry = m_pos[4];
  axes.rz = m_pos[5];
  emit axesChanged(axes);
  emit axesNormChanged(m_norm);
}

#if defined(Q_OS_LINUX)

#define test_bit(bit, array) (array[(bit) / 8] & (1 << ((bit) % 8)))

namespace
{

bool linuxIs3DMouse(int fd)
{
  struct input_id id;
  if (ioctl(fd, EVIOCGID, &id) < 0)
  {
    return false;
  }

  if (id.vendor == USB_VENDOR_ID_LOGITECH)
  {
    return id.product == USB_DEVICE_ID_SPACENAVIGATOR ||
           id.product == USB_DEVICE_ID_SPACETRAVELLER ||
           id.product == USB_DEVICE_ID_SPACEBALL_5000;
  }

  if (id.vendor != USB_VENDOR_ID_3DCONNEXION)
  {
    return false;
  }

  // 3Dconnexion 3D mice (including the Universal Receiver) report
  // translation/rotation as six absolute axes: X Y Z RX RY RZ.
  unsigned char abs_bits[(ABS_MAX + 7) / 8] = {0};
  if (ioctl(fd, EVIOCGBIT(EV_ABS, sizeof(abs_bits)), abs_bits) < 0)
  {
    return false;
  }

  return test_bit(ABS_X, abs_bits) && test_bit(ABS_Y, abs_bits) &&
         test_bit(ABS_Z, abs_bits) && test_bit(ABS_RX, abs_bits) &&
         test_bit(ABS_RY, abs_bits) && test_bit(ABS_RZ, abs_bits);
}

/// The product string the driver reports, empty when there is none.
QString linuxDeviceName(int fd)
{
  char name[256] = {0};
  if (ioctl(fd, EVIOCGNAME(sizeof(name) - 1), name) < 0)
  {
    return QString();
  }
  return QString::fromUtf8(name).trimmed();
}

int linuxOpenDevice(const QString &path)
{
  // Prefer read/write like rm501.c, fall back to read-only when we lack
  // permission to write (common with plain udev rules).
  int fd = ::open(path.toUtf8().constData(), O_RDWR | O_NONBLOCK);
  if (fd < 0 && (errno == EACCES || errno == EPERM))
  {
    fd = ::open(path.toUtf8().constData(), O_RDONLY | O_NONBLOCK);
  }
  return fd;
}

} // namespace

void SpaceNavigator::updateAxisRanges(int fd)
{
  static const int absCodes[NUM_AXES] =
      {ABS_X, ABS_Y, ABS_Z, ABS_RX, ABS_RY, ABS_RZ};
  for (int i = 0; i < NUM_AXES; i++)
  {
    struct input_absinfo info;
    if (ioctl(fd, EVIOCGABS(absCodes[i]), &info) == 0 &&
        info.maximum > info.minimum)
    {
      m_axisCenter[i] = (info.maximum + info.minimum) / 2;
      m_axisScale[i] = 2.0 / (info.maximum - info.minimum);
    }
  }
}

bool SpaceNavigator::openAuto()
{
  for (int i = 0; i < MAX_DEVICES; i++)
  {
    const QString path = QStringLiteral("/dev/input/event%1").arg(i);
    const int fd = linuxOpenDevice(path);
    if (fd < 0)
    {
      continue;
    }
    const bool match = linuxIs3DMouse(fd);
    ::close(fd);
    if (match)
    {
      return openPath(path);
    }
  }
  return false;
}

bool SpaceNavigator::openPath(const QString &path)
{
  const int fd = linuxOpenDevice(path);
  if (fd < 0)
  {
    emit error(QStringLiteral("Unable to open %1: %2")
                 .arg(path, QString::fromUtf8(strerror(errno))));
    return false;
  }
  if (!linuxIs3DMouse(fd))
  {
    ::close(fd);
    emit error(QStringLiteral("%1 is not a 3Dconnexion 3D mouse").arg(path));
    return false;
  }

  resetState();
  updateAxisRanges(fd);
  m_platform = new PlatformData;
  m_platform->fd = fd;
  m_platform->path = path;
  m_platform->name = linuxDeviceName(fd);
  m_platform->notifier = new QSocketNotifier(fd, QSocketNotifier::Read, this);
  connect(m_platform->notifier, &QSocketNotifier::activated,
          this, &SpaceNavigator::onReadyRead);

  emit deviceOpened();
  return true;
}

void SpaceNavigator::poll()
{
  if (!m_platform)
  {
    return;
  }

  struct input_event ev;
  ssize_t n;
  bool axesUpdated = false;
  while ((n = ::read(m_platform->fd, &ev, sizeof(struct input_event))) > 0)
  {
    if (static_cast<size_t>(n) < sizeof(struct input_event))
    {
      continue;
    }
    if (ev.type == EV_KEY)
    {
      // Buttons are reported at BTN_0 (256) and BTN_1 (257).
      if (ev.code >= BTN_0 && ev.code < BTN_0 + NUM_BUTTONS)
      {
        handleButton(ev.code - BTN_0, ev.value != 0);
      }
    }
    else if (ev.type == EV_REL)
    {
      // REL events are deltas; forward them directly.
      if (ev.code < NUM_AXES)
      {
        handleAxisDelta(ev.code, ev.value);
        axesUpdated = true;
      }
    }
    else if (ev.type == EV_ABS)
    {
      if (ev.code < NUM_AXES)
      {
        handleAxisAbsolute(ev.code, ev.value);
        axesUpdated = true;
      }
    }
  }

  if (axesUpdated)
  {
    emitAxes();
  }
}

void SpaceNavigator::onReadyRead()
{
  poll();
}

#endif // Q_OS_LINUX

#if defined(Q_OS_MACOS)

namespace
{

CFDictionaryRef macVendorMatch(int vendor)
{
  CFMutableDictionaryRef dict =
      CFDictionaryCreateMutable(kCFAllocatorDefault, 1,
                                &kCFTypeDictionaryKeyCallBacks,
                                &kCFTypeDictionaryValueCallBacks);
  int value = vendor;
  CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &value);
  CFDictionaryAddValue(dict, CFSTR(kIOHIDVendorIDKey), number);
  CFRelease(number);
  return dict;
}

} // namespace

void SpaceNavigator::macInputValueCallback(void *context, int result, void *sender,
                                           struct __IOHIDValue *value)
{
  Q_UNUSED(result);
  Q_UNUSED(sender);
  SpaceNavigator *self = static_cast<SpaceNavigator *>(context);
  if (!self)
  {
    return;
  }

  IOHIDElementRef element = IOHIDValueGetElement(value);
  const uint32_t usagePage = IOHIDElementGetUsagePage(element);
  const uint32_t usage = IOHIDElementGetUsage(element);
  const CFIndex raw = IOHIDValueGetIntegerValue(value);

  // Generic Desktop page: X Y Z RX RY RZ are usages 0x30..0x35.
  if (usagePage == kHIDPage_GenericDesktop && usage >= 0x30 && usage <= 0x35)
  {
    // handleAxisAbsolute() only records the value; the signals that carry it
    // to the consumer come from emitAxes().
    self->handleAxisAbsolute(static_cast<int>(usage - 0x30), static_cast<int>(raw));
    self->emitAxes();
  }
  // Button page: usages 0x01..0x08 map to button 0..7.
  else if (usagePage == kHIDPage_Button && usage >= 1 && usage <= SpaceNavigator::NUM_BUTTONS)
  {
    self->handleButton(static_cast<int>(usage - 1), raw != 0);
  }
}

bool SpaceNavigator::openAuto()
{
  IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
  if (!manager)
  {
    return false;
  }

  // Match 3Dconnexion (0x256f) and legacy Logitech (0x046d) devices.
  CFMutableArrayRef matches =
      CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
  CFDictionaryRef match3d = macVendorMatch(USB_VENDOR_ID_3DCONNEXION);
  CFDictionaryRef matchLogitech = macVendorMatch(USB_VENDOR_ID_LOGITECH);
  CFArrayAppendValue(matches, match3d);
  CFArrayAppendValue(matches, matchLogitech);
  IOHIDManagerSetDeviceMatchingMultiple(manager, matches);
  CFRelease(match3d);
  CFRelease(matchLogitech);
  CFRelease(matches);

  IOHIDManagerRegisterInputValueCallback(manager, &SpaceNavigator::macInputValueCallback, this);
  IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), kCFRunLoopCommonModes);

  if (IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone) != kIOReturnSuccess)
  {
    IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    CFRelease(manager);
    return false;
  }

  resetState();
  m_platform = new PlatformData;
  m_platform->manager = manager;
  m_platform->path = QStringLiteral("3Dconnexion 3D mouse");

  // IOHIDManagerCopyDevices() hands out a CFSet, not a CFArray.
  CFSetRef devices = IOHIDManagerCopyDevices(manager);
  if (devices)
  {
    const CFIndex count = CFSetGetCount(devices);
    if (count > 0)
    {
      std::vector<const void *> values(static_cast<size_t>(count), nullptr);
      CFSetGetValues(devices, values.data());
      IOHIDDeviceRef device =
          static_cast<IOHIDDeviceRef>(const_cast<void *>(values[0]));
      CFTypeRef product = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
      if (product && CFGetTypeID(product) == CFStringGetTypeID())
      {
        char buffer[128] = {0};
        if (CFStringGetCString(static_cast<CFStringRef>(product), buffer,
                               sizeof(buffer), kCFStringEncodingUTF8))
        {
          m_platform->path = QString::fromUtf8(buffer);
          m_platform->name = m_platform->path;
        }
      }
    }
    CFRelease(devices);
  }

  emit deviceOpened();
  return true;
}

bool SpaceNavigator::openPath(const QString &path)
{
  Q_UNUSED(path);
  return openAuto();
}

void SpaceNavigator::poll()
{
}

void SpaceNavigator::onReadyRead()
{
}

#endif // Q_OS_MACOS

#if defined(Q_OS_WIN)

namespace
{

/// Generic Desktop page; X Y Z RX RY RZ live there as usages 0x30..0x35.
const USAGE HID_PAGE_GENERIC_DESKTOP = 0x01;
const USAGE HID_PAGE_BUTTON = 0x09;
const USAGE HID_USAGE_X = 0x30;
const USAGE HID_USAGE_MULTI_AXIS = 0x08;
const USAGE HID_USAGE_JOYSTICK = 0x04;
const USAGE HID_USAGE_GAMEPAD = 0x05;

bool winIsKnownVendor(USHORT vendor, USHORT product)
{
  if (vendor == USB_VENDOR_ID_3DCONNEXION)
  {
    return true;
  }
  if (vendor == USB_VENDOR_ID_LOGITECH)
  {
    return product == USB_DEVICE_ID_SPACENAVIGATOR ||
           product == USB_DEVICE_ID_SPACETRAVELLER ||
           product == USB_DEVICE_ID_SPACEBALL_5000;
  }
  return false;
}

/*!
 * True when this top-level collection is the one that reports the axes.
 *
 * A 3D mouse is a composite device and Windows hands out one HID device
 * interface per top-level collection, so a single SpaceMouse shows up as a
 * handful of paths.  Only one of them carries the motion data: the Generic
 * Desktop / Multi-Axis Controller collection.  The others are vendor-defined
 * collections used by 3DxWare for firmware and configuration, and they have
 * no input reports at all.
 *
 * The usage pair alone is not enough - checking that the collection really
 * declares the six Generic Desktop axes keeps us off the wrong collection on
 * models we have never seen.
 */
bool winIsAxisCollection(PHIDP_PREPARSED_DATA preparsed, const HIDP_CAPS &caps)
{
  if (caps.UsagePage != HID_PAGE_GENERIC_DESKTOP)
  {
    return false;
  }
  if (caps.Usage != HID_USAGE_MULTI_AXIS && caps.Usage != HID_USAGE_JOYSTICK &&
      caps.Usage != HID_USAGE_GAMEPAD)
  {
    return false;
  }
  if (caps.NumberInputValueCaps == 0)
  {
    return false;
  }

  std::vector<HIDP_VALUE_CAPS> values(caps.NumberInputValueCaps);
  USHORT count = caps.NumberInputValueCaps;
  if (HidP_GetValueCaps(HidP_Input, values.data(), &count, preparsed) !=
      HIDP_STATUS_SUCCESS)
  {
    return false;
  }

  for (USHORT i = 0; i < count; i++)
  {
    const HIDP_VALUE_CAPS &value = values[i];
    if (value.UsagePage != HID_PAGE_GENERIC_DESKTOP)
    {
      continue;
    }
    const USAGE first = value.IsRange ? value.Range.UsageMin : value.NotRange.Usage;
    const USAGE last = value.IsRange ? value.Range.UsageMax : value.NotRange.Usage;
    if (last >= HID_USAGE_X &&
        first < HID_USAGE_X + SpaceNavigator::NUM_AXES)
    {
      return true;
    }
  }
  return false;
}

/*!
 * Open a HID device interface.
 *
 * Enumeration passes \a access 0: a collection that another process or
 * Windows itself holds open refuses GENERIC_READ, but the attributes and the
 * report descriptor can always be queried through a handle with no access
 * rights at all, so probing that way never misses a device.
 */
HANDLE winOpen(const wchar_t *path, DWORD access, DWORD flags)
{
  return CreateFileW(path, access, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                     OPEN_EXISTING, flags, nullptr);
}

/// The product string the device reports, empty when it reports none.
QString winProductName(HANDLE file)
{
  wchar_t buffer[256];
  ZeroMemory(buffer, sizeof(buffer));
  // One wchar_t short of the buffer, so a device that fills it completely
  // still leaves the terminator fromWCharArray() looks for.
  if (!HidD_GetProductString(file, buffer, sizeof(buffer) - sizeof(wchar_t)))
  {
    return QString();
  }
  return QString::fromWCharArray(buffer).trimmed();
}

/// Sign-extend a raw HidP_GetUsageValue() result of \a bits width.
int winSignedValue(ULONG raw, int bits, bool isSigned)
{
  if (!isSigned || bits <= 0 || bits >= 32)
  {
    return static_cast<int>(raw);
  }
  const ULONG signBit = 1UL << (bits - 1);
  if (raw & signBit)
  {
    return static_cast<int>(static_cast<LONG>(raw) -
                            static_cast<LONG>(1UL << bits));
  }
  return static_cast<int>(raw);
}

void winEnumerate3DMice(QStringList &out)
{
  GUID hidGuid;
  HidD_GetHidGuid(&hidGuid);

  // The W entry points are spelled out so that the code does not depend on
  // UNICODE being defined: the device path goes straight to QString.
  HDEVINFO devices = SetupDiGetClassDevsW(&hidGuid, nullptr, nullptr,
                                          DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
  if (devices == INVALID_HANDLE_VALUE)
  {
    return;
  }

  for (DWORD index = 0;; index++)
  {
    SP_DEVICE_INTERFACE_DATA interfaceData;
    ZeroMemory(&interfaceData, sizeof(interfaceData));
    interfaceData.cbSize = sizeof(interfaceData);
    if (!SetupDiEnumDeviceInterfaces(devices, nullptr, &hidGuid, index, &interfaceData))
    {
      break;
    }

    DWORD required = 0;
    SetupDiGetDeviceInterfaceDetailW(devices, &interfaceData, nullptr, 0, &required, nullptr);
    if (required == 0)
    {
      continue;
    }

    std::vector<BYTE> buffer(required);
    SP_DEVICE_INTERFACE_DETAIL_DATA_W *detail =
        reinterpret_cast<SP_DEVICE_INTERFACE_DETAIL_DATA_W *>(buffer.data());
    detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
    if (!SetupDiGetDeviceInterfaceDetailW(devices, &interfaceData, detail,
                                          required, nullptr, nullptr))
    {
      continue;
    }

    HANDLE file = winOpen(detail->DevicePath, 0, 0);
    if (file == INVALID_HANDLE_VALUE)
    {
      continue;
    }

    HIDD_ATTRIBUTES attributes;
    attributes.Size = sizeof(attributes);
    if (HidD_GetAttributes(file, &attributes) &&
        winIsKnownVendor(attributes.VendorID, attributes.ProductID))
    {
      PHIDP_PREPARSED_DATA preparsed = nullptr;
      if (HidD_GetPreparsedData(file, &preparsed))
      {
        HIDP_CAPS caps;
        if (HidP_GetCaps(preparsed, &caps) == HIDP_STATUS_SUCCESS &&
            winIsAxisCollection(preparsed, caps))
        {
          out.append(QString::fromWCharArray(detail->DevicePath));
        }
        HidD_FreePreparsedData(preparsed);
      }
    }
    CloseHandle(file);
  }

  SetupDiDestroyDeviceInfoList(devices);
}

} // namespace

bool SpaceNavigator::openAuto()
{
  QStringList devices;
  winEnumerate3DMice(devices);
  if (devices.isEmpty())
  {
    return false;
  }
  return openPath(devices.first());
}

bool SpaceNavigator::openPath(const QString &path)
{
  if (path.isEmpty())
  {
    return false;
  }

  const std::wstring native = path.toStdWString();

  // Reading is all we need; ask for write access as well only because some
  // models want an output report to drive their LED, and drop it when the
  // collection refuses it.
  HANDLE file = winOpen(native.c_str(), GENERIC_READ | GENERIC_WRITE,
                        FILE_FLAG_OVERLAPPED);
  if (file == INVALID_HANDLE_VALUE)
  {
    file = winOpen(native.c_str(), GENERIC_READ, FILE_FLAG_OVERLAPPED);
  }
  if (file == INVALID_HANDLE_VALUE)
  {
    emit error(QStringLiteral("Unable to open %1 (error %2)")
                 .arg(path)
                 .arg(GetLastError()));
    return false;
  }

  HIDD_ATTRIBUTES attributes;
  attributes.Size = sizeof(attributes);
  PHIDP_PREPARSED_DATA preparsed = nullptr;
  HIDP_CAPS caps;
  ZeroMemory(&caps, sizeof(caps));

  if (!HidD_GetAttributes(file, &attributes) ||
      !winIsKnownVendor(attributes.VendorID, attributes.ProductID) ||
      !HidD_GetPreparsedData(file, &preparsed))
  {
    if (preparsed)
    {
      HidD_FreePreparsedData(preparsed);
    }
    CloseHandle(file);
    emit error(QStringLiteral("%1 is not a supported 3D mouse").arg(path));
    return false;
  }

  if (HidP_GetCaps(preparsed, &caps) != HIDP_STATUS_SUCCESS ||
      !winIsAxisCollection(preparsed, caps))
  {
    HidD_FreePreparsedData(preparsed);
    CloseHandle(file);
    emit error(QStringLiteral("%1 does not report the six axes").arg(path));
    return false;
  }

  const int reportLength =
      caps.InputReportByteLength > 0 ? caps.InputReportByteLength : 64;

  resetState();
  m_platform = new PlatformData;
  m_platform->file = file;
  m_platform->path = path;
  m_platform->name = winProductName(file);
  m_platform->preparsed = preparsed;
  m_platform->caps = caps;
  m_platform->buttonListLength =
      HidP_MaxUsageListLength(HidP_Input, HID_PAGE_BUTTON, preparsed);
  for (int i = 0; i < NUM_AXES; i++)
  {
    m_platform->axisBits[i] = 16;
    m_platform->axisSigned[i] = true;
  }
  m_platform->readEvent = CreateEvent(nullptr, TRUE, FALSE, nullptr);
  m_platform->notifier = new QWinEventNotifier(m_platform->readEvent, this);
  m_platform->buffer.resize(reportLength);
  ZeroMemory(&m_platform->ov, sizeof(m_platform->ov));
  m_platform->ov.hEvent = m_platform->readEvent;
  connect(m_platform->notifier, &QWinEventNotifier::activated,
          this, &SpaceNavigator::onReadComplete);

  updateWindowsAxisRanges();

  emit deviceOpened();
  startWindowsRead();
  return true;
}

/*!
 * Take the axis centre and scale from the report descriptor.
 *
 * The nominal ranges guessed in resetState() are wrong for most models - a
 * SpaceMouse Wireless reports +-350, not +-512 - which would keep the meters
 * short of full scale, so ask the descriptor for the real logical range.
 */
void SpaceNavigator::updateWindowsAxisRanges()
{
  if (!m_platform || !m_platform->preparsed ||
      m_platform->caps.NumberInputValueCaps == 0)
  {
    return;
  }

  std::vector<HIDP_VALUE_CAPS> values(m_platform->caps.NumberInputValueCaps);
  USHORT count = m_platform->caps.NumberInputValueCaps;
  if (HidP_GetValueCaps(HidP_Input, values.data(), &count,
                        m_platform->preparsed) != HIDP_STATUS_SUCCESS)
  {
    return;
  }

  for (USHORT i = 0; i < count; i++)
  {
    const HIDP_VALUE_CAPS &value = values[i];
    if (value.UsagePage != HID_PAGE_GENERIC_DESKTOP)
    {
      continue;
    }
    const USAGE first = value.IsRange ? value.Range.UsageMin : value.NotRange.Usage;
    const USAGE last = value.IsRange ? value.Range.UsageMax : value.NotRange.Usage;

    for (USAGE usage = first; usage <= last; usage++)
    {
      const int axis = static_cast<int>(usage) - HID_USAGE_X;
      if (axis < 0 || axis >= NUM_AXES)
      {
        continue;
      }
      m_platform->axisBits[axis] = value.BitSize;
      m_platform->axisSigned[axis] = value.LogicalMin < 0;
      if (value.LogicalMax > value.LogicalMin)
      {
        m_axisCenter[axis] =
            static_cast<int>((value.LogicalMax + value.LogicalMin) / 2);
        m_axisScale[axis] =
            2.0 / static_cast<double>(value.LogicalMax - value.LogicalMin);
      }
    }
  }
}

void SpaceNavigator::startWindowsRead()
{
  if (!m_platform || m_platform->file == INVALID_HANDLE_VALUE)
  {
    return;
  }

  ResetEvent(m_platform->readEvent);
  ZeroMemory(&m_platform->ov, sizeof(m_platform->ov));
  m_platform->ov.hEvent = m_platform->readEvent;

  // A short report (the button report is shorter than the axis report) leaves
  // the tail of the buffer untouched, so clear it before every read.
  std::fill(m_platform->buffer.begin(), m_platform->buffer.end(), 0);

  const DWORD length = static_cast<DWORD>(m_platform->buffer.size());
  BOOL ok = ReadFile(m_platform->file, m_platform->buffer.data(),
                     length, nullptr, &m_platform->ov);
  if (!ok && GetLastError() != ERROR_IO_PENDING)
  {
    emit error(QStringLiteral("ReadFile failed: %1").arg(GetLastError()));
    close();
  }
}

void SpaceNavigator::onReadComplete()
{
  if (!m_platform || m_platform->file == INVALID_HANDLE_VALUE)
  {
    return;
  }

  DWORD transferred = 0;
  if (GetOverlappedResult(m_platform->file, &m_platform->ov, &transferred, FALSE) &&
      transferred > 0)
  {
    parseWindowsReport(m_platform->buffer.data(), static_cast<int>(transferred));
  }
  startWindowsRead();
}

/*!
 * Decode one input report.
 *
 * The byte layout differs between models: the wired SpaceNavigator splits the
 * axes over report 1 (translation) and report 2 (rotation), while the
 * SpaceMouse Wireless packs all six into report 1 and puts the buttons in
 * report 3.  Rather than hard-coding any of that, ask HidP_* for the usages
 * this particular report carries, which works for every 3Dconnexion model.
 */
void SpaceNavigator::parseWindowsReport(const unsigned char *data, int len)
{
  if (!m_platform || !data || len < 1)
  {
    return;
  }

  if (!m_platform->preparsed)
  {
    parseWindowsReportRaw(data, len);
    return;
  }

  // HidP_* rejects anything shorter than the declared input report length,
  // and startWindowsRead() has zeroed the tail for us.
  PCHAR report =
      reinterpret_cast<PCHAR>(const_cast<unsigned char *>(data));
  ULONG reportLen = m_platform->caps.InputReportByteLength;
  if (reportLen == 0 || reportLen > m_platform->buffer.size())
  {
    reportLen = static_cast<ULONG>(len);
  }

  // Axes: Generic Desktop usages 0x30..0x35.  A usage that this report does
  // not carry simply fails, which is how the split reports sort themselves
  // out.
  bool axesUpdated = false;
  for (int i = 0; i < NUM_AXES; i++)
  {
    ULONG raw = 0;
    if (HidP_GetUsageValue(HidP_Input, HID_PAGE_GENERIC_DESKTOP, 0,
                           static_cast<USAGE>(HID_USAGE_X + i), &raw,
                           m_platform->preparsed, report,
                           reportLen) != HIDP_STATUS_SUCCESS)
    {
      continue;
    }
    handleAxisAbsolute(i, winSignedValue(raw, m_platform->axisBits[i],
                                         m_platform->axisSigned[i]));
    axesUpdated = true;
  }

  if (axesUpdated)
  {
    emitAxes();
  }

  // Buttons: HidP_GetUsages() returns the pressed ones and fails with
  // HIDP_STATUS_INCOMPATIBLE_REPORT_ID on the axis reports, so an axis report
  // never releases a held button.
  if (m_platform->buttonListLength > 0)
  {
    std::vector<USAGE> usages(m_platform->buttonListLength);
    ULONG usageCount = m_platform->buttonListLength;
    if (HidP_GetUsages(HidP_Input, HID_PAGE_BUTTON, 0, usages.data(),
                       &usageCount, m_platform->preparsed, report,
                       reportLen) == HIDP_STATUS_SUCCESS)
    {
      bool pressed[NUM_BUTTONS] = {false};
      for (ULONG i = 0; i < usageCount; i++)
      {
        const int button = static_cast<int>(usages[i]) - 1;
        if (button >= 0 && button < NUM_BUTTONS)
        {
          pressed[button] = true;
        }
      }
      for (int i = 0; i < NUM_BUTTONS; i++)
      {
        handleButton(i, pressed[i]);
      }
    }
  }
}

/*!
 * Fallback decoder for the standard 3Dconnexion layout, used only when the
 * report descriptor is unavailable.
 */
void SpaceNavigator::parseWindowsReportRaw(const unsigned char *data, int len)
{
  const unsigned char reportId = data[0];
  const auto axisAt = [data](int index) {
    return static_cast<int>(static_cast<short>(
        data[1 + 2 * index] | (data[2 + 2 * index] << 8)));
  };

  if (reportId == 1 && len >= 7)
  {
    // Translation, plus rotation when the model sends all six at once.
    const int axes = (len >= 13) ? NUM_AXES : 3;
    for (int i = 0; i < axes; i++)
    {
      handleAxisAbsolute(i, axisAt(i));
    }
    emitAxes();
  }
  else if (reportId == 2 && len >= 7)
  {
    for (int i = 0; i < 3; i++)
    {
      handleAxisAbsolute(3 + i, axisAt(i));
    }
    emitAxes();
  }
  else if (reportId == 3 && len >= 2)
  {
    for (int i = 0; i < NUM_BUTTONS; i++)
    {
      handleButton(i, ((data[1] >> i) & 1) != 0);
    }
  }
}

void SpaceNavigator::poll()
{
}

void SpaceNavigator::onReadyRead()
{
}

#endif // Q_OS_WIN
