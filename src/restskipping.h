#pragma once

/**
 * @file restskipping.h
 * @brief RestSkippingDispatcher, the collision dispatcher of bpp's worlds
 *        (Viewer's constructor and newWorld() make one each).
 */

#include <btBulletCollisionCommon.h>
#include <LinearMath/btPoolAllocator.h>
#include <LinearMath/btThreads.h>

#include <algorithm>
#include <vector>

// bpp's collision dispatcher, which skips pairs at rest.
//
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
