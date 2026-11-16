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
#include "restskipping.h"
#include "viewer_p.h"

#include <cstring>
#include <memory>


#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>

#include "gimpactplane.h"
#include "bppworld.h"

#include "lua_bullet.h"
#include "lua_converters.h"   // for Q_DECLARE_METATYPE(luabind::object)

#include "shadowmap.h"

#if USE_VFE
#include "povray/bppvfesession.h"
#include "povray/bppvfedisplay.h"
#endif // USE_VFE

#ifdef HAS_LUA_QT
#include "lua_register.h"
#endif

#include "objects/object.h"
#include "objects/plane.h"
#include "objects/softbody.h"

#include <BulletSoftBody/btSoftBodyRigidBodyCollisionConfiguration.h>
#include <BulletDynamics/MLCPSolvers/btMLCPSolverInterface.h> // (~Viewer deletes one)

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
void bppGyroPreTick(btDynamicsWorld *world, btScalar dt) {
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
#endif

#include "povexport.h"

#include "objects/cam.h"


#ifdef WIN32
#include <windows.h>
#endif

#include <QDebug>

#include <QTimer>
#include <QTime>
#include <QMap>
#include <QElapsedTimer>
#include <QApplication>
#include <algorithm>
#include <tuple>

#include <boost/exception/all.hpp>
#include <boost/exception/info.hpp>
#include <boost/throw_exception.hpp>

#include <cstdlib>
#include <cmath>

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

// (see viewer_p.h)
[[noreturn]] void luaFail(lua_State *L, const std::string &message) {
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

// A script's constraint changes hands once: luabind's adopt policy, used
// here before, broke the script's handle when the same constraint was added
// twice, and v:removeConstraint made a second handle that freed it while
// the first still pointed at it.
static btTypedConstraint *constraintOf(lua_State *L, const luabind::object &handle, const char *fn) {
  btTypedConstraint *c = nullptr;
  if (handle.is_valid() && luabind::type(handle) == LUA_TUSERDATA)
    c = luabind::object_cast<btTypedConstraint *>(handle);   // (another class: luabind's own error)
  if (c == nullptr)
    luaFail(L, std::string(fn) + ": needs a constraint");
  return c;
}

void Viewer::addConstraintLua(const luabind::object &handle) {
  btTypedConstraint *c = constraintOf(L, handle, "addConstraint");
  if (_constraints->contains(c))
    return;
  if (!_consTakenFromLua.contains(c)) {
    handle.push(L);
    luabind::detail::object_rep *rep = luabind::detail::get_instance(L, -1);
    if (rep != nullptr)
      rep->release();
    lua_pop(L, 1);
    _consTakenFromLua.insert(c);
  }
  _consKept.remove(c);
  addConstraint(c);
}

luabind::object Viewer::removeConstraintLua(const luabind::object &handle) {
  btTypedConstraint *c = constraintOf(L, handle, "removeConstraint");
  if (!_constraints->contains(c))
    return handle;
  removeConstraint(c);
  _consKept.insert(c);
  return handle;
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

// (taken from Lua once, as a constraint is: see constraintOf above. nil
// went into the world as a null vehicle, which crashed the next step.)
void Viewer::addVehicleLua(const luabind::object &handle) {
  btRaycastVehicle *veh = nullptr;
  if (handle.is_valid() && luabind::type(handle) == LUA_TUSERDATA)
    veh = luabind::object_cast<btRaycastVehicle *>(handle);
  if (veh == nullptr)
    luaFail(L, "addVehicle: needs a vehicle");
  if (_raycast_vehicles->contains(veh))
    return;
  handle.push(L);
  luabind::detail::object_rep *rep = luabind::detail::get_instance(L, -1);
  if (rep != nullptr)
    rep->release();
  lua_pop(L, 1);
  addVehicle(veh);
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
void getAABB(ObjectSet *objects, btScalar aabb[6]) {
  aabb[0] = -10;
  aabb[1] = -10;
  aabb[2] = -10;
  aabb[3] = 10;
  aabb[4] = 10;
  aabb[5] = 10;

  ObjectSet::const_iterator oi;
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

  _objects = new ObjectSet();
  _constraints = new OrderedSet<btTypedConstraint *>();
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


  // libQGLViewer leaves the camera setCamera replaces to its caller.
  qglviewer::Camera *defaultCamera = camera();
  setCamera(new Cam(this));
  delete defaultCamera;

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

  closeScript();

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
  qDeleteAll(_consKept);                 // (removed ones the script kept)
  _consKept.clear();

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
  auto failedWith = [this](const QString &message) {
    emitScriptOutput(message);
    _savePOV = false;
    _povExportFailed = true;
    emit POVStateChanged(false);
  };
  auto exportFailed = [&](const QString &dir) {
    failedWith(tr("Unable to create directory %1.").arg(dir));
  };
  auto unwritable = [&](const QString &path) {
    failedWith(tr("Unable to write %1.").arg(path));
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

  if (!PovExport::writeIni(fileINI, byline, sceneName, _firstFrame, _frameNum)) {
    unwritable(fileINI);
    return;
  }

  PovExport::Scene scene;
  scene.radiosity = _povRadiosityEnabled;
  scene.photons = _povPhotonsEnabled;
  scene.fog = _povFogEnabled;
  scene.atmosphere = _povAtmosphereEnabled;
  scene.light0 = _light0;
  scene.light1 = _light1;
  scene.diffuse = _gl_diffuse;
  scene.settingsInc = _pov_settings_inc;
  if (!PovExport::writeMain(fileMain, byline, scene)) {
    unwritable(fileMain);
    return;
  }

  if (!PovExport::writeMakefile(sceneDir)) {
    unwritable(sceneDir + QDir::separator() + "GNUmakefile");
    return;
  }

  _decorations.update();   // (headless runs export without drawing)
  if (!PovExport::writeFrame(file, byline, mPreSDL, _cam, camera(), *_objects, mPostSDL, sceneDir))
    unwritable(file);
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
  updateGLViewer();      // (else the red dot stays until something repaints)
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

// POV-Ray properties

void Viewer::setPreSDL(const QString &preSDL) { mPreSDL = preSDL; }

QString Viewer::getPreSDL() const { return mPreSDL; }

void Viewer::setPostSDL(const QString &postSDL) { mPostSDL = postSDL; }

QString Viewer::getPostSDL() const { return mPostSDL; }

// Writes a script's preferences on the Viewer's preference thread.
// (which store: taken from the Viewer's settings on the main thread; one
// opened by file name, as BPP_USER_DIR's bpp.ini is, has no organization)
class PrefsWriter : public QRunnable {
public:
  PrefsWriter(Viewer *v, const QSettings *store)
      : _v(v), _format(store->format()), _scope(store->scope()),
        _org(store->organizationName()), _app(store->applicationName()),
        _file(store->fileName()) {
    setAutoDelete(true);
  }
  void run() override {
    if (_org.isEmpty()) {
      QSettings s(_file, _format);
      _v->writePendingPrefs(s);
    } else {
      QSettings s(_format, _scope, _org, _app);
      _v->writePendingPrefs(s);
    }
  }

private:
  Viewer *_v;
  QSettings::Format _format;
  QSettings::Scope _scope;
  QString _org, _app, _file;
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
