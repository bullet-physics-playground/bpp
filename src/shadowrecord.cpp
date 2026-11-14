#include "shadowrecord.h"

#include <algorithm>
#include <cmath>

#include <btBulletDynamicsCommon.h>

#include "glutils.h"
#include "objects/object.h"
#include "objects/softbody.h"
#include "shadowmap.h"

bool ShadowRecord::isFixedCaster(const Object *o) {
  return !o->placed && o->body != nullptr && o->body->isStaticObject() &&
         o->getCastShadow() &&
         o->body->getCollisionShape() != nullptr && !o->hasRenderFunction() &&
         dynamic_cast<const SoftBody *>(o) == nullptr;
}

// A fixed object goes into the record once it has stayed put this many
// frames, so one a script moves now and then (a plunger, a gate) keeps out of
// it rather than having it made again every frame.
static const unsigned STILL_FRAMES = 30;

// Each fixed object's address, shape, size and where it is drawn, hashed;
// those that have stayed the same long enough are marked, and their hashes
// summed (so the order the objects come in doesn't matter).
quint64 ShadowRecord::markStillCasters(const ObjectSet &objects, int *count) {
  quint64 sum = 0;
  int n = 0;
  foreach (Object *o, objects) {
    o->shadowListed = false;
    if (!isFixedCaster(o))
      continue;
    btTransform t;
    if (o->body->getMotionState() != nullptr)
      o->body->getMotionState()->getWorldTransform(t);
    else
      t.setIdentity();
    btScalar m[16];
    t.getOpenGLMatrix(m);
    btVector3 lo(0, 0, 0), hi(0, 0, 0);
    const btCollisionShape *s = o->body->getCollisionShape();
    btTransform id;
    id.setIdentity();
    s->getAabb(id, lo, hi);
    const bool seeThrough = o->getTransparency() > 0.0;  // (draws no depth)
    quint64 h = 1469598103934665603ULL;  // (FNV-1a)
    auto mix = [&h](const void *p, size_t len) {
      const unsigned char *b = static_cast<const unsigned char *>(p);
      for (size_t k = 0; k < len; ++k) {
        h ^= b[k];
        h *= 1099511628211ULL;
      }
    };
    const void *ptrs[3] = {o, s, o->shape};
    mix(ptrs, sizeof(ptrs));
    mix(m, sizeof(m));
    mix(&lo, sizeof(btScalar) * 3);
    mix(&hi, sizeof(btScalar) * 3);
    mix(&seeThrough, sizeof(seeThrough));
    if (h != o->shadowHash) {
      // (it had stayed put long enough to be recorded, and has moved: one a
      // script moves now and then -- a cue, an aiming guide's dashes, a
      // sign -- came into the record and went out again over and over, and
      // each time the record of every fixed object in the scene was made
      // again, a frame of 10 to 40 ms. Moved twice, it's kept out for good
      // and drawn on its own, as moving objects are.)
      if (o->shadowStill >= STILL_FRAMES && o->shadowMoves < 2)
        ++o->shadowMoves;
      o->shadowHash = h;
      o->shadowStill = 0;
      // (its patch of the record: where the middle of its box is)
      btVector3 wlo, whi;
      s->getAabb(t, wlo, whi);
      const btVector3 mid = (wlo + whi) * 0.5;
      for (int a = 0; a < 3; ++a)        // (planes and the like: far out, all one)
        o->shadowCell[a] = int(std::max(-1e6, std::min(1e6, std::floor(double(mid[a] / 60.0)))));
    } else if (o->shadowStill < STILL_FRAMES) {
      ++o->shadowStill;
    }
    if (o->shadowStill >= STILL_FRAMES && o->shadowMoves < 2) {
      o->shadowListed = true;
      ++n;
      sum += h;
    }
  }
  *count = n;
  return sum;
}

bool ShadowRecord::fill(const ObjectSet &objects, ShadowMap *map,
                        btBroadphaseInterface *broadphase, bool culled, Counts &counts) {
  // The fixed objects that have stayed put are drawn once, recorded as
  // OpenGL lists, and those are replayed each frame; only the rest are drawn
  // one by one. There is a list for each patch of the scene (a cube 60
  // across: see markStillCasters()), so what culling leaves out still mostly
  // stays out: a patch's list is replayed when culling keeps any of its
  // objects. When which objects are still, or where, changes, only the
  // patches where it changed
  // are recorded again: one script-moved cue or aiming guide used to have
  // every fixed object in the scene -- some 3,000 in the rec room --
  // recorded again, a frame of 10 to 40 ms, every few seconds.
  _cached = 0;
  const void *ctx = glCacheContext();
  if (!_patches.isEmpty() && (_ctx != ctx || _epoch != glCacheEpoch()))
    _patches.clear();              // (its context has gone, and the lists with it)
  bool replay = false;
  auto freePatches = [this]() {
    for (const Patch &p : _patches)
      glDeleteLists(p.list, 1);
    _patches.clear();
  };
  if (enabled && ctx != nullptr) {
    int count = 0;
    const quint64 sig = markStillCasters(objects, &count);
    if (sig != _sig || count != _count || _patches.isEmpty() != (count == 0)) {
      btVector3 minaabb(0, 0, 0), maxaabb(0, 0, 0);
      broadphase->getBroadphaseAabb(minaabb, maxaabb);
      // (with a body gone off to infinity, objects draw at the origin: not
      // something to record)
      bool finite = true;
      for (int a = 0; a < 3; ++a)
        finite = finite && std::isfinite(minaabb[a]) && std::isfinite(maxaabb[a]);
      if (!finite) {
        freePatches();
      } else {
        QMap<std::tuple<int, int, int>, Patch> now;
        foreach (Object *o, objects) {
          if (!o->shadowListed)
            continue;
          Patch &p = now[std::make_tuple(o->shadowCell[0], o->shadowCell[1], o->shadowCell[2])];
          p.objs.append(o);
          p.sum += o->shadowHash;
          ++p.count;
        }
        // the patches that are the same keep their lists; the rest go
        for (auto it = _patches.begin(); it != _patches.end();) {
          auto n = now.constFind(it.key());
          if (n == now.constEnd() || n->sum != it->sum || n->count != it->count) {
            glDeleteLists(it->list, 1);
            it = _patches.erase(it);
          } else {
            ++it;
          }
        }
        // and the new or changed ones are recorded
        bool all = true;
        glSetRecordingList(true);        // (see glRecordingList())
        for (auto n = now.cbegin(); n != now.cend(); ++n) {
          if (_patches.contains(n.key()))
            continue;
          const GLuint list = glGenLists(1);
          if (list == 0) {
            all = false;
            for (Object *o : n->objs)
              o->shadowListed = false;   // (drawn one by one this frame)
            continue;
          }
          glNewList(list, GL_COMPILE);
          for (Object *o : n->objs)
            o->render(minaabb, maxaabb);
          glEndList();
          Patch p = n.value();
          p.list = list;
          _patches.insert(n.key(), p);
          counts.recorded += p.count;
        }
        glSetRecordingList(false);
        _ctx = ctx;
        _epoch = glCacheEpoch();
        // (one that couldn't be made: tried again next frame)
        _sig = all ? sig : sig + 1;
        _count = count;
      }
    }
    replay = !_patches.isEmpty();
  } else if (!_patches.isEmpty()) {
    freePatches();
  }
  // With the record made, and the light and the scene's extent the same as
  // last frame, all of the record is drawn once more and the depth saved
  // (v.shadowSaved); each frame after that puts the saved depth back in one
  // copy on the graphics card, instead of drawing the record again, until
  // the record or the light changes.
  _fromSaved = false;
  bool drewAll = false;
  if (replay && saveDepth) {
    if (_savedDepthSig == _sig && _savedDepthCount == _count &&
        map->savedDepthFits()) {
      map->restoreDepth();
      _fromSaved = true;
    } else if (map->lightSteady() && map->canSaveDepth()) {
      for (const Patch &p : _patches)
        glCallList(p.list);
      drewAll = true;
      counts.depthSaved = true;
      if (map->saveDepth()) {
        _savedDepthSig = _sig;
        _savedDepthCount = _count;
        _fromSaved = true;
      }
    }
  }
  if (_fromSaved || drewAll) {
    _cached = _count;
  } else if (replay) {
    for (const Patch &p : _patches) {
      bool wanted = !culled;
      for (int i = 0; !wanted && i < p.objs.size(); ++i)
        wanted = p.objs[i]->drawInShadow;
      if (wanted) {
        glCallList(p.list);
        _cached += p.objs.size();
      }
    }
  }
  return replay;
}
