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
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation:
 *  version 2.1 of the License.
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
#endif

#if defined(Q_OS_WIN)
#include <QWinEventNotifier>
#include <windows.h>
#include <hidsdi.h>
#include <setupapi.h>
#include <string>
#include <vector>
#endif

#if defined(Q_OS_LINUX)
struct PlatformData
{
  int fd;
  QString path;
  QSocketNotifier *notifier;
};
#elif defined(Q_OS_MACOS)
struct PlatformData
{
  IOHIDManagerRef manager;
  QString path;
};
#elif defined(Q_OS_WIN)
struct PlatformData
{
  HANDLE file;
  QString path;
  HANDLE readEvent;
  OVERLAPPED ov;
  QWinEventNotifier *notifier;
  std::vector<unsigned char> buffer;
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
    m_platform->notifier->setEnabled(false);
    delete m_platform->notifier;
    m_platform->notifier = nullptr;
  }
  if (m_platform->file != INVALID_HANDLE_VALUE)
  {
    CancelIo(m_platform->file);
    CloseHandle(m_platform->file);
    m_platform->file = INVALID_HANDLE_VALUE;
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
  emitAxes();
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
      }
    }
    else if (ev.type == EV_ABS)
    {
      if (ev.code < NUM_AXES)
      {
        handleAxisAbsolute(ev.code, ev.value);
      }
    }
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
    self->handleAxisAbsolute(static_cast<int>(usage - 0x30), static_cast<int>(raw));
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

  CFArrayRef devices = IOHIDManagerCopyDevices(manager);
  if (devices)
  {
    if (CFArrayGetCount(devices) > 0)
    {
      IOHIDDeviceRef device =
          static_cast<IOHIDDeviceRef>(const_cast<void *>(CFArrayGetValueAtIndex(devices, 0)));
      CFTypeRef product = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
      if (product && CFGetTypeID(product) == CFStringGetTypeID())
      {
        char buffer[128] = {0};
        if (CFStringGetCString(static_cast<CFStringRef>(product), buffer,
                               sizeof(buffer), kCFStringEncodingUTF8))
        {
          m_platform->path = QString::fromUtf8(buffer);
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

bool winIsSupported(USHORT vendor, USHORT product, HANDLE file)
{
  if (vendor == USB_VENDOR_ID_3DCONNEXION)
  {
    // 3Dconnexion devices expose a vendor-defined top-level collection.
    PHIDP_PREPARSED_DATA preparsed = nullptr;
    if (!HidD_GetPreparsedData(file, &preparsed))
    {
      return false;
    }
    HIDP_CAPS caps;
    bool ok = HidP_GetCaps(preparsed, &caps) == HIDP_STATUS_SUCCESS &&
              caps.UsagePage == 0xFF00 && caps.Usage == 0x01;
    HidD_FreePreparsedData(preparsed);
    return ok;
  }

  if (vendor == USB_VENDOR_ID_LOGITECH)
  {
    return product == USB_DEVICE_ID_SPACENAVIGATOR ||
           product == USB_DEVICE_ID_SPACETRAVELLER ||
           product == USB_DEVICE_ID_SPACEBALL_5000;
  }

  return false;
}

void winEnumerate3DMice(QStringList &out)
{
  GUID hidGuid;
  HidD_GetHidGuid(&hidGuid);

  HDEVINFO devices = SetupDiGetClassDevs(&hidGuid, nullptr, nullptr,
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
    SetupDiGetDeviceInterfaceDetail(devices, &interfaceData, nullptr, 0, &required, nullptr);
    if (required == 0)
    {
      continue;
    }

    std::vector<BYTE> buffer(required);
    SP_DEVICE_INTERFACE_DETAIL_DATA *detail =
        reinterpret_cast<SP_DEVICE_INTERFACE_DETAIL_DATA *>(buffer.data());
    detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);
    if (!SetupDiGetDeviceInterfaceDetail(devices, &interfaceData, detail,
                                         required, nullptr, nullptr))
    {
      continue;
    }

    HANDLE file = CreateFile(detail->DevicePath,
                             GENERIC_READ | GENERIC_WRITE,
                             FILE_SHARE_READ | FILE_SHARE_WRITE,
                             nullptr, OPEN_EXISTING,
                             FILE_FLAG_OVERLAPPED, nullptr);
    if (file == INVALID_HANDLE_VALUE)
    {
      continue;
    }

    HIDD_ATTRIBUTES attributes;
    attributes.Size = sizeof(attributes);
    if (HidD_GetAttributes(file, &attributes) &&
        winIsSupported(attributes.VendorID, attributes.ProductID, file))
    {
      out.append(QString::fromWCharArray(detail->DevicePath));
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

  HANDLE file = CreateFile(path.toStdWString().c_str(),
                           GENERIC_READ | GENERIC_WRITE,
                           FILE_SHARE_READ | FILE_SHARE_WRITE,
                           nullptr, OPEN_EXISTING,
                           FILE_FLAG_OVERLAPPED, nullptr);
  if (file == INVALID_HANDLE_VALUE)
  {
    emit error(QStringLiteral("Unable to open %1").arg(path));
    return false;
  }

  HIDD_ATTRIBUTES attributes;
  attributes.Size = sizeof(attributes);
  if (!HidD_GetAttributes(file, &attributes) ||
      !winIsSupported(attributes.VendorID, attributes.ProductID, file))
  {
    CloseHandle(file);
    emit error(QStringLiteral("%1 is not a supported 3D mouse").arg(path));
    return false;
  }

  int reportLength = 64;
  PHIDP_PREPARSED_DATA preparsed = nullptr;
  if (HidD_GetPreparsedData(file, &preparsed))
  {
    HIDP_CAPS caps;
    if (HidP_GetCaps(preparsed, &caps) == HIDP_STATUS_SUCCESS &&
        caps.InputReportByteLength > 0)
    {
      reportLength = caps.InputReportByteLength;
    }
    HidD_FreePreparsedData(preparsed);
  }

  resetState();
  m_platform = new PlatformData;
  m_platform->file = file;
  m_platform->path = path;
  m_platform->readEvent = CreateEvent(nullptr, TRUE, FALSE, nullptr);
  m_platform->notifier = new QWinEventNotifier(m_platform->readEvent, this);
  m_platform->buffer.resize(reportLength);
  ZeroMemory(&m_platform->ov, sizeof(m_platform->ov));
  m_platform->ov.hEvent = m_platform->readEvent;
  connect(m_platform->notifier, &QWinEventNotifier::activated,
          this, &SpaceNavigator::onReadComplete);

  emit deviceOpened();
  startWindowsRead();
  return true;
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

void SpaceNavigator::parseWindowsReport(const unsigned char *data, int len)
{
  if (!data || len < 1)
  {
    return;
  }

  const unsigned char reportId = data[0];
  if (reportId == 1)
  {
    // Buttons: report id 1, two-byte bitmask.
    if (len >= 2)
    {
      for (int i = 0; i < NUM_BUTTONS; i++)
      {
        handleButton(i, ((data[1] >> i) & 1) != 0);
      }
    }
  }
  else if (reportId == 2)
  {
    // Axes: report id 2, six axes as signed 16-bit little-endian.
    if (len >= 13)
    {
      for (int i = 0; i < NUM_AXES; i++)
      {
        const short value =
            static_cast<short>(data[1 + 2 * i] | (data[2 + 2 * i] << 8));
        handleAxisAbsolute(i, value);
      }
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
