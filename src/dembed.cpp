/**
 * @file dembed.cpp
 * @brief DemBed: DemCore (a shaken bed of beads, soft spheres) for Lua.
 */

#include "dembed.h"
#include "demcore.h"

#include "objects/object.h"

#include <chrono>
#include <ctime>

#include <luabind/luabind.hpp>

DemBed::DemBed() : core(new DemCore()), cpuSeconds(0) {}

DemBed::~DemBed() {
  finish();
  delete core;
}

bool DemBed::set(const std::string &key, double val) {
  finish();
  return core->set(key, val);
}

double DemBed::get(const std::string &key) {
  finish();
  return core->get(key);
}

void DemBed::init() {
  finish();
  core->init();
  shown.assign(core->count(), nullptr);
  for (int wall = 0; wall < 3; wall++)
    glued[wall].assign(core->gluedCount(wall), nullptr);
}

// (the thread's own CPU time: what stepping this box costs, whatever else runs)
static double threadCpu() {
  timespec ts;
  if (clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ts) != 0)
    return 0;
  return ts.tv_sec + 1e-9 * ts.tv_nsec;
}

void DemBed::run(double t) {
  double c0 = threadCpu();
  core->stepTo(t);
  cpuSeconds += threadCpu() - c0;
}

void DemBed::step(double t) {
  finish();
  run(t);
}

void DemBed::start(double t) {
  finish();
  worker = std::thread(&DemBed::run, this, t);
}

void DemBed::finish() {
  if (worker.joinable())
    worker.join();
}

int DemBed::count() { finish(); return core->count(); }
double DemBed::x(int i) { finish(); return i >= 0 && i < core->count() ? core->posX(i) : 0; }
double DemBed::y(int i) { finish(); return i >= 0 && i < core->count() ? core->posY(i) : 0; }
double DemBed::r(int i) { finish(); return i >= 0 && i < core->count() ? core->radius(i) : 0; }
double DemBed::boxY() { finish(); return core->boxHeight(); }
int DemBed::gluedCount(int wall) { finish(); return wall >= 0 && wall < 3 ? core->gluedCount(wall) : 0; }
double DemBed::gluedX(int wall, int k) { return k >= 0 && k < gluedCount(wall) ? core->gluedX(wall, k) : 0; }
double DemBed::gluedY(int wall, int k) { return k >= 0 && k < gluedCount(wall) ? core->gluedY(wall, k) : 0; }
double DemBed::cpu() { finish(); return cpuSeconds; }

void DemBed::attach(int i, Object *o) {
  finish();
  if (i >= 0 && i < (int)shown.size())
    shown[i] = o;
}

void DemBed::attachGlued(int wall, int k, Object *o) {
  finish();
  if (wall >= 0 && wall < 3 && k >= 0 && k < (int)glued[wall].size())
    glued[wall][k] = o;
}

// (a display-only object put where it's drawn: its body and motion state)
static void place(Object *o, double x, double y, double z) {
  if (o == nullptr || o->body == nullptr)
    return;
  btTransform tr;
  tr.setIdentity();
  tr.setOrigin(btVector3(x, y, z));
  o->body->setWorldTransform(tr);
  if (o->body->getMotionState() != nullptr)
    o->body->getMotionState()->setWorldTransform(tr);
}

void DemBed::sync(double ox, double oy, double oz) {
  finish();
  for (int i = 0; i < (int)shown.size(); i++)
    place(shown[i], ox + core->posX(i), oy + core->posY(i), oz);
  double by = core->boxHeight();
  for (int wall = 0; wall < 3; wall++)
    for (int k = 0; k < (int)glued[wall].size(); k++)
      place(glued[wall][k], ox + core->gluedX(wall, k), oy + by + core->gluedY(wall, k), oz);
}

std::string DemBed::test(const std::string &name) {
  finish();
  return core->test(name);
}

// the wall clock, in seconds (for timing frames: Lua's own clocks are CPU
// time or whole seconds)
static double demWallClock() {
  return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

void DemBed::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<DemBed>("DemBed")
                .def(constructor<>())
                .def("set", &DemBed::set)
                .def("get", &DemBed::get)
                .def("init", &DemBed::init)
                .def("step", &DemBed::step)
                .def("start", &DemBed::start)
                .def("finish", &DemBed::finish)
                .def("count", &DemBed::count)
                .def("x", &DemBed::x)
                .def("y", &DemBed::y)
                .def("r", &DemBed::r)
                .def("boxY", &DemBed::boxY)
                .def("gluedCount", &DemBed::gluedCount)
                .def("gluedX", &DemBed::gluedX)
                .def("gluedY", &DemBed::gluedY)
                .def("cpu", &DemBed::cpu)
                .def("attach", &DemBed::attach)
                .def("attachGlued", &DemBed::attachGlued)
                .def("sync", &DemBed::sync)
                .def("test", &DemBed::test),
            def("demWallClock", &demWallClock)];
}
