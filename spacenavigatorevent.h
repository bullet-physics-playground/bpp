#ifndef SPACENAVIGATOR_EVENT_H
#define SPACENAVIGATOR_EVENT_H

#include <QEvent>

class SpaceNavigatorEvent : public QEvent {

 public:
  SpaceNavigatorEvent(int rx, int ry, int rz, int tx, int ty, int tz);
  SpaceNavigatorEvent(int button, bool pressed);

  int rx, ry, rz, tx, ty, tz;

  int button;
  bool pressed;
};

#endif
