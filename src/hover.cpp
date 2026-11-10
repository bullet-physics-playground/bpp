#include "hover.h"

#include <QApplication>
#include <QToolTip>
#include <QWidget>

#include <algorithm>

#include <BulletSoftBody/btSoftRigidDynamicsWorld.h>
#include <QGLViewer/camera.h>
#include <luabind/luabind.hpp>

#include "objects/object.h"

Hover::Hover(QWidget *view) : _view(view) {}

void Hover::setCallback(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb = fn;
  } else {
    clear();
  }
}

void Hover::clear() {
  _cb = luabind::object();
  hide();
}

void Hover::mouseMoved(const QPoint &pos, Qt::MouseButtons buttons) {
  // only watch movement with no button down
  if (buttons == Qt::NoButton) {
    if (!_armed || (pos - _pos).manhattanLength() > 3) {
      _pos = pos;
      _still.restart();
      _obj = nullptr;                // (moved: forget the sticky object)
      hide();
    }
    _armed = true;
  } else {
    _armed = false;
    hide();
  }
}

void Hover::disarm() {
  _armed = false;
  hide();
}

void Hover::interrupt() {
  _still.restart();
  hide();
}

void Hover::hide() {
  if (_shown) {
    QToolTip::hideText();
    _shown = false;
  }
}

void Hover::tick(const qglviewer::Camera *cam, const std::vector<World> &worlds,
                 const QSet<Object *> *objects, int frameNum,
                 const std::function<void(const std::exception &)> &onError) {
  if (!_cb || !_armed) return;
  if (QApplication::mouseButtons() != Qt::NoButton) { hide(); return; }
  if (!_still.isValid() || _still.elapsed() < 500) return;

  // a ray from the camera through the pointer
  qglviewer::Vec orig, dir;
  cam->convertClickToLine(_pos, orig, dir);
  const btScalar reach = 1.0e6;
  btVector3 from(orig.x, orig.y, orig.z);
  btVector3 to(orig.x + dir.x * reach, orig.y + dir.y * reach, orig.z + dir.z * reach);
  // Everything along the ray, nearest first, in every world (one drawn
  // elsewhere is tested with the ray moved back from where it's drawn, and
  // what it hits moved there again). Objects made with collides = false are
  // seen too: many a script draws its bodies so, and works out their
  // contacts itself, and they still have something to say.
  struct Hit {
    btScalar fraction;
    const btCollisionObject *co;
    btVector3 point;
  };
  struct AllHits : public btCollisionWorld::AllHitsRayResultCallback {
    AllHits(const btVector3 &f, const btVector3 &t) : btCollisionWorld::AllHitsRayResultCallback(f, t) {}
    bool needsCollision(btBroadphaseProxy *) const override { return true; }
  };
  std::vector<Hit> hits;
  auto test = [&](btSoftRigidDynamicsWorld *w, const btTransform *place) {
    btVector3 f = from, t = to;
    if (place) {
      const btTransform inv = place->inverse();
      f = inv * from;
      t = inv * to;
    }
    AllHits ray(f, t);
    w->rayTest(f, t, ray);
    for (int k = 0; k < ray.m_collisionObjects.size(); ++k)
      hits.push_back({ray.m_hitFractions[k], ray.m_collisionObjects[k],
                      place ? (*place) * ray.m_hitPointWorld[k] : ray.m_hitPointWorld[k]});
  };
  for (const World &w : worlds)
    test(w.world, w.place);
  std::sort(hits.begin(), hits.end(), [](const Hit &a, const Hit &b) { return a.fraction < b.fraction; });

  auto objectOf = [&](const btCollisionObject *co) -> Object * {
    if (!objects) return nullptr;
    for (Object *o : *objects)
      if (o && o->getRigidBody() && static_cast<const btCollisionObject *>(o->getRigidBody()) == co) return o;
    return nullptr;
  };
  auto ask = [&](Object *o, const btVector3 &p) -> QString {
    if (!_cb) return QString();
    try {
      luabind::object res = luabind::call_function<luabind::object>(
          _cb, frameNum, o, (double)p.x(), (double)p.y(), (double)p.z());
      if (res.is_valid() && luabind::type(res) == LUA_TSTRING)
        return QString::fromUtf8(luabind::object_cast<std::string>(res).c_str());
    } catch (const std::exception &e) {
      onError(e);
      _cb = luabind::object();    // (don't repeat the error 10x a second)
    }
    return QString();
  };

  // the nearest that has something to say; one that collides and hasn't
  // stops the search (it's in the way), one that doesn't is looked through
  QString text;
  for (const Hit &h : hits) {
    Object *o = objectOf(h.co);
    if (!o) continue;
    text = ask(o, h.point);
    if (!text.isEmpty()) {
      _obj = o;
      _hitPt = h.point;
      _lastHit.restart();
      break;
    }
    if (o->getCollides()) break;
  }
  if (text.isEmpty() && _obj && _lastHit.isValid() && _lastHit.elapsed() < 1500 &&
      objects && objects->contains(_obj)) {
    // sticky: a spinning or rocking object can slip out from under a resting
    // pointer for a moment -- keep reporting it for 1.5 s (no flicker)
    text = ask(_obj, _hitPt);
  }
  if (text.isEmpty()) {
    _obj = nullptr;
    hide();
    return;
  }
  // monospace so a script can line things up
  QToolTip::showText(_view->mapToGlobal(_pos + QPoint(16, 16)),
                     QString("<pre style='margin:0'>%1</pre>").arg(text.toHtmlEscaped()),
                     _view, QRect(), 600000);
  _shown = true;
}
