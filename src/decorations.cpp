#include "decorations.h"

#include <btBulletDynamicsCommon.h>

namespace {
// where @p o is drawn: its motion state's place, else its body's
btTransform drawnAt(const Object *o) {
  btTransform t;
  if (btMotionState *ms = o->body->getMotionState())
    ms->getWorldTransform(t);
  else
    t = o->body->getWorldTransform();
  return t;
}
} // namespace

void Decorations::attach(Object *o, Object *parent) {
  detach(o);
  if (o == nullptr || parent == nullptr || o == parent || o->body == nullptr || parent->body == nullptr)
    return;
  _links.push_back({o, parent, drawnAt(parent).inverse() * drawnAt(o)});
}

void Decorations::detach(Object *o) {
  for (size_t i = 0; i < _links.size();) {
    if (_links[i].o == o)
      _links.erase(_links.begin() + i);
    else
      ++i;
  }
}

void Decorations::update() {
  for (size_t i = 0; i < _links.size();) {
    Link &l = _links[i];
    if (l.o.isNull() || l.parent.isNull() || l.o->body == nullptr || l.parent->body == nullptr) {
      _links.erase(_links.begin() + i);   // (deleted, or its body gone)
      continue;
    }
    const btTransform t = drawnAt(l.parent) * l.offset;
    btRigidBody *b = l.o->body;
    if (btMotionState *ms = b->getMotionState())
      ms->setWorldTransform(t);
    else
      b->setMotionState(new btDefaultMotionState(t));
    b->setWorldTransform(t);   // (outside the world, Bullet never copies the motion state over)
    ++i;
  }
}
