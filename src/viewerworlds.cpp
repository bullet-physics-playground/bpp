/**
 * @file viewerworlds.cpp
 * @brief The Viewer's physics worlds and solver, for scripts: v:newWorld(),
 *        useWorld(), placeWorld(), v.tau, erp, cfm, solverIterations,
 *        v:setSolver(), setSolverInfo(), setThreads(); and the step itself.
 */

// GCC 13 (Ubuntu 24.04, -O3) warns of a memset past any object's size inside
// Bullet's btLemkeSolver, all of it in Bullet's headers and compiled in where
// setSolver makes one; it gave no warning in viewer.cpp, where this code was
// before, with the same headers. A false alarm of its inlining, as GCC
// reports for headers' templates; it ties the warning to Bullet's header
// line, so it must be off before viewer.h brings btScalar.h in.
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic ignored "-Wstringop-overflow"
#endif

#include "viewer.h"
#include "viewer_p.h"

#include "bppworld.h"
#include "gimpactplane.h"
#include "objects/softbody.h"
#include "restskipping.h"

#include <BulletSoftBody/btSoftBodyRigidBodyCollisionConfiguration.h>
#include <BulletDynamics/ConstraintSolver/btNNCGConstraintSolver.h>
#include <BulletDynamics/MLCPSolvers/btMLCPSolver.h>
#include <BulletDynamics/MLCPSolvers/btDantzigSolver.h>
#include <BulletDynamics/MLCPSolvers/btSolveProjectedGaussSeidel.h>
#include <BulletDynamics/MLCPSolvers/btLemkeSolver.h>

void Viewer::setTau(btScalar tau) {
  dynamicsWorld->getSolverInfo().m_tau = tau;
}


// Bullet recomputes every object's bounding box on every substep by
// default, even objects that never move; with many substeps a frame and
// thousands of fixed parts, that's most of the work of a quiet scene.
// Instead, the substeps update only moving (active) objects, as Bullet does
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
