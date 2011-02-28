#include "collisionfilter.h"

FilterCallback::FilterCallback() {
}

// return true when pairs need collision
bool FilterCallback::needBroadphaseCollision(btBroadphaseProxy* proxy0,btBroadphaseProxy* proxy1) const {
  bool collides = (proxy0->m_collisionFilterGroup & proxy1->m_collisionFilterMask) != 0;
  collides = collides && (proxy1->m_collisionFilterGroup & proxy0->m_collisionFilterMask);
  
  //add some additional logic here that modified 'collides'
  return collides;
}

