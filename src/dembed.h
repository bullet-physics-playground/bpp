#ifndef DEMBED_H
#define DEMBED_H

/**
 * @file dembed.h
 * @brief DemBed: a shaken bed of beads simulated outside Bullet (DemCore,
 * the soft-sphere model of the Brazil-nut exhibit's reference), for Lua.
 *
 * One DemBed is one box. Its parameters are bead-bed.c's keys (set()); it
 * steps itself to a given simulated time in its own fixed steps, in a thread
 * of its own if asked (start() / finish()), so several boxes run side by
 * side. Nothing is shared between boxes, so each runs the same, bit for bit,
 * however the threads are scheduled. Its beads are drawn by display-only bpp
 * objects that sync() moves.
 */

#include <string>
#include <thread>
#include <vector>

struct lua_State;
class DemCore;
class Object;

class DemBed {
public:
  DemBed();
  ~DemBed();

  /** @brief Sets a parameter (bead-bed.c's keys); false if unknown. */
  bool set(const std::string &key, double val);
  /** @brief A parameter or a measurement by name (see demcore.cpp). */
  double get(const std::string &key);
  /** @brief Pours the bed (after set()). */
  void init();
  /** @brief Runs on to simulated time t, here and now. */
  void step(double t);
  /** @brief Runs on to simulated time t in a thread of its own; finish()
   * waits for it. Every other call waits for it first too. */
  void start(double t);
  /** @brief Waits for start()'s run to end. */
  void finish();

  int count();
  double x(int i);
  double y(int i);
  double r(int i);
  double boxY();
  int gluedCount(int wall);
  double gluedX(int wall, int k);
  double gluedY(int wall, int k);
  /** @brief The thread CPU time spent stepping, in seconds. */
  double cpu();

  /** @brief Bead i is drawn by o (display-only: mass 0, collides false). */
  void attach(int i, Object *o);
  /** @brief Glued sphere k of a wall (0 left, 1 right, 2 floor) is drawn by o. */
  void attachGlued(int wall, int k, Object *o);
  /** @brief Moves the attached objects to their beads and glued spheres,
   * the box's floor centre (at rest) at (ox, oy, oz). */
  void sync(double ox, double oy, double oz);

  /** @brief A validation test (drop, pair, incline, gdrop, ghollow), as
   * bead-bed.c's TEST=; returns its output. On a DemBed that has been
   * set() but not init(): it uses the bed up. */
  std::string test(const std::string &name);

  static void luaBind(lua_State *s);

private:
  void run(double t);
  DemCore *core;
  std::thread worker;
  std::vector<Object *> shown, glued[3];
  double cpuSeconds;
};

#endif
