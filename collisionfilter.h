#ifndef COLLISION_FILTER_H
#define COLLISION_FILTER_H

#include <btBulletDynamicsCommon.h>

#include "MidiIO.h"

class FilterCallback : public btOverlapFilterCallback {
 public:
  FilterCallback(MidiIO *mio);
  virtual bool needBroadphaseCollision(btBroadphaseProxy* proxy0,btBroadphaseProxy* proxy1) const;

 private:
  MidiIO *mio;
};

#endif
