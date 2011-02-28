#ifndef COLLISION_FILTER_H
#define COLLISION_FILTER_H

#include <btBulletDynamicsCommon.h>

class FilterCallback : public btOverlapFilterCallback {
 public:
  FilterCallback();
  virtual bool needBroadphaseCollision(btBroadphaseProxy* proxy0,btBroadphaseProxy* proxy1) const;
};

#endif
