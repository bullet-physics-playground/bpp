#ifndef BPPWORLD_H
#define BPPWORLD_H

#include <memory>

#include <BulletSoftBody/btSoftRigidDynamicsWorld.h>

class btConstraintSolverPoolMt;
struct WarmCache;

/// si-warm's factor (setSolverInfo "jointWarmstart", default 0.85): each joint row starts a step from this much of its
/// last step's impulse.
extern btScalar g_jointWarmstart;

/// A new si-warm solver (setSolver "si-warm"): Bullet's sequential impulse solver that starts each joint from its
/// impulse of the step before (bppworld.cpp).
btConstraintSolver *newWarmJointSolver();

/**
 * @brief bpp's world: Bullet's soft body world, which with setThreads(n)
 * solves its islands -- groups of bodies joined by joints or touching, such
 * as one walker -- side by side on n threads, as Bullet's
 * btDiscreteDynamicsWorldMt does, keeping soft bodies.
 *
 * Only the solve is threaded, inside stepSimulation, which returns when
 * every island is solved: collisions, integration, soft bodies, the scripts
 * and the drawing run as before, on the one thread that calls it. One walker
 * is solved exactly as without threads, and any number of threads gives the
 * same run. Needs Bullet built with threads (BT_THREADSAFE:
 * scripts/bullet-threads.sh, qmake CONFIG+=bundled_bullet); without it
 * threads() is 0 and startThreads does nothing.
 */
class BppWorld : public btSoftRigidDynamicsWorld {
public:
  using btSoftRigidDynamicsWorld::btSoftRigidDynamicsWorld;
  ~BppWorld() override;
  /// As Bullet's; si-warm also forgets the joint's impulses, so a joint made later at the same address does not
  /// start from them.
  void removeConstraint(btTypedConstraint *c) override;
  /// The threads solving the islands (0: one, as Bullet's world).
  int threads() const;
  /// n solvers in a pool, one a thread; warm: si-warm's, sharing one cache, else Bullet's sequential impulse.
  void startThreads(int n, bool warm);
  /// Back to Bullet's own solve, on one thread.
  void stopThreads();
#if BT_THREADSAFE
  void solveConstraints(btContactSolverInfo &info) override;
#endif

private:
  struct IslandsMt;
  btSimulationIslandManager *_serialIslands = nullptr;   // the world's own, while threaded
  IslandsMt *_islandsMt = nullptr;
  btConstraintSolverPoolMt *_pool = nullptr;
  std::unique_ptr<WarmCache> _warm;                       // si-warm's cache, shared by the pool's solvers
  int _threads = 0;
};

/// A new world for bpp (a BppWorld).
btSoftRigidDynamicsWorld *newBppWorld(btDispatcher *dispatcher, btBroadphaseInterface *broadphase,
                                      btConstraintSolver *solver, btCollisionConfiguration *cfg);

#endif // BPPWORLD_H
