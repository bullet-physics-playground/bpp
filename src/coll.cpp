#include "coll.h"

#ifdef HAS_MIDI

#define BIT(x) (1<<(x))

enum collisiontypes {
  COL_NOTHING = 0, //<Collide with nothing
  COL_SHIP = BIT(1), //<Collide with ships
  COL_WALL = BIT(2), //<Collide with walls
  COL_POWERUP = BIT(3) //<Collide with powerups
};

FilterCallback::FilterCallback(MidiIO *mMio) {
  mio = mMio;
}

// return true when pairs need collision
bool FilterCallback::needBroadphaseCollision(btBroadphaseProxy* proxy0,btBroadphaseProxy* proxy1) const {
  bool collides = (proxy0->m_collisionFilterGroup & proxy1->m_collisionFilterMask) != 0;
  collides = collides && (proxy1->m_collisionFilterGroup & proxy0->m_collisionFilterMask);

  /*
  bool shipShip = (proxy0->m_collisionFilterGroup & COL_SHIP) != 0;
  shipShip = shipShip && (proxy1->m_collisionFilterGroup & COL_SHIP);

  if (shipShip) {
    QString msg; msg += 144; msg += 48; msg += 127;
    mio->send(msg);
  }
  */
  //add some additional logic here that modified 'collides'
  return collides;
}

#endif

