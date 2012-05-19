#ifndef SPNAV_H
#define SPNAV_H

#include "spacenavigatorevent.h"

#include <QThread>
#include <QDebug>

#ifdef SPACENAVIGATOR
#include <spnav.h>

class SpaceNavigator : public QThread {
  Q_OBJECT;

 public:
  SpaceNavigator(QObject *parent = 0);
  ~SpaceNavigator();

  void run();

 signals:
  void moveRecived(SpaceNavigatorEvent *e);
  void buttonRecived(SpaceNavigatorEvent *e);

 protected:
  spnav_event sev;

  bool connected;
  bool stopThread;
};

#endif

#endif // SPNAV_H
