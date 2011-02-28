#include "spacenavigatorevent.h"

SpaceNavigatorEvent::SpaceNavigatorEvent(int _rx, int _ry, int _rz,
					 int _tx, int _ty, int _tz) :

  QEvent((QEvent::Type)(QEvent::User + 1))
{
  rx = _rx;
  ry = _ry;
  rz = _rz;

  tx = _tx;
  ty = _ty;
  tz = _tz;
}

SpaceNavigatorEvent::SpaceNavigatorEvent(int _button, bool _pressed) :
  QEvent((QEvent::Type)(QEvent::User + 2))
{
  button = _button;
  pressed = _pressed;
}
