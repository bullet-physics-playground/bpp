/**
 * @file viewer.cpp
 * @brief Implementation of the 3D view, the simulation and the script host.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "viewer.h"
#include "prefs.h"

#include "appenv.h"

#include <cstring>
#include <memory>


#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>

#include "gimpactplane.h"
#include "bppworld.h"

#include "lua_bullet.h"
#include "lua_converters.h"   // for Q_DECLARE_METATYPE(luabind::object)

#include "glutils.h"
#include "shadowmap.h"

#if USE_VFE
#include "povray/bppvfesession.h"
#include "povray/bppvfedisplay.h"
#endif // USE_VFE

#ifdef HAS_LUA_QT
#include "lua_register.h"
#endif

#include "objects/bezierpatch.h"
#include "objects/blob.h"
#include "objects/bound.h"
#include "objects/cone.h"
#include "objects/cube.h"
#include "objects/cylinder.h"
#include "objects/csg.h"
#include "objects/disc.h"
#include "objects/heightfield.h"
#include "objects/layer.h"
#include "objects/patch.h"
#include "objects/povscriptwriter.h"
#include "objects/referenceobject.h"
#include "objects/sweep.h"
#include "objects/superquadric.h"
#include "objects/truetype.h"
#include "objects/torus.h"
#include "objects/object.h"
#include "objects/plane.h"
#include "objects/rigidsoftcontact.h"
#include "objects/softbody.h"
#include "objects/sphere.h"
#include "objects/terrain.h"
#include "objects/triangle.h"

#include <BulletSoftBody/btSoftBodyRigidBodyCollisionConfiguration.h>
#include <BulletSoftBody/btSoftRigidDynamicsWorld.h>
#if BT_THREADSAFE
#include <LinearMath/btThreads.h>
#include <LinearMath/btPoolAllocator.h>
#endif
#include <BulletDynamics/ConstraintSolver/btNNCGConstraintSolver.h>
#include <BulletDynamics/MLCPSolvers/btMLCPSolver.h>
#include <BulletDynamics/MLCPSolvers/btDantzigSolver.h>
#include <BulletDynamics/MLCPSolvers/btSolveProjectedGaussSeidel.h>
#include <BulletDynamics/MLCPSolvers/btLemkeSolver.h>

// A rigid body's gyroscopic term, solved together with its contacts and
// joints, for bodies a script marks (body.gyroSolved = true: the flag
// BPP_GYRO_MIDPOINT, Bullet's own gyroscopic flags off). Euler's equations
// in the world frame are I dw/dt = -w x I w + torque. Before every step the
// body's spin takes the linearly implicit midpoint step of them,
// (I + dt/2 Jg) dw = -dt w x I w with Jg = d(w x I w)/dw = [w]x I - [I w]x,
// and for this step the body answers the solver's impulses through
// (I + dt/2 Jg)^-1 instead of I^-1, so the joints and contacts are solved
// with the gyroscopic coupling in them. Bullet puts I^-1 back when it moves
// the body at the end of the step (proceedToTransform). A free body keeps
// its energy and angular momentum; a jointed chain of spinning bodies stays
// stable, which it does not when the term is applied before the solve.
// (Bullet's own term, applied outside the solve by backward Euler, takes
// energy out of a tumbling body, and is not applied at all to a body whose
// inertia's determinant is under FLT_EPSILON, as for small bodies in kg and
// cm.) Unmarked bodies are untouched. No state of its own: one world's
// step touches only that world's bodies.
static void bppGyroPreTick(btDynamicsWorld *world, btScalar dt) {
  btCollisionObjectArray &objs = world->getCollisionObjectArray();
  for (int i = 0; i < objs.size(); i++) {
    btRigidBody *b = btRigidBody::upcast(objs[i]);
    if (b == nullptr || !(b->getFlags() & BPP_GYRO_MIDPOINT) ||
        b->getInvMass() == 0 || !b->isActive() ||
        b->isStaticOrKinematicObject())
      continue;
    const btMatrix3x3 &R = b->getWorldTransform().getBasis();
    const btMatrix3x3 I = R.scaled(b->getLocalInertia()) * R.transpose();
    const btVector3 w = b->getAngularVelocity();
    const btVector3 Iw = I * w;
    btMatrix3x3 Sw, SIw;                       // [w]x and [I w]x
    w.getSkewSymmetricMatrix(&Sw[0], &Sw[1], &Sw[2]);
    Iw.getSkewSymmetricMatrix(&SIw[0], &SIw[1], &SIw[2]);
    const btMatrix3x3 A = I + (Sw * I - SIw) * (btScalar(0.5) * dt);
    const btMatrix3x3 Ainv = A.inverse();
    b->setAngularVelocity(w - Ainv * (w.cross(Iw) * dt));
    // (Bullet hands out only a const reference to the body's inverse world
    // inertia; the body is not const, and the next proceedToTransform
    // overwrites it)
    const_cast<btMatrix3x3 &>(b->getInvInertiaTensorWorld()) = Ainv;
  }
}

#ifdef HAS_LIB_ASSIMP
#include "objects/mesh.h"
#include "objects/openscad.h"
#endif

#include "objects/palette.h"
#include "constraintdraw.h"
#include "culling.h"
#include "povexport.h"
#include "screenmerge.h"
#include "shadowrecord.h"

#include "objects/cam.h"

#include "dembed.h"
#include "geo.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QDebug>

#include <QTimer>
#include <QAbstractEventDispatcher>
#include <QMetaEnum>
#include <QTime>
#include <QMap>
#include <QElapsedTimer>
#include <QApplication>
#include <QOpenGLContext>
#include <algorithm>
#include <tuple>

#include <boost/exception/all.hpp>
#include <boost/exception/info.hpp>
#include <boost/throw_exception.hpp>

#include <cstdlib>
#include <cmath>

#if defined(Q_OS_LINUX)
/**
 * @brief Lua allocator that returns 16-byte aligned memory.
 *
 * Bullet's maths types are SIMD-aligned, so a Bullet object Lua allocates and
 * owns has to sit on a 16-byte boundary; the default allocator only promises
 * the platform's malloc alignment. Follows the lua_Alloc contract: a zero
 * @p nsize frees, and a non-null @p ptr reallocates by allocating, copying and
 * freeing, since posix_memalign has no realloc counterpart.
 *
 * @param ud    User data. Unused.
 * @param ptr   Block to resize or free, or null to allocate.
 * @param osize Size of the existing block.
 * @param nsize Requested size, or 0 to free.
 * @return The new block, or null when freeing or on allocation failure.
 */
static void *aligned_lua_alloc(void *ud, void *ptr, size_t osize, size_t nsize) {
  (void)ud;
  (void)osize;
  if (nsize == 0) {
    if (ptr)
      free(ptr);
    return nullptr;
  }
  if (ptr) {
    void *newptr = nullptr;
    if (posix_memalign(&newptr, 16, nsize) != 0)
      return nullptr;
    size_t copy = nsize < osize ? nsize : osize;
    memcpy(newptr, ptr, copy);
    free(ptr);
    return newptr;
  }
  void *newptr = nullptr;
  if (posix_memalign(&newptr, 16, nsize) != 0)
    return nullptr;
  return newptr;
}
#endif

#include <luabind/class_info.hpp>
#include <luabind/tag_function.hpp>


#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QStringList>

/// Boost.Exception tag carrying a Lua stack trace on a thrown exception,
/// read back by Viewer::showLuaException().
using stack_info = boost::error_info<struct tag_stack_str, std::string>;

using namespace std;

/**
 * @brief Forwards Bullet's debug-draw geometry to immediate-mode OpenGL.
 *
 * Bullet asks a btIDebugDraw to render its own visualisations, in bpp's case
 * the constraint geometry from btDynamicsWorld::debugDrawConstraint(). Only
 * drawLine() is used for that, so the rest of the interface is stubbed out.
 */
class GLDebugDrawer : public btIDebugDraw {
public:
  /**
   * @brief Draws one coloured line segment.
   * @param from  Start point in world space.
   * @param to    End point in world space.
   * @param color RGB colour.
   */
  void drawLine(const btVector3 &from, const btVector3 &to,
                const btVector3 &color) override {
    glColor3f(color.x(), color.y(), color.z());
    glBegin(GL_LINES);
    glVertex3d(from.x(), from.y(), from.z());
    glVertex3d(to.x(), to.y(), to.z());
    glEnd();
  }

  /**
   * @brief Draws a contact point. Not implemented.
   *
   * Bullet passes the contact position and normal on the second body, the
   * separation distance, the contact's age and a colour; all are ignored, and
   * the parameters are left unnamed so the empty body draws no warning.
   */
  void drawContactPoint(const btVector3 &, const btVector3 &, btScalar, int,
                        const btVector3 &) override {}

  /**
   * @brief Reports a Bullet diagnostic through Qt's warning channel.
   * @param warningString The message.
   */
  void reportErrorWarning(const char *warningString) override {
    qWarning() << warningString;
  }

  /**
   * @brief Draws text in the scene. Not implemented.
   *
   * Bullet passes the world position and the string; both are ignored, and the
   * parameters are left unnamed so the empty body draws no warning.
   */
  void draw3dText(const btVector3 &, const char *) override {}

  /**
   * @brief Sets which categories of debug geometry Bullet should emit.
   * @param mode A combination of btIDebugDraw::DebugDrawModes.
   */
  void setDebugMode(int mode) override { _debugMode = mode; }

  /**
   * @brief Returns which categories of debug geometry are enabled.
   * @return The current debug mode flags.
   */
  int getDebugMode() const override { return _debugMode; }

private:
  int _debugMode = 0; ///< Which categories of debug geometry Bullet emits.
};

QString Viewer::toString() const { return QString("Viewer"); }

void Viewer::addObject(Object *o) {
  if (o == nullptr)
    return;

  if (L != nullptr && _luabindRegistry.find(o) == _luabindRegistry.end()) {
    // Only attempt to create a luabind::object if there are at least two
    // stack elements (self + arg) and the second isn't nil. When this
    // function is called from C++ (not Lua) the Lua stack may be empty and
    // calling from_stack would read invalid memory and corrupt luabind's
    // object_rep.
    if (lua_gettop(L) >= 2 && !lua_isnil(L, 2)) {
      // Create a Lua reference to the object on the stack.
      // This avoids holding a luabind::object that calls luaL_unref in its destructor.
      lua_pushvalue(L, 2);  // Copy the object at stack index 2
      int ref = luaL_ref(L, LUA_REGISTRYINDEX);
      _luabindRegistry[o] = ref;
    }
  }

  addObject(o, o->getCol1(), o->getCol2());
  addConstraints(o->getConstraints());
}

void Viewer::addObjectLua(const luabind::object &handle) {
  if (L == nullptr || !handle.is_valid())
    return;
  if (luabind::type(handle) == LUA_TTABLE) {
    addObjectList(handle);
    return;
  }
  Object *o = luabind::object_cast<Object *>(handle);
  if (o == nullptr)
    return;
  if (!_takenFromLua.contains(o)) {
    handle.push(L);
    luabind::detail::object_rep *rep = luabind::detail::get_instance(L, -1);
    if (rep != nullptr)
      rep->release();
    lua_pop(L, 1);
    _takenFromLua.insert(o);
  }
  addObject(o);
}

void Viewer::addObjectList(const luabind::object &objs) {
  if (L == nullptr || !objs.is_valid())
    return;

  // Re-enter through the Lua-visible v:add(Object) overload for each
  // element, instead of calling addObject(Object*) directly here, so every
  // object goes through the same adopt(_2)/registry bookkeeping that a
  // plain v:add(obj) call from a script would trigger.
  luabind::object self(L, this);
  luabind::object addFn = self["add"];
  for (luabind::iterator i(objs), end; i != end; ++i) {
    luabind::call_function<void>(addFn, self, *i);
  }
}

Object *Viewer::removeObject(Object *o) {
  if (o == nullptr)
    return nullptr;

  // (out of the world it is in, whichever is in use)
  const int was = _curWorld;
  if (!_worlds.empty() && o->getWorld() != nullptr && o->getWorld() != dynamicsWorld) {
    const int k = worldIndex(o->getWorld());
    if (k >= 0)
      useWorld(k);
  }
  struct Back {
    Viewer *v; int was;
    ~Back() { v->useWorld(was); }
  } back{this, was};

  // A constraint joining its body comes out of the world with it (Bullet
  // can't step a constraint whose body has left the world). It stays the
  // script's to remove, and goes back in when the object is added back.
  // So do bodies it had before (one a constraint kept in the world).
  QList<btRigidBody *> bodies;
  if (o->body != nullptr && !o->isDecoration())   // (a decoration's body is never in the world)
    bodies.append(o->body);
  for (btRigidBody *b : o->formerBodies())
    if (b->isInWorld())
      bodies.append(b);
  for (btRigidBody *b : bodies) {
    for (btTypedConstraint *c : *_constraints) {
      if (&c->getRigidBodyA() == b || &c->getRigidBodyB() == b) {
        if (!_detached.contains(c)) {
          dynamicsWorld->removeConstraint(c);
          _detached.insert(c);
        }
      }
    }
    dynamicsWorld->removeRigidBody(b);
  }

  SoftBody *sb = dynamic_cast<SoftBody *>(o);
  if (sb != nullptr && sb->getSoftBody() != nullptr)
    dynamicsWorld->removeSoftBody(sb->getSoftBody());

  _objects->remove(o);
  _merge.remove(o);                      // (its batch is made again without it)
  o->setWorld(nullptr);
  o->setParent(0);

  return o;
}

// Removed objects bpp still owns are listed, by address, in a table in the
// Lua registry whose values are the scripts' handles to them, held weakly:
// when a handle is collected its entry goes, and reapRemoved() frees the
// object.
static const char *REMOVED_TABLE = "bpp_removed_objects";

static void pushRemovedTable(lua_State *L) {
  lua_getfield(L, LUA_REGISTRYINDEX, REMOVED_TABLE);
  if (lua_istable(L, -1))
    return;
  lua_pop(L, 1);
  lua_newtable(L);
  lua_newtable(L);
  lua_pushstring(L, "v");
  lua_setfield(L, -2, "__mode");
  lua_setmetatable(L, -2);
  lua_pushvalue(L, -1);
  lua_setfield(L, LUA_REGISTRYINDEX, REMOVED_TABLE);
}

static void setRemovedEntry(lua_State *L, Object *o, const luabind::object *handle) {
  pushRemovedTable(L);
  lua_pushlightuserdata(L, o);
  if (handle != nullptr)
    handle->push(L);
  else
    lua_pushnil(L);
  lua_rawset(L, -3);
  lua_pop(L, 1);
}

luabind::object Viewer::removeObjectLua(const luabind::object &handle) {
  Object *o = luabind::object_cast<Object *>(handle);
  if (o == nullptr || L == nullptr)
    return handle;

  // Only an object v:add took from Lua is bpp's to free; anything else
  // still belongs to its Lua handle.
  const bool ours = _objects->contains(o);
  removeObject(o);
  if (!ours)
    return handle;

  // (the handle it was added with: the one the script has; see handleOf())
  luabind::object kept = _luabindRegistry.count(o) ? handleOf(o) : handle;
  auto it = _luabindRegistry.find(o);
  if (it != _luabindRegistry.end()) {
    luaL_unref(L, LUA_REGISTRYINDEX, it->second);
    _luabindRegistry.erase(it);
  }
  _removed.insert(o);
  setRemovedEntry(L, o, &kept);
  return kept;
}

void Viewer::reapRemoved() {
  if (_removed.isEmpty() || L == nullptr)
    return;

  QList<Object *> gone;
  pushRemovedTable(L);
  for (Object *o : _removed) {
    lua_pushlightuserdata(L, o);
    lua_rawget(L, -2);
    const bool held = !lua_isnil(L, -1);
    lua_pop(L, 1);
    if (held)
      continue;
    // (a constraint still joins one of its bodies: not while the script
    // has it)
    bool joined = false;
    for (btTypedConstraint *c : *_constraints) {
      btRigidBody *a = &c->getRigidBodyA(), *b = &c->getRigidBodyB();
      if (o->body != nullptr && (a == o->body || b == o->body))
        joined = true;
      for (btRigidBody *r : o->formerBodies())
        if (a == r || b == r)
          joined = true;
    }
    if (joined)
      continue;
    gone.append(o);
  }
  lua_pop(L, 1);

  for (Object *o : gone) {
    _removed.remove(o);
    _takenFromLua.remove(o);
    if (o->body != nullptr)
      _aabbSeen.erase(o->body);
    o->preDestructor();
    delete o;
  }
}

void Viewer::setTau(btScalar tau) {
  dynamicsWorld->getSolverInfo().m_tau = tau;
}


// Bullet recomputes every object's bounding box on every substep by
// default, even objects that never move; with many substeps a frame and
// thousands of fixed parts, that's most of the work of a quiet scene.
// Instead, the substeps update only moving (active) objects, as Bullet does
// The narrowphase's pass over the broadphase's pairs. Bullet visits every
// pair whose boxes overlap at every step, and for each one first asks
// needsCollision(): a pair of which neither object is active -- fixed,
// asleep, or out of the simulation -- is turned down there and nothing more
// is done with it. bpp's collision groups let fixed objects pair up with
// each other (see Object), and those pairs never go away: in the rec room
// 3,764 of 3,917 pairs, turned down at every step, a fifth of all the
// physics time. This makes the same test first, in a tight loop, and hands
// every other pair to Bullet's own callback just as before: the same pairs,
// in the same order, with the same outcome, so the simulation is exactly the
// same. (With a near callback of a script's own, or Bullet's sorted pair
// order asked for, it leaves the pass to Bullet.)
//
// With threads (setThreads), the same pass runs over the pairs side by side
// (setThreaded), as Bullet's btCollisionDispatcherMt does, but in the same
// order as on one thread. Each pair is worked out by one thread, so its
// contacts come out the same whichever thread it is; what threads would
// change is the order of the dispatcher's list of manifolds (one per
// touching pair), which the solver follows: on one thread a pair's new
// manifold goes on the end and a released one is swapped out at once, as
// the pairs come. Threaded, each thread notes its manifolds made and
// released, with the pair's place in the pass, and afterwards, on one
// thread, they are put on and taken off the list in the pass's order, just
// as on one thread. So the list is the same, and a threaded world collides
// exactly as with threads off (handover/THREADS.md in the Walker Room).
namespace {
class RestSkippingDispatcher : public btCollisionDispatcher {
public:
  explicit RestSkippingDispatcher(btCollisionConfiguration *cfg) : btCollisionDispatcher(cfg) {}
#if BT_THREADSAFE
  void setThreaded(bool on) { _threaded = on; }
#endif
  void dispatchAllCollisionPairs(btOverlappingPairCache *pairCache, const btDispatcherInfo &info,
                                 btDispatcher *dispatcher) override {
    if (info.m_deterministicOverlappingPairs || getNearCallback() != defaultNearCallback) {
      btCollisionDispatcher::dispatchAllCollisionPairs(pairCache, info, dispatcher);
      return;
    }
    btBroadphasePairArray &pairs = pairCache->getOverlappingPairArray();
#if BT_THREADSAFE
    if (_threaded) {
      dispatchThreaded(pairs, info);
      return;
    }
#endif
    for (int i = 0; i < pairs.size(); ++i) {
      btBroadphasePair &pair = pairs[i];
      const btCollisionObject *a = static_cast<btCollisionObject *>(pair.m_pProxy0->m_clientObject);
      const btCollisionObject *b = static_cast<btCollisionObject *>(pair.m_pProxy1->m_clientObject);
      if (!a->isActive() && !b->isActive())
        continue;                       // (needsCollision()'s first test)
      defaultNearCallback(pair, *this, info);
    }
  }
#if BT_THREADSAFE
  btPersistentManifold *getNewManifold(const btCollisionObject *b0, const btCollisionObject *b1) override {
    if (!_inPass)
      return btCollisionDispatcher::getNewManifold(b0, b1);
    // (btCollisionDispatcher::getNewManifold, without putting it on the list)
    btScalar breaking = (m_dispatcherFlags & CD_USE_RELATIVE_CONTACT_BREAKING_THRESHOLD)
      ? btMin(b0->getCollisionShape()->getContactBreakingThreshold(gContactBreakingThreshold),
              b1->getCollisionShape()->getContactBreakingThreshold(gContactBreakingThreshold))
      : gContactBreakingThreshold;
    btScalar processing = btMin(b0->getContactProcessingThreshold(), b1->getContactProcessingThreshold());
    void *mem = m_persistentManifoldPoolAllocator->allocate(sizeof(btPersistentManifold));   // (locks: BT_THREADSAFE)
    if (mem == nullptr) {
      btAssert((m_dispatcherFlags & CD_DISABLE_CONTACTPOOL_DYNAMIC_ALLOCATION) == 0);
      mem = btAlignedAlloc(sizeof(btPersistentManifold), 16);
    }
    btPersistentManifold *m = new (mem) btPersistentManifold(b0, b1, 0, breaking, processing);
    note(m, true);
    return m;
  }
  void releaseManifold(btPersistentManifold *m) override {
    if (!_inPass)
      btCollisionDispatcher::releaseManifold(m);
    else
      note(m, false);                   // (taken off the list, and freed, after the pass)
  }

private:
  struct Change { int pair, seq; btPersistentManifold *m; bool made; };
  static thread_local int t_pair, t_seq;   // (the pair this thread is on, and its changes so far)
  void note(btPersistentManifold *m, bool made) {
    _changes[btGetCurrentThreadIndex()].push_back(Change{t_pair, t_seq++, m, made});
  }
  struct Body : public btIParallelForBody {
    RestSkippingDispatcher *d;
    btBroadphasePair *pairs;
    const int *active;
    const btDispatcherInfo *info;
    void forLoop(int iBegin, int iEnd) const override {
      for (int k = iBegin; k < iEnd; ++k) {
        t_pair = active[k];
        t_seq = 0;
        defaultNearCallback(pairs[active[k]], *d, *info);
      }
    }
  };
  void dispatchThreaded(btBroadphasePairArray &pairs, const btDispatcherInfo &info) {
    _active.resize(0);
    bool soft = false;
    for (int i = 0; i < pairs.size(); ++i) {
      const btCollisionObject *a = static_cast<btCollisionObject *>(pairs[i].m_pProxy0->m_clientObject);
      const btCollisionObject *b = static_cast<btCollisionObject *>(pairs[i].m_pProxy1->m_clientObject);
      if (a->isActive() || b->isActive()) {
        _active.push_back(i);           // (needsCollision()'s first test, as above)
        soft = soft || a->getInternalType() == btCollisionObject::CO_SOFT_BODY ||
                       b->getInternalType() == btCollisionObject::CO_SOFT_BODY;
      }
    }
    if (soft || _active.size() < MIN_THREADED_PAIRS) {
      // (a soft body's collisions change the soft body: one thread; and too few
      // pairs to share out -- one walker, about 55 a step, ran half as fast
      // threaded, waking the threads costing more than they saved; four, about
      // 250, gained 1.6 times on 2 threads. Either way the same collisions.)
      for (int i : _active)
        defaultNearCallback(pairs[i], *this, info);
      return;
    }
    Body body;
    body.d = this;
    body.pairs = &pairs[0];
    body.active = &_active[0];
    body.info = &info;
    _inPass = true;
    btParallelFor(0, _active.size(), 4, body);
    _inPass = false;
    _all.resize(0);
    for (auto &c : _changes) {
      _all.insert(_all.end(), c.begin(), c.end());
      c.clear();
    }
    std::sort(_all.begin(), _all.end(), [](const Change &x, const Change &y) {
      return x.pair != y.pair ? x.pair < y.pair : x.seq < y.seq;
    });
    for (const Change &c : _all) {     // (on and off the list in the pass's order, as on one thread)
      if (c.made) {
        c.m->m_index1a = m_manifoldsPtr.size();
        m_manifoldsPtr.push_back(c.m);
      } else {
        btCollisionDispatcher::releaseManifold(c.m);
      }
    }
  }
  static const size_t MIN_THREADED_PAIRS = 128;
  bool _threaded = false, _inPass = false;
  std::vector<int> _active;
  std::vector<Change> _changes[BT_MAX_THREAD_COUNT], _all;
#endif
};
#if BT_THREADSAFE
thread_local int RestSkippingDispatcher::t_pair = 0;
thread_local int RestSkippingDispatcher::t_seq = 0;
#endif
} // namespace

// with forceUpdateAllAabbs off, and before each frame's step this brings up
// to date the box of any sleeping or fixed object a script has moved since
// the last frame (scripts only move things between steps). Only moved
// objects are touched: refreshing a fixed object's box shifts it into the
// broadphase's moving set, which would be slower if done to all of them.
void Viewer::updateMovedAabbs() {
  dynamicsWorld->setForceUpdateAllAabbs(false);
  btCollisionObjectArray &objs = dynamicsWorld->getCollisionObjectArray();
  if (_aabbSeen.size() > (size_t)objs.size() * 2 + 64)
    _aabbSeen.clear();                  // forget objects that have gone
  for (int i = 0; i < objs.size(); ++i) {
    btCollisionObject *o = objs[i];
    if (o->isActive())
      continue;                         // Bullet keeps these up to date
    const btTransform &t = o->getWorldTransform();
    const btCollisionShape *shape = o->getCollisionShape();
    auto it = _aabbSeen.find(o);
    if (it == _aabbSeen.end()) {
      _aabbSeen.emplace(o, std::make_pair(t, shape));
      dynamicsWorld->updateSingleAabb(o);
    } else if (!(it->second.first == t) || it->second.second != shape) {
      it->second = std::make_pair(t, shape);
      dynamicsWorld->updateSingleAabb(o);
    }
  }
}

int Viewer::stepSimulation(btScalar timeStep, int maxSubSteps, btScalar fixedTimeStep) {
  reapRemoved();
  updateMovedAabbs();
  return dynamicsWorld->stepSimulation(timeStep, maxSubSteps, fixedTimeStep);
}

// More worlds. A script that never asks for one has the scene's own, and
// none of this does anything. Each new world is made exactly as clear()
// makes the scene's own, so what is loaded into one runs as it does alone.
// The world in use is always the one in the members (dynamicsWorld, ...), so
// everything else here works on it unchanged; useWorld() swaps.
int Viewer::newWorld() {
  if (_worlds.empty()) {
    PhysWorld main;
    main.cfg = collisionCfg;
    main.broadphase = broadphase;
    main.dispatcher = dispatcher;
    main.solver = solver;
    main.world = dynamicsWorld;
    _worlds.push_back(std::move(main));
    _curWorld = 0;
  }
  PhysWorld w;
  w.cfg = new btSoftBodyRigidBodyCollisionConfiguration();
  w.broadphase = new btDbvtBroadphase();
  w.dispatcher = new RestSkippingDispatcher(w.cfg);
  w.solver = new btSequentialImpulseConstraintSolver();
  w.world = newBppWorld(w.dispatcher, w.broadphase, w.solver, w.cfg);
  w.world->setInternalTickCallback(bppGyroPreTick, nullptr, true);
  w.world->setDebugDrawer(_debugDrawer);
  w.world->setGravity(btVector3(0.0f, -9.81f, 0.0f));      // (G, as clear() sets it)
  w.world->getWorldInfo().m_broadphase = w.broadphase;
  w.world->getWorldInfo().m_dispatcher = w.dispatcher;
  w.world->getWorldInfo().m_gravity = w.world->getGravity();
  w.world->getWorldInfo().m_sparsesdf.Initialize();
  btCollisionDispatcher *dispatcher_ptr = w.dispatcher;
  GImpactPlaneAlgorithm::registerAlgorithm(dispatcher_ptr);
  w.place.setIdentity();
  _worlds.push_back(std::move(w));
  return (int)_worlds.size() - 1;
}

void Viewer::useWorld(int i) {
  if (_worlds.empty() || i == _curWorld)
    return;
  if (i < 0 || i >= (int)_worlds.size()) {
    qWarning() << "useWorld: no world" << i;
    return;
  }
  std::swap(_worlds[_curWorld].aabbSeen, _aabbSeen);
  PhysWorld &w = _worlds[i];
  collisionCfg = w.cfg;
  broadphase = w.broadphase;
  dispatcher = w.dispatcher;
  solver = w.solver;
  dynamicsWorld = w.world;
  std::swap(w.aabbSeen, _aabbSeen);
  SoftBody::setWorldInfo(&dynamicsWorld->getWorldInfo());
  _curWorld = i;
}

void Viewer::placeWorld(int i, const btTransform &place) {
  if (i <= 0 || i >= (int)_worlds.size())
    return;
  PhysWorld &w = _worlds[i];
  w.placed = true;
  w.place = place;
  foreach (Object *o, *_objects) {
    if (o->getWorld() == w.world) {
      o->placed = true;
      o->place = place;
    }
  }
  _merge.invalidate();
}

int Viewer::worldIndex(const btDynamicsWorld *w) const {
  for (int i = 0; i < (int)_worlds.size(); ++i)
    if (_worlds[i].world == w)
      return i;
  return -1;
}

btSoftRigidDynamicsWorld *Viewer::worldOfObject(const Object *o) const {
  btDynamicsWorld *w = o->getWorld();
  return w ? static_cast<btSoftRigidDynamicsWorld *>(w) : dynamicsWorld;
}

void Viewer::dropWorlds() {
  if (_worlds.empty())
    return;
  useWorld(0);
  for (size_t i = 1; i < _worlds.size(); ++i) {
    PhysWorld &w = _worlds[i];
    for (int k = w.world->getNumConstraints() - 1; k >= 0; --k)
      w.world->removeConstraint(w.world->getConstraint(k));
    btCollisionObjectArray &all = w.world->getCollisionObjectArray();
    for (int k = all.size() - 1; k >= 0; --k) {
      btCollisionObject *co = all[k];
      if (btSoftBody *sb = btSoftBody::upcast(co))
        w.world->removeSoftBody(sb);
      else if (btRigidBody *rb = btRigidBody::upcast(co))
        w.world->removeRigidBody(rb);
      else
        w.world->removeCollisionObject(co);
    }
    delete w.world;
    delete w.solver;
    delete w.dispatcher;
    delete w.broadphase;
    delete w.cfg;
  }
  _worlds.clear();
  _curWorld = 0;
  _conWorld.clear();
}

void Viewer::setErp(btScalar erp) {
  dynamicsWorld->getSolverInfo().m_erp = erp;
}

void Viewer::setErp2(btScalar erp) {
  dynamicsWorld->getSolverInfo().m_erp2 = erp;
}

void Viewer::setCfm(btScalar cfm) {
  dynamicsWorld->getSolverInfo().m_globalCfm = cfm;
}

void Viewer::setSolverIterations(int n) {
  dynamicsWorld->getSolverInfo().m_numIterations = n;
}

// Joint warm-starting ("si-warm") and bpp's world (BppWorld, setThreads): bppworld.cpp.

// Raises a Lua error from a function luabind calls, with the same message
// luaL_error gives (where in the script, then what), but by throwing:
// luaL_error would jump straight out past luabind's C++ frames, never
// freeing what they hold (Lua is built as C). luabind::error tells luabind
// the message is already on the stack; it raises it once its frames are
// done. See tests/21-lua-errors.lua.
[[noreturn]] static void luaFail(lua_State *L, const std::string &message) {
  luaL_where(L, 1);
  lua_pushstring(L, message.c_str());
  lua_concat(L, 2);
  throw luabind::error(L);
}

// Decorations that follow a body: decorations.cpp.
void Viewer::attach(Object *o, Object *parent) {
  if (o == nullptr || parent == nullptr)
    luaFail(L, "attach: needs two objects");
  if (!o->isDecoration())
    luaFail(L, "attach: only a decoration can follow another object (set o.decoration = true before v:add)");
  if (o == parent)
    luaFail(L, "attach: an object can't follow itself");
  _decorations.attach(o, parent);
}

void Viewer::detach(Object *o) { _decorations.detach(o); }

int Viewer::setThreads(int n) {
#if BT_THREADSAFE
  BppWorld *w = static_cast<BppWorld *>(dynamicsWorld);
  if (n <= 0) {
    w->stopThreads();
    static_cast<RestSkippingDispatcher *>(dispatcher)->setThreaded(false);
    return 0;
  }
  if (_solverKind != "si" && _solverKind != "si-warm") {
    luaFail(L, "setThreads: needs the solver \"si\" or \"si-warm\" (setSolver), not '" + _solverKind + "'");
  }
  static btITaskScheduler *scheduler = nullptr;   // (Bullet's own thread pool, one for all worlds)
  if (scheduler == nullptr) {
    scheduler = btCreateDefaultTaskScheduler();
    btSetTaskScheduler(scheduler);
  }
  n = btMin(n, scheduler->getMaxNumThreads());
  scheduler->setNumThreads(n);
  w->startThreads(n, _solverKind == "si-warm");
  static_cast<RestSkippingDispatcher *>(dispatcher)->setThreaded(true);   // (collisions side by side too)
  return n;
#else
  if (n > 1)
    emitScriptOutput(QString("setThreads: this bpp's Bullet has no threads, so it runs on one "
                             "(build bpp with qmake CONFIG+=bundled_bullet: scripts/bullet-threads.sh)"));
  return 0;
#endif
}

void Viewer::setSolverInfo(const std::string &name, double value) {
  btContactSolverInfo &i = dynamicsWorld->getSolverInfo();
  if (name == "residual") i.m_leastSquaresResidualThreshold = value;
  else if (name == "sor") i.m_sor = value;
  else if (name == "warmstarting") i.m_warmstartingFactor = value;
  else if (name == "splitImpulse") i.m_splitImpulse = value != 0;
  else if (name == "randomOrder") {
    if (value != 0) i.m_solverMode |= SOLVER_RANDMIZE_ORDER; else i.m_solverMode &= ~SOLVER_RANDMIZE_ORDER;
  } else if (name == "iterations") i.m_numIterations = int(value);
  else if (name == "jointWarmstart") g_jointWarmstart = value;
  else if (name == "erp") i.m_erp = value;
  else if (name == "erp2") i.m_erp2 = value;
  else luaFail(L, "setSolverInfo: unknown '" + name + "' (residual, sor, warmstarting, jointWarmstart, erp, erp2, splitImpulse, randomOrder, iterations)");
}

int Viewer::solverFallbacks() const {
  if (_mlcpInterface && dynamicsWorld)
    return static_cast<btMLCPSolver *>(dynamicsWorld->getConstraintSolver())->getNumFallbacks();
  return 0;
}

void Viewer::setSolver(const std::string &kind) {
  btMLCPSolverInterface *method = nullptr;
  btConstraintSolver *s = nullptr;
  if (kind == "si")
    s = new btSequentialImpulseConstraintSolver();
  else if (kind == "si-warm")   // (joint warm-starting: bppworld.cpp)
    s = newWarmJointSolver();
  else if (kind == "nncg")
    s = new btNNCGConstraintSolver();
  else if (kind == "nncg-joints") {   // (NNCG for the joints only, sequential impulse for contacts)
    btNNCGConstraintSolver *n = new btNNCGConstraintSolver();
    n->m_onlyForNoneContact = true;
    s = n;
  }
  else if (kind == "mlcp-dantzig" || kind == "mlcp-pgs" || kind == "mlcp-lemke") {
    if (kind == "mlcp-dantzig") method = new btDantzigSolver();
    else if (kind == "mlcp-pgs") method = new btSolveProjectedGaussSeidel();
    else method = new btLemkeSolver();
    s = new btMLCPSolver(method);
  } else {
    luaFail(L, "setSolver: unknown kind '" + kind + "' (si, si-warm, nncg, nncg-joints, mlcp-dantzig, mlcp-pgs, mlcp-lemke)");
  }
  btConstraintSolver *old = dynamicsWorld->getConstraintSolver();
  dynamicsWorld->setConstraintSolver(s);
  for (PhysWorld &w : _worlds)
    if (w.solver == old) w.solver = s;
  if (solver == old) solver = s;
  delete old;
  delete _mlcpInterface;
  _mlcpInterface = method;
  _solverKind = kind;
#if BT_THREADSAFE
  if (int n = static_cast<BppWorld *>(dynamicsWorld)->threads()) {   // (threaded: the pool made again of this kind)
    if (kind == "si" || kind == "si-warm") {
      setThreads(n);
    } else {
      static_cast<BppWorld *>(dynamicsWorld)->stopThreads();
      static_cast<RestSkippingDispatcher *>(dispatcher)->setThreaded(false);
      emitScriptOutput(QString("setSolver: threads off (they need \"si\" or \"si-warm\")"));
    }
  }
#endif
}

luabind::object Viewer::handleOf(Object *o) {
  if (L == nullptr)
    return luabind::object();
  if (o == nullptr) {
    lua_pushnil(L);
    luabind::object nil(luabind::from_stack(L, -1));
    lua_pop(L, 1);
    return nil;
  }
  auto it = _luabindRegistry.find(o);
  if (it == _luabindRegistry.end())
    return luabind::object(L, o);
  lua_rawgeti(L, LUA_REGISTRYINDEX, it->second);
  luabind::object h(luabind::from_stack(L, -1));
  lua_pop(L, 1);
  return h;
}

void Viewer::eachContact(const luabind::object &fn) {
  if (dynamicsWorld == nullptr || !fn.is_valid())
    return;

  btDispatcher *dispatcher = dynamicsWorld->getDispatcher();
  if (dispatcher == nullptr)
    return;

  // Map a collision body back to the Object that owns it. The object set is
  // small (a scene is tens of objects, not thousands) and this only runs when
  // a script explicitly asks for a dump, so a linear scan is fine and avoids
  // keeping a parallel index in sync with add/removeObject.
  auto ownerOf = [this](const btCollisionObject *co) -> Object * {
    if (co == nullptr || _objects == nullptr)
      return nullptr;
    for (Object *o : *_objects) {
      if (o != nullptr && o->body == co)
        return o;
    }
    return nullptr;
  };

  const int numManifolds = dispatcher->getNumManifolds();
  for (int i = 0; i < numManifolds; ++i) {
    btPersistentManifold *manifold = dispatcher->getManifoldByIndexInternal(i);
    if (manifold == nullptr)
      continue;

    const int numContacts = manifold->getNumContacts();
    if (numContacts == 0)
      continue;

    // (the handles the script added them with, so an object never has two:
    // see removeObjectLua())
    luabind::object oa = handleOf(ownerOf(manifold->getBody0()));
    luabind::object ob = handleOf(ownerOf(manifold->getBody1()));

    for (int j = 0; j < numContacts; ++j) {
      const btManifoldPoint &pt = manifold->getContactPoint(j);
      const btVector3 &pos = pt.getPositionWorldOnB();
      const btVector3 &nrm = pt.m_normalWorldOnB;

      luabind::call_function<void>(fn, oa, ob, pos.x(), pos.y(), pos.z(),
                                   nrm.x(), nrm.y(), nrm.z(),
                                   pt.getDistance(), pt.getAppliedImpulse());
    }
  }
}

btScalar Viewer::rayTest(const btVector3 &from, const btVector3 &to) {
  return rayTest(from, to, luabind::object());
}

btScalar Viewer::rayTest(const btVector3 &from, const btVector3 &to,
                         const luabind::object &ignore) {
  if (dynamicsWorld == nullptr)
    return 1;
  const btCollisionObject *skip = nullptr;
  if (ignore.is_valid() && luabind::type(ignore) == LUA_TUSERDATA) {
    Object *o = luabind::object_cast<Object *>(ignore);
    if (o != nullptr)
      skip = o->body;
  }
  // The nearest body that collides (objects with collides = false are not
  // seen), leaving out `skip`. Boxes are hit exactly, by the slab test in
  // the box's frame: Bullet's own ray test of a convex shape (GJK) is off
  // by 2 cm on a 10 m box and misses one 33 m long when the ray starts
  // within a few tenths of a metre of it. Other shapes are Bullet's.
  struct Ray : public btCollisionWorld::ClosestRayResultCallback {
    const btCollisionObject *skip;
    Ray(const btVector3 &f, const btVector3 &t, const btCollisionObject *s)
        : btCollisionWorld::ClosestRayResultCallback(f, t), skip(s) {
      m_collisionFilterGroup = btBroadphaseProxy::AllFilter; // (BPP's bodies are COL_WALL)
    }
    bool needsCollision(btBroadphaseProxy *proxy) const override {
      if (skip != nullptr && proxy->m_clientObject == skip)
        return false;
      if (!btCollisionWorld::ClosestRayResultCallback::needsCollision(proxy))
        return false;
      const btCollisionObject *co = static_cast<const btCollisionObject *>(proxy->m_clientObject);
      const btCollisionShape *sh = co->getCollisionShape();
      if (sh == nullptr || sh->getShapeType() != BOX_SHAPE_PROXYTYPE)
        return true;
      const btVector3 h = static_cast<const btBoxShape *>(sh)->getHalfExtentsWithMargin();
      const btTransform inv = co->getWorldTransform().inverse();
      const btVector3 o = inv * m_rayFromWorld, d = inv * m_rayToWorld - o;
      btScalar t0 = 0, t1 = 1;
      for (int i = 0; i < 3; ++i) {
        if (btFabs(d[i]) < btScalar(1e-12)) {
          if (o[i] < -h[i] || o[i] > h[i]) return false;
        } else {
          btScalar a = (-h[i] - o[i]) / d[i], b = (h[i] - o[i]) / d[i];
          if (a > b) btSwap(a, b);
          if (a > t0) t0 = a;
          if (b < t1) t1 = b;
          if (t0 > t1) return false;
        }
      }
      // a hit only from outside (a ray that starts inside a box, as
      // Bullet's, does not see it), and only if nearer than the best so far
      bool inside = btFabs(o[0]) < h[0] && btFabs(o[1]) < h[1] && btFabs(o[2]) < h[2];
      if (!inside && t0 < m_closestHitFraction) {
        Ray *self = const_cast<Ray *>(this);
        self->m_closestHitFraction = t0;
        self->m_collisionObject = co;
      }
      return false;
    }
  };
  Ray ray(from, to, skip);
  dynamicsWorld->rayTest(from, to, ray);
  return ray.hasHit() ? ray.m_closestHitFraction : btScalar(1);
}

void Viewer::addConstraint(btTypedConstraint *con) {
  if (!con)
    return;
  dynamicsWorld->addConstraint(con, true);
  _constraints->insert(con);
  if (_curWorld != 0)
    _conWorld.insert(con, _curWorld);
}

btTypedConstraint *Viewer::removeConstraint(btTypedConstraint *con) {
  const int k = _conWorld.value(con, 0);
  if (!_worlds.empty() && k != _curWorld && k < (int)_worlds.size())
    _worlds[k].world->removeConstraint(con);
  else
    dynamicsWorld->removeConstraint(con);
  _conWorld.remove(con);
  _constraints->remove(con);
  _detached.remove(con);
  return con;
}

void Viewer::addConstraints(QList<btTypedConstraint *> cons) {
  for (int i = 0; i < cons.size(); ++i)
    if (cons[i])
      addConstraint(cons[i]);
}

btVehicleRaycaster *Viewer::createVehicleRaycaster() {
  btVehicleRaycaster *raycaster = new btDefaultVehicleRaycaster(dynamicsWorld);
  _vehicle_raycasters->insert(raycaster);
  return raycaster;
}

void Viewer::addVehicle(btRaycastVehicle *veh) {
  dynamicsWorld->addVehicle(veh);
  _raycast_vehicles->insert(veh);
}

void Viewer::luaBindInstance(lua_State *s) {
  using namespace luabind;

  L = s;
  globals(s)["v"] = this;
}

/**
 * @brief Prints a pending Lua error to stderr and pops it off the stack.
 * @param L      The Lua state.
 * @param status Status returned by lua_pcall() or similar; 0 means no error
 *               and nothing is done.
 */
void report_errors(lua_State *L, int status) {
  if (status != 0) {
    std::cerr << "-- " << lua_tostring(L, -1) << "\n";
    lua_pop(L, 1); // remove error message
  }
}

/// Standard gravity in m/s^2, used as the default for a fresh world.
constexpr btScalar G = 9.81f;

using namespace qglviewer;

namespace {
/**
 * @brief Computes an axis-aligned bounding box around every object.
 *
 * Starts from a fixed 10-unit box so an empty scene still has a sensible
 * extent, then grows it to include each rigid and soft body. A Plane
 * contributes its declared size rather than the effectively infinite AABB
 * Bullet reports for it, and a body whose position is not finite is included
 * without being offset, so one diverged object cannot make the box unusable.
 *
 * Runs every frame over every object, so a fixed body keeps its part of the
 * box (Object::boxMin and boxMax) and has it worked out again only when its
 * shape, scale, place or drawn position changes; the result is the same, to
 * the bit, as working every part out afresh.
 *
 * @param[in]  objects The objects to cover.
 * @param[out] aabb    Receives minimum x, y, z followed by maximum x, y, z.
 */
void getAABB(QSet<Object *> *objects, btScalar aabb[6]) {
  aabb[0] = -10;
  aabb[1] = -10;
  aabb[2] = -10;
  aabb[3] = 10;
  aabb[4] = 10;
  aabb[5] = 10;

  QSet<Object *>::iterator oi;
  for (oi = objects->begin(); oi != objects->end(); oi++) {
    Object *o = *oi;

    if (o->body != nullptr && o->placed) {
      // (a world drawn elsewhere: its box where it's drawn; its endless
      // planes left out)
      if (dynamic_cast<Plane *>(o) != nullptr || o->body->getCollisionShape() == nullptr)
        continue;
      btVector3 lo, hi;
      o->body->getCollisionShape()->getAabb(o->place * o->body->getWorldTransform(), lo, hi);
      for (int i = 0; i < 3; ++i) {
        aabb[i] = btMin(aabb[i], lo[i]);
        aabb[i + 3] = btMax(aabb[i + 3], hi[i]);
      }
      continue;
    } else if (o->body != nullptr) {
      btVector3 oaabbmin(0, 0, 0), oaabbmax(0, 0, 0);
      const btRigidBody *rb = o->body;
      const btCollisionShape *shape = rb->getCollisionShape();
      btVector3 pos(0, 0, 0);
      if (rb->getMotionState() != nullptr) {
        btTransform mt;
        rb->getMotionState()->getWorldTransform(mt);
        pos = mt.getOrigin();            // (what getPosition() gives)
      }
      // A fixed body's part of the box is worked out again only when its
      // shape, scale or place changes: for a compound or a mesh, working it
      // out from the shape is most of the cost of all this.
      const bool fixed = rb->isStaticObject() && shape != nullptr;
      const btTransform &t = rb->getWorldTransform();
      if (fixed && o->boxKept && o->boxShape == shape &&
          o->boxScale == shape->getLocalScaling() && o->boxPos == pos &&
          o->boxTrans.getOrigin() == t.getOrigin() &&
          o->boxTrans.getBasis() == t.getBasis()) {
        oaabbmin = o->boxMin;
        oaabbmax = o->boxMax;
      } else {
        rb->getAabb(oaabbmin, oaabbmax);
        if (Plane *pl = dynamic_cast<Plane *>(o)) {
          btScalar s = pl->getSize();
          oaabbmin[0] = -s;
          oaabbmin[1] = -s;
          oaabbmin[2] = -s;

          oaabbmax[0] = s;
          oaabbmax[1] = s;
          oaabbmax[2] = s;
        }
        if (isfinite(pos.x()) && isfinite(pos.y()) && isfinite(pos.z())) {
          oaabbmin -= pos;
          oaabbmax += pos;
        }
        o->boxKept = fixed;
        if (fixed) {
          o->boxShape = shape;
          o->boxScale = shape->getLocalScaling();
          o->boxTrans = t;
          o->boxPos = pos;
          o->boxMin = oaabbmin;
          o->boxMax = oaabbmax;
        }
      }

      for (int i = 0; i < 3; ++i) {
        aabb[i] = qMin(aabb[i], oaabbmin[i]);
        aabb[3 + i] = qMax(aabb[3 + i], oaabbmax[i]);
      }
      continue;                          // (a SoftBody has no rigid body)
    }

    SoftBody *sb = dynamic_cast<SoftBody *>(o);
    if (sb != nullptr && sb->getSoftBody() != nullptr) {
      btVector3 oaabbmin(0, 0, 0), oaabbmax(0, 0, 0);
      sb->getSoftBody()->getAabb(oaabbmin, oaabbmax);

      for (int i = 0; i < 3; ++i) {
        aabb[i] = qMin(aabb[i], oaabbmin[i]);
        aabb[3 + i] = qMax(aabb[3 + i], oaabbmax[i]);
      }
    }
  }
}
} // namespace

void Viewer::keyReleaseEvent(QKeyEvent *e) {
  _keys.release(e, _frameNum, [this](const std::exception &ex, const char *where) {
    showLuaException(ex, where);
  });
  QGLViewer::keyReleaseEvent(e);
}

void Viewer::keyPressEvent(QKeyEvent *e) {
  _hover.interrupt();                // (a key hides the tooltip)
  if (_keys.press(e, _frameNum, [this](const std::exception &ex, const char *where) {
        showLuaException(ex, where);
      }))
    return; // (the script's key)

  switch (e->key()) {

  case Qt::Key_S:
    _simulate = !_simulate;
    emit simulationStateChanged(_simulate);
    break;
  case Qt::Key_P:
    _savePOV = !_savePOV;
    if (_savePOV) {
      _firstFrame = _frameNum;
    }
    // (saying so: it writes the whole scene to a file every frame, which
    // can slow a big scene right down, and is easy to start by mistake)
    emitScriptOutput(_savePOV ? "POV-Ray export ON (P): every frame is saved for "
                                "POV-Ray until P is pressed again"
                              : "POV-Ray export OFF (P)");
    emit POVStateChanged(_savePOV);
    break;
  case Qt::Key_D:
    _deactivation = !_deactivation;
    emit deactivationStateChanged(_deactivation);
    break;
  case Qt::Key_R:
    parse(_scriptContent);
    break;
  case Qt::Key_F1:
  case Qt::Key_F2:
    if (luabind::type(_cb_cycleObject) == LUA_TFUNCTION) {
      int direction = (e->key() == Qt::Key_F1) ? -1 : 1;
      try {
        luabind::call_function<void>(_cb_cycleObject, direction);
      } catch (const std::exception &e) {
        showLuaException(e, "onCycleObject()");
      }
    }
    break;
  case Qt::Key_C:
    resetCamView();
    break;
  case Qt::Key_Tab:
    _quad.toggle();
    update();
    break;
#if USE_VFE
  case Qt::Key_Escape:
    if (_vfeRenderActive && _vfeSession) {
      _vfeSession->CancelRender();
    } else {
      QGLViewer::keyPressEvent(e);
    }
    break;
  case Qt::Key_Space:
    if (_vfeRenderActive && _vfeSession && _vfeSession->IsPausable()) {
      if (_vfeSession->Paused()) {
        _vfeSession->Resume();
      } else {
        _vfeSession->Pause();
      }
    } else {
      QGLViewer::keyPressEvent(e);
    }
    break;
#endif // USE_VFE
  default:
    QGLViewer::keyPressEvent(e);
  }
}

void Viewer::mousePressEvent(QMouseEvent *e) {
  _hover.disarm();                   // (a click hides the tooltip)
#if USE_VFE
  if (_vfePreviewVisible && (_vfeRenderActive || _vfePreviewTexture)) {
    // Dismiss the VFE render preview back to the normal OpenGL scene; an
    // in-progress render keeps running, just no longer displayed. The click
    // itself is consumed rather than also starting a camera drag, so
    // dismissing doesn't also nudge the view.
    _vfePreviewVisible = false;
    update();
    e->accept();
    return;
  }
#endif // USE_VFE

  if (_quad.startPan(e->pos())) {
    e->accept();
    return;
  }
  QGLViewer::mousePressEvent(e);
}

void Viewer::mouseMoveEvent(QMouseEvent *e) {
  _hover.mouseMoved(e->pos(), e->buttons()); // (never consumes the event)
  if (_quad.pan(e->pos())) {
    e->accept();
    return;
  }
  QGLViewer::mouseMoveEvent(e);
}

void Viewer::mouseReleaseEvent(QMouseEvent *e) {
  if (_quad.endPan()) {
    e->accept();
    return;
  }
  QGLViewer::mouseReleaseEvent(e);
}

void Viewer::wheelEvent(QWheelEvent *e) {
  _hover.interrupt();                // (hide while zooming)
  if (_quad.zoom(e->position().toPoint(), e->angleDelta().y())) {
    e->accept();
    update();
    return;
  }
  // The main (perspective) view, wheel alone: each click moves the camera
  // 10% of the way towards the pivot's depth, along its view. QGLViewer's
  // own step is never less than a fifth of the scene's radius, so in a big
  // scene one click could jump metres, and the camera could never ease up
  // to something small. (Clicks the other way move it back by the same
  // factor; modified wheels are QGLViewer's as before.)
  if (e->modifiers() == Qt::NoModifier &&
      camera()->type() == qglviewer::Camera::PERSPECTIVE) {
    const qreal notches = e->angleDelta().y() / 120.0;
    const qreal depth =
        qMax(qreal(fabs(camera()->frame()->coordinatesOf(camera()->pivotPoint()).z)),
             qreal(0.001) * camera()->sceneRadius());
    const qreal step = depth * (1.0 - pow(0.9, notches));
    camera()->setPosition(camera()->position() + camera()->viewDirection() * step);
    e->accept();
    update();
    return;
  }
  QGLViewer::wheelEvent(e);
}

void Viewer::addObject(Object *o, int type, int mask) {
  _objects->insert(o);
  o->setWorld(dynamicsWorld);
  o->placed = !_worlds.empty() && _worlds[_curWorld].placed;
  if (o->placed)
    o->place = _worlds[_curWorld].place;
  if (_removed.remove(o) && L != nullptr)
    setRemovedEntry(L, o, nullptr);   // (bpp's again, held by the scene)

  if (o->body != nullptr && !o->isDecoration()) {   // (a decoration is only drawn: Bullet never sees it)
    if (!_deactivation) {
      o->body->setActivationState(DISABLE_DEACTIVATION);
    }
    dynamicsWorld->addRigidBody(o->body, type, mask);
  }

  SoftBody *sb = dynamic_cast<SoftBody *>(o);
  if (sb != nullptr && sb->getSoftBody() != nullptr)
    dynamicsWorld->addSoftBody(sb->getSoftBody(), type, mask);

  // constraints that came out of the world with it go back once both
  // their bodies are in it again
  if (o->body != nullptr && !o->isDecoration() && !_detached.isEmpty()) {
    for (btTypedConstraint *c : _detached.values()) {
      // (a constraint to a fixed point joins its body to Bullet's fixed body,
      // which is never in the world)
      btRigidBody &fixed = btTypedConstraint::getFixedBody();
      btRigidBody &a = c->getRigidBodyA(), &b = c->getRigidBodyB();
      if ((&a == o->body || &b == o->body) && (&a == &fixed || a.isInWorld()) &&
          (&b == &fixed || b.isInWorld())) {
        dynamicsWorld->addConstraint(c, true);
        _detached.remove(c);
      }
    }
  }
}

void Viewer::addObjects(QList<Object *> ol, int type, int mask) {
  foreach (Object *o, ol) {
    addObject(o, type, mask);
  }
}

void Viewer::addObjects() {}

void Viewer::setGravity(btVector3 gravity) {
  dynamicsWorld->setGravity(gravity);
  // btDiscreteDynamicsWorld::setGravity() only updates rigid bodies; soft
  // bodies read gravity from the world info instead.
  dynamicsWorld->getWorldInfo().m_gravity = gravity;
}

btVector3 Viewer::getGravity() { return dynamicsWorld->getGravity(); }

void Viewer::setTimeStep(btScalar ts) { _timeStep = ts; }

btScalar Viewer::getTimeStep() { return _timeStep; }

void Viewer::setMaxSubSteps(int mst) { _maxSubSteps = mst; }

int Viewer::getMaxSubSteps() { return _maxSubSteps; }

int Viewer::loadSound(const QString &path) {
  if (!_audioAvailable) {
    return -1;
  }

  auto existing = _soundIdByPath.find(path);
  if (existing != _soundIdByPath.end()) {
    return existing->second;
  }

  Mix_Chunk *chunk = Mix_LoadWAV(path.toUtf8().constData());
  if (!chunk) {
    qWarning() << "loadSound: failed to load" << path << ":" << Mix_GetError();
    return -1;
  }

  int id = _nextSoundId++;
  _soundChunks[id] = chunk;
  _soundIdByPath[path] = id;
  return id;
}

void Viewer::playSound(int id) {
  if (!_audioAvailable || id < 0) {
    return;
  }
  auto it = _soundChunks.find(id);
  if (it == _soundChunks.end()) {
    return;
  }
  // -1: play on the first free channel. 0: play once, don't loop.
  int ch = Mix_PlayChannel(-1, it->second, 0);
  if (ch >= 0) Mix_Volume(ch, MIX_MAX_VOLUME);
  recordSound(it->second, 1.0);
}

void Viewer::playSound(int id, double volume) {
  if (!_audioAvailable || id < 0) {
    return;
  }
  auto it = _soundChunks.find(id);
  if (it == _soundChunks.end()) {
    return;
  }
  if (volume <= 0) return;
  if (volume > 1) volume = 1;
  int ch = Mix_PlayChannel(-1, it->second, 0);
  if (ch >= 0) Mix_Volume(ch, (int)(volume * MIX_MAX_VOLUME + 0.5));
  recordSound(it->second, volume);
}

// (Lua numbers voices from 1, the synth from 0)
void Viewer::setTone(int voice, double freq, double amp) {
  _synth.setTone(voice - 1, freq, amp, 0.0);
}

void Viewer::setTone(int voice, double freq, double amp, double pan) {
  _synth.setTone(voice - 1, freq, amp, pan);
}

void Viewer::setToneTimbre(int voice, double brightness, double noise) {
  _synth.setTimbre(voice - 1, brightness, noise);
}

void Viewer::silenceTones() { _synth.reset(); }

void Viewer::recordSound(Mix_Chunk *chunk, double volume) {
  if (!_savePOV)
    return;
  _wavTrack.record(chunk, volume, _frameNum);
}

void Viewer::setFixedTimeStep(btScalar fts) { _fixedTimeStep = fts; }

btScalar Viewer::getFixedTimeStep() { return _fixedTimeStep; }

double Viewer::getTime() const { return _wallTimer.nsecsElapsed() / 1e9; }

Viewer::Viewer(QWidget *parent, QSettings *settings, bool savePOV)
    : QGLViewer() {
  Q_UNUSED(parent);

  _settings = settings;

  setStateFileName(QString());

  _wallTimer.start();
  _prefsPool.setMaxThreadCount(1); // (preference writes in the order made)
  _prefsPool.setExpiryTimeout(-1);

  {
    bool ok = false;
    double ms = qEnvironmentVariable("BPP_FRAME_TIMING").toDouble(&ok);
    if (ok && ms > 0)
      setFrameTiming(ms);
  }

  _objects = new QSet<Object *>();
  _constraints = new QSet<btTypedConstraint *>();
  _raycast_vehicles = new QSet<btRaycastVehicle *>();
  _vehicle_raycasters = new QSet<btVehicleRaycaster *>();

  L = nullptr;

  _parsing = false;
  _has_exception = false;

  _savePOV = savePOV;
  _povExportFailed = false;

  setSnapshotFormat("png");

  _simulate = false;
  _deactivation = true;

  _timeStep = 1 / 25.0;
  _maxSubSteps = 7;
  _snCamera = new SpaceNavigatorCamera(this);
  if (_settings != nullptr)
    _snCamera->loadSettings(_settings);
  _fixedTimeStep = 1 / 100.0;

  _initialCameraPosition = Vec(0, 0, 0);
  _initialCameraOrientation = Quaternion();
  _initialCameraHorizontalFieldOfView = 0.5;
  _initialCameraUpVector = Vec(0, 1, 0);

  // Matches the POV-Ray light_source <500,500,-500> in includes/settings.inc.
  // POV-Ray is left-handed, OpenGL is right-handed, so Z is negated (see
  // Object::povMatrixFromGL()).
  _light0 = btVector4(500.0, 500.0, 500.0, 0.4);
  _light1 = btVector4(-200.0, 100.0, 200.0, 0.2);
  _light0Color = _light1Color = btVector4(1, 1, 1, 1);
  _gl_ambient = btVector3(0.2f, 0.2f, 0.2f);
  _gl_diffuse = btVector4(0.7f, 0.7f, 0.7f, 1.0f);
  _gl_shininess = btScalar(100.0);
  _gl_specular_col = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_specular = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_model_ambient = btVector4(0.2f, 0.2f, 0.2f, 1.0f);

  // A soft/rigid collision configuration is a drop-in superset of
  // btDefaultCollisionConfiguration, so every existing rigid-body code path
  // keeps working; it additionally registers the soft-vs-rigid and
  // soft-vs-soft collision algorithms that SoftBody objects need.
  collisionCfg = new btSoftBodyRigidBodyCollisionConfiguration();
  // create and keep pointers to subcomponents so we can delete them later
  broadphase = new btDbvtBroadphase();
  dispatcher = new RestSkippingDispatcher(collisionCfg);
  solver = new btSequentialImpulseConstraintSolver();

  _aabbSeen.clear();
  dynamicsWorld = newBppWorld(dispatcher, broadphase,
                                               solver, collisionCfg);
  dynamicsWorld->setInternalTickCallback(bppGyroPreTick, nullptr, true);
  dynamicsWorld->getWorldInfo().m_broadphase = broadphase;
  dynamicsWorld->getWorldInfo().m_dispatcher = dispatcher;
  dynamicsWorld->getWorldInfo().m_gravity = dynamicsWorld->getGravity();
  dynamicsWorld->getWorldInfo().m_sparsesdf.Initialize();
  SoftBody::setWorldInfo(&dynamicsWorld->getWorldInfo());

  _debugDrawer = new GLDebugDrawer();
  _debugDrawer->setDebugMode(btIDebugDraw::DBG_DrawConstraints |
                             btIDebugDraw::DBG_DrawConstraintLimits);
  dynamicsWorld->setDebugDrawer(_debugDrawer);
  _showConstraints = true;

  _shadows = true;
  // Holds no GL resources until the first shadowed frame asks for them, so
  // building it here, with no context current, is safe.
  _shadowMap = new ShadowMap();

  btCollisionDispatcher *dispatcher_ptr = dispatcher;
  GImpactPlaneAlgorithm::registerAlgorithm(dispatcher_ptr);

  _frameNum = 1;
  _firstFrame = 1;

#if USE_VFE
  _vfePollTimer = nullptr;
  _vfeRenderActive = false;
  _vfeRestartPending = false;
  _vfePreviewVisible = true;
  _vfePreviewNeedsReset = false;
  _vfePreviewTexture = 0;
  _vfePreviewWidth = 0;
  _vfePreviewHeight = 0;
#endif // USE_VFE


  setCamera(new Cam(this));

  // POV-Ray properties
  mPreSDL = "";
  mPostSDL = "";

  // joystick integration
  _joystickInterface = new JoystickInterfaceSDL();
  connect(&_joystickHandler, &JoystickHandler::data, this,
          &Viewer::onJoystickData);
  _joystickHandler.setInterface(_joystickInterface);
  _joystickHandler.initialize();
  _joystickHandler.setUpdateInterval(40); // 25 fps

  // audio: short sound effects, e.g. an escapement's tick/tock, triggered
  // from Lua. SDL_INIT_JOYSTICK is already up by this point (see above);
  // SDL_InitSubSystem is safe to call again to add AUDIO on top of it.
  // Deliberately tolerant of failure -- no audio device (common in
  // headless/CI runs) must not crash the simulation, just leave sound
  // effects silently unavailable.
  _audioAvailable = false;
  _nextSoundId = 0;
  if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
    qWarning() << "Audio unavailable (SDL_InitSubSystem):" << SDL_GetError()
               << "-- sound effects disabled, simulation continues normally.";
  } else if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024) < 0) {
    qWarning() << "Audio unavailable (Mix_OpenAudio):" << Mix_GetError()
               << "-- sound effects disabled, simulation continues normally.";
    SDL_QuitSubSystem(SDL_INIT_AUDIO);
  } else {
    _audioAvailable = true;
    // room for many overlapping effects (e.g. a pool break)
    Mix_AllocateChannels(32);
    // and the synthesised voices of setTone(), mixed in after them
    _synth.attach();
  }
  // The voices sound only while the simulation is stepping: pausing (S,
  // the toolbar button, stopSim()) hushes them, resuming brings them back.
  connect(this, &Viewer::simulationStateChanged, this, [this](bool on) {
    _synth.setGate(on && animationIsStarted());
  });


  // SpaceNavigator 3D mouse integration
  _spaceNavigator = new SpaceNavigator(this);
  connect(_spaceNavigator, &SpaceNavigator::axesChanged, this,
          &Viewer::onSpaceNavigatorAxes);
  connect(_spaceNavigator, &SpaceNavigator::axesNormChanged, this,
          &Viewer::onSpaceNavigatorNorm);
  connect(_spaceNavigator, &SpaceNavigator::buttonChanged, this,
          &Viewer::onSpaceNavigatorButton);

  // (the sustaining timer of the built-in camera control: see
  // SpaceNavigatorCamera)
  connect(_snCamera, &SpaceNavigatorCamera::tick, this, &Viewer::onSpaceNavigatorTick);

  connect(_spaceNavigator, &SpaceNavigator::deviceOpened, this, [this] {
    emit statusEvent(QString("SpaceNavigator opened: %1")
                         .arg(_spaceNavigator->devicePath()));
  });
  connect(_spaceNavigator, &SpaceNavigator::error, this,
          [this](const QString &message) {
            emit statusEvent(QString("SpaceNavigator: %1").arg(message));
          });
  const bool snOpened = _spaceNavigator->open();
  if (snOpened) {
    emit statusEvent(QString("SpaceNavigator detected: %1")
                         .arg(_spaceNavigator->devicePath()));
  }

  startAnimation();
}

void Viewer::onJoystickData(const JoystickInfo &ji) {
  if (simHeld()) // (a dialog is open: see simHeld())
    return;
  QMutexLocker locker(&mutex);
  if (_cb_onJoystick) {
    try {
      luabind::call_function<void>(_cb_onJoystick, _frameNum, ji);
    } catch (const std::exception &e) {
      showLuaException(e, "onJoystick()");
    }
  }
}

void Viewer::onSpaceNavigatorAxes(const SpaceNavigator::Axes &axes) {
  if (simHeld()) // (a dialog is open: see simHeld())
    return;
  QMutexLocker locker(&mutex);

  // A Lua onSpaceNavigator callback takes precedence over the built-in
  // camera control, so scripts can use the 3D mouse for their own purposes.
  if (_cb_onSpaceNavigator) {
    try {
      luabind::call_function<void>(_cb_onSpaceNavigator, _frameNum, axes);
    } catch (const std::exception &e) {
      showLuaException(e, "onSpaceNavigator()");
    }
  }
}

void Viewer::onSpaceNavigatorNorm(const SpaceNavigator::AxesNorm &axes) {
  if (simHeld()) // (a dialog is open: see simHeld())
    return;
  QMutexLocker locker(&mutex);

  // A Lua onSpaceNavigator callback takes precedence over the built-in
  // camera control.  Clear the target so no residual deflection moves the
  // camera once the script takes over.
  if (_cb_onSpaceNavigator) {
    _snCamera->clearTarget();
    return;
  }

  if (_snCamera->report(axes, camera(), _initialCameraUpVector))
    updateGLViewer();
}

void Viewer::onSpaceNavigatorTick() {
  if (simHeld()) // (a dialog is open: see simHeld())
    return;
  QMutexLocker locker(&mutex);
  // (while a script has the device, the interval passes unused)
  if (_snCamera->sustain(_cb_onSpaceNavigator ? nullptr : camera(), _initialCameraUpVector))
    updateGLViewer();
}

void Viewer::onSpaceNavigatorButton(int button, bool pressed) {
  if (simHeld()) // (a dialog is open: see simHeld())
    return;
  QMutexLocker locker(&mutex);
  if (pressed) {
    if (button == 0) {
      resetCamView();
    } else if (button == 1 || button == 2) {
      if (_snCamera->mode == SpaceNavigatorCamera::Object) {
        _snCamera->mode = SpaceNavigatorCamera::Fly;
        emit statusEvent(QString("SpaceNavigator mode: Fly"));
      } else {
        _snCamera->mode = SpaceNavigatorCamera::Object;
        emit statusEvent(QString("SpaceNavigator mode: Object"));
      }
    }
  }
}

// The 3D mouse settings take no mutex, like setShowConstraints() below:
// a script sets them (v.snMode and the rest) while Viewer::parse() holds
// `mutex` for its whole run, and a plain QMutex locked again on the same
// thread deadlocks. Each is a single value read only on this (the GUI)
// thread.
void Viewer::setSpaceNavigatorMode(int mode) {
  _snCamera->mode = (mode == 1) ? SpaceNavigatorCamera::Object : SpaceNavigatorCamera::Fly;
}

int Viewer::spaceNavigatorMode() const {
  return (_snCamera->mode == SpaceNavigatorCamera::Object) ? 1 : 0;
}

void Viewer::setSpaceNavigatorLockHorizon(bool on) {
  _snCamera->lockHorizon = on;
}

bool Viewer::spaceNavigatorLockHorizon() const { return _snCamera->lockHorizon; }

void Viewer::setSpaceNavigatorAutoFlySpeed(bool on) {
  _snCamera->autoFlySpeed = on;
}

bool Viewer::spaceNavigatorAutoFlySpeed() const { return _snCamera->autoFlySpeed; }

void Viewer::setSpaceNavigatorShowOrbitAxis(bool on) {
  _snCamera->showOrbitAxis = on;
  updateGLViewer();
}

bool Viewer::spaceNavigatorShowOrbitAxis() const { return _snCamera->showOrbitAxis; }

void Viewer::setSpaceNavigatorZoomDirection(bool forward) {
  _snCamera->zoomForward = forward;
}

bool Viewer::spaceNavigatorZoomForward() const { return _snCamera->zoomForward; }

void Viewer::setSpaceNavigatorPanZoom(bool on) {
  _snCamera->panZoom = on;
}

bool Viewer::spaceNavigatorPanZoom() const { return _snCamera->panZoom; }

void Viewer::setShowConstraints(bool on) {
  // No mutex here (unlike the input-event setters above): Viewer::parse()
  // already holds `mutex` for a script's entire run, so a script setting
  // v.showConstraints at top level -- the natural place to do it -- would
  // deadlock against itself on a plain (non-recursive) QMutex. _showConstraints
  // is a single bool only ever read from the render thread in
  // drawConstraints(), same as the unlocked setTau/setErp/setCfm above.
  _showConstraints = on;
}

bool Viewer::showConstraints() const { return _showConstraints; }

// Shadows are a render-path setting a script will normally choose at top
// level, so like setShowConstraints() above these take no mutex: see the note
// there. _shadowMap exists from the constructor on, and only reaches for GL
// resources on the render thread, in renderShadowDepth() and
// drawSceneInternal().
void Viewer::setShadows(bool on) {
  if (_shadows == on)
    return;
  _shadows = on;
  emit shadowsChanged(on);
}

void Viewer::setShadowsPreference(bool on) {
  _shadowsPref = on;
  setShadows(on);
}

bool Viewer::shadowsPreference() const { return _shadowsPref; }

void Viewer::setShadowsFromScript(bool on) {
  if (on == _shadowsPref || _shadowsNoted)
    return;
  _shadowsNoted = true;
  const QString note =
      QString("(this script asked for shadows %1; your setting -- %2 -- is "
              "kept: View > Shadows. To keep one object out of the shadows, "
              "set its obj.castShadow = false)")
          .arg(on ? "on" : "off", _shadowsPref ? "on" : "off");
  // (headless, on stderr: a run's own output stays exactly what it was)
  if (isHeadless())
    fprintf(stderr, "%s\n", note.toUtf8().constData());
  else
    emitScriptOutput(note);
}

bool Viewer::shadows() const { return _shadows; }

void Viewer::setCulling(bool on) { _culling = on; }

bool Viewer::culling() const { return _culling; }

int Viewer::drawnObjects() const { return _drawnObjects; }

int Viewer::shadowCasters() const { return _shadowCasters; }

void Viewer::setShadowCache(bool on) { _shadowRecord.enabled = on; }

bool Viewer::shadowCache() const { return _shadowRecord.enabled; }

int Viewer::shadowCached() const { return _shadowRecord.cached(); }


void Viewer::setShadowSaved(bool on) { _shadowRecord.saveDepth = on; }

bool Viewer::shadowSaved() const { return _shadowRecord.saveDepth; }

bool Viewer::shadowFromSaved() const { return _shadowRecord.fromSaved(); }

// The drawing timer. The graphics card's times come from timer queries
// (GL_TIME_ELAPSED, OpenGL 3.3 or ARB_timer_query), looked up by name so a
// context without them simply has none.
namespace {
typedef void(QOPENGLF_APIENTRYP DtGenQueries)(GLsizei, GLuint *);
typedef void(QOPENGLF_APIENTRYP DtBeginQuery)(GLenum, GLuint);
typedef void(QOPENGLF_APIENTRYP DtEndQuery)(GLenum);
typedef void(QOPENGLF_APIENTRYP DtGetQueryObjectuiv)(GLuint, GLenum, GLuint *);
const GLenum DT_TIME_ELAPSED = 0x88BF;
const GLenum DT_QUERY_RESULT = 0x8866;
const GLenum DT_QUERY_RESULT_AVAILABLE = 0x8867;
DtGenQueries dtGen = nullptr;
DtBeginQuery dtBegin = nullptr;
DtEndQuery dtEnd = nullptr;
DtGetQueryObjectuiv dtGet = nullptr;
} // namespace

void Viewer::setDrawTiming(bool on) { _drawTiming = on; }

bool Viewer::drawTiming() const { return _drawTiming; }

void Viewer::dtGpuBegin(int which) {
  if (_dtNoGpu)
    return;
  QOpenGLContext *c = QOpenGLContext::currentContext();
  if (c == nullptr)
    return;
  const void *ctx = glCacheContext();
  if (ctx != _dtCtx || glCacheEpoch() != _dtEpoch) {
    // (a new context: the old queries went with the old one)
    memset(_dtQueries, 0, sizeof(_dtQueries));
    memset(_dtPending, 0, sizeof(_dtPending));
    _dtCtx = ctx;
    _dtEpoch = glCacheEpoch();
    const QSurfaceFormat f = c->format();
    const bool has = (f.majorVersion() > 3 || (f.majorVersion() == 3 && f.minorVersion() >= 3)) ||
                     c->hasExtension("GL_ARB_timer_query");
    dtGen = reinterpret_cast<DtGenQueries>(c->getProcAddress("glGenQueries"));
    dtBegin = reinterpret_cast<DtBeginQuery>(c->getProcAddress("glBeginQuery"));
    dtEnd = reinterpret_cast<DtEndQuery>(c->getProcAddress("glEndQuery"));
    dtGet = reinterpret_cast<DtGetQueryObjectuiv>(c->getProcAddress("glGetQueryObjectuiv"));
    if (!has || !dtGen || !dtBegin || !dtEnd || !dtGet) {
      _dtNoGpu = true;
      return;
    }
  }
  unsigned &q = _dtQueries[_dtSlot][which];
  if (q == 0)
    dtGen(1, &q);
  dtBegin(DT_TIME_ELAPSED, q);
}

void Viewer::dtGpuEnd() {
  if (_dtNoGpu || dtEnd == nullptr || glCacheContext() != _dtCtx)
    return;
  dtEnd(DT_TIME_ELAPSED);
}

// The results of the frames before, whichever the card has finished (never
// waiting for one), and this frame's slot made ready.
void Viewer::dtGpuCollect() {
  if (_dtNoGpu || dtGet == nullptr || glCacheContext() != _dtCtx)
    return;
  for (int s = 0; s < 4; ++s) {
    if (!_dtPending[s])
      continue;
    GLuint ready0 = 0, ready1 = 0;
    dtGet(_dtQueries[s][0], DT_QUERY_RESULT_AVAILABLE, &ready0);
    dtGet(_dtQueries[s][1], DT_QUERY_RESULT_AVAILABLE, &ready1);
    if (!ready0 || !ready1) {
      if (s == _dtSlot)                  // (the ring has come round: drop it)
        _dtPending[s] = false;
      continue;
    }
    GLuint ns0 = 0, ns1 = 0;
    dtGet(_dtQueries[s][0], DT_QUERY_RESULT, &ns0);
    dtGet(_dtQueries[s][1], DT_QUERY_RESULT, &ns1);
    _dtShadowGpu += ns0 / 1.0e6;
    _dtScreenGpu += ns1 / 1.0e6;
    ++_dtGpuFrames;
    _dtPending[s] = false;
  }
}

QString Viewer::lastFrameDrawing() const {
  const LastFrame &f = _lfDone;
  if (f.all <= 0)
    return QString();
  QString merge = QString("merge %1").arg(f.merge, 0, 'f', 1);
  QStringList what;
  if (f.batches > 0)
    what << QString("%1 batch%2 made again").arg(f.batches).arg(f.batches == 1 ? "" : "es");
  if (f.recoloured > 0)
    what << QString("%1 recoloured").arg(f.recoloured);
  if (f.blanked > 0)
    what << QString("%1 with objects blanked").arg(f.blanked);
  if (!what.isEmpty())
    merge += " (" + what.join(", ") + ")";
  QString shadow = QString("shadow map %1").arg(f.shadow, 0, 'f', 1);
  QStringList sw;
  if (f.recorded > 0)
    sw << QString("record of %1 fixed objects made again").arg(f.recorded);
  if (f.depthSaved)
    sw << "saved depth made again";
  if (!sw.isEmpty())
    shadow += " (" + sw.join(", ") + ")";
  return QString("box %1, %2, cull %3, %4, screen %5, all %6")
      .arg(f.box, 0, 'f', 1)
      .arg(merge)
      .arg(f.cull, 0, 'f', 1)
      .arg(shadow)
      .arg(f.screen, 0, 'f', 1)
      .arg(f.all, 0, 'f', 1);
}

QString Viewer::drawTimingReport() {
  QString r;
  if (_dtFrames > 0) {
    const double n = _dtFrames;
    r = QString("processor: box %5, cull %1, shadow map %2, screen %3, all of draw %4")
            .arg(_dtCull / n, 0, 'f', 2)
            .arg(_dtShadow / n, 0, 'f', 2)
            .arg(_dtScreen / n, 0, 'f', 2)
            .arg(_dtDraw / n, 0, 'f', 2)
            .arg(_dtBox / n, 0, 'f', 2);
    if (_merge.made() > 0)
      r += QString(" (merge made %1 times)").arg(_merge.made());
    if (_dtGpuFrames > 0)
      r += QString("; graphics card: shadow map %1, screen %2")
               .arg(_dtShadowGpu / _dtGpuFrames, 0, 'f', 2)
               .arg(_dtScreenGpu / _dtGpuFrames, 0, 'f', 2);
    else if (_dtNoGpu)
      r += "; graphics card: no timers";
  }
  _dtCull = _dtShadow = _dtScreen = _dtDraw = _dtBox = 0;
  _merge.resetMade();
  _dtShadowGpu = _dtScreenGpu = 0;
  _dtFrames = _dtGpuFrames = 0;
  return r;
}

void Viewer::setShadowMapSize(int px) { _shadowMap->setMapSize(px); }

int Viewer::shadowMapSize() const { return _shadowMap->mapSize(); }

void Viewer::setShadowSoftness(btScalar texels) {
  _shadowMap->setSoftness(texels);
}

btScalar Viewer::shadowSoftness() const {
  return btScalar(_shadowMap->softness());
}

void Viewer::setShadowDarkness(btScalar d) { _shadowMap->setDarkness(d); }

btScalar Viewer::shadowDarkness() const {
  return btScalar(_shadowMap->darkness());
}

void Viewer::close() {
  QGLViewer::close();
}

void Viewer::setCamera(Cam *cam) {
  _cam = cam;
  QGLViewer::setCamera(cam);
}

Cam *Viewer::getCamera() { return _cam; }

void Viewer::setSavePOV(bool pov) {
  _savePOV = pov;

  if (_savePOV) {
    _firstFrame = _frameNum;
  }
}

void Viewer::setPOVSettingsInc(QString s) { _pov_settings_inc = s; }

QString Viewer::getPOVSettingsInc() { return _pov_settings_inc; }

bool Viewer::povExportFailed() const { return _povExportFailed; }

void Viewer::toggleSavePOV(bool savePOV) {
  _savePOV = savePOV;

  if (_savePOV) {
    _firstFrame = _frameNum;
  }
}

void Viewer::toggleDeactivation(bool deactivation) {
  _deactivation = deactivation;
}

void Viewer::startSim() {
  _simulate = true;
  emit simulationStateChanged(_simulate);
}

void Viewer::stopSim() {
  _simulate = false;
  emit simulationStateChanged(_simulate);
}

void Viewer::restartSim() {
  Vec camPos = camera()->position();
  Quaternion camOri = camera()->orientation();
  btScalar camHfov = camera()->horizontalFieldOfView();
  Vec camUp = camera()->upVector();

  // The values the parameters have now, to give back after the script runs
  // again. Not the buttons': their functions belong to this run's Lua state,
  // which parse() closes (given back, they crashed bpp); the new run makes
  // its own.
  // (In a block: the copies hold the buttons' functions too, and must go
  // while this run's state is still open.)
  QHash<QString, QVariant> savedParams;
  {
    const QHash<QString, QVariant> all = _params.all();
    for (auto it = all.constBegin(); it != all.constEnd(); ++it) {
      const ParamInfo info = _params.info(it.key());
      if (!info.isButton && !info.isButtonGroup)
        savedParams.insert(it.key(), it.value());
    }
  }

  parse(_scriptContent);

  camera()->setPosition(camPos);
  camera()->setOrientation(camOri);
  camera()->setHorizontalFieldOfView(camHfov);
  camera()->setUpVector(camUp, true);

  for (auto it = savedParams.constBegin(); it != savedParams.constEnd(); ++it) {
    if (!_params.all().contains(it.key())) continue;
    ParamInfo info = _params.info(it.key());
    if (info.hasRange) {
      addParam(it.key(), it.value().toDouble(), info.min, info.max, info.step, info.comment);
    } else {
      addParam(it.key(), it.value(), info.comment);
    }
  }
}

void Viewer::setScriptName(QString sn) { _scriptName = sn; }
void Viewer::setScriptBasePath(QString sbp) { _scriptBasePath = sbp; }

void Viewer::emitScriptOutput(const QString &out) { emit scriptHasOutput(out); }

// Sets the "Shortcuts" dock panel's text; see the declaration in viewer.h.
void Viewer::setHelpText(const QString &text) { emit helpTextChanged(text); }

// Sets the script's status-bar line; see the declaration in viewer.h.
void Viewer::setStatusText(const QString &text) {
  if (text == _statusText)
    return;
  _statusText = text;
  emit statusTextChanged(text);
}

int Viewer::lua_print(lua_State *L) {

  Viewer *p = static_cast<Viewer *>(lua_touserdata(L, lua_upvalueindex(1)));

  if (p) {
    int n = lua_gettop(L); /* number of arguments */

    int i;
    lua_getglobal(L, "tostring");
    for (i = 1; i <= n; i++) {
      const char *s;
      lua_pushvalue(L, -1); /* function to be called */
      lua_pushvalue(L, i);  /* value to print */
      lua_call(L, 1, 1);
      s = lua_tostring(L, -1); /* get result */
      if (s == nullptr)
        return luaL_error(L, "'tostring' must return a string to 'print'");
      // if (i>1) p->emitScriptOutput(QString("\t"));
      p->emitScriptOutput(QString(s));
      lua_pop(L, 1); /* pop result */
    }

    // p->emitScriptOutput(QString("\n"));
  } else {
    return luaL_error(L, "stack has no thread ref", "");
  }

  return 0;
}

/*
void Viewer::luabind_error(lua_State* L) {
    qDebug() << "luabind_error" << "\n";

    // the error message should be on top of the stack
    QString luaWhat = QString("%1").arg(lua_tostring(L, -1));

    //emit scriptHasOutput(QString("%1").arg(luaWhat));
}*/

bool Viewer::parse(QString txt) {
  QMutexLocker locker(&mutex);

  emit scriptStopped();

  if (_cb_preStop) {
    try {
      luabind::call_function<void>(_cb_preStop, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "preStop()");
    }
  }

  _parsing = true;
  _has_exception = false;

  _scriptContent = txt;

  bool animStarted = animationIsStarted();

  if (animStarted) {
    stopAnimation();
  }

emit scriptStarts();

  if (L != nullptr) {
    // Invalidate callback refs so Lua GC can collect the functions
    _cb_preStart = luabind::object();
    _cb_preStop = luabind::object();
    _cb_preDraw = luabind::object();
    _cb_postDraw = luabind::object();
    _cb_preSim = luabind::object();
    _cb_postSim = luabind::object();
    _cb_onCommand = luabind::object();
    _cb_onJoystick = luabind::object();
    _keys.clear();
    _cb_cycleObject = luabind::object();
    setStatusText(QString());   // (a script's status line goes with it)
    _synth.reset();             // (and its voices)
    _cb_onSpaceNavigator = luabind::object();
    _hover.clear();

    _params.releaseLua();

    // (removed objects bpp still owns go with the rest)
    for (Object *o : _removed)
      _objects->insert(o);
    _removed.clear();

    // Notify all objects that their luabind weak pointers are about to become
    // invalid (C++ objects will be deleted by clear() below).
    foreach (Object *o, *_objects) {
      o->preDestructor();
    }

    // Remove rigid bodies from the dynamics world while pointers are still
    // valid. After lua_close() the Bullet objects will be freed by Lua's GC.
    if (dynamicsWorld) {
      foreach (Object *o, *_objects) {
        if (o->body != nullptr && !o->isDecoration()) {
          worldOfObject(o)->removeRigidBody(o->body);
        }
        SoftBody *sb = dynamic_cast<SoftBody *>(o);
        if (sb != nullptr && sb->getSoftBody() != nullptr) {
          worldOfObject(o)->removeSoftBody(sb->getSoftBody());
        }
      }
    }
    removeLeftoverBodies();

    // Clear the luabind registry BEFORE closing the Lua state.
    // Release Lua references from the registry while L is still valid.
    if (L != nullptr) {
      for (auto& pair : _luabindRegistry) {
        luaL_unref(L, LUA_REGISTRYINDEX, pair.second);
      }
      _luabindRegistry.clear();
    }

    // lua_close() performs a final GC sweep that deletes all Lua-adopted
    // Bullet objects via their unique_ptr holders (adopt(result) policy).
    // After this call, C++ raw pointers to those objects become dangling.
    lua_close(L);
    L = nullptr;

    // Null out Bullet object pointers that Lua has freed. The C++ Object
    // destructors in clear() will skip these null pointers, avoiding
    // use-after-free and double-free.
    foreach (Object *o, *_objects) {
      o->body = nullptr;
      o->shape = nullptr;
#ifdef HAS_LIB_ASSIMP
      Mesh *m = dynamic_cast<Mesh *>(o);
      if (m) {
        m->luaRelease();
      }
#endif
      SoftBody *sb = dynamic_cast<SoftBody *>(o);
      if (sb) {
        sb->luaRelease();
      }
    }
  }

  clear();

  {
    // setup lua
#if defined(Q_OS_LINUX)
    L = lua_newstate(aligned_lua_alloc, nullptr);
#else
    L = luaL_newstate();
#endif

    // open all standard Lua libs
    luaL_openlibs(L);

    luaL_dostring(L, "os.setlocale('C')");
    // Lua 5.3+ folded math.atan2(y, x) into a two-argument math.atan;
    // restore the legacy name so older scripts keep working.
    luaL_dostring(L,
        "if type(math) == 'table' and type(math.atan2) ~= 'function' then "
        "math.atan2 = function(y, x) return math.atan(y, x) end end\n"
        "if atan2 == nil then atan2 = math.atan2 end");
    luaL_dostring(L, "printf = function(s,...) print(s:format(...)) end");

    // Build Lua package.path: search script directory first (if console mode), then CWD/demo, then installed
    QString defaultPath = getDefaultLuaPath(_scriptBasePath);
    QString path = _settings->value("lua/path").toString();
    if (path.isEmpty()) {
      path = defaultPath;
    } else {
      bool allExist = true;
      for (const QString &entry : path.split(';', Qt::SkipEmptyParts)) {
        QString dir = entry;
        dir.replace("?.lua", "");
        if (!QDir(dir).exists()) {
          allExist = false;
          break;
        }
      }
      if (!allExist)
        path = defaultPath;
    }
    QString p = QString("package.path = package.path..\";%1\"").arg(path);

    int error =
        luaL_loadstring(L, qPrintable(p)) || lua_pcall(L, 0, LUA_MULTRET, 0);

    if (error) {
      lua_error = tr("error: %1").arg(lua_tostring(L, -1));

      if (lua_error.contains(QRegularExpression(tr("stopping$")))) {
        lua_error = tr("script stopped");
        // qDebug() << "lua run : script stopped";
      } else {
        // qDebug() << QString("lua run : %1").arg(lua_error);
        emit scriptHasOutput(lua_error);
      }

      lua_pop(L, 1); /* pop error message from the stack */
    } else {
      lua_error = tr("ok");
    }

    luabind::open(L);

    // Lua's garbage collector stays on. It used to be stopped here, because a
    // script can build its own Bullet pieces (btRigidBody, btGImpactMeshShape,
    // btTriangleMesh, ...) and hand them to an object, which kept only raw
    // pointers to them: collecting them left dangling pointers. Now everything
    // the C++ side uses is kept referenced from Lua: an object keeps the body,
    // shape and mesh a script hands it (Object::keepLua()), and a Bullet
    // constructor that takes another script-made piece keeps it alive
    // (luabind's dependency policy, in lua_bullet_*.cpp). So the collector can
    // run all the time, and scripts no longer need to manage it.

    // register all bpp classes
    LuaBullet::luaBind(L);

    Cam::luaBind(L);
    Object::luaBind(L);
    Cone::luaBind(L);
    Cube::luaBind(L);
    Cylinder::luaBind(L);
    CsgObject::luaBind(L);
    Disc::luaBind(L);
    Heightfield::luaBind(L);
    Torus::luaBind(L);
    PovScriptWriter_luaBind(L);
    LayerManager::luaBind(L);
    BezierPatch::luaBind(L);
    Blob::luaBind(L);
    Bound::luaBind(L);
    Patch::luaBind(L);
    ReferenceObject::luaBind(L);
    Sweep::luaBind(L);
    SuperQuadric::luaBind(L);
    TrueType::luaBind(L);
#ifdef HAS_LIB_ASSIMP
    Mesh::luaBind(L);
    OpenSCAD::luaBind(L);
#endif
    Palette::luaBind(L);
    Plane::luaBind(L);
    RigidSoftContact::luaBind(L);
    SoftBody::luaBind(L);
    Sphere::luaBind(L);
    Terrain::luaBind(L);
    Triangle::luaBind(L);
    DemBed::luaBind(L);
    Geo::luaBind(L);
    Viewer::luaBind(L);

    luabind::bind_class_info(L);

    lua_pushlightuserdata(L, (void *)this);
    lua_pushcclosure(L, &Viewer::lua_print, 1);
    lua_setglobal(L, "print");

    // Scripts written when the collector was kept stopped call
    // collectgarbage("stop") after collecting by hand; that would switch the
    // collector off for good, so it is ignored. "collect", "step", "count"
    // and the rest work as usual. BPP_GC_AUTO tells a script that bpp
    // collects garbage itself.
    if (luaL_dostring(L,
                      "BPP_GC_AUTO = true\n"
                      "do\n"
                      "  local gc = collectgarbage\n"
                      "  collectgarbage = function(opt, ...)\n"
                      "    if opt == 'stop' then return 0 end\n"
                      "    return gc(opt, ...)\n"
                      "  end\n"
                      "end\n") != 0) {
      emit scriptHasOutput(QString("collectgarbage setup: %1").arg(lua_tostring(L, -1)));
      lua_pop(L, 1);
    }
  }

  luaBindInstance(L);

  // useful for shell scripting. Example:
  //
  // #!/usr/bin/bpp -f
  // print("Hello, BPP!")

  if (txt.startsWith("#!")) { // remove potential shebang on first line
    QStringList tmp = txt.split("\n");
    tmp.removeAt(0);
    txt = tmp.join("\n");
  }

  // Snapshot camera state before script execution so we can detect if
  // the script explicitly positioned the camera (e.g. via cam.pos/cam.look).
  Vec camPosBeforeScript = camera()->position();
  Quaternion camOriBeforeScript = camera()->orientation();

  int error = luaL_loadstring(L, txt.toUtf8().constData()) ||
              lua_pcall(L, 0, LUA_MULTRET, 0);

  // (Lua's garbage collector runs throughout: see where the classes are
  // registered above for why that is safe.)

  if (error) {
    lua_error = tr("error: %1").arg(lua_tostring(L, -1));

    QString trace;
    lua_Debug ar;
    for (int level = 0; lua_getstack(L, level, &ar); level++) {
      lua_getinfo(L, "Snl", &ar);
      QString info = QString("[%1] %2 (%3)")
                      .arg(ar.name ? ar.name : "?")
                      .arg(ar.short_src)
                      .arg(ar.currentline);
      if (trace.isEmpty()) {
        trace = info;
      } else {
        trace += "\n" + info;
      }
    }

    if (lua_error.contains(QRegularExpression(tr("stopping$")))) {
      lua_error = tr("script stopped");
    } else {
      if (!trace.isEmpty()) {
        emit scriptHasOutput(lua_error + "\n" + trace);
      } else {
        emit scriptHasOutput(lua_error);
      }
    }

    lua_pop(L, 1);
  } else {
    lua_error = tr("ok");
  }

  // If the script changed the camera (e.g. via cam.pos/cam.look), update the
  // initial camera state so the "House" button returns to the script's view.
  Vec camPosAfterScript = camera()->position();
  Quaternion camOriAfterScript = camera()->orientation();
  bool camChanged = (camPosBeforeScript != camPosAfterScript);
  if (!camChanged)
    for (int i = 0; i < 4; ++i)
      if (camOriBeforeScript[i] != camOriAfterScript[i]) { camChanged = true; break; }
  if (camChanged) {
    _initialCameraPosition = camPosAfterScript;
    _initialCameraOrientation = camOriAfterScript;
    _initialCameraHorizontalFieldOfView = camera()->horizontalFieldOfView();
    _initialCameraUpVector = camera()->upVector();
  }

  _frameNum = 1; // reset frames counter
  _firstFrame = 1;

  if (animStarted) {
    startAnimation();
  }

  // qDebug() << "Viewer::parse() end";

  emit scriptFinished();

  _parsing = false;

  return (error ? false : true);
}

// Removes whatever is still in the dynamics world once every object's own
// body is out: a body a script replaced (obj.body = another) stays in the
// world, kept alive from Lua (Object::retireLua()), and Lua frees it when the
// state is closed -- so it has to leave the world first.
void Viewer::removeLeftoverBodies() {
  if (!dynamicsWorld)
    return;
  QList<btSoftRigidDynamicsWorld *> worlds;
  worlds.append(dynamicsWorld);
  for (const PhysWorld &w : _worlds)
    if (w.world != nullptr && w.world != dynamicsWorld)
      worlds.append(w.world);
  for (btSoftRigidDynamicsWorld *dw : worlds) {
    btCollisionObjectArray &all = dw->getCollisionObjectArray();
    for (int i = all.size() - 1; i >= 0; --i) {
      btCollisionObject *co = all[i];
      if (btSoftBody *sb = btSoftBody::upcast(co))
        dw->removeSoftBody(sb);
      else if (btRigidBody *rb = btRigidBody::upcast(co))
        dw->removeRigidBody(rb);
      else
        dw->removeCollisionObject(co);
    }
  }
}

bool Viewer::executeLua(const QString &code) {
  if (!L) return false;
  int err = luaL_dostring(L, code.toUtf8().constData());
  if (err != 0) {
    emit scriptHasOutput(QString("executeLua: %1").arg(lua_tostring(L, -1)));
    lua_pop(L, 1);
    return false;
  }
  return true;
}

void Viewer::clear() {
  // qDebug() << "Viewer::clear() objects: " << _objects->size();

  _merge.clear();                        // (before the objects go)

  _params.clear();        // (a script's showParams() filter goes with it)
  emit paramsChanged();

  // Notify all objects that their luabind weak pointers are about to become
  // invalid (C++ objects will be deleted by clear() below).
  foreach (Object* o, *_objects) {
    o->preDestructor();
  }

  // Remove rigid bodies from the dynamics world before deleting anything.
  // Note: body pointers may already be null if they were nulled before
  // lua_close (Lua-owned bodies were freed by Lua GC).
  if (dynamicsWorld) {
    foreach (Object* o, *_objects) {
      if (o->body != nullptr && !o->isDecoration()) {
        worldOfObject(o)->removeRigidBody(o->body);
      }
      SoftBody *sb = dynamic_cast<SoftBody *>(o);
      if (sb != nullptr && sb->getSoftBody() != nullptr) {
        worldOfObject(o)->removeSoftBody(sb->getSoftBody());
      }
    }
  }

  // Remove constraints from the dynamics world before deleting them.
  if (dynamicsWorld) {
    foreach (btTypedConstraint* c, *_constraints) {
      const int k = _conWorld.value(c, 0);
      if (!_worlds.empty() && k != _curWorld && k < (int)_worlds.size())
        _worlds[k].world->removeConstraint(c);
      else
        dynamicsWorld->removeConstraint(c);
    }
  }

  // Delete Object instances. Body/shape pointers that were Lua-owned
  // have already been nulled before lua_close, so destructors skip them.
  // C++-owned body pointers (_ownsBody=true) are still valid and get deleted.
  {
    QList<Object*> objs = _objects->values();
    for (Object* o : objs) delete o;
  }
  _objects->clear();
  _takenFromLua.clear();
  _detached.clear();

  {
    QList<btTypedConstraint*> cons = _constraints->values();
    for (btTypedConstraint* c : cons) delete c;
  }
  _constraints->clear();

  {
    QList<btRaycastVehicle*> rvs = _raycast_vehicles->values();
    for (btRaycastVehicle* rv : rvs) delete rv;
  }
  _raycast_vehicles->clear();

  {
    QList<btVehicleRaycaster*> vrs = _vehicle_raycasters->values();
    for (btVehicleRaycaster* vr : vrs) delete vr;
  }
  _vehicle_raycasters->clear();

  // The other worlds go first (with the scene's own back in use)
  dropWorlds();

  // Delete existing dynamics world and its subcomponents
  if (dynamicsWorld) {
    delete dynamicsWorld;
    dynamicsWorld = nullptr;
  }
  if (collisionCfg) {
    delete collisionCfg;
    collisionCfg = nullptr;
  }
  if (dispatcher) {
    delete dispatcher;
    dispatcher = nullptr;
  }
  if (solver) {
    delete solver;
    solver = nullptr;
  }
  delete _mlcpInterface;
  _mlcpInterface = nullptr;
  if (broadphase) {
    delete broadphase;
    broadphase = nullptr;
  }

  // It's important that timeStep is always less than maxSubSteps*fixedTimeStep,
  // otherwise you are losing time. Mathematically,
  //
  //   timeStep < maxSubSteps * fixedTimeStep
  //
  _timeStep = 1 / 25.0; // 25fps
  //_timeStep = 1/120.0;    // 1/120th of a second
  _maxSubSteps = 7;
  _fixedTimeStep = 1 / 100.0; // 1/60th of a second

  collisionCfg = new btSoftBodyRigidBodyCollisionConfiguration();
  broadphase = new btDbvtBroadphase();
  dispatcher = new RestSkippingDispatcher(collisionCfg);
  solver = new btSequentialImpulseConstraintSolver();

  _aabbSeen.clear();
  dynamicsWorld = newBppWorld(dispatcher, broadphase,
                                               solver, collisionCfg);
  dynamicsWorld->setInternalTickCallback(bppGyroPreTick, nullptr, true);
  dynamicsWorld->setDebugDrawer(_debugDrawer);
  dynamicsWorld->setGravity(btVector3(0.0f, -G, 0.0f));
  dynamicsWorld->getWorldInfo().m_broadphase = broadphase;
  dynamicsWorld->getWorldInfo().m_dispatcher = dispatcher;
  dynamicsWorld->getWorldInfo().m_gravity = dynamicsWorld->getGravity();
  dynamicsWorld->getWorldInfo().m_sparsesdf.Initialize();
  SoftBody::setWorldInfo(&dynamicsWorld->getWorldInfo());

  btCollisionDispatcher *dispatcher_ptr = dispatcher;
  GImpactPlaneAlgorithm::registerAlgorithm(dispatcher_ptr);

  _pov_settings_inc = "settings.inc";

  _povRadiosityEnabled = false;
  _povPhotonsEnabled = false;
  _povFogEnabled = false;
  _povAtmosphereEnabled = false;

  setPreSDL(QString());
  setPostSDL(QString());

  if (_cam != nullptr) {
    _cam->setPreSDL(QString());
    _cam->setPostSDL(QString());
    _cam->setUseFocalBlur(0);
    _cam->setUpVector(btVector3(0, 1, 0), true);
    _cam->setPivotPoint(_cam->sceneCenter());   // (following the scene again, till it's chosen)
  }

  // Matches the POV-Ray light_source <500,500,-500> in includes/settings.inc.
  // POV-Ray is left-handed, OpenGL is right-handed, so Z is negated (see
  // Object::povMatrixFromGL()).
  _light0 = btVector4(500.0, 500.0, 500.0, 0.4);
  _light1 = btVector4(-200.0, 100.0, 200.0, 0.2);
  _light0Color = _light1Color = btVector4(1, 1, 1, 1);

  // (and its music; the shadows are the user's, see setShadowsFromScript())
  freeMusic();
  setShadows(_shadowsPref);
  _shadowsNoted = false;

  // (a script's culling and shadow-record settings go with it, as the
  // lights do)
  _culling = true;
  _shadowRecord.enabled = true;
  _merge.enabled = true;
  _shadowRecord.saveDepth = true;
  _drawTiming = false;

  _gl_ambient = btVector3(0.2f, 0.2f, 0.2f);
  _gl_diffuse = btVector4(0.7f, 0.7f, 0.7f, 1.0f);
  _gl_shininess = btScalar(100.0);
  _gl_specular_col = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_specular = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_model_ambient = btVector4(0.2f, 0.2f, 0.2f, 1.0f);
}

void Viewer::resetCamView() {
  camera()->setUpVector(_initialCameraUpVector, true);
  camera()->setPosition(_initialCameraPosition);
  camera()->setOrientation(_initialCameraOrientation);
  camera()->setHorizontalFieldOfView(_initialCameraHorizontalFieldOfView);

  // Reinitialise the SpaceNavigator orbit distance from the new view.
  _snCamera->orbitDist = 0.0;

  if (_quad.on()) {
    _quad.fit();
  }
}

Viewer::~Viewer() {
  // qDebug() << "Viewer::~Viewer()";

  // (let a script's last saved preferences reach the settings file)
  _prefsPool.waitForDone();

#if USE_VFE
  // Tear down any in-flight VFE render before anything else: it owns a
  // worker thread that can call back into this Viewer via the poll timer.
  if (_vfePollTimer) {
    _vfePollTimer->stop();
  }
  if (_vfeSession) {
    teardownVfeRender(true);
  }
  if (_vfePreviewTexture) {
    makeCurrent();
    glDeleteTextures(1, &_vfePreviewTexture);
    _vfePreviewTexture = 0;
  }
#endif // USE_VFE

  // Free any loaded sound effects and shut audio down before anything
  // else that might still reference it.
  freeDownloads();
  freeMusic();
  if (_audioAvailable) {
    for (auto &kv : _soundChunks) {
      Mix_FreeChunk(kv.second);
    }
    _soundChunks.clear();
    _soundIdByPath.clear();
    _synth.detach();
    Mix_CloseAudio();
    SDL_QuitSubSystem(SDL_INIT_AUDIO);
  }

  // Stop the joystick handler before deleting anything
  _joystickHandler.stop();

  // Stop the SpaceNavigator camera control (its sustaining timer), then
  // close the device and drop Lua references before Lua teardown
  delete _snCamera;
  _snCamera = nullptr;
  delete _spaceNavigator;
  _spaceNavigator = nullptr;

  // Reset luabind::object members before closing Lua state
  _cb_preStart = luabind::object();
  _cb_preDraw = luabind::object();
  _cb_postDraw = luabind::object();
  _cb_preSim = luabind::object();
  _cb_postSim = luabind::object();
  _cb_preStop = luabind::object();
  _cb_onCommand = luabind::object();
  _cb_onJoystick = luabind::object();
  _keys.clear();                     // (shortcuts too: before Lua closes)
  _cb_cycleObject = luabind::object();
  _cb_onSpaceNavigator = luabind::object();
  _hover.clear();

  _params.releaseLua();

  // (removed objects bpp still owns go with the rest)
  for (Object *o : _removed)
    _objects->insert(o);
  _removed.clear();

  // Notify all objects that their luabind weak pointers are invalid
  foreach (Object* o, *_objects) {
    o->preDestructor();
  }

  // Remove rigid bodies from the dynamics world while pointers are still valid.
  if (dynamicsWorld) {
    foreach (Object* o, *_objects) {
      if (o->body != nullptr && !o->isDecoration()) {
        worldOfObject(o)->removeRigidBody(o->body);
      }
      SoftBody *sb = dynamic_cast<SoftBody *>(o);
      if (sb != nullptr && sb->getSoftBody() != nullptr) {
        worldOfObject(o)->removeSoftBody(sb->getSoftBody());
      }
    }
    // (and every world's constraints, while the bodies they hold are still
    // there: closing Lua frees a script's own, and dropWorlds() below would
    // take the joints out of bodies already gone)
    QList<btSoftRigidDynamicsWorld *> worlds;
    worlds.append(dynamicsWorld);
    for (const PhysWorld &w : _worlds)
      if (w.world != nullptr && w.world != dynamicsWorld)
        worlds.append(w.world);
    for (btSoftRigidDynamicsWorld *dw : worlds)
      for (int k = dw->getNumConstraints() - 1; k >= 0; --k)
        dw->removeConstraint(dw->getConstraint(k));
  }
  removeLeftoverBodies();

  // Release Lua references from the registry BEFORE closing Lua state.
  // These are raw integer refs, not luabind::object instances.
  if (L != nullptr) {
    for (auto& pair : _luabindRegistry) {
      luaL_unref(L, LUA_REGISTRYINDEX, pair.second);
    }
    _luabindRegistry.clear();
    lua_close(L);
    L = nullptr;
  }

  // Null out Bullet object pointers that Lua has freed. The C++ Object
  // destructors below will skip these null pointers, avoiding use-after-free
  // and double-free.
  foreach (Object* o, *_objects) {
    o->body = nullptr;
    o->shape = nullptr;
#ifdef HAS_LIB_ASSIMP
    Mesh *m = dynamic_cast<Mesh *>(o);
    if (m) {
      m->luaRelease();
    }
#endif
    SoftBody *sb = dynamic_cast<SoftBody *>(o);
    if (sb) {
      sb->luaRelease();
    }
  }

  dropWorlds();

  // Delete dynamics world and collision config (after removing rigid bodies).
  if (dynamicsWorld) {
    delete dynamicsWorld;
    dynamicsWorld = nullptr;
  }
  if (_debugDrawer) {
    delete _debugDrawer;
    _debugDrawer = nullptr;
  }
  if (dispatcher) {
    delete dispatcher;
    dispatcher = nullptr;
  }
  if (solver) {
    delete solver;
    solver = nullptr;
  }
  delete _mlcpInterface;
  _mlcpInterface = nullptr;
  if (broadphase) {
    delete broadphase;
    broadphase = nullptr;
  }
  if (collisionCfg) {
    delete collisionCfg;
    collisionCfg = nullptr;
  }

  // Delete Object instances. Lua-owned pointers (body, shape, m_shape, m_mesh)
  // have been nulled above, so destructors skip them.
  {
    QList<Object*> objs = _objects->values();
    for (Object* o : objs) delete o;
  }
  _objects->clear();
  _takenFromLua.clear();
  _detached.clear();
  delete _objects;

  {
    QList<btTypedConstraint*> cons = _constraints->values();
    for (btTypedConstraint* c : cons) delete c;
  }
  _constraints->clear();
  delete _constraints;

  {
    QList<btRaycastVehicle*> rvs = _raycast_vehicles->values();
    for (btRaycastVehicle* rv : rvs) delete rv;
  }
  _raycast_vehicles->clear();
  delete _raycast_vehicles;

  {
    QList<btVehicleRaycaster*> vrs = _vehicle_raycasters->values();
    for (btVehicleRaycaster* vr : vrs) delete vr;
  }
  _vehicle_raycasters->clear();
  delete _vehicle_raycasters;

  delete _joystickInterface;

  // The depth map and the shader live in the GL context, so make it current
  // before dropping them; failing that ShadowMap leaves them to go with the
  // context instead of deleting them into whichever one happens to be current.
  makeCurrent();
  delete _shadowMap;
}

void Viewer::computeBoundingBox() {
  getAABB(_objects, _aabb);

  qglviewer::Vec qmin(_aabb[0], _aabb[1], _aabb[2]);
  qglviewer::Vec qmax(_aabb[3], _aabb[4], _aabb[5]);

  // (QGLViewer's setSceneCenter() also moves the pivot to the scene's
  // centre. Done every frame, that would undo any pivot that was chosen --
  // by a script's cam.look or cam.pivot, or by Shift + right click -- and
  // in a big scene the mouse would orbit, zoom and pan about a point far
  // from what's shown. So a pivot that isn't the scene's centre is kept;
  // one that is, follows it, as before.)
  const qglviewer::Vec pivot = camera()->pivotPoint();
  const bool keepPivot = (pivot - camera()->sceneCenter()).norm() > 0.0;
  setSceneBoundingBox(qmin, qmax);
  if (keepPivot)
    camera()->setPivotPoint(pivot);

  // The scene changed, so the SpaceNavigator orbit distance is stale.
  _snCamera->orbitDist = 0.0;
}

void Viewer::init() {
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);

  computeBoundingBox();

  showEntireScene();

  // Matches the POV-Ray light_source <500,500,-500> in includes/settings.inc.
  // POV-Ray is left-handed, OpenGL is right-handed, so Z is negated (see
  // Object::povMatrixFromGL()).
  _light0 = btVector4(500.0, 500.0, 500.0, 0.4);
  _light1 = btVector4(-200.0, 100.0, 200.0, 0.2);
  _light0Color = _light1Color = btVector4(1, 1, 1, 1);

  _gl_ambient = btVector3(0.2f, 0.2f, 0.2f);
  _gl_diffuse = btVector4(0.7f, 0.7f, 0.7f, 1.0f);
  _gl_specular = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_shininess = btScalar(100.0);
  _gl_specular_col = btVector4(1.0f, 1.0f, 1.0f, 1.0f);

  _gl_model_ambient = btVector4(0.2f, 0.2f, 0.2f, 1.0f);

  _initialCameraPosition = camera()->position();
  _initialCameraOrientation = camera()->orientation();
  _initialCameraHorizontalFieldOfView = camera()->horizontalFieldOfView();
  _initialCameraUpVector = camera()->upVector();

  // Turntable orbit: keep the camera aligned with the horizon during mouse
  // orbit (QGLViewer's "rotates around the up vector" mode).  Rotation is a
  // yaw around the scene up vector plus a pitch around the camera's right
  // axis, so the camera never rolls.  This only affects the mouse ROTATE
  // action; the SpaceNavigator keeps its own navigation paths.
  camera()->frame()->setRotatesAroundUpVector(true);
  camera()->frame()->setSceneUpVector(_initialCameraUpVector);
}

void Viewer::draw() {
  if (_frameTimingMs > 0)
    frameMark(FM_PAINT);
  _stepsSinceDraw = 0;
  _lastDrawNs = _wallTimer.nsecsElapsed();

  if (!mutex.tryLock())
    return;

  if (_parsing || !isVisible()) {
    mutex.unlock();
    return;
  }

  if (_cb_preDraw) {
    try {
      luabind::call_function<void>(_cb_preDraw, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "preDraw()");
    }
  }
  _decorations.update();                // (the decorations to their parents: before anything reads places)

  QElapsedTimer dtAll;                  // (the drawing timer: all of draw())
  if (_drawTiming && !_quad.on())
    dtAll.start();
  _lf = LastFrame();

  computeBoundingBox();
  if (dtAll.isValid()) {
    _lf.box = dtAll.nsecsElapsed() / 1.0e6;
    _dtBox += _lf.box;
  }

  GLfloat light_ambient[] = {_gl_ambient.x(), _gl_ambient.y(), _gl_ambient.z()};
  GLfloat light_diffuse[] = {_gl_diffuse.x(), _gl_diffuse.y(), _gl_diffuse.z()};
  GLfloat light_specular[] = {_gl_specular.x(), _gl_specular.y(),
                              _gl_specular.z()};

  // light_position is NOT default value
  GLfloat light_position0[] = {_light0.x(), _light0.y(), _light0.z(),
                               _light0.w()};
  GLfloat light_position1[] = {_light1.x(), _light1.y(), _light1.z(),
                               _light1.w()};

  // (each light's own colour, see setGLLight0Color())
  GLfloat light_diffuse0[4], light_specular0[4];
  GLfloat light_diffuse1[4], light_specular1[4];
  for (int i = 0; i < 3; ++i) {
    light_diffuse0[i] = light_diffuse[i] * _light0Color[i];
    light_specular0[i] = light_specular[i] * _light0Color[i];
    light_diffuse1[i] = light_diffuse[i] * _light1Color[i];
    light_specular1[i] = light_specular[i] * _light1Color[i];
  }
  light_diffuse0[3] = light_specular0[3] = 1.0f;
  light_diffuse1[3] = light_specular1[3] = 1.0f;

  glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse0);
  glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular0);
  glLightfv(GL_LIGHT0, GL_POSITION, light_position0);

  glLightfv(GL_LIGHT1, GL_AMBIENT, light_ambient);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, light_diffuse1);
  glLightfv(GL_LIGHT1, GL_SPECULAR, light_specular1);
  glLightfv(GL_LIGHT1, GL_POSITION, light_position1);

  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHT1);

  glEnable(GL_COLOR_MATERIAL);
  glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);

  glShadeModel(GL_SMOOTH);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);

  glClearColor(btScalar(0), btScalar(0), btScalar(0), btScalar(1.0));

  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, _gl_model_ambient);

  glMaterialfv(GL_FRONT, GL_AMBIENT, _gl_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, _gl_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, _gl_specular);
  glMaterialf(GL_FRONT, GL_SHININESS, _gl_shininess);
  // (nothing glows but what says so: see Object::setEmission())
  const GLfloat noEmission[] = {0.0f, 0.0f, 0.0f, 1.0f};
  glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, noEmission);

  // (the drawing timer, when it's on: see setDrawTiming())
  QElapsedTimer dt;
  const bool timing = _drawTiming && !_quad.on();
  if (timing) {
    dtGpuCollect();
    dt.start();
  }

  {                                      // (see setScreenMerge())
    const ScreenMerge::Counts mc = _merge.update(*_objects);
    _lf.batches += mc.batches;
    _lf.recoloured += mc.recoloured;
    _lf.blanked += mc.blanked;
  }
  const qint64 tMerge = timing ? dt.nsecsElapsed() : 0;

  // What this frame can skip (see setCulling()), while the camera's own
  // matrices are loaded.
  cullObjects();
  qint64 tCull = timing ? dt.nsecsElapsed() : 0;

  // Fill the shadow map before anything is drawn for the screen: it needs the
  // camera's own matrices to be the ones currently loaded, and the whole scene
  // casts into one map that every quad-view pane then shares.
  if (timing)
    dtGpuBegin(0);
  renderShadowDepth();
  if (timing)
    dtGpuEnd();
  qint64 tShadow = timing ? dt.nsecsElapsed() : 0;

  if (_quad.on()) {
    _quad.draw([this](int i) { drawSceneInternal(i); });
    mutex.unlock();
    return;
  }

  if (manipulatedFrame() != nullptr) {
    glPushMatrix();
    glMultMatrixd(manipulatedFrame()->matrix());
  }

  glDisable(GL_CULL_FACE);
  if (timing)
    dtGpuBegin(1);
  drawSceneInternal(0);
  if (timing) {
    dtGpuEnd();
    if (!_dtNoGpu && _dtQueries[_dtSlot][0] != 0 && _dtQueries[_dtSlot][1] != 0)
      _dtPending[_dtSlot] = true;
    _dtSlot = (_dtSlot + 1) % 4;
    const qint64 tScreen = dt.nsecsElapsed();
    _dtCull += tCull / 1.0e6;
    _dtShadow += (tShadow - tCull) / 1.0e6;
    _dtScreen += (tScreen - tShadow) / 1.0e6;
    _lf.merge = tMerge / 1.0e6;
    _lf.cull = (tCull - tMerge) / 1.0e6;
    _lf.shadow = (tShadow - tCull) / 1.0e6;
    _lf.screen = (tScreen - tShadow) / 1.0e6;
  }

  if (manipulatedFrame() != nullptr) {
    glPopMatrix();
  }

  if (_snCamera->showOrbitAxis) {
    // Visualize the orbit/rotation centre as a small world-axis marker.
    qreal orbitDist = _snCamera->orbitDist;
    if (orbitDist <= 0.0) {
      orbitDist = (camera()->pivotPoint() - camera()->position()).norm();
    }
    if (orbitDist <= 0.0) {
      orbitDist = camera()->sceneRadius();
    }
    const qglviewer::Vec pivot =
        camera()->position() + camera()->viewDirection() * orbitDist;

    glPushMatrix();
    glTranslatef(pivot.x, pivot.y, pivot.z);
    QGLViewer::drawAxis(qMax(qreal(0.05), camera()->sceneRadius() * 0.1));
    glPopMatrix();
    glEnable(GL_LIGHTING);
  }

  if (dtAll.isValid()) {
    _lf.all = dtAll.nsecsElapsed() / 1.0e6;
    _dtDraw += _lf.all;
    ++_dtFrames;
    _lfDone = _lf;
  }

  mutex.unlock();
}

// The screen's merge (see setScreenMerge()).

void Viewer::setScreenMerge(bool on) { _merge.enabled = on; }

bool Viewer::screenMerge() const { return _merge.enabled; }

int Viewer::screenMerged() const { return _merge.drawn(); }

void Viewer::drawSceneInternal(int pass) {
  Q_UNUSED(pass)

  // The shader needs to get from the eye space it works in back out to the
  // light's, which takes the inverse of the camera's view matrix - and that is
  // exactly what is loaded right now, before any object pushes its own
  // transform on top.
  bool shaded = false;
  if (_shadows) {
    GLdouble camModelView[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, camModelView);
    shaded = _shadowMap->bind(camModelView);
  }

  _merge.draw(_culled);
  drawObjects();

  if (shaded) {
    // Released before the constraint markers, which are flat unlit lines and
    // crosses and have no business being shaded.
    _shadowMap->release();
  }

  drawConstraints();
}

void Viewer::drawObjects(bool shadowPass, bool skipFixed) {
  // btScalar m[16];
  btMatrix3x3 rot;
  rot.setIdentity();

  btVector3 minaabb(0, 0, 0), maxaabb(0, 0, 0);
  dynamicsWorld->getBroadphase()->getBroadphaseAabb(minaabb, maxaabb);

  //    minaabb-=btVector3(BT_LARGE_FLOAT,BT_LARGE_FLOAT,BT_LARGE_FLOAT);
  //    maxaabb+=btVector3(BT_LARGE_FLOAT,BT_LARGE_FLOAT,BT_LARGE_FLOAT);

  // For the screen, what can be seen through is drawn after everything else
  // (in the order it comes in), so whatever is behind it is there to be seen
  // through it; drawn before, what came after would paint over it.
  QVector<Object *> seeThrough;
  auto drawOne = [&](Object *o) {
    ++(shadowPass ? _shadowCasters : _drawnObjects);
    // SoftBody has no rigid body/motion-state, so Object::render() (which
    // requires one) would silently skip it. Render it directly instead.
    // (an object of a world drawn elsewhere: moved there)
    if (o->placed) {
      btScalar pm[16];
      o->place.getOpenGLMatrix(pm);
      glPushMatrix();
      glMultMatrixf(pm);
    }
    SoftBody *sb = dynamic_cast<SoftBody *>(o);
    if (sb != nullptr) {
      sb->renderWorld();
    } else {
      o->render(minaabb, maxaabb);
    }
    if (o->placed)
      glPopMatrix();
  };
  foreach (Object *o, *_objects) {
    // (what cullObjects() decided for this frame)
    if (_culled && !(shadowPass ? o->drawInShadow : o->drawOnScreen))
      continue;
    if (shadowPass && !o->getCastShadow())  // (see Object::setCastShadow())
      continue;
    if (skipFixed && o->shadowListed)
      continue;
    if (!shadowPass && o->mergeDrawn && _merge.ready())  // (drawn by _merge.draw())
      continue;
    // Layer visibility: skip objects on hidden layers
    if (!shadowPass && o->layer() && !o->layer()->isVisible())
      continue;
    if (!shadowPass && o->getTransparency() > 0.0) {
      seeThrough.append(o);
      continue;
    }
    drawOne(o);
  }
  for (Object *o : seeThrough)
    drawOne(o);
}

void Viewer::cullObjects() {
  _drawnObjects = 0;
  _shadowCasters = 0;
  _culled = _culling && !_quad.on() && manipulatedFrame() == nullptr;
  if (!_culled)
    return;

  Culling::cull(*_objects, camera(), _shadows, _light0, _shadowMap);
}

void Viewer::renderShadowDepth() {
  if (!_shadows)
    return;

  const qglviewer::Vec c = camera()->sceneCenter();

  if (!_shadowMap->renderDepthBegin(_light0, btVector3(c.x, c.y, c.z),
                                    camera()->sceneRadius())) {
    return;
  }

  // Only the objects: a constraint marker is a hint about the scene, not part
  // of it, and should not throw a shadow across it. Anything a script draws
  // from an object's own render callback does cast, since that runs from
  // Object::render(). The fixed objects that have stayed put come from the
  // record (see ShadowRecord); the rest are drawn one by one.
  ShadowRecord::Counts rc;                // (see setShadowCache())
  const bool skipFixed =
      _shadowRecord.fill(*_objects, _shadowMap, dynamicsWorld->getBroadphase(), _culled, rc);
  _lf.recorded += rc.recorded;
  if (rc.depthSaved)
    _lf.depthSaved = true;
  drawObjects(true, skipFixed);

  _shadowMap->renderDepthEnd();
}

// Renders every constraint via btDynamicsWorld::debugDrawConstraint(),
// which dispatches on the constraint's own type (hinge, point2point,
// slider, cone-twist, 6dof, gear, ...).
void Viewer::drawConstraints() {
  if (!_showConstraints)
    return;

  glEnable(GL_DEPTH_TEST);

  // Size each constraint's markers relative to the parts it connects
  // instead of the whole scene's AABB - a single far-away or oversized
  // object (a ground plane, a long road, ...) would otherwise blow up
  // every marker's size, even for small constraints elsewhere.
  foreach (btTypedConstraint *c, *_constraints) {
    // (one in a world drawn elsewhere: moved there)
    const int k = _conWorld.value(c, 0);
    const bool placed = k > 0 && k < (int)_worlds.size() && _worlds[k].placed;
    if (placed) {
      btScalar pm[16];
      _worlds[k].place.getOpenGLMatrix(pm);
      glPushMatrix();
      glMultMatrixf(pm);
    }
    ConstraintDraw::draw(c, ConstraintDraw::size(c));
    if (placed)
      glPopMatrix();
  }
}

void Viewer::savePOV(bool force) {
  if (!force && !_savePOV)
    return;

  qDebug() << "openPovFile() scriptName: " << _scriptName;

  QString sceneName;
  if (!_scriptName.isEmpty()) {
    QFileInfo fi(_scriptName);
    sceneName = fi.completeBaseName();
  } else {
    sceneName = "no_name";
  }

  QDir pwdDir(startupWorkingDir());

  QString exportDir = _settings->value("povray/export", "export").toString();

  qDebug() << "exportDir: " << exportDir;

  // (No dialog for a directory that cannot be created: it would run an event
  // loop inside animate(), with the mutex held, that nobody can answer in a
  // headless run, and the animation timer firing in it blocks on that mutex.)
  auto exportFailed = [this](const QString &dir) {
    emitScriptOutput(tr("Unable to create directory %1.").arg(dir));
    _savePOV = false;
    _povExportFailed = true;
    emit POVStateChanged(false);
  };

  if (!pwdDir.exists(exportDir)) {
    if (!pwdDir.mkpath(exportDir)) {
      exportFailed(pwdDir.absoluteFilePath(exportDir));
      return;
    }
  }

  QString sceneDir =
      pwdDir.absoluteFilePath(exportDir + QDir::separator() + sceneName);

  qDebug() << "sceneDir: " << sceneDir;

  if (!pwdDir.exists(sceneDir)) {
    if (!pwdDir.mkpath(sceneDir)) {
      exportFailed(sceneDir);
      return;
    }
  }

  PovExport::copySettingsIncludes(_pov_settings_inc, startupWorkingDir(), sceneDir);

  QString fn = QString("%1").arg(_frameNum, 5, 10, QChar('0'));
  QString file = QString("%1%2%3.inc").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(fn);
  QString fileMain = QString("%1%2%3.pov").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));
  QString fileINI = QString("%1%2%3.ini").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));
  QString fileWAV = QString("%1%2%3.wav").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));

  qDebug() << "POV-Ray file: " << file;

  if (_savePOV)
    _wavTrack.write(fileWAV, _firstFrame, _frameNum, _synth);

  const QString byline = PovExport::byline();

  PovExport::writeIni(fileINI, byline, sceneName, _firstFrame, _frameNum);

  PovExport::Scene scene;
  scene.radiosity = _povRadiosityEnabled;
  scene.photons = _povPhotonsEnabled;
  scene.fog = _povFogEnabled;
  scene.atmosphere = _povAtmosphereEnabled;
  scene.light0 = _light0;
  scene.light1 = _light1;
  scene.diffuse = _gl_diffuse;
  scene.settingsInc = _pov_settings_inc;
  PovExport::writeMain(fileMain, byline, scene);

  PovExport::writeMakefile(sceneDir);

  _decorations.update();   // (headless runs export without drawing)
  PovExport::writeFrame(file, byline, mPreSDL, _cam, camera(), *_objects, mPostSDL, sceneDir);
}

void Viewer::setCBPreStart(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preStart = fn;
  }
}

void Viewer::setCBPreDraw(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preDraw = fn;
  }
}

void Viewer::setCBPostDraw(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_postDraw = fn;
  }
}

void Viewer::setCBPreSim(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preSim = fn;
  }
}

void Viewer::setCBPostSim(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_postSim = fn;
  }
}

void Viewer::setCBPreStop(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preStop = fn;
  }
}

void Viewer::setCBOnCommand(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onCommand = fn;
  }
}

void Viewer::setCBOnKey(const luabind::object &fn) { _keys.setOnKey(fn); }

int Viewer::getAnimationPeriod() const { return animationPeriod(); }

void Viewer::setAnimationPeriodMs(int ms) { setAnimationPeriod(ms); }

void Viewer::setCBOnJoystick(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onJoystick = fn;
  }
}

void Viewer::setCBOnSpaceNavigator(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onSpaceNavigator = fn;
  }
}

void Viewer::setCBOnParamChanged(const luabind::object &fn) { _params.setOnChanged(fn); }

void Viewer::setCBOnHover(const luabind::object &fn) {
  _hover.setCallback(fn);
  if (luabind::type(fn) == LUA_TFUNCTION) {
    setMouseTracking(true);          // movement without a button is reported
    if (!_hoverTimer) {
      _hoverTimer = new QTimer(this);
      _hoverTimer->setInterval(100);
      connect(_hoverTimer, &QTimer::timeout, this, [this]() { hoverTick(); });
    }
    _hoverTimer->start();
  } else {
    if (_hoverTimer) _hoverTimer->stop();
  }
}

void Viewer::hoverTick() {
  if (!dynamicsWorld) return;
  // the ortho pane's camera if the pointer is over one
  qglviewer::Camera *cam = _quad.cameraAt(_hover.pos());
  if (!cam) cam = camera();
  std::vector<Hover::World> worlds;
  if (_worlds.empty()) {
    worlds.push_back({dynamicsWorld, nullptr});
  } else {
    for (const PhysWorld &w : _worlds)
      worlds.push_back({w.world, w.placed ? &w.place : nullptr});
  }
  _hover.tick(cam, worlds, _objects, _frameNum,
              [this](const std::exception &e) { showLuaException(e, "onHover()"); });
}

void Viewer::leaveEvent(QEvent *e) {
  _hover.disarm();
  QGLViewer::leaveEvent(e);
}

void Viewer::setCBCycleObject(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_cycleObject = fn;
  }
}

void Viewer::addParam(const QString &name, const QVariant &value) {
  addParam(name, value, QString());
}

void Viewer::addParam(const QString &name, const QVariant &value, const QString &comment) {
  _params.add(L, _frameNum, name, value, comment, [this](const std::exception &e, const QString &where) { showLuaException(e, where); });
  emit paramsChanged();
}

void Viewer::addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max) {
  addParam(name, value, min, max, 0.0, QString());
}

void Viewer::addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max, const btScalar &step) {
  addParam(name, value, min, max, step, QString());
}

void Viewer::addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max, const btScalar &step, const QString &comment) {
  _params.addRange(L, _frameNum, name, value, min, max, step, comment, [this](const std::exception &e, const QString &where) { showLuaException(e, where); });
  emit paramsChanged();
}

void Viewer::pressButton(const QString &name, const QString &label) {
  _params.press(L, name, label, [this](const std::exception &e, const QString &where) { showLuaException(e, where); });
}

ParamInfo Viewer::getParamInfo(const QString &name) const { return _params.info(name); }

QVariant Viewer::getParam(const QString &name) const { return _params.get(L, name); }

QHash<QString, QVariant> Viewer::getParams() const { return _params.all(); }

void Viewer::showParams(const QString &prefix) {
  if (_params.show(prefix))
    emit paramsChanged();
}

QHash<QString, QVariant> Viewer::getShownParams() const { return _params.shown(); }

void Viewer::clearParams() {
  _params.clear();
  emit paramsChanged();
}

void Viewer::addShortcut(const QString &keys, const luabind::object &fn) {
  _keys.addShortcut(keys, fn);
}

void Viewer::removeShortcut(const QString &keys) { _keys.removeShortcut(keys); }

void Viewer::postDraw() {
  if (_parsing)
    return QGLViewer::postDraw();

  if (_cb_postDraw) {
    try {
      luabind::call_function<void>(_cb_postDraw, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "postDraw()");
    }
  }

  // Red dot when EventRecorder is active

  if (animationIsStarted()) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(1.0, 0.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 20, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    // XXXqglColor(foregroundColor());
  }

  if (_simulate) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 40, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    // XXXqglColor(foregroundColor());
  }

  if (_savePOV) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 1.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 80, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    // XXXqglColor(foregroundColor());
  }

  if (_deactivation) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(1.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 100, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    // XXXqglColor(foregroundColor());
  }

#if USE_VFE
  if (_vfePreviewVisible && (_vfeRenderActive || _vfePreviewTexture)) {
    drawVfePreview();
  }
#endif // USE_VFE

  if (_frameTimingMs > 0)
    frameMark(FM_AFTER_PAINT);
}

// ---------------------------------------------------------------------------
// Frame timing: where a late frame's time went.
//
// Each step of bpp's frame is marked with the time it starts: the animation
// step (scripts and physics), the drawing, every Qt event the application
// handles (seen through an event filter on the application) and the time
// Qt's event loop sits waiting for something to do (the event dispatcher's
// aboutToBlock/awake signals). A step lasts until the next mark. When the
// gap from one animation step to the next is over the threshold, the steps
// in between are added up by kind and the biggest are printed.
// ---------------------------------------------------------------------------

void Viewer::setFrameTiming(double ms) {
  _frameTimingMs = ms > 0 ? ms : 0;
  _frameTimingLast = -1;
  _frameMarks.clear();
  if (_frameTimingMs > 0 && !_frameTimingHooked) {
    _frameTimingHooked = true;
    _frameMarks.reserve(4096);
    qApp->installEventFilter(this);
    if (QAbstractEventDispatcher *d = QAbstractEventDispatcher::instance()) {
      connect(d, &QAbstractEventDispatcher::aboutToBlock, this, [this]() {
        if (_frameTimingMs > 0) frameMark(FM_WAITING);
      }, Qt::DirectConnection);
      connect(d, &QAbstractEventDispatcher::awake, this, [this]() {
        if (_frameTimingMs > 0) frameMark(FM_AWAKE);
      }, Qt::DirectConnection);
    }
  }
}

double Viewer::getFrameTiming() const { return _frameTimingMs; }

void Viewer::frameMark(int kind, int eventType, const char *cls,
                       const char *pcls) {
  if (_frameMarks.size() >= 100000)
    return; // never stopped by a missing animation step: just stop noting
  _frameMarks.append({_wallTimer.nsecsElapsed(), kind, eventType, cls, pcls});
}

bool Viewer::eventFilter(QObject *obj, QEvent *ev) {
  if (_frameTimingMs > 0 && obj && ev) {
    QObject *parent = obj->parent();
    frameMark(FM_EVENT, int(ev->type()), obj->metaObject()->className(),
              parent ? parent->metaObject()->className() : nullptr);
  }
  return QGLViewer::eventFilter(obj, ev);
}

void Viewer::frameTimingReport(qint64 now) {
  if (_frameMarks.isEmpty())
    return;
  // Add up the time after each mark, until the next one, by what it marks.
  QMap<QString, double> byStep; // ms
  QString longestStep;
  double longestMs = 0;
  QMetaEnum types = QMetaEnum::fromType<QEvent::Type>();
  for (int i = 0; i < _frameMarks.size(); i++) {
    const FrameMark &m = _frameMarks[i];
    qint64 end = i + 1 < _frameMarks.size() ? _frameMarks[i + 1].ns : now;
    double ms = (end - m.ns) / 1e6;
    QString step;
    switch (m.kind) {
    case FM_ANIMATE: step = "animation step (scripts, physics)"; break;
    case FM_AFTER_ANIMATE: step = "after the animation step"; break;
    case FM_PAINT: step = "drawing (with the preDraw/postDraw scripts)"; break;
    case FM_AFTER_PAINT: step = "after drawing (Qt shows the frame: compose, swap)"; break;
    case FM_WAITING: step = "event loop waiting (idle, or blocked in the system)"; break;
    case FM_AWAKE: step = "event loop woke up"; break;
    default: {
      const char *name = types.valueToKey(m.eventType);
      step = QString("event %1 -> %2%3")
                 .arg(name ? QString(name) : QString::number(m.eventType))
                 .arg(m.cls ? m.cls : "?")
                 .arg(m.pcls ? QString(" (in %1)").arg(m.pcls) : QString());
    }
    }
    byStep[step] += ms;
    if (ms > longestMs) {
      longestMs = ms;
      longestStep = step;
    }
  }
  QList<QPair<double, QString>> sorted;
  for (auto it = byStep.begin(); it != byStep.end(); ++it)
    sorted.append(qMakePair(it.value(), it.key()));
  std::sort(sorted.begin(), sorted.end(),
            [](const QPair<double, QString> &a, const QPair<double, QString> &b) {
              return a.first > b.first;
            });
  QString out = QString("FRAME TIMING: %1 ms between animation steps, ending at %2 "
                        "(%3 steps noted). Longest single step: %4 ms, %5. Largest totals:")
                    .arg((now - _frameTimingLast) / 1e6, 0, 'f', 0)
                    .arg(QTime::currentTime().toString("HH:mm:ss"))
                    .arg(_frameMarks.size())
                    .arg(longestMs, 0, 'f', 0)
                    .arg(longestStep);
  for (int i = 0; i < sorted.size() && i < 5; i++)
    out += QString("\n  %1 ms  %2").arg(sorted[i].first, 6, 'f', 1).arg(sorted[i].second);
  _frameTimingReports++;
  fprintf(stderr, "%s\n", out.toUtf8().constData());
  fflush(stderr);
  emitScriptOutput(out);
}

bool Viewer::simHeld() const {
  return _holdSim > 0 || QApplication::activeModalWidget() != nullptr;
}

void Viewer::timerEvent(QTimerEvent *e) {
  // QGLViewer's animation tick steps (animate()) and repaints (update()). With
  // a modal dialog open neither happens, so the dialog gets the event loop to
  // itself; the steps are fixed, so the world carries on from where it
  // stopped when the dialog closes. (And the pause is not a late frame.)
  if (simHeld()) {
    _frameTimingLast = -1;
    return;
  }
  QGLViewer::timerEvent(e);
}

void Viewer::startAnimation() {
  if (_cb_preStart) {
    try {
      luabind::call_function<void>(_cb_preStart, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "preStart()");
    }
  }

  _timer.start();
  _frameTimingLast = -1; // (a pause is not a late frame)
  QGLViewer::startAnimation();
  _synth.setGate(_simulate);
}

void Viewer::stopAnimation() {
  if (_cb_preStop) {
    try {
      luabind::call_function<void>(_cb_preStop, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "preStop()");
    }
  }

  QGLViewer::stopAnimation();
  _synth.setGate(false); // (the voices hush while paused)
  // XXX updateGLViewer();
}

void Viewer::animate() {
  // (a dialog is open: the world waits for it, see simHeld())
  if (simHeld())
    return;
  // (one step a picture: a tick before the last step has been drawn waits
  // for the next, unless nothing has been drawn for a while)
  if (_onePerFrame && _stepsSinceDraw > 0 && _lastDrawNs >= 0 &&
      _wallTimer.nsecsElapsed() - _lastDrawNs < 50000000)
    return;
  _stepsSinceDraw++;
  if (_frameTimingMs > 0) {
    qint64 now = _wallTimer.nsecsElapsed();
    if (_frameTimingLast >= 0 && now - _frameTimingLast > _frameTimingMs * 1e6)
      frameTimingReport(now);
    _frameMarks.clear();
    _frameTimingLast = now;
    frameMark(FM_ANIMATE);
  }
  struct AfterAnimate {
    Viewer *v;
    ~AfterAnimate() { if (v->_frameTimingMs > 0) v->frameMark(FM_AFTER_ANIMATE); }
  } afterAnimate{this};

  QMutexLocker locker(&mutex);

  if (_has_exception || _parsing) {
    return;
  }

  reapRemoved();

  // emitScriptOutput(QString("_frameNum = %1").arg(_frameNum));

  // emitScriptOutput("Viewer::animate() begin");

  if (_cb_preDraw) {
    try {
      luabind::call_function<void>(_cb_preDraw, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "preDraw()");
    }
  }

  if (_savePOV) {
    savePOV();
  }

  if (_simulate) {

    if (_cb_preSim) {
      try {
        luabind::call_function<void>(_cb_preSim, _frameNum);
      } catch (const std::exception &e) {
        showLuaException(e, "preSim()");
      }
    }

    // Find the time elapsed between last time
    // float nbSecsElapsed = 0.08f; // 25 pics/sec
    // float nbSecsElapsed = 1.0 / 24.0;
    // float nbSecsElapsed = _timer.elapsed()/10.0f;

    // old: dynamicsWorld->stepSimulation(nbSecsElapsed, 10);

    if (_has_exception || _parsing) {
      return;
    }

    // new: bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
    updateMovedAabbs();
    dynamicsWorld->stepSimulation(_timeStep, _maxSubSteps, _fixedTimeStep);

    if (_cb_postSim) {
      try {
        luabind::call_function<void>(_cb_postSim, _frameNum);
      } catch (const std::exception &e) {
        showLuaException(e, "postSim()");
      }
    }

    if (_frameNum > 10)
      emit postDrawShot(_frameNum);

    emit frameUpdate(_frameNum);
    _frameNum++;
  }

  // Restart the elapsed time counter
  _timer.restart();

  // emitScriptOutput("Viewer::animate() end");
}

void Viewer::command(QString cmd) {
  QMutexLocker locker(&mutex);

  // emitScriptOutput("Viewer::command() begin");

  if (_cb_onCommand) {
    try {
      luabind::call_function<void>(_cb_onCommand, _frameNum, cmd);
    } catch (const std::exception &e) {
      showLuaException(e, "onCommand()");
    }
  }

  // emitScriptOutput("Viewer::command() end");
}

void Viewer::showLuaException(const std::exception &e, const QString &context) {
  _has_exception = true;

  if (std::string const *stack = boost::get_error_info<stack_info>(e)) {
    emitScriptOutput(QString::fromStdString(*stack));
  }

  if (L) {
    const char *s = lua_tostring(L, -1);
    QString luaWhat = QString("%1").arg(s ? s : "");

    lua_Debug ar;
    int stack_ok = lua_getstack(L, 1, &ar);
    if (stack_ok && lua_getinfo(L, "nSl", &ar)) {
      int line = ar.currentline;
      emitScriptOutput(QString("%1 in %2: %3 (line %4)")
                           .arg(e.what())
                           .arg(context)
                           .arg(luaWhat)
                           .arg(line));
    } else {
      emitScriptOutput(QString("%1 in %2: %3").arg(e.what()).arg(context).arg(luaWhat));
    }
  } else {
    emitScriptOutput(QString("%1 in %2").arg(e.what()).arg(context));
  }
}

void Viewer::setGLShininess(const btScalar &s) { _gl_shininess = s; }

btScalar Viewer::getGLShininess() const { return _gl_shininess; }

void Viewer::setGLSpecularColor(const btVector4 &col) {
  _gl_specular_col = col;
}

btVector4 Viewer::getGLSpecularColor() const { return _gl_specular_col; }

void Viewer::setGLSpecularCol(const btScalar col) {
  _gl_specular_col = btVector4(col, col, col, col);
}

btScalar Viewer::getGLSpecularCol() const { return _gl_specular_col.length(); }

void Viewer::setGLLight0(const btVector4 &pos) { _light0 = pos; }

btVector4 Viewer::getGLLight0() const { return _light0; }

void Viewer::setGLLight1(const btVector4 &pos) { _light1 = pos; }

btVector4 Viewer::getGLLight1() const { return _light1; }

void Viewer::setGLLight0Color(const btVector4 &col) { _light0Color = col; }

btVector4 Viewer::getGLLight0Color() const { return _light0Color; }

void Viewer::setGLLight1Color(const btVector4 &col) { _light1Color = col; }

btVector4 Viewer::getGLLight1Color() const { return _light1Color; }

// Vector

void Viewer::setGLAmbient(const btVector3 &am) { _gl_ambient = am; }

btVector3 Viewer::getGLAmbient() const { return _gl_ambient; }

void Viewer::setGLDiffuse(const btVector4 &col) { _gl_diffuse = col; }

btVector4 Viewer::getGLDiffuse() const { return _gl_diffuse; }

void Viewer::setGLSpecular(const btVector4 &col) { _gl_specular = col; }

btVector4 Viewer::getGLSpecular() const { return _gl_specular; }

void Viewer::setGLModelAmbient(const btVector4 &am) { _gl_model_ambient = am; }

btVector4 Viewer::getGLModelAmbient() const { return _gl_model_ambient; }

// Percent

void Viewer::setGLAmbientPercent(const btScalar am) {
  _gl_ambient = btVector3(am, am, am);
}

btScalar Viewer::getGLAmbientPercent() const {
  return (_gl_ambient.x() + _gl_ambient.y() + _gl_ambient.z()) / 3;
}

void Viewer::setGLDiffusePercent(const btScalar col) {
  _gl_diffuse = btVector4(col, col, col, 1);
}

btScalar Viewer::getGLDiffusePercent() const { return _gl_diffuse.length(); }

void Viewer::setGLSpecularPercent(const btScalar col) {
  _gl_specular = btVector4(col, col, col, 1);
}

btScalar Viewer::getGLSpecularPercent() const { return _gl_specular.length(); }

void Viewer::setGLModelAmbientPercent(const btScalar am) {
  _gl_model_ambient = btVector4(am, am, am, 1);
}

btScalar Viewer::getGLModelAmbientPercent() const {
  return (_gl_model_ambient.x() + _gl_model_ambient.y() +
          _gl_model_ambient.z()) / 3;
}

// POV-Ray properties

void Viewer::setPreSDL(const QString &preSDL) { mPreSDL = preSDL; }

QString Viewer::getPreSDL() const { return mPreSDL; }

void Viewer::setPostSDL(const QString &postSDL) { mPostSDL = postSDL; }

QString Viewer::getPostSDL() const { return mPostSDL; }

// Writes a script's preferences on the Viewer's preference thread.
// (which store: taken from the Viewer's settings on the main thread)
class PrefsWriter : public QRunnable {
public:
  PrefsWriter(Viewer *v, const QSettings *store)
      : _v(v), _format(store->format()), _scope(store->scope()),
        _org(store->organizationName()), _app(store->applicationName()) {
    setAutoDelete(true);
  }
  void run() override {
    QSettings s(_format, _scope, _org, _app);
    _v->writePendingPrefs(s);
  }

private:
  Viewer *_v;
  QSettings::Format _format;
  QSettings::Scope _scope;
  QString _org, _app;
};

void Viewer::setPrefs(QString key, QString value) {
  _luaPrefs[key] = value;
  QMutexLocker lock(&_prefsMutex);
  _prefsToWrite[key] = value;
  if (!_prefsWriteQueued) {
    _prefsWriteQueued = true;
    _prefsPool.start(new PrefsWriter(this, _settings));
  }
}

// On the preference thread: everything set since the last write, in one go,
// through a QSettings of its own for the same store (Qt keeps different
// QSettings objects for one store consistent across threads).
void Viewer::writePendingPrefs(QSettings &s) {
  QHash<QString, QString> todo;
  {
    QMutexLocker lock(&_prefsMutex);
    todo.swap(_prefsToWrite);
    _prefsWriteQueued = false;
  }
  if (todo.isEmpty())
    return;
  s.beginGroup("lua");
  for (auto it = todo.constBegin(); it != todo.constEnd(); ++it)
    s.setValue(it.key(), it.value());
  s.endGroup();
  s.sync();
}

QString Viewer::getPrefs(QString key, QString defaultValue) const {
  auto it = _luaPrefs.constFind(key);
  if (it != _luaPrefs.constEnd())
    return it.value();
  _settings->beginGroup("lua");
  QString v = _settings->value(key, defaultValue).toString();
  _settings->endGroup();
  return v;
}

void Viewer::setSettings(QSettings *settings) { _settings = settings; }

void Viewer::onQuickRender() { onQuickRender(""); }

void Viewer::onQuickRender(QString povargs) {
  savePOV(true);

  const QuickRender::Plan plan =
      QuickRender::plan(_settings, geometry().size(), _scriptName, _frameNum, povargs);

#if USE_VFE
  // (the names the VFE block below was written with)
  const QString &opts = plan.opts;
  const int renderWidth = plan.width;
  const int renderHeight = plan.height;
  const QString &png = plan.png;
  const QString &sceneName = plan.sceneName;
  const QString &sceneDir = plan.sceneDir;

  if (_settings->value("povray/useVFE", false).toBool()) {
    // vfeRenderOptions::AddCommand() feeds each string whole into POV-Ray's
    // own ProcessOptions::ParseString(), which tokenizes and handles quoting
    // itself across the *entire* string passed in one call (it's built to
    // parse a whole command line or INI line, not a single pre-split argv
    // token). `args` is built for QProcess instead, which pre-splits `opts`
    // on spaces via opts.split(" ") -- that breaks any quoted, space-
    // containing path in `opts` (e.g. +L'C:/Program Files (x86)/...')
    // into fragments, since each AddCommand() call is parsed independently
    // and never sees the other fragments' quotes. So the VFE path passes
    // `opts` through whole instead of reusing the pre-split fragments from
    // `args`; the individually-built switches below have no embedded quotes
    // to lose and are safe to reuse as-is.
    QString scenePovAbsolute = QDir(sceneDir).absoluteFilePath(sceneName + ".pov");
    QStringList vfeArgs;
    vfeArgs << opts;
    vfeArgs << QString("+W%1").arg(renderWidth);
    vfeArgs << QString("+H%1").arg(renderHeight);
    vfeArgs << "+F";
    vfeArgs << QString("+O%1").arg(png);
    vfeArgs << QString("+K%1").arg(_frameNum);
    vfeArgs << scenePovAbsolute;
    if (!povargs.isEmpty()) {
      vfeArgs << povargs;
    }
    // /EXIT etc are pvengine.exe GUI-shell switches (windows/pvtext.cpp),
    // stripped out by pvengine itself before the real option parser ever
    // sees them. The embedded VFE core has no such pre-filter, so its
    // parser correctly rejects them; drop them before handing args over.
    QRegularExpression exitSwitch("\\s*/EXIT\\s*", QRegularExpression::CaseInsensitiveOption);
    vfeArgs[0].replace(exitSwitch, " ");
    startVfeQuickRender(sceneName, sceneDir, vfeArgs);
    return;
  }
#endif // USE_VFE

  QuickRender::start(plan, this, [this](const QString &s) { emitScriptOutput(s); });
}

#if USE_VFE

void Viewer::startVfeQuickRender(const QString &sceneName, const QString &sceneDir,
                                  const QStringList &args) {
  if (_vfeRenderActive) {
    emitScriptOutput("POV-Ray (VFE): cancelling current render to start a new one.");
    _vfePendingSceneName = sceneName;
    _vfePendingSceneDir = sceneDir;
    _vfePendingArgs = args;
    _vfeRestartPending = true;
    _vfeSession->CancelRender();
    return;
  }

  if (!_vfeSession) {
    _vfeSession.reset(new BppVfeSession());
    if (_vfeSession->Initialize(nullptr, nullptr) != vfe::vfeNoError) {
      emitScriptOutput(QString("POV-Ray (VFE) failed to initialize: %1")
                            .arg(_vfeSession->GetErrorString()));
      drainVfeMessages();
      _vfeSession.reset();
      return;
    }
    _vfeSession->SetDisplayCreator(
        [](unsigned int w, unsigned int h, vfe::vfeSession *s, bool visible) -> vfe::vfeDisplay * {
          return new BppVfeDisplay(w, h, s, visible);
        });
  }

  // StartRender() does not do this itself -- vfeSession::Clear() is
  // documented as the client's responsibility before each new render.
  // Without it, m_Failed/m_Succeeded/pixel counters carry over from
  // whatever the session's last render left them as (most visibly after a
  // cancelled render), so e.g. Failed() could still read true on this,
  // otherwise fully successful, render.
  _vfeSession->Clear();

  // Dropped, not acquired here: vfe creates the Display asynchronously on
  // its worker thread sometime after StartRender() returns, so there's
  // nothing to fetch yet. pollVfeRender() acquires it lazily once available.
  _vfeDisplay.reset();

  // Drop the previous render's preview texture so it doesn't linger on
  // screen (or, if this render is a different resolution, leave stale
  // glTexSubImage2D calls writing into a wrongly-sized texture) before the
  // new render's first pixels arrive. The actual GL deletion happens inside
  // drawVfePreview() -- see the comment on _vfePreviewNeedsReset in
  // viewer.h for why it can't happen here.
  _vfePreviewNeedsReset = true;

  vfe::vfeRenderOptions opts;

  // POV-Ray's own standard include library (colors.inc, textures.inc, etc)
  // isn't implicit for an embedded VFE session the way it is for a real
  // install (which resolves it via povray.conf/registry, none of which
  // exists here) -- add it explicitly. povray/distribution/include is the
  // sibling checkout's copy; this is a dev-tree assumption specific to this
  // prototype, not something that survives packaging.
  // POV-Ray's own standard include library (colors.inc, textures.inc, etc)
  // is not implicit for an embedded VFE session the way it is for a real
  // install. Try the obvious checkout-relative locations first, then walk
  // far enough up from the .app binary / launch directory to reach a
  // sibling povray/ checkout (bpp/release/bpp.app/Contents/MacOS needs
  // four levels up to land back at bpp/'s parent), and finally a few
  // install prefixes.
  QStringList vfeIncludeCandidates;
  vfeIncludeCandidates << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("povray-include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../povray-include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../povray/distribution/include")
                      << QDir(startupWorkingDir()).absoluteFilePath("../povray/distribution/include")
                      << QDir(startupWorkingDir()).absoluteFilePath("../povray/include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../../../povray/distribution/include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../../../povray/include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../../povray/distribution/include")
                      << "/opt/homebrew/share/povray-3.7/include"
                      << "/usr/local/share/povray-3.7/include"
                      << "/usr/share/povray-3.7/include"
                      << "/usr/share/povray/include"
                      << "/usr/share/bpp/includes";
  bool vfeIncludesAdded = false;
  for (const QString &candidate : vfeIncludeCandidates) {
    if (QDir(candidate).exists()) {
      opts.AddLibraryPath(QDir(candidate).absolutePath().toStdString());
      vfeIncludesAdded = true;
      break;
    }
  }
  Q_UNUSED(vfeIncludesAdded);

  // bpp's shipped include library (settings.inc, bpp_CIE.inc, etc.) is not
  // implicit in an embedded VFE session, so add every place it can live the
  // same way locateMeshFile/settingsIncPath do. Without this, a scene that
  // pulls in settings.inc/bpp_CIE.inc fails with "Cannot open include file".
  QStringList bppIncludeCandidates;
  QString appDir = QCoreApplication::applicationDirPath();
  bppIncludeCandidates << appDir + "/includes"
                      << appDir + "/../includes"
                      << appDir + "/../../includes"
                      << startupWorkingDir() + "/includes"
                      << "/Applications/bpp.app/Contents/includes"
                      << "/usr/local/share/bpp/includes"
                      << "/opt/homebrew/share/bpp/includes"
                      << "/usr/share/bpp/includes";
  for (const QString &dir : bppIncludeCandidates) {
    if (QDir(dir).exists())
      opts.AddLibraryPath(QDir(dir).absolutePath().toStdString());
  }

  // savePOV() writes a per-frame include (e.g. "00038.inc") alongside the
  // .pov file and the main .pov references it by bare relative name. The
  // real povray.exe finds it because QProcess::setWorkingDirectory(sceneDir)
  // makes sceneDir its CWD; POV-Ray does not otherwise search relative to
  // the directory of the file doing the including, so the embedded session
  // needs sceneDir added as a library path explicitly (verified: without
  // this, "Cannot open include file NNNNN.inc").
  opts.AddLibraryPath(sceneDir.toStdString());

  for (const QString &arg : args) {
    opts.AddCommand(arg.toStdString());
  }

  if (_vfeSession->SetOptions(opts) != vfe::vfeNoError) {
    emitScriptOutput(QString("POV-Ray (VFE) failed to set options: %1")
                          .arg(_vfeSession->GetErrorString()));
    drainVfeMessages();
    return;
  }

  _vfePreviewWidth = _vfeSession->GetRenderWidth();
  _vfePreviewHeight = _vfeSession->GetRenderHeight();

  if (_vfeSession->StartRender() != vfe::vfeNoError) {
    emitScriptOutput(QString("POV-Ray (VFE) failed to start render: %1")
                          .arg(_vfeSession->GetErrorString()));
    drainVfeMessages();
    return;
  }

  _vfeRenderActive = true;
  _vfePreviewVisible = true;

  if (!_vfePollTimer) {
    _vfePollTimer = new QTimer(this);
    _vfePollTimer->setInterval(33);
    connect(_vfePollTimer, &QTimer::timeout, this, &Viewer::pollVfeRender);
  }
  _vfePollTimer->start();
}

void Viewer::drainVfeMessages() {
  if (!_vfeSession) {
    return;
  }
  vfe::vfeSession::MessageType type;
  std::string msg;
  while (_vfeSession->GetNextCombinedMessage(type, msg)) {
    emitScriptOutput(QString::fromStdString(msg));
  }
}

void Viewer::pollVfeRender() {
  if (!_vfeSession) {
    _vfePollTimer->stop();
    return;
  }

  vfe::vfeStatusFlags flags = _vfeSession->GetStatus(true, 0);

  drainVfeMessages();

  // Lazily acquire the display once vfe has created it (see the comment in
  // startVfeQuickRender()). Once acquired, stop asking: GetDisplay() walks
  // vfe's internal view map with no locking of its own, so this is called
  // only until it first succeeds, not on every tick.
  if (_vfeRenderActive && _vfeDisplay.expired()) {
    _vfeDisplay = std::dynamic_pointer_cast<BppVfeDisplay>(_vfeSession->GetDisplay());
  }

  if (auto display = _vfeDisplay.lock()) {
    if (display->dirty()) {
      update();
    }
  }

  if (flags & vfe::stCriticalError) {
    emitScriptOutput("POV-Ray (VFE) hit a critical error; resetting session.");
    _vfeRestartPending = false; // a broken session isn't worth auto-retrying
    teardownVfeRender(true);
    update();
    return;
  }

  if (flags & vfe::stRenderShutdown) {
    _vfePollTimer->stop();
    _vfeRenderActive = false;
    if (_vfeSession->Failed()) {
      emitScriptOutput(QString("POV-Ray (VFE) render failed: %1")
                            .arg(_vfeSession->GetErrorString()));
    } else if (_vfeSession->OutputToFileSet()) {
      vfe::UCS2String outputFilename = _vfeSession->GetOutputFilename();
      emitScriptOutput(QString("POV-Ray (VFE): saved %1")
                            .arg(QString::fromUtf16(outputFilename.c_str(),
                                                     static_cast<int>(outputFilename.size()))));
    }
    update();

    if (_vfeRestartPending) {
      _vfeRestartPending = false;
      startVfeQuickRender(_vfePendingSceneName, _vfePendingSceneDir, _vfePendingArgs);
    }
  }
}

void Viewer::drawVfePreview() {
  // Deferred from startVfeQuickRender() -- see the comment on
  // _vfePreviewNeedsReset in viewer.h. postDraw() (our only caller) always
  // runs within a current GL context, unlike the keypress handler that set
  // this flag.
  if (_vfePreviewNeedsReset) {
    if (_vfePreviewTexture) {
      glDeleteTextures(1, &_vfePreviewTexture);
      _vfePreviewTexture = 0;
    }
    _vfePreviewNeedsReset = false;
  }

  // display is null once vfe has torn the render down (see the comment on
  // _vfeDisplay in viewer.h) -- that's expected after completion, not an
  // error: _vfePreviewTexture already holds the last frame, so there's
  // nothing left to pull, just keep showing what's on the GPU already.
  auto display = _vfeDisplay.lock();
  if (!display && !_vfePreviewTexture) {
    return;
  }
  if (_vfePreviewWidth <= 0 || _vfePreviewHeight <= 0) {
    return;
  }

  if (!_vfePreviewTexture) {
    // A null data pointer allocates storage without defining its content
    // (implementation-defined, not guaranteed black), which would show
    // whatever garbage happened to be in that GPU memory for the first
    // few frames; zero-fill explicitly so a fresh render starts blank.
    QByteArray blank(_vfePreviewWidth * _vfePreviewHeight * 4, '\0');
    glGenTextures(1, &_vfePreviewTexture);
    glBindTexture(GL_TEXTURE_2D, _vfePreviewTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _vfePreviewWidth, _vfePreviewHeight, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, blank.constData());
  } else {
    glBindTexture(GL_TEXTURE_2D, _vfePreviewTexture);
  }

  if (display && display->dirty()) {
    QImage snap = display->snapshot();
    if (snap.width() == _vfePreviewWidth && snap.height() == _vfePreviewHeight) {
      glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, snap.width(), snap.height(),
                       GL_RGBA, GL_UNSIGNED_BYTE, snap.constBits());
    }
  }

  startScreenCoordinatesSystem();
  glDisable(GL_LIGHTING);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_TEXTURE_2D);
  glColor3f(1.0, 1.0, 1.0);

  glBegin(GL_QUADS);
  glTexCoord2f(0.0f, 0.0f);
  glVertex2i(0, 0);
  glTexCoord2f(1.0f, 0.0f);
  glVertex2i(width(), 0);
  glTexCoord2f(1.0f, 1.0f);
  glVertex2i(width(), height());
  glTexCoord2f(0.0f, 1.0f);
  glVertex2i(0, height());
  glEnd();

  glDisable(GL_TEXTURE_2D);
  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);
  stopScreenCoordinatesSystem();
}

void Viewer::teardownVfeRender(bool shutdownSession) {
  if (_vfePollTimer) {
    _vfePollTimer->stop();
  }
  _vfeRenderActive = false;
  if (shutdownSession && _vfeSession) {
    _vfeSession->Shutdown();
    _vfeSession.reset();
    _vfeDisplay.reset();
  }
}

#endif // USE_VFE
