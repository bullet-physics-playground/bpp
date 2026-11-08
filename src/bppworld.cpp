#include "bppworld.h"

#include <unordered_map>
#include <utility>
#include <vector>

#include <btBulletDynamicsCommon.h>
#if BT_THREADSAFE
#include <BulletDynamics/Dynamics/btDiscreteDynamicsWorldMt.h>
#include <BulletDynamics/Dynamics/btSimulationIslandManagerMt.h>
#endif

// Joint warm-starting ("si-warm", setSolver): Bullet's sequential impulse solver starts every joint row from zero
// impulse each step (only contacts carry theirs over, in their manifold points). This one keeps each joint row's
// final impulse and starts the next step from it, scaled by g_jointWarmstart (setSolverInfo "jointWarmstart",
// default 0.85, the factor Bullet uses for contacts) -- for linkages whose joints carry much the same forces from one
// small step to the next, so the iterations start near the answer.
//
// The world hands the solver its joints a group at a time (Bullet joins small islands into groups of about 128
// joints and contacts), so one step can be several groups. Each joint's entry is marked with the step it was last
// solved in; at the end of each step (allSolved) entries not solved in it -- joints removed, or asleep -- are
// dropped. (Until November 2026 the cache was cut back to the group just solved whenever it grew past four times
// that group, which in a room of more than about ten walkers threw away nearly every other walker's entries at
// every step: with all 21 walkers no joint started warm.)
//
// A threaded world (BppWorld, setThreads) solves its islands with a pool of these, one a thread, and an island can go
// to a different one each step; so there they share one cache, kept by the world (WarmCache). Before the islands are
// solved the world makes an entry for every joint, on one thread; while they are solved each joint's entry is read
// and written only by the thread solving that joint's island (a joint is in one island), and no entry is added or
// removed; afterwards, on one thread, entries not solved in the step are dropped, as here.
btScalar g_jointWarmstart = 0.85;
struct WarmCache {
  struct Entry { std::vector<btScalar> impulse; unsigned step = 0; };
  std::unordered_map<const btTypedConstraint *, Entry> map;
  unsigned step = 0;       // (counts steps)
  void dropUnsolved() {
    for (auto it = map.begin(); it != map.end();)
      it = it->second.step == step ? std::next(it) : map.erase(it);
  }
};
class WarmJointSolver : public btSequentialImpulseConstraintSolver {
  WarmCache _own;
  WarmCache *_cache = &_own;   // (or a threaded world's, shared)
  std::vector<std::pair<const btTypedConstraint *, int>> _rows;   // this group's joints and their row counts, in order
  size_t _solved = 0;      // joints solved this step (own cache)
public:
  WarmJointSolver() {}
  explicit WarmJointSolver(WarmCache *shared) : _cache(shared) {}
  // a joint taken out of the world: its entry goes now, so a joint made later at the same address (as when the room
  // swaps a walker) does not start from its forces
  void forget(const btTypedConstraint *c) { _own.map.erase(c); }
  void prepareSolve(int numBodies, int numManifolds) override {
    btSequentialImpulseConstraintSolver::prepareSolve(numBodies, numManifolds);
    if (_cache == &_own) {
      ++_own.step;
      _solved = 0;
    }
  }
  void allSolved(const btContactSolverInfo &info, btIDebugDraw *debugDrawer) override {
    if (_cache == &_own && _own.map.size() > _solved)
      _own.dropUnsolved();
    btSequentialImpulseConstraintSolver::allSolved(info, debugDrawer);
  }
protected:
  void convertJoints(btTypedConstraint **constraints, int numConstraints, const btContactSolverInfo &info) override {
    btSequentialImpulseConstraintSolver::convertJoints(constraints, numConstraints, info);
    _rows.clear();
    int row = 0;
    for (int i = 0; i < numConstraints; i++) {
      int n = m_tmpConstraintSizesPool[i].m_numConstraintRows;
      _rows.emplace_back(constraints[i], n);
      auto it = _cache->map.find(constraints[i]);
      if (g_jointWarmstart > 0 && it != _cache->map.end() && int(it->second.impulse.size()) == n) {
        for (int j = 0; j < n; j++) {
          btSolverConstraint &c = m_tmpSolverNonContactConstraintPool[row + j];
          btScalar imp = btMax(c.m_lowerLimit, btMin(c.m_upperLimit, g_jointWarmstart * it->second.impulse[j]));
          if (imp == 0) continue;
          c.m_appliedImpulse = imp;
          btSolverBody &a = m_tmpSolverBodyPool[c.m_solverBodyIdA];
          btSolverBody &b = m_tmpSolverBodyPool[c.m_solverBodyIdB];
          a.internalApplyImpulse(c.m_contactNormal1 * a.internalGetInvMass(), c.m_angularComponentA, imp);
          b.internalApplyImpulse(c.m_contactNormal2 * b.internalGetInvMass(), c.m_angularComponentB, imp);
        }
      }
      row += n;
    }
  }
  btScalar solveGroupCacheFriendlyFinish(btCollisionObject **bodies, int numBodies, const btContactSolverInfo &info) override {
    int row = 0;
    for (auto &r : _rows) {
      // (a shared cache already has every joint's entry: find, never add)
      WarmCache::Entry &e = _cache == &_own ? _own.map[r.first] : _cache->map.find(r.first)->second;
      e.impulse.resize(r.second);
      for (int j = 0; j < r.second; j++) e.impulse[j] = m_tmpSolverNonContactConstraintPool[row + j].m_appliedImpulse;
      if (e.step != _cache->step) { e.step = _cache->step; ++_solved; }
      row += r.second;
    }
    return btSequentialImpulseConstraintSolver::solveGroupCacheFriendlyFinish(bodies, numBodies, info);
  }
};

btConstraintSolver *newWarmJointSolver() { return new WarmJointSolver(); }

// BppWorld: see bppworld.h.
BppWorld::~BppWorld() { stopThreads(); }

void BppWorld::removeConstraint(btTypedConstraint *c) {   // (si-warm forgets it: WarmJointSolver::forget)
  if (WarmJointSolver *w = dynamic_cast<WarmJointSolver *>(m_constraintSolver)) w->forget(c);
#if BT_THREADSAFE
  if (_warm) _warm->map.erase(c);
#endif
  btSoftRigidDynamicsWorld::removeConstraint(c);
}

btSoftRigidDynamicsWorld *newBppWorld(btDispatcher *dispatcher, btBroadphaseInterface *broadphase,
                                      btConstraintSolver *solver, btCollisionConfiguration *cfg) {
  return new BppWorld(dispatcher, broadphase, solver, cfg);
}

#if BT_THREADSAFE
namespace {
// (Bullet's own, in btDiscreteDynamicsWorld.cpp and btSimulationIslandManager.cpp, copied: they aren't in its
// headers)
int islandOf(const btTypedConstraint *c) {
  const btCollisionObject &a = c->getRigidBodyA(), &b = c->getRigidBodyB();
  return a.getIslandTag() >= 0 ? a.getIslandTag() : b.getIslandTag();
}
int islandOf(const btPersistentManifold *m) {
  const btCollisionObject *a = m->getBody0(), *b = m->getBody1();
  return a->getIslandTag() >= 0 ? a->getIslandTag() : b->getIslandTag();
}
struct ByIsland {
  bool operator()(const btTypedConstraint *l, const btTypedConstraint *r) const { return islandOf(l) < islandOf(r); }
  bool operator()(const btPersistentManifold *l, const btPersistentManifold *r) const { return islandOf(l) < islandOf(r); }
};
struct ByIslandDeterministic {   // (with m_deterministicOverlappingPairs)
  bool operator()(const btPersistentManifold *l, const btPersistentManifold *r) const {
    const int il = islandOf(l), ir = islandOf(r);
    const int a0 = l->getBody0()->getBroadphaseHandle()->m_uniqueId, b0 = r->getBody0()->getBroadphaseHandle()->m_uniqueId;
    return il < ir || (il == ir && a0 < b0) ||
           (il == ir && a0 == b0 && l->getBody1()->getBroadphaseHandle()->m_uniqueId < r->getBody1()->getBroadphaseHandle()->m_uniqueId);
  }
};
} // namespace

struct BppWorld::IslandsMt : public btSimulationIslandManagerMt {
  bool deterministic = false;
  btAlignedObjectArray<btPersistentManifold *> sorted;
  IslandsMt() {
    m_batchIslandMinBodyCount = 0;   // (Bullet joins islands of under 32 bodies into one batch)
    setMinimumSolverBatchSize(1);    // (and merges small islands until a batch costs 1024)
  }
  // as Bullet's (btSimulationIslandManagerMt::addManifoldsToIslands), but the contacts sorted by island first, as
  // its one-thread world sorts them (btSimulationIslandManager::processIslands), so each island gets them in the
  // same order
  void addManifoldsToIslands(btDispatcher *dispatcher) override {
    sorted.resizeNoInitialize(0);   // (resize(0) here makes GCC 12 warn of an overflow that cannot happen)
    for (int i = 0; i < dispatcher->getNumManifolds(); i++) {
      btPersistentManifold *m = dispatcher->getManifoldByIndexInternal(i);
      if (deterministic && m->getNumContacts() == 0) continue;
      const btCollisionObject *a = m->getBody0(), *b = m->getBody1();
      if ((a && a->getActivationState() != ISLAND_SLEEPING) || (b && b->getActivationState() != ISLAND_SLEEPING)) {
        // kinematic objects don't join islands, but wake what they touch
        if (a->isKinematicObject() && a->getActivationState() != ISLAND_SLEEPING && a->hasContactResponse())
          b->activate();
        if (b->isKinematicObject() && b->getActivationState() != ISLAND_SLEEPING && b->hasContactResponse())
          a->activate();
        if (dispatcher->needsResponse(a, b)) sorted.push_back(m);
      }
    }
    if (deterministic) sorted.quickSort(ByIslandDeterministic());
    else sorted.quickSort(ByIsland());
    for (int i = 0; i < sorted.size(); i++)
      if (Island *island = getIsland(islandOf(sorted[i]))) island->manifoldArray.push_back(sorted[i]);
  }
};

int BppWorld::threads() const { return _pool ? _threads : 0; }

void BppWorld::startThreads(int n, bool warm) {
  stopThreads();
  if (warm) _warm.reset(new WarmCache());
  btAlignedObjectArray<btConstraintSolver *> solvers;
  for (int i = 0; i < n; i++)
    solvers.push_back(warm ? static_cast<btConstraintSolver *>(new WarmJointSolver(_warm.get()))
                           : new btSequentialImpulseConstraintSolver());
  _pool = new btConstraintSolverPoolMt(&solvers[0], n);
  _islandsMt = new IslandsMt();
  _serialIslands = m_islandManager;
  m_islandManager = _islandsMt;      // (calculateSimulationIslands fills the one in use)
  _threads = n;
}

void BppWorld::stopThreads() {
  if (!_pool) return;
  m_islandManager = _serialIslands;
  delete _islandsMt;
  _islandsMt = nullptr;
  delete _pool;                      // (and its solvers)
  _pool = nullptr;
  _warm.reset();
  _threads = 0;
}

void BppWorld::solveConstraints(btContactSolverInfo &info) {
  if (!_pool) {
    btSoftRigidDynamicsWorld::solveConstraints(info);
    return;
  }
  if (_warm) {                       // (every joint's entry made before the threads start: see WarmCache)
    ++_warm->step;
    for (int i = 0; i < m_constraints.size(); i++) _warm->map.emplace(m_constraints[i], WarmCache::Entry());
  }
  // the joints in the order Bullet's one-thread world gives them (btDiscreteDynamicsWorld::solveConstraints: sorted
  // by island, by the same sort), so each island's joints come in the same order (the threaded island manager
  // keeps the order it is given); the contacts likewise (IslandsMt). So one walker is solved exactly as without
  // threads.
  m_sortedConstraints.resize(m_constraints.size());
  for (int i = 0; i < m_constraints.size(); i++) m_sortedConstraints[i] = m_constraints[i];
  m_sortedConstraints.quickSort(ByIsland());
  _islandsMt->deterministic = getDispatchInfo().m_deterministicOverlappingPairs;
  btSimulationIslandManagerMt::SolverParams p;
  p.m_solverPool = _pool;
  p.m_solverMt = nullptr;            // (Bullet's solver that splits one island across threads: not used)
  p.m_solverInfo = &info;
  p.m_debugDrawer = m_debugDrawer;
  p.m_dispatcher = getDispatcher();
  _islandsMt->buildAndProcessIslands(getDispatcher(), this, m_sortedConstraints, p);
  _pool->allSolved(info, m_debugDrawer);
  if (_warm) _warm->dropUnsolved();
}
#else
int BppWorld::threads() const { return 0; }
void BppWorld::startThreads(int, bool) {}
void BppWorld::stopThreads() {}
#endif
