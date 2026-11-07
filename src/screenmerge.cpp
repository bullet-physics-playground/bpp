#include "screenmerge.h"

#include <QOpenGLContext>
#include <QOpenGLFunctions>

#include <climits>
#include <cmath>
#include <cstddef>
#include <cstring>

#include "glutils.h"
#include "objects/cube.h"
#include "objects/cylinder.h"
#include "objects/object.h"

namespace {
// What can go into the merge: a fixed box or cylinder, opaque, without an
// image, a glow or a script's drawing.
bool mergeable(Object *o) {
  return !o->placed && o->body != nullptr && o->body->isStaticObject() &&
         o->body->getMotionState() != nullptr && o->getTransparency() <= 0.0 &&
         !o->hasTexture() && !o->hasRenderFunction() && !o->hasEmission() &&
         (dynamic_cast<Cube *>(o) != nullptr || dynamic_cast<Cylinder *>(o) != nullptr);
}

btTransform drawnTrans(const Object *o) {
  btTransform t;
  o->body->getMotionState()->getWorldTransform(t);
  return t;
}

bool sameTrans(const btTransform &a, const btTransform &b) {
  return a.getOrigin() == b.getOrigin() && a.getBasis() == b.getBasis();
}

struct MergeVertex {
  float p[3];
  float n[3];
  unsigned char c[4];
};

// An object's triangles, in the room's coordinates, as drawing it would make
// them: its transform, then its own scale (and, for a cylinder, the shift to
// Bullet's middle), then the unit shape glutils.cpp draws.
void mergeTriangles(Object *o, std::vector<MergeVertex> &out) {
  const btTransform t = drawnTrans(o);
  const btMatrix3x3 &R = t.getBasis();
  const btVector3 &T = t.getOrigin();
  const unsigned char *rgb = o->rgb();
  btVector3 scale(1, 1, 1), shift(0, 0, 0);
  QVector<btVector3> lp, ln;             // local positions, normals (triangles)
  if (Cube *c = dynamic_cast<Cube *>(o)) {
    scale = btVector3(c->lengths[0], c->lengths[1], c->lengths[2]);
    // (as solidCubeDraw(1): six quads, each two triangles)
    for (int i = 0; i < 6; i++) {
      const int flip = i & 1, rotx = i >> 2, idx = (~i & 2) - rotx;
      float norm[3] = {0, 0, 0}, vpos[3] = {0, 0, 0};
      norm[idx] = (flip ^ ((i >> 1) & 1)) ? -1 : 1;
      vpos[idx] = norm[idx] * 0.5f;
      btVector3 q[4];
      for (int j = 0; j < 4; j++) {
        const int gray = j ^ (j >> 1);
        vpos[i & 2] = ((gray ^ flip) & 1) ? 0.5f : -0.5f;
        vpos[rotx + 1] = ((gray ^ (rotx << 1)) & 2) ? 0.5f : -0.5f;
        q[j] = btVector3(vpos[0], vpos[1], vpos[2]);
      }
      const btVector3 n(norm[0], norm[1], norm[2]);
      for (int k : {0, 1, 2, 0, 2, 3}) {
        lp.append(q[k]);
        ln.append(n);
      }
    }
  } else if (Cylinder *c = dynamic_cast<Cylinder *>(o)) {
    scale = btVector3(c->lengths[0], c->lengths[1], c->lengths[2]);
    shift = btVector3(0, 0, -c->lengths[2] * 0.5);
    // (as solidCylinderDraw(1, 1, 16, 16): strips up the side, fans at the ends)
    const int slices = 16, stacks = 16;
    for (int i = 0; i < stacks; i++) {
      const float z0 = float(i) / stacks, z1 = float(i + 1) / stacks;
      QVector<btVector3> sp, sn;
      for (int j = 0; j <= slices; j++) {
        const double th = j * 2.0 * M_PI / slices;
        const float x = float(cos(th)), y = float(sin(th));
        sp.append(btVector3(x, y, z0));
        sn.append(btVector3(x, y, 0));
        sp.append(btVector3(x, y, z1));
        sn.append(btVector3(x, y, 0));
      }
      // (a strip's every other triangle turns the other way round, so all
      // face the same way: the shader lights a back face from behind)
      for (int k = 0; k + 2 < sp.size(); k++) {
        const int order[3] = {(k & 1) ? k + 1 : k, (k & 1) ? k : k + 1, k + 2};
        for (int m : order) {
          lp.append(sp[m]);
          ln.append(sn[m]);
        }
      }
    }
    for (int side = 0; side < 2; side++) {
      const float z = side == 0 ? 0.0f : 1.0f, nz = side == 0 ? -1.0f : 1.0f;
      QVector<btVector3> ring;
      for (int j = 0; j <= slices; j++) {
        const double th = side == 0 ? (j * 2.0 * M_PI / slices) : (-j * 2.0 * M_PI / slices);
        ring.append(btVector3(float(cos(th)), float(sin(th)), z));
      }
      for (int j = 0; j + 1 < ring.size(); j++)
        for (const btVector3 &p : {btVector3(0, 0, z), ring[j], ring[j + 1]}) {
          lp.append(p);
          ln.append(btVector3(0, 0, nz));
        }
    }
  }
  for (int k = 0; k < lp.size(); k++) {
    const btVector3 p = T + R * (lp[k] * scale + shift);
    // (a normal goes through the scale's inverse, as GL_NORMALIZE leaves it)
    btVector3 n = ln[k] / scale;
    n = R * n.normalized();
    MergeVertex v;
    for (int a = 0; a < 3; a++) {
      v.p[a] = float(p[a]);
      v.n[a] = float(n[a]);
    }
    v.c[0] = rgb[0];
    v.c[1] = rgb[1];
    v.c[2] = rgb[2];
    v.c[3] = 255;
    out.push_back(v);
  }
}
} // namespace

void ScreenMerge::clear() {
  QOpenGLContext *c = QOpenGLContext::currentContext();
  const bool canDelete = c != nullptr && glCacheContext() == _ctx &&
                         glCacheEpoch() == _epoch;
  for (Batch &b : _batches) {
    if (b.vbo != 0 && canDelete)
      c->functions()->glDeleteBuffers(1, &b.vbo);
    if (b.cvbo != 0 && canDelete)
      c->functions()->glDeleteBuffers(1, &b.cvbo);
  }
  _batches.clear();
  _openGen.clear();
  for (Object *o : _objs)
    o->merged = o->mergeDrawn = false;
  _objs.clear();
  _ready = false;
}

namespace {
std::tuple<int, int, int, int> mergeKey(const Object *o) {
  return std::make_tuple(o->mergeCell[0], o->mergeCell[1], o->mergeCell[2], o->mergeGen);
}
} // namespace

// An object leaves its batch. Making the batch again (all of its patch's
// boxes and cylinders) took a frame 8 to 19 ms in the rec room, each time
// a script moved a merged object -- an aiming guide's dash, say. So its
// triangles are blanked where they are instead (next frame, before
// anything is drawn: see updateMerge()), and the batch is made again only
// once more than half of it is blanks.
void ScreenMerge::unmerge(Object *o) {
  auto it = _batches.find(mergeKey(o));
  if (it != _batches.end()) {
    Batch &b = it.value();
    b.objs.removeOne(o);
    bool again = b.objs.isEmpty();
    if (!again && !b.dirty && b.vbo != 0 && o->mergeDrawn) {
      b.blank.push_back(std::make_pair(o->mergeFirst, o->mergeVerts));
      b.holes += o->mergeVerts;
      again = 2 * b.holes > b.verts;
    } else if (!b.dirty) {
      again = true;
    }
    if (again && !b.dirty) {
      b.dirty = true;
      for (Object *p : b.objs)          // (one by one until it's made again)
        p->mergeDrawn = false;
    }
    if (b.objs.isEmpty())
      b.dirty = true;                    // (and it goes: see buildMerge())
  }
  o->merged = false;
  o->mergeDrawn = false;
  o->mergeSteady = 0;
}

void ScreenMerge::remove(Object *o) {
  if (o->merged) {                       // (its batch is made again without it)
    unmerge(o);
    _objs.removeOne(o);
    _ready = false;
  }
}

void ScreenMerge::build(Counts &counts) {
  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
  std::vector<MergeVertex> verts;
  std::vector<quint32> colours;
  bool made = false;
  // (a few a frame, so no one frame does them all: what's in the others is
  // drawn one by one meanwhile)
  int budget = 4;
  for (auto it = _batches.begin(); it != _batches.end();) {
    Batch &b = it.value();
    if (!b.dirty || (budget <= 0 && !b.objs.isEmpty())) {
      ++it;
      continue;
    }
    if (b.vbo != 0)
      f->glDeleteBuffers(1, &b.vbo);
    if (b.cvbo != 0)
      f->glDeleteBuffers(1, &b.cvbo);
    b.vbo = b.cvbo = 0;
    b.verts = 0;
    b.holes = 0;
    b.blank.clear();
    if (b.objs.isEmpty()) {
      it = _batches.erase(it);
      continue;
    }
    --budget;
    verts.clear();
    for (Object *o : b.objs) {
      o->mergeFirst = int(verts.size());
      mergeTriangles(o, verts);
      o->mergeVerts = int(verts.size()) - o->mergeFirst;
    }
    f->glGenBuffers(1, &b.vbo);
    f->glBindBuffer(GL_ARRAY_BUFFER, b.vbo);
    f->glBufferData(GL_ARRAY_BUFFER, verts.size() * sizeof(MergeVertex), verts.data(),
                    GL_STATIC_DRAW);
    colours.resize(verts.size());
    for (size_t k = 0; k < verts.size(); ++k)
      memcpy(&colours[k], verts[k].c, 4);
    f->glGenBuffers(1, &b.cvbo);
    f->glBindBuffer(GL_ARRAY_BUFFER, b.cvbo);
    f->glBufferData(GL_ARRAY_BUFFER, colours.size() * 4, colours.data(), GL_STATIC_DRAW);
    b.verts = int(verts.size());
    b.dirty = false;
    for (Object *o : b.objs)
      o->mergeDrawn = true;
    made = true;
    ++counts.batches;
    ++it;
  }
  f->glBindBuffer(GL_ARRAY_BUFFER, 0);
  if (made)
    ++_made;
}

ScreenMerge::Counts ScreenMerge::update(const QSet<Object *> &objects) {
  Counts counts;
  ++_frame;
  _ready = false;
  const void *ctx = glCacheContext();
  if (ctx != _ctx || glCacheEpoch() != _epoch) {
    for (Batch &b : _batches) {
      b.vbo = b.cvbo = 0;                // (they went with their context)
      b.dirty = true;
      for (Object *o : b.objs)
        o->mergeDrawn = false;
    }
    _ctx = ctx;
    _epoch = glCacheEpoch();
  }
  if (!enabled || ctx == nullptr) {
    if (!_objs.isEmpty() || !_batches.isEmpty())
      clear();
    return counts;
  }
  // What has moved since it was merged comes out (its batch made again):
  // for ten seconds the first time, for good the second. What has only
  // changed colour (a lamp, a scoreboard's segment) stays, and gets its new
  // colour where it is in its batch: taken out for good after two changes,
  // a blinking lamp was drawn on its own from then on, and the room's
  // hundreds of lamps one by one cost more each frame than the rest of the
  // merge saved (more still with the shadow shader on).
  std::vector<quint32> recoloured;
  bool bound = false;
  for (int k = 0; k < _objs.size(); ++k) {
    Object *o = _objs[k];
    const bool still = mergeable(o) && sameTrans(drawnTrans(o), o->mergeTrans);
    if (still && memcmp(o->rgb(), o->mergeRgb, 3) == 0)
      continue;
    if (still) {
      auto it = _batches.find(mergeKey(o));
      if (it != _batches.end() && it.value().cvbo != 0 && !it.value().dirty && o->mergeDrawn) {
        // (its vertices' colours, as mergeTriangles() gives them)
        const unsigned char *rgb = o->rgb();
        const unsigned char c4[4] = {rgb[0], rgb[1], rgb[2], 255};
        quint32 c;
        memcpy(&c, c4, 4);
        recoloured.assign(size_t(o->mergeVerts), c);
        QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
        f->glBindBuffer(GL_ARRAY_BUFFER, it.value().cvbo);
        f->glBufferSubData(GL_ARRAY_BUFFER, o->mergeFirst * 4, recoloured.size() * 4, recoloured.data());
        bound = true;
        ++counts.recoloured;
      }
      // (a batch not made yet takes the colour it has when it's made)
      memcpy(o->mergeRgb, o->rgb(), 3);
      continue;
    }
    unmerge(o);
    o->mergeBanUntil = ++o->mergeChanges >= 2 ? LONG_MAX : _frame + 600;
    _objs.removeAt(k--);
  }
  if (bound)
    QOpenGLContext::currentContext()->functions()->glBindBuffer(GL_ARRAY_BUFFER, 0);
  // Once a second, more: what has stayed put for five looks running goes
  // into the batch of its patch (whatever its colour does: see above).
  if (_frame % 60 == 0) {
    foreach (Object *o, objects) {
      if (o->merged || _frame < o->mergeBanUntil || !mergeable(o))
        continue;
      const btTransform t = drawnTrans(o);
      if (o->mergeSteady > 0 && sameTrans(t, o->mergeTrans)) {
        if (++o->mergeSteady < 5)
          continue;
        memcpy(o->mergeRgb, o->rgb(), 3);
        const btVector3 &p = t.getOrigin();
        auto cell = [](btScalar x) { return int(std::floor(double(x) / 60.0)); };
        o->mergeCell[0] = cell(p.x());
        o->mergeCell[1] = cell(p.y());
        o->mergeCell[2] = cell(p.z());
        // (into its patch's batch that's taking newcomers; once that's
        // made, a new one: a newcomer never has a whole patch made again)
        int &gen = _openGen[std::make_tuple(o->mergeCell[0], o->mergeCell[1], o->mergeCell[2])];
        o->mergeGen = gen;
        auto open = _batches.constFind(mergeKey(o));
        if (open != _batches.constEnd() && !open->dirty && open->vbo != 0)
          o->mergeGen = gen = ++_genCount;
        Batch &b = _batches[mergeKey(o)];
        b.objs.append(o);
        b.dirty = true;
        for (Object *p : b.objs)
          p->mergeDrawn = false;
        o->merged = true;
        _objs.append(o);
      } else {
        o->mergeSteady = 1;
        o->mergeTrans = t;
        memcpy(o->mergeRgb, o->rgb(), 3);
      }
    }
  }
  // the blanks of objects that have left their batches (see unmerge())
  std::vector<MergeVertex> zeros;
  for (Batch &b : _batches) {
    if (b.blank.empty())
      continue;
    if (!b.dirty && b.vbo != 0) {
      QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
      f->glBindBuffer(GL_ARRAY_BUFFER, b.vbo);
      for (const auto &r : b.blank) {
        zeros.assign(size_t(r.second), MergeVertex{});     // (all at one point: nothing drawn)
        f->glBufferSubData(GL_ARRAY_BUFFER, r.first * sizeof(MergeVertex),
                           r.second * sizeof(MergeVertex), zeros.data());
      }
      f->glBindBuffer(GL_ARRAY_BUFFER, 0);
      ++counts.blanked;
    }
    b.blank.clear();
  }
  build(counts);                         // (only the batches that need it)
  _ready = true;
  return counts;
}

void ScreenMerge::draw(bool culled) {
  _drawn = 0;
  if (!_ready || _batches.isEmpty())
    return;
  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnable(GL_NORMALIZE);
  for (const Batch &b : _batches) {
    if (b.dirty || b.vbo == 0 || b.cvbo == 0)
      continue;
    bool wanted = !culled;
    for (int i = 0; !wanted && i < b.objs.size(); ++i)
      wanted = b.objs[i]->drawOnScreen;
    if (!wanted)
      continue;
    f->glBindBuffer(GL_ARRAY_BUFFER, b.vbo);
    glVertexPointer(3, GL_FLOAT, sizeof(MergeVertex), (const void *)offsetof(MergeVertex, p));
    glNormalPointer(GL_FLOAT, sizeof(MergeVertex), (const void *)offsetof(MergeVertex, n));
    f->glBindBuffer(GL_ARRAY_BUFFER, b.cvbo);
    glColorPointer(4, GL_UNSIGNED_BYTE, 4, nullptr);
    glDrawArrays(GL_TRIANGLES, 0, b.verts);
    _drawn += b.objs.size();
  }
  f->glBindBuffer(GL_ARRAY_BUFFER, 0);
  glDisableClientState(GL_COLOR_ARRAY);
  glColor4ub(255, 255, 255, 255);        // (the colour after a colour array isn't defined)
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);
}
