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

#include <QColor>
#include <QTextCodec>

#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>

#include "lua_bullet.h"

#include "glutils.h"
#include "shadowmap.h"

#if USE_VFE
#include "povray/bppvfesession.h"
#include "povray/bppvfedisplay.h"
#endif // USE_VFE

#ifdef HAS_LUA_QT
#include "lua_register.h"
#endif

#include "objects/cone.h"
#include "objects/cube.h"
#include "objects/cylinder.h"
#include "objects/object.h"
#include "objects/plane.h"
#include "objects/rigidsoftcontact.h"
#include "objects/softbody.h"
#include "objects/sphere.h"
#include "objects/terrain.h"
#include "objects/triangle.h"

#include <BulletSoftBody/btSoftBodyRigidBodyCollisionConfiguration.h>
#include <BulletSoftBody/btSoftRigidDynamicsWorld.h>

#ifdef HAS_LIB_ASSIMP
#include "objects/mesh.h"
#include "objects/openscad.h"
#endif

#include "objects/palette.h"

#include "objects/cam.h"

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
#include <QToolTip>
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

#include <luabind/adopt_policy.hpp>
#include <luabind/class_info.hpp>
#include <luabind/operator.hpp>
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

/**
 * @brief Writes a Viewer's description to a standard stream.
 * @param ostream The stream to write to.
 * @param v       The viewer to describe.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const Viewer &v) {
  ostream << v.toString().toUtf8().data();
  return ostream;
}

// luabind's comparison policy needs an operator== reachable via ADL for
// every class registered with it (see the identity-operator comment in
// lua_bullet.cpp for why this matters). Viewer/JoystickInfo have no natural
// value equality, so fall back to identity; QColor already has a real
// operator== from Qt, and SpaceNavigator::Axes is a plain field struct.
/**
 * @brief Compares two Viewers by identity.
 * @param a First viewer.
 * @param b Second viewer.
 * @return True only if both are the same object.
 */
bool operator==(const Viewer &a, const Viewer &b) { return &a == &b; }

/**
 * @brief Compares two JoystickInfos by identity.
 * @param a First report.
 * @param b Second report.
 * @return True only if both are the same object.
 */
bool operator==(const JoystickInfo &a, const JoystickInfo &b) {
  return &a == &b;
}

/**
 * @brief Compares two sets of 3D mouse axes by value.
 * @param a First set of axes.
 * @param b Second set of axes.
 * @return True if all six axes match.
 */
bool operator==(const SpaceNavigator::Axes &a, const SpaceNavigator::Axes &b) {
  return a.x == b.x && a.y == b.y && a.z == b.z && a.rx == b.rx &&
         a.ry == b.ry && a.rz == b.rz;
}

/**
 * @brief Writes a QString to a standard stream as UTF-8.
 * @param ostream The stream to write to.
 * @param s       The string.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const QString &s) {
  ostream << s.toUtf8().data();
  return ostream;
}

/**
 * @brief Writes a QColor to a standard stream by its name.
 * @param ostream The stream to write to.
 * @param c       The colour.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const QColor &c) {
  ostream << "QColor(\"" << c.name().toUtf8().data() << "\")";
  return ostream;
}

/**
 * @brief Writes a placeholder description of a JoystickInfo to a stream.
 * @param ostream The stream to write to.
 * @param ji      The report. Its contents are not printed.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const JoystickInfo &ji) {
  Q_UNUSED(ji)
  ostream << "JoystickInfo()"; // XXX
  return ostream;
}

/**
 * @brief Writes a set of 3D mouse axes to a standard stream.
 * @param ostream The stream to write to.
 * @param axes    The axes.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream,
                         const SpaceNavigator::Axes &axes) {
  ostream << QString("SpaceNavigatorAxes(x=%1, y=%2, z=%3, rx=%4, ry=%5, rz=%6)")
                 .arg(axes.x)
                 .arg(axes.y)
                 .arg(axes.z)
                 .arg(axes.rx)
                 .arg(axes.ry)
                 .arg(axes.rz)
                 .toUtf8()
                 .data();
  return ostream;
}

QString Viewer::toString() const { return QString("Viewer"); }

void Viewer::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)
      [class_<Viewer>("Viewer")
           .def(constructor<>())
           .def("setCam", (void(Viewer::*)(Cam *)) & Viewer::setCamera,
                adopt(_2))
           .def("getCam", &Viewer::getCamera)
           .def("add", &Viewer::addObjectLua)
           .def("remove", &Viewer::removeObjectLua)
           .def("setTau", (void(Viewer::*)(btScalar))&Viewer::setTau)
           .def("setErp", (void(Viewer::*)(btScalar))&Viewer::setErp)
           .def("setErp2", (void(Viewer::*)(btScalar))&Viewer::setErp2)
           .def("setCfm", (void(Viewer::*)(btScalar))&Viewer::setCfm)
           .def("setSolverIterations",
                (void(Viewer::*)(int)) & Viewer::setSolverIterations)
           .def("eachContact",
                (void(Viewer::*)(const luabind::object &)) &
                    Viewer::eachContact)
           .def("addConstraint",
                (void(Viewer::*)(btTypedConstraint *)) & Viewer::addConstraint,
                adopt(_2))
           .def("removeConstraint",
                (btTypedConstraint * (Viewer::*)(btTypedConstraint *)) &
                    Viewer::removeConstraint,
                adopt(result))
           .def("createVehicleRaycaster", &Viewer::createVehicleRaycaster)
           .def("addVehicle",
                (void(Viewer::*)(btRaycastVehicle *)) & Viewer::addVehicle,
                adopt(_2))
           .def("addShortcut", &Viewer::addShortcut)
           .def("removeShortcut", &Viewer::removeShortcut)
           .def("preStart",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBPreStart,
                adopt(luabind::result))
           .def("preDraw",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBPreDraw,
                adopt(luabind::result))
           .def("postDraw",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBPostDraw,
                adopt(luabind::result))
           .def("preSim",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBPreSim,
                adopt(luabind::result))
           .def("postSim",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBPostSim,
                adopt(luabind::result))
           .def("preStop",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBPreStop,
                adopt(luabind::result))
           .def("onCommand",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBOnCommand,
                adopt(luabind::result))
            .def("onJoystick",
                 (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBOnJoystick,
                 adopt(luabind::result))
            .def("onKey",
                 (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBOnKey,
                 adopt(luabind::result))
            .def("onSpaceNavigator",
                 (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBOnSpaceNavigator,
                 adopt(luabind::result))
            .def("cycleObject",
                 (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBCycleObject,
                 adopt(luabind::result))
           .def("onParamChanged",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBOnParamChanged,
                 adopt(luabind::result))
           .def("onHover",
                (void(Viewer::*)(const luabind::object &fn)) &
                    Viewer::setCBOnHover,
                 adopt(luabind::result))
            .def("addParam", (void(Viewer::*)(const QString &, const QVariant &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const QVariant &, const QString &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const btScalar &, const btScalar &, const btScalar &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const btScalar &, const btScalar &, const btScalar &, const btScalar &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const btScalar &, const btScalar &, const btScalar &, const btScalar &, const QString &)) & Viewer::addParam)
            .def("getParam", &Viewer::getParam)
            .def("getParams", &Viewer::getParams)
            .def("getTime", &Viewer::getTime)
            .def("stepSimulation", &Viewer::stepSimulation)
            .def("savePrefs", &Viewer::setPrefs)
           .def("loadPrefs", &Viewer::getPrefs)
           .def("clearDebugText", &Viewer::clearDebugText)
           .def("setHelpText", &Viewer::setHelpText)

           .def("quickRender",
                (void(Viewer::*)(QString povargs)) & Viewer::onQuickRender)

           .property("cam", &Viewer::getCamera, &Viewer::setCamera)

           .property("gravity", &Viewer::getGravity, &Viewer::setGravity)

           .property("animationPeriod", &Viewer::getAnimationPeriod,
                     &Viewer::setAnimationPeriodMs)

           .property("onePerFrame", &Viewer::getOnePerFrame,
                     &Viewer::setOnePerFrame)

           // SpaceNavigator 3D mouse navigation settings
           .property("snMode", &Viewer::spaceNavigatorMode,
                     &Viewer::setSpaceNavigatorMode)
           .property("snLockHorizon", &Viewer::spaceNavigatorLockHorizon,
                     &Viewer::setSpaceNavigatorLockHorizon)
           .property("snAutoFlySpeed", &Viewer::spaceNavigatorAutoFlySpeed,
                     &Viewer::setSpaceNavigatorAutoFlySpeed)
           .property("snShowOrbitAxis", &Viewer::spaceNavigatorShowOrbitAxis,
                     &Viewer::setSpaceNavigatorShowOrbitAxis)
           .property("snZoomForward", &Viewer::spaceNavigatorZoomForward,
                     &Viewer::setSpaceNavigatorZoomDirection)
           .property("snPanZoom", &Viewer::spaceNavigatorPanZoom,
                     &Viewer::setSpaceNavigatorPanZoom)

           .property("showConstraints", &Viewer::showConstraints,
                     &Viewer::setShowConstraints)

           .property("shadows", &Viewer::shadows, &Viewer::setShadows)
           .property("culling", &Viewer::culling, &Viewer::setCulling)
           .property("drawnObjects", &Viewer::drawnObjects)
           .property("shadowCasters", &Viewer::shadowCasters)
           .property("shadowCache", &Viewer::shadowCache, &Viewer::setShadowCache)
           .property("shadowCached", &Viewer::shadowCached)
           .property("screenMerge", &Viewer::screenMerge, &Viewer::setScreenMerge)
           .property("screenMerged", &Viewer::screenMerged)
           .property("shadowSaved", &Viewer::shadowSaved, &Viewer::setShadowSaved)
           .property("shadowFromSaved", &Viewer::shadowFromSaved)
           .property("drawTiming", &Viewer::drawTiming, &Viewer::setDrawTiming)
           .def("drawTimingReport", &Viewer::drawTimingReport)
           .property("shadowMapSize", &Viewer::shadowMapSize,
                     &Viewer::setShadowMapSize)
           .property("shadowSoftness", &Viewer::shadowSoftness,
                     &Viewer::setShadowSoftness)
           .property("shadowDarkness", &Viewer::shadowDarkness,
                     &Viewer::setShadowDarkness)

           // http://bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
           .property("timeStep", &Viewer::getTimeStep, &Viewer::setTimeStep)
           .property("maxSubSteps", &Viewer::getMaxSubSteps,
                     &Viewer::setMaxSubSteps)
           .property("fixedTimeStep", &Viewer::getFixedTimeStep,
                     &Viewer::setFixedTimeStep)

           // Short sound-effect playback (ticks, tocks, bells, ...).
           // loadSound() is safe to call even with no audio device
           // present -- returns -1, and playSound() on -1 is a no-op.
           .def("loadSound", &Viewer::loadSound)
           .def("playSound", (void(Viewer::*)(int)) & Viewer::playSound)
           .def("playSound", (void(Viewer::*)(int, double)) & Viewer::playSound)

           // Where a late frame's time went (0 = off), see setFrameTiming().
           .def("setFrameTiming", &Viewer::setFrameTiming)
           .property("frameTiming", &Viewer::getFrameTiming,
                     &Viewer::setFrameTiming)

           .property("glShininess", &Viewer::getGLShininess,
                     &Viewer::setGLShininess)
           .property("glSpecularColor", &Viewer::getGLSpecularColor,
                     &Viewer::setGLSpecularColor)
           .property("glSpecularColor", &Viewer::getGLSpecularCol,
                     &Viewer::setGLSpecularCol)
           .property("glLight0", &Viewer::getGLLight0, &Viewer::setGLLight0)
           .property("glLight1", &Viewer::getGLLight1, &Viewer::setGLLight1)

           .property("glAmbient", &Viewer::getGLAmbient, &Viewer::setGLAmbient)
           .property("glDiffuse", &Viewer::getGLDiffuse, &Viewer::setGLDiffuse)
           .property("glSpecular", &Viewer::getGLSpecular,
                     &Viewer::setGLSpecular)
           .property("glModelAmbient", &Viewer::getGLModelAmbient,
                     &Viewer::setGLModelAmbient)

           .property("glAmbient", &Viewer::getGLAmbientPercent,
                     &Viewer::setGLAmbientPercent)
           .property("glDiffuse", &Viewer::getGLDiffusePercent,
                     &Viewer::setGLDiffusePercent)
           .property("glSpecular", &Viewer::getGLSpecularPercent,
                     &Viewer::setGLSpecularPercent)
           .property("glModelAmbient", &Viewer::getGLModelAmbientPercent,
                     &Viewer::setGLModelAmbientPercent)

           .property("pre_sdl", &Viewer::getPreSDL, &Viewer::setPreSDL)
           .property("post_sdl", &Viewer::getPostSDL, &Viewer::setPostSDL)

           .property("pov_settings", &Viewer::getPOVSettingsInc,
                     &Viewer::setPOVSettingsInc)

           .def(tostring(const_self))
           .def(const_self == const_self)];

  // QT helper classes

  module(s)[class_<QColor>("QColor")
                .def(constructor<>(), adopt(result))
                .def(constructor<QString>(), adopt(result))
                .def(constructor<int, int, int>(), adopt(result))
                .def(constructor<int, int, int, int>(), adopt(result))
                .property("r", &QColor::red, &QColor::setRed)
                .property("g", &QColor::green, &QColor::setGreen)
                .property("b", &QColor::blue, &QColor::setBlue)
                .def(tostring(self))
                .def(self == self)];

// QString is handled by the default_converter<QString> in lua_converters.h
  // which converts Lua strings to QString automatically.
  // Registering class_<QString> here would shadow that converter and
  // break overload resolution for any function taking a QString argument.

  module(
      s)[class_<JoystickInfo>("JoystickInfo")
             .def(constructor<>())
             .property("axes", &JoystickInfo::getAxisValues)
             .property("axis0", &JoystickInfo::getAxis0)
             .property("axis1", &JoystickInfo::getAxis1)
             .property("axis2", &JoystickInfo::getAxis2)
             .property("axis3", &JoystickInfo::getAxis3)
             .property("buttons", &JoystickInfo::getButtonValues)
             .property("button0", &JoystickInfo::getButton0)
             .property("button1", &JoystickInfo::getButton1)
             .property("button2", &JoystickInfo::getButton2)
             .property("button3", &JoystickInfo::getButton3)
             .property("triggeredButton0", &JoystickInfo::getTriggeredButton0)
             .property("triggeredButton1", &JoystickInfo::getTriggeredButton1)
             .property("triggeredButton2", &JoystickInfo::getTriggeredButton2)
             .property("triggeredButton3", &JoystickInfo::getTriggeredButton3)
             .def(tostring(self))
             .def(self == self)];

  module(s)[class_<SpaceNavigator::Axes>("SpaceNavigatorAxes")
                .def(constructor<>())
                .def_readwrite("x", &SpaceNavigator::Axes::x)
                .def_readwrite("y", &SpaceNavigator::Axes::y)
                .def_readwrite("z", &SpaceNavigator::Axes::z)
                .def_readwrite("rx", &SpaceNavigator::Axes::rx)
                .def_readwrite("ry", &SpaceNavigator::Axes::ry)
                .def_readwrite("rz", &SpaceNavigator::Axes::rz)
                .def(tostring(self))
                .def(self == self)];
}

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

  // A constraint joining its body comes out of the world with it (Bullet
  // can't step a constraint whose body has left the world). It stays the
  // script's to remove, and goes back in when the object is added back.
  // So do bodies it had before (one a constraint kept in the world).
  QList<btRigidBody *> bodies;
  if (o->body != nullptr)
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
  if (o->merged) {                       // (its batch is made again without it)
    unmerge(o);
    _mergeObjs.removeOne(o);
    _mergeReady = false;
  }
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
namespace {
class RestSkippingDispatcher : public btCollisionDispatcher {
public:
  explicit RestSkippingDispatcher(btCollisionConfiguration *cfg) : btCollisionDispatcher(cfg) {}
  void dispatchAllCollisionPairs(btOverlappingPairCache *pairCache, const btDispatcherInfo &info,
                                 btDispatcher *dispatcher) override {
    if (info.m_deterministicOverlappingPairs || getNearCallback() != defaultNearCallback) {
      btCollisionDispatcher::dispatchAllCollisionPairs(pairCache, info, dispatcher);
      return;
    }
    btBroadphasePairArray &pairs = pairCache->getOverlappingPairArray();
    for (int i = 0; i < pairs.size(); ++i) {
      btBroadphasePair &pair = pairs[i];
      const btCollisionObject *a = static_cast<btCollisionObject *>(pair.m_pProxy0->m_clientObject);
      const btCollisionObject *b = static_cast<btCollisionObject *>(pair.m_pProxy1->m_clientObject);
      if (!a->isActive() && !b->isActive())
        continue;                       // (needsCollision()'s first test)
      defaultNearCallback(pair, *this, info);
    }
  }
};
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

void Viewer::addConstraint(btTypedConstraint *con) {
  if (!con)
    return;
  dynamicsWorld->addConstraint(con, true);
  _constraints->insert(con);
}

btTypedConstraint *Viewer::removeConstraint(btTypedConstraint *con) {
  dynamicsWorld->removeConstraint(con);
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
// SpaceNavigator input dead band (fraction of full deflection): deflections
// within this range of centre are treated as rest, so sensor noise and the
// cap's spring-back cannot drift the camera.  This plays the role of Blender's
// NDOF dead zone (GHOST_NDOFManager::setDeadZone), which is applied per axis
// with the same threshold.
const double kSnInputDeadBand = 0.06;
// Low-pass alpha for the shaped target velocity in onSpaceNavigatorNorm and
// for easing resting axes to zero on the sustaining path.  The device reports
// at ~125 Hz, so a modest alpha gives a gradual velocity transition (smoother
// motion) while still tracking a new deflection within a few report intervals.
const double kSnLowPassAlpha = 0.4;
// Blender's translation/rotation sensitivities (wm_event_system.c
// attach_ndof_data): the GHOST layer normalises the raw device axes to +/-1
// and the WM scales them again by these factors (4.0 by default).  Tuned down
// to 2.0 so the same deflection drives the camera at half Blender's speed.
const double kSnSensitivity = 2.0;
// Target-velocity dead band used by the integrator.  The response is cubic
// and scaled by Blender's sensitivity kSnSensitivity, so any deflection above
// the input dead band produces a target velocity of at least
// kSnInputDeadBand^3 * kSnSensitivity; zeroing below that threshold stops the
// camera cleanly once the cap returns to rest without widening the physical
// dead zone.
const double kSnTargetDeadBand =
    kSnInputDeadBand * kSnInputDeadBand * kSnInputDeadBand * kSnSensitivity;
// Blender pans at NDOF_PIXELS_PER_SECOND screen pixels per second
// (view3d_navigate_view_ndof.c): the pan speed is pixsize * NDOF_PIXELS_PER_SECOND
// where pixsize is the world-space size of one screen pixel at the orbit depth.
const double kSnPixelsPerSecond = 600.0;

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

    if (o->body != nullptr) {
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

namespace {
// Name a key for the onKey() hook: its Qt key sequence text, except that the
// two Shift keys are told apart (pinball flippers are traditionally on the
// left and right Shift). Qt reports both as Key_Shift, so the side comes from
// the platform's native code.
QString luaKeyName(const QKeyEvent *e) {
  if (e->key() == Qt::Key_Shift) {
#if defined(Q_OS_MAC)
    const bool right = e->nativeVirtualKey() == 60; // kVK_RightShift
#elif defined(Q_OS_WIN)
    const bool right = e->nativeScanCode() == 54;
#else
    const bool right = e->nativeScanCode() == 62; // X11 / evdev keycode
#endif
    return right ? QStringLiteral("RShift") : QStringLiteral("LShift");
  }
  return QKeySequence(e->key()).toString(QKeySequence::PortableText);
}
} // namespace

void Viewer::keyReleaseEvent(QKeyEvent *e) {
  if (!e->isAutoRepeat() && _cb_onKey) {
    _luaHeldKeys.remove(e->key());
    try {
      luabind::call_function<void>(_cb_onKey, _frameNum, luaKeyName(e), false);
    } catch (const std::exception &ex) {
      showLuaException(ex, "onKey()");
    }
  }
  QGLViewer::keyReleaseEvent(e);
}

void Viewer::keyPressEvent(QKeyEvent *e) {
  _hoverStill.restart();             // (hover: a key hides the tooltip)
  hoverHide();
  if (_cb_onKey) {
    if (e->isAutoRepeat()) {
      if (_luaHeldKeys.contains(e->key()))
        return;
    } else {
      bool consumed = false;
      try {
        luabind::object r = luabind::call_function<luabind::object>(
            _cb_onKey, _frameNum, luaKeyName(e), true);
        consumed = r && luabind::type(r) == LUA_TBOOLEAN &&
                   luabind::object_cast<bool>(r);
      } catch (const std::exception &ex) {
        showLuaException(ex, "onKey()");
      }
      if (consumed) {
        _luaHeldKeys.insert(e->key());
        return;
      }
    }
  }

  int keyInt = e->key();
  Qt::Key key = static_cast<Qt::Key>(keyInt);

  if (key == Qt::Key_unknown) {
    qDebug() << "Unknown key from a macro probably";
    return;
  }

  // the user have clicked just and only the special keys Ctrl, Shift, Alt,
  // Meta.
  if (key == Qt::Key_Control || key == Qt::Key_Shift || key == Qt::Key_Alt ||
      key == Qt::Key_Meta) {
    // qDebug() << "Single click of special key: Ctrl, Shift, Alt or Meta";
    // qDebug() << "New KeySequence:" <<
    // QKeySequence(keyInt).toString(QKeySequence::NativeText); return;
  }

  // check for a combination of user clicks
  Qt::KeyboardModifiers modifiers = e->modifiers();
  QString keyText = e->text();
  // if the keyText is empty than it's a special key like F1, F5, ...
  //  qDebug() << "Pressed Key:" << keyText;

  QList<Qt::Key> modifiersList;
  if (modifiers & Qt::ShiftModifier)
    keyInt += Qt::SHIFT;
  if (modifiers & Qt::ControlModifier)
    keyInt += Qt::CTRL;
  if (modifiers & Qt::AltModifier)
    keyInt += Qt::ALT;
  if (modifiers & Qt::MetaModifier)
    keyInt += Qt::META;

  QString seq = QKeySequence(keyInt).toString(QKeySequence::NativeText);
  // qDebug() << "KeySequence:" << seq;

  if (_cb_shortcuts->contains(seq)) {
    try {
      luabind::call_function<void>(*_cb_shortcuts->value(seq), _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "onShortcut()");
    }

    return; // skip built in command if overridden by shortcut
  }

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
    _quadView = !_quadView;
    if (_quadView && !_orthoCamerasFitted) {
      // Auto-frame the ortho cameras only the first time quad view is
      // shown, so later toggles remember any pan/zoom the user applied.
      updateOrthoCameras();
      _orthoCamerasFitted = true;
    }
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
  _hoverArmed = false;               // (hover: a click hides the tooltip)
  hoverHide();
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

  qglviewer::Camera *cam = orthoCameraAt(e->pos());
  if (cam) {
    _orthoPanCamera = cam;
    _orthoPanLastPos = e->pos();
    e->accept();
    return;
  }
  QGLViewer::mousePressEvent(e);
}

void Viewer::mouseMoveEvent(QMouseEvent *e) {
  // hover: only watch movement with no button down; never consume the event
  if (e->buttons() == Qt::NoButton) {
    if (!_hoverArmed || (e->pos() - _hoverPos).manhattanLength() > 3) {
      _hoverPos = e->pos();
      _hoverStill.restart();
      _hoverObj = nullptr;           // (moved: forget the sticky object)
      hoverHide();
    }
    _hoverArmed = true;
  } else {
    _hoverArmed = false;
    hoverHide();
  }
  if (_orthoPanCamera) {
    const QPoint delta = e->pos() - _orthoPanLastPos;
    _orthoPanLastPos = e->pos();

    if (!delta.isNull()) {
      // Convert screen-pixel movement to world units at the pane's current
      // zoom level (screenHeight() is this camera's pane height, set each
      // time drawQuadView() renders it).
      GLdouble halfWidth, halfHeight;
      _orthoPanCamera->getOrthoWidthHeight(halfWidth, halfHeight);
      const int paneHeight = _orthoPanCamera->screenHeight();
      const qreal unitsPerPixel =
          (paneHeight > 0) ? (2.0 * halfHeight / paneHeight) : 0.0;

      const qglviewer::Vec translation =
          -_orthoPanCamera->rightVector() * (delta.x() * unitsPerPixel) +
          _orthoPanCamera->upVector() * (delta.y() * unitsPerPixel);

      _orthoPanCamera->setPosition(_orthoPanCamera->position() + translation);
      _orthoPanCamera->setPivotPoint(_orthoPanCamera->pivotPoint() +
                                     translation);
      update();
    }
    e->accept();
    return;
  }
  QGLViewer::mouseMoveEvent(e);
}

void Viewer::mouseReleaseEvent(QMouseEvent *e) {
  if (_orthoPanCamera) {
    _orthoPanCamera = nullptr;
    e->accept();
    return;
  }
  QGLViewer::mouseReleaseEvent(e);
}

void Viewer::wheelEvent(QWheelEvent *e) {
  _hoverStill.restart();             // (hover: hide while zooming)
  hoverHide();
  qglviewer::Camera *cam = orthoCameraAt(e->position().toPoint());
  if (cam) {
    // One wheel "click" is 120 (QWheelEvent::angleDelta() units); each
    // click zooms by 10%, scrolling the camera towards/away from its
    // pivot along its own view direction.
    const qreal notches = e->angleDelta().y() / 120.0;
    const qreal factor = pow(0.9, notches);
    const qglviewer::Vec pivot = cam->pivotPoint();
    cam->setPosition(pivot + (cam->position() - pivot) * factor);
    e->accept();
    update();
    return;
  }
  QGLViewer::wheelEvent(e);
}

void Viewer::addObject(Object *o, int type, int mask) {
  _objects->insert(o);
  o->setWorld(dynamicsWorld);
  if (_removed.remove(o) && L != nullptr)
    setRemovedEntry(L, o, nullptr);   // (bpp's again, held by the scene)

  if (o->body != nullptr) {
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
  if (o->body != nullptr && !_detached.isEmpty()) {
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

void Viewer::recordSound(Mix_Chunk *chunk, double volume) {
  if (!_savePOV)
    return;
  // Once this frame is exported, the next one is the first to show what the
  // sound is about.
  int frame = (_wavFrame == _frameNum) ? _frameNum + 1 : _frameNum;
  _wavEvents.push_back({frame, chunk, volume});
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

  _file = nullptr;
  _fileMain = nullptr;
  _fileINI = nullptr;
  _fileMakefile = nullptr;
  _stream = nullptr;

  _savePOV = savePOV;
  _povExportFailed = false;

  setSnapshotFormat("png");

  _simulate = false;
  _deactivation = true;

  _quadView = false;
  _orthoCamerasFitted = false;

  _camTop = new qglviewer::Camera();
  _camTop->setType(qglviewer::Camera::ORTHOGRAPHIC);
  _camTop->setViewDirection(qglviewer::Vec(0, -1, 0));
  _camTop->setUpVector(qglviewer::Vec(0, 0, -1));

  _camFront = new qglviewer::Camera();
  _camFront->setType(qglviewer::Camera::ORTHOGRAPHIC);
  _camFront->setViewDirection(qglviewer::Vec(0, 0, -1));
  _camFront->setUpVector(qglviewer::Vec(0, 1, 0));

  _camRight = new qglviewer::Camera();
  _camRight->setType(qglviewer::Camera::ORTHOGRAPHIC);
  _camRight->setViewDirection(qglviewer::Vec(-1, 0, 0));
  _camRight->setUpVector(qglviewer::Vec(0, 1, 0));

  _orthoPanCamera = nullptr;

  _timeStep = 1 / 25.0;
  _maxSubSteps = 7;
  _snOrbitDist = 0.0;
  _snMode = SN_MODE_FLY;
  _snLockHorizon = true;
  _snAutoFlySpeed = true;
  _snShowOrbitAxis = false;
  _snZoomForward = true;
  _snPanZoom = true;
  if (_settings != nullptr) {
    _snMode = (_settings->value("spacenavigator/navigationMode", 0).toInt() == 1)
                  ? SN_MODE_OBJECT
                  : SN_MODE_FLY;
    _snLockHorizon =
        _settings->value("spacenavigator/lockHorizon", _snLockHorizon).toBool();
    _snAutoFlySpeed =
        _settings->value("spacenavigator/autoFlySpeed", _snAutoFlySpeed).toBool();
    _snShowOrbitAxis =
        _settings->value("spacenavigator/showOrbitAxis", _snShowOrbitAxis).toBool();
    _snZoomForward =
        (_settings->value("spacenavigator/zoomDirection", 0).toInt() == 0);
    _snPanZoom = _settings->value("spacenavigator/panZoom", _snPanZoom).toBool();
  }
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
  dynamicsWorld = new btSoftRigidDynamicsWorld(dispatcher, broadphase,
                                               solver, collisionCfg);
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
  btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher_ptr);

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

  _cb_shortcuts = new QHash<QString, std::shared_ptr<luabind::object>>();

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
  _wavFirstFrame = 0;
  _wavFrame = 0;
  _wavWritten = -1;
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
  }


  // SpaceNavigator 3D mouse integration
  _spaceNavigator = new SpaceNavigator(this);
  connect(_spaceNavigator, &SpaceNavigator::axesChanged, this,
          &Viewer::onSpaceNavigatorAxes);
  connect(_spaceNavigator, &SpaceNavigator::axesNormChanged, this,
          &Viewer::onSpaceNavigatorNorm);
  connect(_spaceNavigator, &SpaceNavigator::buttonChanged, this,
          &Viewer::onSpaceNavigatorButton);

  // Sustaining timer for the built-in camera control: each device report is
  // integrated immediately in onSpaceNavigatorNorm (event-driven), and this
  // timer keeps integrating the last target while a deflection is held still,
  // since the absolute device only reports when the cap moves.  The interval
  // matches the ~125 Hz USB report rate and uses precise timing so sustained
  // motion stays smooth.  (The socket is fully drained per read, so no device
  // events accumulate here.)
  _snTimer = new QTimer(this);
  _snTimer->setInterval(8);
  _snTimer->setTimerType(Qt::PreciseTimer);
  connect(_snTimer, &QTimer::timeout, this, &Viewer::onSpaceNavigatorTick);

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
  QMutexLocker locker(&mutex);

  // A Lua onSpaceNavigator callback takes precedence over the built-in
  // camera control.  Clear the target so no residual deflection moves the
  // camera once the script takes over.
  if (_cb_onSpaceNavigator) {
    _snTarget = SpaceNavigator::AxesNorm();
    return;
  }

  // Apply the current target velocity over the time elapsed since the previous
  // device report, so every report moves the camera immediately (event-driven,
  // like Blender's NDOF) rather than waiting for the next timer tick.  On the
  // first report there is no previous interval to apply, so the integration
  // baseline is established below instead.
  if (_snTimer->isActive()) {
    integrateSpaceNavigator();
  }

  // Remember the raw deflection of this report so the sustaining path can tell
  // whether each axis is held or at rest once the device stops reporting.
  _snLastInput = axes;

  // Dead band (input side): deflections within kSnInputDeadBand of the
  // centre are ignored so a resting controller does not drift.  A cubic
  // response curve (fine control near the centre, fast travel at full
  // deflection) scaled by Blender's sensitivity (see kSnSensitivity) turns the
  // deflection into a target velocity which is integrated over the real
  // elapsed time, so the camera moves smoothly no matter how irregularly the
  // device reports arrive.
  auto shave = [](double v) {
    return std::fabs(v) < kSnInputDeadBand ? 0.0 : v;
  };
  auto curve = [](double v) {
    return v * v * v * kSnSensitivity;
  };

  const double targetX = curve(shave(axes.x));
  const double targetY = curve(shave(axes.y));
  const double targetZ = curve(shave(axes.z));
  const double targetRX = curve(shave(axes.rx));
  const double targetRY = curve(shave(axes.ry));
  const double targetRZ = curve(shave(axes.rz));

  // Low-pass filter the target velocity to smooth out device packet jitter
  // and the cap's spring-back.
  const double alpha = kSnLowPassAlpha;
  _snTarget.x = _snTarget.x * (1.0 - alpha) + targetX * alpha;
  _snTarget.y = _snTarget.y * (1.0 - alpha) + targetY * alpha;
  _snTarget.z = _snTarget.z * (1.0 - alpha) + targetZ * alpha;
  _snTarget.rx = _snTarget.rx * (1.0 - alpha) + targetRX * alpha;
  _snTarget.ry = _snTarget.ry * (1.0 - alpha) + targetRY * alpha;
  _snTarget.rz = _snTarget.rz * (1.0 - alpha) + targetRZ * alpha;

  if (!_snTimer->isActive() &&
      !(_snTarget.x == 0.0 && _snTarget.y == 0.0 && _snTarget.z == 0.0 &&
        _snTarget.rx == 0.0 && _snTarget.ry == 0.0 && _snTarget.rz == 0.0)) {
    // First movement: establish the integration baseline and arm the
    // sustaining timer, which keeps integrating the held target while the cap
    // is at rest (the absolute device only reports when it moves).
    _snTickTimer.start();
    _snTimer->start();
  }
}

void Viewer::integrateSpaceNavigator(bool sustained) {
  // Integrate the target velocity over the real elapsed time (clamped so a
  // delayed tick cannot cause a jump).  The elapsed interval is measured from
  // the previous device report or timer tick, and _snTickTimer is restarted
  // here, so the event-driven path (onSpaceNavigatorNorm) and the sustaining
  // timer (onSpaceNavigatorTick) integrate disjoint time intervals and no
  // motion is ever double-counted or skipped.  The caller must hold the mutex.
  const qint64 elapsedMs = _snTickTimer.restart();
  const qreal dt = qMin(qreal(elapsedMs) / 1000.0, qreal(0.1));

  if (camera() == nullptr || _cb_onSpaceNavigator) {
    return;
  }

  // Dead band (sustaining path): once the cap returns to rest the absolute
  // device stops reporting, so the low-pass decay in onSpaceNavigatorNorm is
  // cut short and the target would freeze above the target dead band, leaving
  // the camera to drift forever on this sustaining timer.  Continue easing any
  // resting axis toward zero here, using the last raw deflection as the
  // rest/held discriminator (the same kSnInputDeadBand as the input shave).
  // Axes held above the dead band keep their velocity for as long as the cap
  // is held, and the event-driven path applies no extra decay (its low-pass
  // already chases every report), so held motion stays immediate.
  if (sustained) {
    const double decay = 1.0 - kSnLowPassAlpha;
    auto easeToRest = [&](double &target, double lastInput) {
      if (std::fabs(lastInput) < kSnInputDeadBand) {
        target *= decay;
      }
    };
    easeToRest(_snTarget.x, _snLastInput.x);
    easeToRest(_snTarget.y, _snLastInput.y);
    easeToRest(_snTarget.z, _snLastInput.z);
    easeToRest(_snTarget.rx, _snLastInput.rx);
    easeToRest(_snTarget.ry, _snLastInput.ry);
    easeToRest(_snTarget.rz, _snLastInput.rz);
  }

  // Dead band (target side): zero any component of the target velocity that
  // has eased back below what the input dead band can still produce, so the
  // camera comes to a clean rest instead of creeping.  Larger deflections are
  // kept as-is: the SpaceNavigator is an absolute device that only reports a
  // new value when the cap moves, so a held deflection produces no events and
  // the camera must keep moving at the last commanded velocity rather than
  // decay to a stop.
  if (std::fabs(_snTarget.x) < kSnTargetDeadBand) _snTarget.x = 0.0;
  if (std::fabs(_snTarget.y) < kSnTargetDeadBand) _snTarget.y = 0.0;
  if (std::fabs(_snTarget.z) < kSnTargetDeadBand) _snTarget.z = 0.0;
  if (std::fabs(_snTarget.rx) < kSnTargetDeadBand) _snTarget.rx = 0.0;
  if (std::fabs(_snTarget.ry) < kSnTargetDeadBand) _snTarget.ry = 0.0;
  if (std::fabs(_snTarget.rz) < kSnTargetDeadBand) _snTarget.rz = 0.0;

  const double tx = _snTarget.x, ty = _snTarget.y, tz = _snTarget.z;
  const double rxp = _snTarget.rx, ryp = _snTarget.ry, rzp = _snTarget.rz;
  if (tx == 0.0 && ty == 0.0 && tz == 0.0 && rxp == 0.0 && ryp == 0.0 &&
      rzp == 0.0) {
    _snTimer->stop();
    return;
  }

  if (_snOrbitDist <= 0.0) {
    _snOrbitDist = (camera()->pivotPoint() - camera()->position()).norm();
  }
  if (_snOrbitDist <= 0.0) {
    _snOrbitDist = camera()->sceneRadius();
  }
  const qreal sceneRadius = camera()->sceneRadius() > 0.0
                                ? camera()->sceneRadius()
                                : 1.0;
  const qreal orbitDist =
      _snOrbitDist > 0.0 ? _snOrbitDist : sceneRadius;

  qglviewer::Vec right = camera()->rightVector();
  qglviewer::Vec up = camera()->upVector();
  qglviewer::Vec view = camera()->viewDirection();

  // Blender pan speed: pixsize * NDOF_PIXELS_PER_SECOND, i.e. the world-space
  // extent of one screen pixel at the given depth times 600 pixels per second
  // (view3d_navigate_view_ndof.c view3d_ndof_pan_speed_calc_ex).  Computed
  // from a projection so it holds for perspective and orthographic cameras.
  // The view vectors are refreshed after a rotation so the pan happens in the
  // post-rotation view frame, as in Blender.
  auto panSpeedAt = [&](qreal depth) -> qreal {
    const qglviewer::Vec p = camera()->projectedCoordinatesOf(
        camera()->position() + view * depth);
    const qglviewer::Vec q = camera()->projectedCoordinatesOf(
        camera()->position() + view * depth + right);
    const qreal pixelsPerUnit = (q - p).norm();
    if (pixelsPerUnit < 1.0e-9) {
      return 0.0;
    }
    return (1.0 / pixelsPerUnit) * kSnPixelsPerSecond;
  };

  // The Y-axis translate direction toggles the cap sense of the forward/back
  // movement (the same pref that used to set the zoom/dolly direction).
  const qreal zoomSign = _snZoomForward ? 1.0 : -1.0;

  // Locked-horizon helper: after yaw/pitch the camera is re-rolled so its
  // up vector stays in the plane spanned by the reference up and the view
  // direction, i.e. the horizon stays level.
  auto enforceLockedHorizon = [this]() {
    if (!_snLockHorizon) {
      return;
    }
    const qglviewer::Vec worldUp(_initialCameraUpVector);
    const qglviewer::Vec viewDir = camera()->viewDirection();
    qglviewer::Vec upNoRoll =
        worldUp - viewDir * (viewDir * worldUp);
    if (upNoRoll.norm() > 1.0e-6) {
      upNoRoll.normalize();
      camera()->setUpVector(upNoRoll, true);
    }
  };

  if (_snMode == SN_MODE_FLY) {
    // Fly mode: first-person navigation around the camera position.  The three
    // translation axes move the camera freely (X strafes right, Y translates
    // along the view direction, Z moves up/down).  Auto fly speed scales the
    // pan speed with the distance to the scene so navigation feels constant
    // whether you are close up or far away.
    const qreal depth = _snAutoFlySpeed ? orbitDist : sceneRadius;

    if (_snLockHorizon) {
      // Turntable rotation (yaw around the view up axis, pitch around the
      // right axis) with the device roll ignored; the horizon is then levelled
      // by enforceLockedHorizon, matching Blender's horizon-locked orbit.
      qglviewer::Quaternion rotation(
          qglviewer::Quaternion(qglviewer::Vec(0.0, 1.0, 0.0), rzp * dt) *
          qglviewer::Quaternion(camera()->rightVector(), rxp * dt));
      camera()->frame()->rotateAroundPoint(rotation, camera()->position());
    } else {
      // Free rotation: a single axis-angle rotation around the device rotation
      // vector mapped into view space (Blender view3d_ndof_orbit).  Fly-mode
      // rotation vector: +rxp pitch, +rzp yaw, -ryp roll.
      qglviewer::Vec axisLocal = right * rxp + up * rzp - view * ryp;
      const double angle = std::sqrt(rxp * rxp + rzp * rzp + ryp * ryp) * dt;
      if (angle > 1.0e-6) {
        axisLocal.normalize();
        camera()->frame()->rotateAroundPoint(
            qglviewer::Quaternion(axisLocal, angle), camera()->position());
      }
    }

    // Refresh the view vectors: Blender pans in the post-rotation view frame.
    right = camera()->rightVector();
    up = camera()->upVector();
    view = camera()->viewDirection();

    if (_snPanZoom) {
      const qreal panSpeed = panSpeedAt(depth);
      camera()->frame()->translate((right * (tx * panSpeed) +
                                    view * (ty * zoomSign * panSpeed) +
                                    up * (tz * panSpeed)) *
                                   dt);
    }
    enforceLockedHorizon();
  } else {
    // Object mode: NDOF orbit around the view-centre pivot point.  The three
    // translation axes move the camera freely (X strafes right, Y translates
    // along the view direction, Z moves up/down); rotation happens around the
    // orbit centre, which follows the camera at _snOrbitDist.
    const qglviewer::Vec pivot = camera()->position() + view * orbitDist;

    if (_snLockHorizon) {
      // Turntable rotation around the pivot (yaw around the view up axis,
      // pitch around the right axis); roll is ignored and the horizon is then
      // levelled by enforceLockedHorizon.
      qglviewer::Quaternion rotation(
          qglviewer::Quaternion(qglviewer::Vec(0.0, 1.0, 0.0), -rzp * dt) *
          qglviewer::Quaternion(camera()->rightVector(), -rxp * dt));
      camera()->frame()->rotateAroundPoint(rotation, pivot);
    } else {
      // Free rotation around the pivot.  Object-mode rotation vector:
      // -rxp pitch, -rzp yaw, +ryp roll (the Object mode inverts the
      // navigation axes, as in Blender's WM_event_ndof_rotation_get_for_navigation).
      qglviewer::Vec axisLocal = right * (-rxp) + up * (-rzp) + view * ryp;
      const double angle = std::sqrt(rxp * rxp + rzp * rzp + ryp * ryp) * dt;
      if (angle > 1.0e-6) {
        axisLocal.normalize();
        camera()->frame()->rotateAroundPoint(
            qglviewer::Quaternion(axisLocal, angle), pivot);
      }
    }

    // Refresh the view vectors: Blender pans in the post-rotation view frame.
    right = camera()->rightVector();
    up = camera()->upVector();
    view = camera()->viewDirection();

    if (_snPanZoom) {
      // Pure translation on all three axes, computed from the projection at
      // the orbit depth so the apparent screen-space speed stays constant.
      // The Y component moves along the view direction (the same sense as the
      // Fly-mode dolly), Z moves up/down.
      const qreal panSpeed = panSpeedAt(orbitDist);
      camera()->frame()->translate((right * (tx * panSpeed) +
                                    view * (ty * zoomSign * panSpeed) +
                                    up * (tz * panSpeed)) *
                                   dt);
    }
    enforceLockedHorizon();
  }

  updateGLViewer();
}

void Viewer::onSpaceNavigatorTick() {
  QMutexLocker locker(&mutex);
  // Sustaining timer: the SpaceNavigator is an absolute device that only
  // reports a new value when the cap moves, so while a deflection is held
  // still no reports arrive.  The timer keeps integrating the last target
  // velocity at a fixed rate for as long as the cap is held, and eases the
  // target back to rest once the last report was within the input dead band
  // (see integrateSpaceNavigator).  Motion stops cleanly when the eased target
  // falls back into the dead band and the timer is stopped there.
  integrateSpaceNavigator(true);
}

void Viewer::onSpaceNavigatorButton(int button, bool pressed) {
  QMutexLocker locker(&mutex);
  if (pressed) {
    if (button == 0) {
      resetCamView();
    } else if (button == 1 || button == 2) {
      if (_snMode == SN_MODE_OBJECT) {
        _snMode = SN_MODE_FLY;
        emit statusEvent(QString("SpaceNavigator mode: Fly"));
      } else {
        _snMode = SN_MODE_OBJECT;
        emit statusEvent(QString("SpaceNavigator mode: Object"));
      }
    }
  }
}

void Viewer::setSpaceNavigatorMode(int mode) {
  QMutexLocker locker(&mutex);
  _snMode = (mode == 1) ? SN_MODE_OBJECT : SN_MODE_FLY;
}

int Viewer::spaceNavigatorMode() const {
  return (_snMode == SN_MODE_OBJECT) ? 1 : 0;
}

void Viewer::setSpaceNavigatorLockHorizon(bool on) {
  QMutexLocker locker(&mutex);
  _snLockHorizon = on;
}

bool Viewer::spaceNavigatorLockHorizon() const { return _snLockHorizon; }

void Viewer::setSpaceNavigatorAutoFlySpeed(bool on) {
  QMutexLocker locker(&mutex);
  _snAutoFlySpeed = on;
}

bool Viewer::spaceNavigatorAutoFlySpeed() const { return _snAutoFlySpeed; }

void Viewer::setSpaceNavigatorShowOrbitAxis(bool on) {
  QMutexLocker locker(&mutex);
  _snShowOrbitAxis = on;
  updateGLViewer();
}

bool Viewer::spaceNavigatorShowOrbitAxis() const { return _snShowOrbitAxis; }

void Viewer::setSpaceNavigatorZoomDirection(bool forward) {
  QMutexLocker locker(&mutex);
  _snZoomForward = forward;
}

bool Viewer::spaceNavigatorZoomForward() const { return _snZoomForward; }

void Viewer::setSpaceNavigatorPanZoom(bool on) {
  QMutexLocker locker(&mutex);
  _snPanZoom = on;
}

bool Viewer::spaceNavigatorPanZoom() const { return _snPanZoom; }

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
void Viewer::setShadows(bool on) { _shadows = on; }

bool Viewer::shadows() const { return _shadows; }

void Viewer::setCulling(bool on) { _culling = on; }

bool Viewer::culling() const { return _culling; }

int Viewer::drawnObjects() const { return _drawnObjects; }

int Viewer::shadowCasters() const { return _shadowCasters; }

void Viewer::setShadowCache(bool on) { _shadowCache = on; }

bool Viewer::shadowCache() const { return _shadowCache; }

int Viewer::shadowCached() const { return _shadowCached; }


void Viewer::setShadowSaved(bool on) { _shadowSaved = on; }

bool Viewer::shadowSaved() const { return _shadowSaved; }

bool Viewer::shadowFromSaved() const { return _shadowFromSaved; }

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
    if (_mergesMade > 0)
      r += QString(" (merge made %1 times)").arg(_mergesMade);
    if (_dtGpuFrames > 0)
      r += QString("; graphics card: shadow map %1, screen %2")
               .arg(_dtShadowGpu / _dtGpuFrames, 0, 'f', 2)
               .arg(_dtScreenGpu / _dtGpuFrames, 0, 'f', 2);
    else if (_dtNoGpu)
      r += "; graphics card: no timers";
  }
  _dtCull = _dtShadow = _dtScreen = _dtDraw = _dtBox = 0;
  _mergesMade = 0;
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

  QHash<QString, QVariant> savedParams = _params;

  parse(_scriptContent);

  camera()->setPosition(camPos);
  camera()->setOrientation(camOri);
  camera()->setHorizontalFieldOfView(camHfov);
  camera()->setUpVector(camUp, true);

  for (auto it = savedParams.constBegin(); it != savedParams.constEnd(); ++it) {
    if (!_params.contains(it.key())) continue;
    ParamInfo info = _paramInfo.value(it.key());
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
    _cb_onKey = luabind::object();
    _luaHeldKeys.clear();
    _cb_onParamChanged = luabind::object();
    _cb_onSpaceNavigator = luabind::object();
    _cb_onHover = luabind::object();
    hoverHide();

    if (_cb_shortcuts) {
      for (auto it = _cb_shortcuts->begin(); it != _cb_shortcuts->end(); ++it) {
        it->reset();
      }
      _cb_shortcuts->clear();
    }

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
        if (o->body != nullptr) {
          dynamicsWorld->removeRigidBody(o->body);
        }
        SoftBody *sb = dynamic_cast<SoftBody *>(o);
        if (sb != nullptr && sb->getSoftBody() != nullptr) {
          dynamicsWorld->removeSoftBody(sb->getSoftBody());
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
    luaL_dostring(L, "printf = function(s,...) print(s:format(...)) end");

    // Build Lua package.path: search script directory first (if console mode), then CWD/demo, then installed
    QString defaultPath = getDefaultLuaPath(_scriptBasePath);
    QString path = _settings->value("lua/path", defaultPath).toString();
    QString p = QString("package.path = package.path..\";%1\"").arg(path);

    int error =
        luaL_loadstring(L, qPrintable(p)) || lua_pcall(L, 0, LUA_MULTRET, 0);

    if (error) {
      lua_error = tr("error: %1").arg(lua_tostring(L, -1));

      if (lua_error.contains(QRegExp(tr("stopping$")))) {
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

    if (lua_error.contains(QRegExp(tr("stopping$")))) {
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
  btCollisionObjectArray &all = dynamicsWorld->getCollisionObjectArray();
  for (int i = all.size() - 1; i >= 0; --i) {
    btCollisionObject *co = all[i];
    if (btSoftBody *sb = btSoftBody::upcast(co))
      dynamicsWorld->removeSoftBody(sb);
    else if (btRigidBody *rb = btRigidBody::upcast(co))
      dynamicsWorld->removeRigidBody(rb);
    else
      dynamicsWorld->removeCollisionObject(co);
  }
}

void Viewer::clear() {
  // qDebug() << "Viewer::clear() objects: " << _objects->size();

  freeMerge();                           // (before the objects go)

  _params.clear();
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
      if (o->body != nullptr) {
        dynamicsWorld->removeRigidBody(o->body);
      }
      SoftBody *sb = dynamic_cast<SoftBody *>(o);
      if (sb != nullptr && sb->getSoftBody() != nullptr) {
        dynamicsWorld->removeSoftBody(sb->getSoftBody());
      }
    }
  }

  // Remove constraints from the dynamics world before deleting them.
  if (dynamicsWorld) {
    foreach (btTypedConstraint* c, *_constraints) {
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
  dynamicsWorld = new btSoftRigidDynamicsWorld(dispatcher, broadphase,
                                               solver, collisionCfg);
  dynamicsWorld->setDebugDrawer(_debugDrawer);
  dynamicsWorld->setGravity(btVector3(0.0f, -G, 0.0f));
  dynamicsWorld->getWorldInfo().m_broadphase = broadphase;
  dynamicsWorld->getWorldInfo().m_dispatcher = dispatcher;
  dynamicsWorld->getWorldInfo().m_gravity = dynamicsWorld->getGravity();
  dynamicsWorld->getWorldInfo().m_sparsesdf.Initialize();
  SoftBody::setWorldInfo(&dynamicsWorld->getWorldInfo());

  btCollisionDispatcher *dispatcher_ptr = dispatcher;
  btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher_ptr);

  _pov_settings_inc = "settings.inc";

  setPreSDL(QString());
  setPostSDL(QString());

  if (_cam != nullptr) {
    _cam->setPreSDL(QString());
    _cam->setPostSDL(QString());
    _cam->setUseFocalBlur(0);
    _cam->setUpVector(btVector3(0, 1, 0), true);
  }

  // Matches the POV-Ray light_source <500,500,-500> in includes/settings.inc.
  // POV-Ray is left-handed, OpenGL is right-handed, so Z is negated (see
  // Object::povMatrixFromGL()).
  _light0 = btVector4(500.0, 500.0, 500.0, 0.4);
  _light1 = btVector4(-200.0, 100.0, 200.0, 0.2);

  // (a script's culling and shadow-record settings go with it, as the
  // lights do)
  _culling = true;
  _shadowCache = true;
  _screenMerge = true;
  _shadowSaved = true;
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
  _snOrbitDist = 0.0;

  if (_quadView) {
    updateOrthoCameras();
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
  if (_audioAvailable) {
    for (auto &kv : _soundChunks) {
      Mix_FreeChunk(kv.second);
    }
    _soundChunks.clear();
    _soundIdByPath.clear();
    Mix_CloseAudio();
    SDL_QuitSubSystem(SDL_INIT_AUDIO);
  }

  // Stop the joystick handler before deleting anything
  _joystickHandler.stop();

  // Stop the SpaceNavigator integration timer, then close the device and
  // drop Lua references before Lua teardown
  if (_snTimer) {
    _snTimer->stop();
  }
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
  _cb_onKey = luabind::object();
  _luaHeldKeys.clear();
  _cb_onSpaceNavigator = luabind::object();
  _cb_onParamChanged = luabind::object();
  _cb_onHover = luabind::object();
  hoverHide();

  // Clear shortcuts BEFORE closing Lua state.
  // The shared_ptr<luabind::object> destructors call luaL_unref.
  if (_cb_shortcuts) {
    _cb_shortcuts->clear();
    delete _cb_shortcuts;
    _cb_shortcuts = nullptr;
  }

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
      if (o->body != nullptr) {
        dynamicsWorld->removeRigidBody(o->body);
      }
      SoftBody *sb = dynamic_cast<SoftBody *>(o);
      if (sb != nullptr && sb->getSoftBody() != nullptr) {
        dynamicsWorld->removeSoftBody(sb->getSoftBody());
      }
    }
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
  if (broadphase) {
    delete broadphase;
    broadphase = nullptr;
  }
  if (collisionCfg) {
    delete collisionCfg;
    collisionCfg = nullptr;
  }

  // Close and delete POV export files
  if (_stream) {
    delete _stream;
    _stream = nullptr;
  }
  if (_file && _file->isOpen()) {
    _file->close();
  }
  if (_file) {
    delete _file;
    _file = nullptr;
  }
  if (_fileMain && _fileMain->isOpen()) {
    _fileMain->close();
  }
  if (_fileMain) {
    delete _fileMain;
    _fileMain = nullptr;
  }
  if (_fileINI && _fileINI->isOpen()) {
    _fileINI->close();
  }
  if (_fileINI) {
    delete _fileINI;
    _fileINI = nullptr;
  }
  if (_fileMakefile && _fileMakefile->isOpen()) {
    _fileMakefile->close();
  }
  if (_fileMakefile) {
    delete _fileMakefile;
    _fileMakefile = nullptr;
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

  delete _camTop;
  delete _camFront;
  delete _camRight;

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

  setSceneBoundingBox(qmin, qmax);

  // The scene changed, so the SpaceNavigator orbit distance is stale.
  _snOrbitDist = 0.0;
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

  QElapsedTimer dtAll;                  // (the drawing timer: all of draw())
  if (_drawTiming && !_quadView)
    dtAll.start();

  computeBoundingBox();
  if (dtAll.isValid())
    _dtBox += dtAll.nsecsElapsed() / 1.0e6;

  GLfloat light_ambient[] = {_gl_ambient.x(), _gl_ambient.y(), _gl_ambient.z()};
  GLfloat light_diffuse[] = {_gl_diffuse.x(), _gl_diffuse.y(), _gl_diffuse.z()};
  GLfloat light_specular[] = {_gl_specular.x(), _gl_specular.y(),
                              _gl_specular.z()};

  // light_position is NOT default value
  GLfloat light_position0[] = {_light0.x(), _light0.y(), _light0.z(),
                               _light0.w()};
  GLfloat light_position1[] = {_light1.x(), _light1.y(), _light1.z(),
                               _light1.w()};

  glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
  glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
  glLightfv(GL_LIGHT0, GL_POSITION, light_position0);

  glLightfv(GL_LIGHT1, GL_AMBIENT, light_ambient);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, light_diffuse);
  glLightfv(GL_LIGHT1, GL_SPECULAR, light_specular);
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

  // (the drawing timer, when it's on: see setDrawTiming())
  QElapsedTimer dt;
  const bool timing = _drawTiming && !_quadView;
  if (timing) {
    dtGpuCollect();
    dt.start();
  }

  updateMerge();                         // (see setScreenMerge())

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

  if (_quadView) {
    drawQuadView();
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
  }

  if (manipulatedFrame() != nullptr) {
    glPopMatrix();
  }

  if (_snShowOrbitAxis) {
    // Visualize the orbit/rotation centre as a small world-axis marker.
    qreal orbitDist = _snOrbitDist;
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
    _dtDraw += dtAll.nsecsElapsed() / 1.0e6;
    ++_dtFrames;
  }

  mutex.unlock();
}

// The screen's merge (see setScreenMerge()).

void Viewer::setScreenMerge(bool on) { _screenMerge = on; }

bool Viewer::screenMerge() const { return _screenMerge; }

int Viewer::screenMerged() const { return _screenMerged; }

namespace {
// What can go into the merge: a fixed box or cylinder, opaque, without an
// image or a script's drawing.
bool mergeable(Object *o) {
  return o->body != nullptr && o->body->isStaticObject() &&
         o->body->getMotionState() != nullptr && o->getTransparency() <= 0.0 &&
         !o->hasTexture() && !o->hasRenderFunction() &&
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

void Viewer::freeMerge() {
  QOpenGLContext *c = QOpenGLContext::currentContext();
  const bool canDelete = c != nullptr && glCacheContext() == _mergeCtx &&
                         glCacheEpoch() == _mergeEpoch;
  for (MergeBatch &b : _mergeBatches) {
    if (b.vbo != 0 && canDelete)
      c->functions()->glDeleteBuffers(1, &b.vbo);
    if (b.cvbo != 0 && canDelete)
      c->functions()->glDeleteBuffers(1, &b.cvbo);
  }
  _mergeBatches.clear();
  for (Object *o : _mergeObjs)
    o->merged = o->mergeDrawn = false;
  _mergeObjs.clear();
  _mergeReady = false;
}

void Viewer::unmerge(Object *o) {
  auto it = _mergeBatches.find(std::make_tuple(o->mergeCell[0], o->mergeCell[1], o->mergeCell[2]));
  if (it != _mergeBatches.end()) {
    it->objs.removeOne(o);
    it->dirty = true;
    for (Object *p : it->objs)          // (one by one until it's made again)
      p->mergeDrawn = false;
  }
  o->merged = false;
  o->mergeDrawn = false;
  o->mergeSteady = 0;
}

void Viewer::buildMerge() {
  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
  std::vector<MergeVertex> verts;
  std::vector<quint32> colours;
  bool made = false;
  // (a few a frame, so no one frame does them all: what's in the others is
  // drawn one by one meanwhile)
  int budget = 4;
  for (auto it = _mergeBatches.begin(); it != _mergeBatches.end();) {
    MergeBatch &b = it.value();
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
    if (b.objs.isEmpty()) {
      it = _mergeBatches.erase(it);
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
    ++it;
  }
  f->glBindBuffer(GL_ARRAY_BUFFER, 0);
  if (made)
    ++_mergesMade;
}

void Viewer::updateMerge() {
  ++_mergeFrame;
  _mergeReady = false;
  const void *ctx = glCacheContext();
  if (ctx != _mergeCtx || glCacheEpoch() != _mergeEpoch) {
    for (MergeBatch &b : _mergeBatches) {
      b.vbo = b.cvbo = 0;                // (they went with their context)
      b.dirty = true;
      for (Object *o : b.objs)
        o->mergeDrawn = false;
    }
    _mergeCtx = ctx;
    _mergeEpoch = glCacheEpoch();
  }
  if (!_screenMerge || ctx == nullptr) {
    if (!_mergeObjs.isEmpty() || !_mergeBatches.isEmpty())
      freeMerge();
    return;
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
  for (int k = 0; k < _mergeObjs.size(); ++k) {
    Object *o = _mergeObjs[k];
    const bool still = mergeable(o) && sameTrans(drawnTrans(o), o->mergeTrans);
    if (still && memcmp(o->rgb(), o->mergeRgb, 3) == 0)
      continue;
    if (still) {
      auto it = _mergeBatches.find(std::make_tuple(o->mergeCell[0], o->mergeCell[1], o->mergeCell[2]));
      if (it != _mergeBatches.end() && it.value().cvbo != 0 && !it.value().dirty && o->mergeDrawn) {
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
      }
      // (a batch not made yet takes the colour it has when it's made)
      memcpy(o->mergeRgb, o->rgb(), 3);
      continue;
    }
    unmerge(o);
    o->mergeBanUntil = ++o->mergeChanges >= 2 ? LONG_MAX : _mergeFrame + 600;
    _mergeObjs.removeAt(k--);
  }
  if (bound)
    QOpenGLContext::currentContext()->functions()->glBindBuffer(GL_ARRAY_BUFFER, 0);
  // Once a second, more: what has stayed put for five looks running goes
  // into the batch of its patch (whatever its colour does: see above).
  if (_mergeFrame % 60 == 0) {
    foreach (Object *o, *_objects) {
      if (o->merged || _mergeFrame < o->mergeBanUntil || !mergeable(o))
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
        MergeBatch &b = _mergeBatches[std::make_tuple(o->mergeCell[0], o->mergeCell[1],
                                                      o->mergeCell[2])];
        b.objs.append(o);
        b.dirty = true;
        for (Object *p : b.objs)
          p->mergeDrawn = false;
        o->merged = true;
        _mergeObjs.append(o);
      } else {
        o->mergeSteady = 1;
        o->mergeTrans = t;
        memcpy(o->mergeRgb, o->rgb(), 3);
      }
    }
  }
  buildMerge();                          // (only the batches that need it)
  _mergeReady = true;
}

void Viewer::drawMerged() {
  _screenMerged = 0;
  if (!_mergeReady || _mergeBatches.isEmpty())
    return;
  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnable(GL_NORMALIZE);
  for (const MergeBatch &b : _mergeBatches) {
    if (b.dirty || b.vbo == 0 || b.cvbo == 0)
      continue;
    bool wanted = !_culled;
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
    _screenMerged += b.objs.size();
  }
  f->glBindBuffer(GL_ARRAY_BUFFER, 0);
  glDisableClientState(GL_COLOR_ARRAY);
  glColor4ub(255, 255, 255, 255);        // (the colour after a colour array isn't defined)
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);
}

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

  drawMerged();
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
    SoftBody *sb = dynamic_cast<SoftBody *>(o);
    if (sb != nullptr) {
      sb->renderWorld();
    } else {
      o->render(minaabb, maxaabb);
    }
  };
  foreach (Object *o, *_objects) {
    // (what cullObjects() decided for this frame)
    if (_culled && !(shadowPass ? o->drawInShadow : o->drawOnScreen))
      continue;
    if (skipFixed && o->shadowListed)
      continue;
    if (!shadowPass && o->mergeDrawn && _mergeReady)  // (drawn by drawMerged())
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

// Culling. The camera's view is six planes (left, right, bottom, top, near,
// far), read off its projection and modelview matrices; a box is out of view
// when it lies wholly on the outer side of any one of them. An object's box
// is its collision shape's, where and as the object is drawn, with a tenth of
// its size to spare.
//
// For the shadow map: a shadow that falls into the view only shows where it
// lands on something drawn there, so an object out of view still goes into
// the map if its box, swept the way the light shines (one direction for the
// whole scene, as the shadow map takes it) until it is past everything in
// view, meets the view.
void Viewer::cullObjects() {
  _drawnObjects = 0;
  _shadowCasters = 0;
  _culled = _culling && !_quadView && manipulatedFrame() == nullptr;
  if (!_culled)
    return;

  GLdouble proj[16], mv[16], m[16];
  glGetDoublev(GL_PROJECTION_MATRIX, proj);
  glGetDoublev(GL_MODELVIEW_MATRIX, mv);
  for (int c = 0; c < 4; ++c)            // m = proj * mv (column-major)
    for (int r = 0; r < 4; ++r) {
      double sum = 0;
      for (int k = 0; k < 4; ++k)
        sum += proj[k * 4 + r] * mv[c * 4 + k];
      m[c * 4 + r] = sum;
    }
  double planes[6][4];
  for (int p = 0; p < 6; ++p) {
    const int row = p / 2;
    const double sign = (p % 2 == 0) ? 1.0 : -1.0;
    for (int c = 0; c < 4; ++c)
      planes[p][c] = m[c * 4 + 3] + sign * m[c * 4 + row];
  }
  auto outside = [&](const btVector3 &lo, const btVector3 &hi) {
    for (int p = 0; p < 6; ++p) {
      const double *q = planes[p];
      const double x = q[0] >= 0 ? hi.x() : lo.x();
      const double y = q[1] >= 0 ? hi.y() : lo.y();
      const double z = q[2] >= 0 ? hi.z() : lo.z();
      if (q[0] * x + q[1] * y + q[2] * z + q[3] < 0)
        return true;
    }
    return false;
  };

  const double radius = camera()->sceneRadius();
  const btScalar spare = btScalar(1e-3 * radius);

  // 1: the screen. (Everything in view, or that can't be boxed, makes up
  // what a shadow can land on.)
  struct Box { Object *o; btVector3 lo, hi; };
  std::vector<Box> offScreen;
  bool anyInView = false, unboxedInView = false;
  btVector3 viewLo(BT_LARGE_FLOAT, BT_LARGE_FLOAT, BT_LARGE_FLOAT), viewHi = -viewLo;
  foreach (Object *o, *_objects) {
    o->drawOnScreen = true;
    o->drawInShadow = true;
    btRigidBody *b = o->body;
    // (always drawn: no shape to box; drawn by a script, or by a plain
    // Object, which draws a ball whatever its shape; a soft body)
    if (b == nullptr || b->getCollisionShape() == nullptr || o->hasRenderFunction() ||
        typeid(*o) == typeid(Object) || dynamic_cast<SoftBody *>(o) != nullptr) {
      unboxedInView = true;
      continue;
    }
    // (where it is drawn: a body without a motion state is drawn as it
    // stands, in world coordinates)
    btTransform t;
    if (b->getMotionState() != nullptr)
      b->getMotionState()->getWorldTransform(t);
    else
      t.setIdentity();
    btVector3 lo, hi;
    b->getCollisionShape()->getAabb(t, lo, hi);
    const btVector3 shift = t.getBasis() * o->drawnOffset();
    lo += shift;
    hi += shift;
    const btVector3 pad = (hi - lo) * btScalar(0.1) + btVector3(spare, spare, spare);
    lo -= pad;
    hi += pad;
    o->drawOnScreen = !outside(lo, hi);
    if (o->drawOnScreen) {
      anyInView = true;
      viewLo.setMin(lo);
      viewHi.setMax(hi);
    } else {
      offScreen.push_back(Box{o, lo, hi});
    }
  }

  // 2: the shadow map
  if (!_shadows)
    return;
  const qglviewer::Vec sc = camera()->sceneCenter();
  btVector3 toLight(_light0.x(), _light0.y(), _light0.z());
  if (_light0.w() != 0.0)
    toLight = toLight / _light0.w() - btVector3(sc.x, sc.y, sc.z);
  const bool lit = toLight.length2() > 0;
  const btVector3 d = lit ? -toLight.normalized() : btVector3(0, -1, 0);
  // (a soft shadow's blur reaches a few texels of the map further)
  const btScalar blur = btScalar(2.0 * 1.02 * radius / qMax(1, _shadowMap->mapSize()) *
                                 (_shadowMap->softness() + 1.0));
  for (Box &x : offScreen) {
    x.o->drawInShadow = false;
    if (!lit || !(anyInView || unboxedInView))
      continue;
    // (how far until the whole box is past everything in view, along d;
    // with something in view that can't be boxed, all the way)
    btScalar reach = btScalar(BT_LARGE_FLOAT);
    if (!unboxedInView) {
      for (int k = 0; k < 3; ++k) {
        if (d[k] < 0)
          reach = btMin(reach, (viewLo[k] - x.hi[k]) / d[k]);
        else if (d[k] > 0)
          reach = btMin(reach, (viewHi[k] - x.lo[k]) / d[k]);
      }
      reach = btMax(reach, btScalar(0));
    }
    btVector3 lo = x.lo - btVector3(blur, blur, blur), hi = x.hi + btVector3(blur, blur, blur);
    btVector3 slo = lo, shi = hi;
    slo.setMin(lo + d * reach);
    shi.setMax(hi + d * reach);
    x.o->drawInShadow = !outside(slo, shi);
  }
}

bool Viewer::isFixedCaster(const Object *o) {
  return o->body != nullptr && o->body->isStaticObject() &&
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
quint64 Viewer::markStillCasters(int *count) {
  quint64 sum = 0;
  int n = 0;
  foreach (Object *o, *_objects) {
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
      o->shadowHash = h;
      o->shadowStill = 0;
    } else if (o->shadowStill < STILL_FRAMES) {
      ++o->shadowStill;
    }
    if (o->shadowStill >= STILL_FRAMES) {
      o->shadowListed = true;
      ++n;
      sum += h;
    }
  }
  *count = n;
  return sum;
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
  // Object::render().
  //
  // The fixed objects that have stayed put are drawn once, recorded as
  // OpenGL lists, and those are replayed each frame; only the rest are drawn
  // one by one. There is a list for each patch of the scene (a cube
  // SHADOW_PATCH across), so what culling leaves out still mostly stays out:
  // a patch's list is replayed when culling keeps any of its objects. When
  // which objects are still, or where, changes, the lists are made again.
  static const btScalar SHADOW_PATCH = 60;
  _shadowCached = 0;
  const void *ctx = glCacheContext();
  if (_fixedShadowLists != 0 && (_fixedShadowCtx != ctx || _fixedShadowEpoch != glCacheEpoch()))
    _fixedShadowLists = 0;               // (its context has gone, and the lists with it)
  if (_fixedShadowLists == 0)
    _fixedShadowCells.clear();
  bool replay = false;
  if (_shadowCache && ctx != nullptr) {
    int count = 0;
    const quint64 sig = markStillCasters(&count);
    if (_fixedShadowLists != 0 && (sig != _fixedShadowSig || count != _fixedShadowCount)) {
      glDeleteLists(_fixedShadowLists, _fixedShadowCells.size());
      _fixedShadowLists = 0;
      _fixedShadowCells.clear();
    }
    if (_fixedShadowLists == 0 && count > 0) {
      QMap<std::tuple<int, int, int>, QVector<Object *>> patches;
      foreach (Object *o, *_objects) {
        if (!o->shadowListed)
          continue;
        btTransform t;
        if (o->body->getMotionState() != nullptr)
          o->body->getMotionState()->getWorldTransform(t);
        else
          t.setIdentity();
        btVector3 lo, hi;
        o->body->getCollisionShape()->getAabb(t, lo, hi);
        const btVector3 mid = (lo + hi) * 0.5;
        auto cell = [&](btScalar x) {    // (planes and the like: far out, all one)
          return int(std::max(-1e6, std::min(1e6, std::floor(double(x / SHADOW_PATCH)))));
        };
        patches[std::make_tuple(cell(mid.x()), cell(mid.y()), cell(mid.z()))].append(o);
      }
      btVector3 minaabb(0, 0, 0), maxaabb(0, 0, 0);
      dynamicsWorld->getBroadphase()->getBroadphaseAabb(minaabb, maxaabb);
      // (with a body gone off to infinity, objects draw at the origin: not
      // something to record)
      bool finite = true;
      for (int a = 0; a < 3; ++a)
        finite = finite && std::isfinite(minaabb[a]) && std::isfinite(maxaabb[a]);
      GLuint lists = finite ? glGenLists(patches.size()) : 0;
      if (lists != 0) {
        glSetRecordingList(true);        // (see glRecordingList())
        GLuint list = lists;
        for (auto it = patches.cbegin(); it != patches.cend(); ++it, ++list) {
          glNewList(list, GL_COMPILE);
          foreach (Object *o, it.value())
            o->render(minaabb, maxaabb);
          glEndList();
          _fixedShadowCells.append(it.value());
        }
        glSetRecordingList(false);
        _fixedShadowLists = lists;
        _fixedShadowCtx = ctx;
        _fixedShadowEpoch = glCacheEpoch();
        _fixedShadowSig = sig;
        _fixedShadowCount = count;
      }
    }
    replay = _fixedShadowLists != 0;
  } else if (_fixedShadowLists != 0) {
    glDeleteLists(_fixedShadowLists, _fixedShadowCells.size());
    _fixedShadowLists = 0;
    _fixedShadowCells.clear();
  }
  // With the record made, and the light and the scene's extent the same as
  // last frame, all of the record is drawn once more and the depth saved
  // (v.shadowSaved); each frame after that puts the saved depth back in one
  // copy on the graphics card, instead of drawing the record again, until
  // the record or the light changes.
  _shadowFromSaved = false;
  bool drewAll = false;
  if (replay && _shadowSaved) {
    if (_savedDepthSig == _fixedShadowSig && _savedDepthCount == _fixedShadowCount &&
        _shadowMap->savedDepthFits()) {
      _shadowMap->restoreDepth();
      _shadowFromSaved = true;
    } else if (_shadowMap->lightSteady() && _shadowMap->canSaveDepth()) {
      for (int k = 0; k < _fixedShadowCells.size(); ++k)
        glCallList(_fixedShadowLists + k);
      drewAll = true;
      if (_shadowMap->saveDepth()) {
        _savedDepthSig = _fixedShadowSig;
        _savedDepthCount = _fixedShadowCount;
        _shadowFromSaved = true;
      }
    }
  }
  if (_shadowFromSaved || drewAll) {
    _shadowCached = _fixedShadowCount;
    drawObjects(true, true);
  } else if (replay) {
    for (int k = 0; k < _fixedShadowCells.size(); ++k) {
      const QVector<Object *> &cell = _fixedShadowCells[k];
      bool wanted = !_culled;
      for (int i = 0; !wanted && i < cell.size(); ++i)
        wanted = cell[i]->drawInShadow;
      if (wanted) {
        glCallList(_fixedShadowLists + k);
        _shadowCached += cell.size();
      }
    }
    drawObjects(true, true);
  } else {
    drawObjects(true);
  }

  _shadowMap->renderDepthEnd();
}

// Re-frames the three fixed orthographic cameras on the current scene,
// keeping their view direction/up vector (set once, in the constructor)
// and just sliding them along that direction so the whole scene is in
// frame - the same thing fitSphere() is for. Called once when quad view
// is switched on (and on 'C' reset), not every frame, so it doesn't fight
// the user's own pan/zoom in those views afterwards.
void Viewer::updateOrthoCameras() {
  const qglviewer::Vec center = camera()->sceneCenter();
  const qreal radius = camera()->sceneRadius();

  for (qglviewer::Camera *cam : {_camTop, _camFront, _camRight}) {
    cam->setSceneCenter(center);
    cam->setSceneRadius(radius);
    cam->setPivotPoint(center);
    cam->fitSphere(center, radius);
  }
}

// The current quad-view pane layout: perspective (top-left, the
// interactive camera()), top (top-right), front (bottom-left), right
// (bottom-right) - the classic AutoCAD/Maya 4-view layout. Rectangles are
// in widget coordinates (Qt convention: origin top-left, y down), shared
// by drawQuadView() (which flips to OpenGL's bottom-left-origin viewport)
// and orthoCameraAt() (which hit-tests mouse events directly against
// these).
QVector<Viewer::Pane> Viewer::computePanes() const {
  const int w = width();
  const int h = height();
  const int leftW = w / 2;
  const int rightW = w - leftW;
  const int topH = h / 2;
  const int bottomH = h - topH;

  return {
      {camera(), QRect(0, 0, leftW, topH)},            // top-left: perspective
      {_camTop, QRect(leftW, 0, rightW, topH)},         // top-right: top
      {_camFront, QRect(0, topH, leftW, bottomH)},      // bottom-left: front
      {_camRight, QRect(leftW, topH, rightW, bottomH)}, // bottom-right: right
  };
}

// The ortho camera under widget position pos, or nullptr when quad view
// is off or pos is over the perspective pane (where camera()'s own
// default mouse handling already applies).
qglviewer::Camera *Viewer::orthoCameraAt(const QPoint &pos) const {
  if (!_quadView) return nullptr;

  for (const Pane &p : computePanes()) {
    if (p.cam != camera() && p.rect.contains(pos)) {
      return p.cam;
    }
  }
  return nullptr;
}

// Splits the viewport into the 4 quadView panes and renders the scene
// once per pane, each with its own camera and clipped to its own
// rectangle.
void Viewer::drawQuadView() {
  const int w = width();
  const int h = height();
  const QVector<Pane> panes = computePanes();

  for (int i = 0; i < panes.size(); i++) {
    const Pane &p = panes[i];
    // glViewport() takes the bottom-left corner; p.rect.y() is measured
    // from the top, so flip it.
    const int glX = p.rect.x();
    const int glY = h - p.rect.y() - p.rect.height();
    glViewport(glX, glY, p.rect.width(), p.rect.height());

    p.cam->setScreenWidthAndHeight(p.rect.width(), p.rect.height());
    p.cam->loadProjectionMatrix();
    p.cam->loadModelViewMatrix();

    glDisable(GL_CULL_FACE);
    drawSceneInternal(i);
  }

  // Restore the full-window viewport and camera() state: postDraw()'s
  // screen-coordinate overlays (record/simulate/save/deactivation dots)
  // assume the whole widget, and the next frame's mouse handling assumes
  // camera()'s screen size matches the widget again.
  glViewport(0, 0, w, h);
  camera()->setScreenWidthAndHeight(w, h);
  camera()->loadProjectionMatrix();
  camera()->loadModelViewMatrix();
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
    drawConstraint(c, constraintDrawSize(c));
  }
}

// A solid cylinder from `from` to `to`, radius `radius`, colored `color`.
// Builds a rotation (via btPlaneSpace1, matching how btHingeConstraint
// itself derives a frame from a single axis) that maps the cylinder's
// local Z (solidCylinder()'s axis) onto the from->to direction.
void Viewer::drawConstraintCylinder(const btVector3 &from, const btVector3 &to,
                                    btScalar radius, const btVector3 &color) {
  btVector3 dir = to - from;
  btScalar length = dir.length();
  if (length < SIMD_EPSILON)
    return;
  dir /= length;

  btVector3 p1, p2;
  btPlaneSpace1(dir, p1, p2);

  btTransform t;
  t.setIdentity();
  t.setOrigin(from);
  t.getBasis().setValue(p1.x(), p2.x(), dir.x(), p1.y(), p2.y(), dir.y(),
                        p1.z(), p2.z(), dir.z());

  GLfloat m[16];
  t.getOpenGLMatrix(m);

  glColor3f(color.x(), color.y(), color.z());
  glPushMatrix();
  glMultMatrixf(m);
  solidCylinder(radius, length, 8, 1);
  glPopMatrix();
}

/// Colour every constraint marker is drawn in.
static const btVector3 kConstraintColor(1.0, 0.5, 0.0); // orange

// A 3-axis cross, for constraints that pin a full frame (generic 6dof /
// fixed) rather than a single axis or point.
void Viewer::drawConstraintFrame(const btTransform &t, btScalar size) {
  btScalar radius = size * btScalar(0.1);
  const btVector3 &origin = t.getOrigin();
  drawConstraintCylinder(origin, origin + t.getBasis().getColumn(0) * size,
                         radius, kConstraintColor);
  drawConstraintCylinder(origin, origin + t.getBasis().getColumn(1) * size,
                         radius, kConstraintColor);
  drawConstraintCylinder(origin, origin + t.getBasis().getColumn(2) * size,
                         radius, kConstraintColor);
}

// A single cylinder through t's origin along one of its local axes, for
// constraints defined by one axis (hinge, slider, cone-twist's twist axis).
void Viewer::drawConstraintAxis(const btTransform &t, int axis, btScalar size,
                                const btVector3 &color) {
  btScalar radius = size * btScalar(0.15);
  const btVector3 &origin = t.getOrigin();
  btVector3 dir = t.getBasis().getColumn(axis);
  drawConstraintCylinder(origin - dir * size, origin + dir * size, radius,
                         color);
}

// A small 3-axis cross of cylinders at a single world point, for point
// constraints (point2point pivot).
void Viewer::drawConstraintPoint(const btVector3 &p, btScalar size,
                                 const btVector3 &color) {
  btScalar radius = size * btScalar(0.15);
  drawConstraintCylinder(p - btVector3(size, 0, 0), p + btVector3(size, 0, 0),
                         radius, color);
  drawConstraintCylinder(p - btVector3(0, size, 0), p + btVector3(0, size, 0),
                         radius, color);
  drawConstraintCylinder(p - btVector3(0, 0, size), p + btVector3(0, 0, size),
                         radius, color);
}

// Half the average bounding-sphere radius of the two connected bodies, so
// markers scale with the parts a constraint actually joins rather than the
// whole scene (a single far-away or oversized object would otherwise blow
// up every marker's size).
btScalar Viewer::constraintDrawSize(btTypedConstraint *c) {
  btVector3 center;
  btScalar radiusA = 0, radiusB = 0;

  if (c->getRigidBodyA().getCollisionShape())
    c->getRigidBodyA().getCollisionShape()->getBoundingSphere(center, radiusA);
  if (c->getRigidBodyB().getCollisionShape())
    c->getRigidBodyB().getCollisionShape()->getBoundingSphere(center, radiusB);

  btScalar radius = (radiusA + radiusB) * btScalar(0.5);
  if (radius <= 0)
    radius = btScalar(1.0);

  return radius * btScalar(0.5);
}

// Modelled on btDiscreteDynamicsWorld::debugDrawConstraint(), implemented
// directly so we control size/color per type instead of Bullet's internal
// (often too-small) defaults.
void Viewer::drawConstraint(btTypedConstraint *c, btScalar size) {
  const btTransform &trA = c->getRigidBodyA().getCenterOfMassTransform();
  const btTransform &trB = c->getRigidBodyB().getCenterOfMassTransform();

  switch (c->getConstraintType()) {
  case POINT2POINT_CONSTRAINT_TYPE: {
    auto *p2p = static_cast<btPoint2PointConstraint *>(c);
    drawConstraintPoint(trA * p2p->getPivotInA(), size, kConstraintColor);
    drawConstraintPoint(trB * p2p->getPivotInB(), size, kConstraintColor);
    break;
  }
  case HINGE_CONSTRAINT_TYPE: {
    // Hinge axis is the frame's local Z (see btHingeConstraint::setAxis()).
    auto *hinge = static_cast<btHingeConstraint *>(c);
    drawConstraintAxis(trA * hinge->getFrameOffsetA(), 2, size,
                       kConstraintColor);
    break;
  }
  case SLIDER_CONSTRAINT_TYPE: {
    // Slide axis is the frame's local X.
    auto *slider = static_cast<btSliderConstraint *>(c);
    drawConstraintAxis(slider->getCalculatedTransformA(), 0, size,
                       kConstraintColor);
    break;
  }
  case CONETWIST_CONSTRAINT_TYPE: {
    // Twist axis is the frame's local X.
    auto *cone = static_cast<btConeTwistConstraint *>(c);
    drawConstraintAxis(trA * cone->getAFrame(), 0, size, kConstraintColor);
    break;
  }
  case D6_CONSTRAINT_TYPE:
  case D6_SPRING_CONSTRAINT_TYPE: {
    // btGeneric6DofConstraint and btGeneric6DofSpringConstraint (which
    // derives from it) are a separate class hierarchy from
    // btGeneric6DofSpring2Constraint below -- casting either family to the
    // other's type would read through the wrong vtable/layout.
    auto *d6 = static_cast<btGeneric6DofConstraint *>(c);
    drawConstraintFrame(d6->getCalculatedTransformA(), size);
    break;
  }
  case D6_SPRING_2_CONSTRAINT_TYPE:
  case FIXED_CONSTRAINT_TYPE: {
    // Covers plain btGeneric6DofSpring2Constraint and btFixedConstraint
    // (both report D6_SPRING_2_CONSTRAINT_TYPE/FIXED_CONSTRAINT_TYPE and
    // draw as a 3-axis frame cross), and btHinge2Constraint, which also
    // reports D6_SPRING_2_CONSTRAINT_TYPE but is drawn more usefully as
    // its own two joint axes (steering + wheel-spin) through its anchor.
    auto *hinge2 = dynamic_cast<btHinge2Constraint *>(c);
    if (hinge2 != nullptr) {
      btVector3 anchor = hinge2->getAnchor();
      btScalar radius = size * btScalar(0.15);
      drawConstraintCylinder(anchor - hinge2->getAxis1() * size,
                             anchor + hinge2->getAxis1() * size, radius,
                             kConstraintColor);
      drawConstraintCylinder(anchor - hinge2->getAxis2() * size,
                             anchor + hinge2->getAxis2() * size, radius,
                             kConstraintColor);
    } else {
      auto *d6b = static_cast<btGeneric6DofSpring2Constraint *>(c);
      drawConstraintFrame(d6b->getCalculatedTransformA(), size);
    }
    break;
  }
  case GEAR_CONSTRAINT_TYPE: {
    auto *gear = static_cast<btGearConstraint *>(c);
    btVector3 axisA = trA.getBasis() * gear->getAxisA();
    btVector3 axisB = trB.getBasis() * gear->getAxisB();
    btScalar radius = size * btScalar(0.15);
    drawConstraintCylinder(trA.getOrigin() - axisA * size,
                           trA.getOrigin() + axisA * size, radius,
                           kConstraintColor);
    drawConstraintCylinder(trB.getOrigin() - axisB * size,
                           trB.getOrigin() + axisB * size, radius,
                           kConstraintColor);
    break;
  }
  default:
    break;
  }
}

// Writes one of the interactive view's lights out as a POV-Ray vector.
//
// glLightfv(GL_POSITION) takes a homogeneous coordinate, so the point OpenGL
// really lights from is xyz/w -- the default GL_LIGHT0, btVector4(500, 500,
// 500, 0.4), lights from <1250,1250,1250> and not from <500,500,500>. A w of
// 0 asks for a light infinitely far off in the direction xyz; POV-Ray has no
// such light, so it gets one a long way along it instead, which is the same
// thing to within a rounding error at any scene's size.
//
// Z is negated last because POV-Ray is left-handed where the OpenGL and
// Bullet world is right-handed, the same conversion
// Object::povMatrixFromGL() applies to every object's transform.
static void povLightDeclare(QTextStream &s, const char *name,
                            const btVector4 &light) {
  btVector3 p(light.x(), light.y(), light.z());

  if (light.w() != btScalar(0)) {
    p /= light.w();
  } else if (p.length2() > btScalar(0)) {
    p = p.normalized() * btScalar(1e5);
  }

  s << "#declare " << name << " = <" << p.x() << ", " << p.y() << ", "
    << -p.z() << ">;" << "\n";
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

  // Keep sceneDir self-contained: copy the include the main scene pulls in
  // (includes/settings.inc, or the file a script names with v.pov_settings)
  // alongside the exported scene, rather than relying on the +L library
  // path to find the original when the scene is rendered later, elsewhere.
  // A name with no file under includes/ leaves sceneDir's copy alone.
  QString settingsIncPath = startupWorkingDir() + QDir::separator() +
                             "includes" + QDir::separator() + _pov_settings_inc;
  if (!_pov_settings_inc.isEmpty() && QFile::exists(settingsIncPath)) {
    QString sceneSettingsInc = sceneDir + QDir::separator() + _pov_settings_inc;
    QFile::remove(sceneSettingsInc);
    QFile::copy(settingsIncPath, sceneSettingsInc);
  }

  QString fn = QString("%1").arg(_frameNum, 5, 10, QChar('0'));
  QString file = QString("%1%2%3.inc").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(fn);
  QString fileMain = QString("%1%2%3.pov").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));
  QString fileINI = QString("%1%2%3.ini").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));
  QString fileWAV = QString("%1%2%3.wav").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));

  qDebug() << "POV-Ray file: " << file;

  if (_savePOV)
    saveWAV(fileWAV);

  // Clean up any previous export objects to avoid leaking when saving every
  // frame (savePOV can be called repeatedly during animation).
  if (_stream) {
    delete _stream;
    _stream = nullptr;
  }
  if (_file) {
    if (_file->isOpen())
      _file->close();
    delete _file;
    _file = nullptr;
  }
  if (_fileMain) {
    if (_fileMain->isOpen())
      _fileMain->close();
    delete _fileMain;
    _fileMain = nullptr;
  }
  if (_fileINI) {
    if (_fileINI->isOpen())
      _fileINI->close();
    delete _fileINI;
    _fileINI = nullptr;
  }
  if (_fileMakefile) {
    if (_fileMakefile->isOpen())
      _fileMakefile->close();
    delete _fileMakefile;
    _fileMakefile = nullptr;
  }

  _fileINI = new QFile(fileINI, this);
  _fileINI->open(QFile::WriteOnly | QFile::Truncate);

  QString name = qgetenv("USER");
  if (name.isEmpty())
    name = qgetenv("USERNAME");

  QString timestamp =
      QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

  QTextStream ini(_fileINI);
  ini << "; Animation INI file generated by Bullet Physics Playground" << "\n";
  ini << QString("; %1 by %2").arg(timestamp, name) << "\n"
      << "\n";
  ini << "Input_File_Name=" << sceneName << ".pov" << "\n";
  ini << "Output_File_Name=" << sceneName << "\n";
  ini << "Output_to_File=On" << "\n";
  ini << "Pause_When_Done=Off" << "\n";
  ini << "Verbose=Off" << "\n";
  ini << "Display=On" << "\n";
  ini << "Width=1280" << "\n";
  ini << "Height=720" << "\n";
  ini << "+FN" << "\n";
  ini << "+UA" << "\n";
  ini << "Bits_Per_Color=16" << "\n";
  ini << "+a +j0" << "\n";

  ini << "+L" << QStandardPaths::writableLocation(QStandardPaths::CacheLocation) << "\n";
  ini << "+L../../includes" << "\n" << "\n";
  ini << "+L/nfs/cache" << "\n" << "\n"; // XXX make this an option in the prefs

  ini << "Initial_Clock=" << _firstFrame << "\n";
  ini << "Final_Clock="   << _frameNum << "\n";
  ini << "Final_Frame="   << _frameNum << "\n";

  ini << "[240p]" << "\n"
      << "Width=426" << "\n"
      << "Height=240" << "\n";
  ini << "[720p]" << "\n"
      << "Width=1280" << "\n"
      << "Height=720" << "\n";
  ini << "[1080p]" << "\n"
      << "Width=1920" << "\n"
      << "Height=1080" << "\n";
  ini << "[TikTok]" << "\n"
      << "Width=1080" << "\n"
      << "Height=1920" << "\n";
  ini << "[4K]" << "\n"
      << "Width=3840" << "\n"
      << "Height=2160" << "\n";
  ini << "[Apple-M1]" << "\n"
      << "Width=4480" << "\n"
      << "Height=2520" << "\n";
  ini << "[Apple-5K]" << "\n"
      << "Width=5120" << "\n"
      << "Height=2880" << "\n";
  ini << "[8K]" << "\n"
      << "Width=7680" << "\n"
      << "Height=4320" << "\n";
  ini << "[DIN-A4-landscape-300dpi-5mm-margin]" << "\n"
      << "Width=3470" << "\n"
      << "Height=2442" << "\n";
  ini << "[DIN-A4-landscape-600dpi-5mm-margin]" << "\n"
      << "Width=6780" << "\n"
      << "Height=4725" << "\n";
  ini << "[portrait]" << "\n"
      << "Width=600" << "\n"
      << "Height=800" << "\n";

  _fileINI->close();

  _fileMain = new QFile(fileMain, this);
  _fileMain->open(QFile::WriteOnly | QFile::Truncate);

  QTextStream smain(_fileMain);
  smain << "// Main POV file generated by Bullet Physics Playground" << "\n";
  smain << QString("// %1 by %2").arg(timestamp, name) << "\n"
        << "\n";

  smain << "#version 3.7;" << "\n"
        << "\n";

  // The interactive view's two lights, for the settings include to pick up,
  // so that a script moving them with v.glLight0 or v.glLight1 is rendered
  // the way its view looks. The include declares its own defaults where this
  // preamble is missing, which is what makes a hand-written scene that does
  // not have it still render.
  //
  // They go in the main scene rather than in the per-frame include because
  // the settings file, which reads them, is included ahead of that; a scene
  // whose lights move while it runs therefore renders every one of its frames
  // with the lights as they stood when the export last wrote this file.
  povLightDeclare(smain, "GL_Light0", _light0);
  povLightDeclare(smain, "GL_Light1", _light1);
  smain << "#declare GL_Diffuse = <" << _gl_diffuse.x() << ", "
        << _gl_diffuse.y() << ", " << _gl_diffuse.z() << ">;" << "\n"
        << "\n";

  if (!_pov_settings_inc.isEmpty()) {
    smain << "#include \"" + _pov_settings_inc + "\"" << "\n"
          << "\n";
  }

  smain << "#include concat(concat(str(clock,-5,0)),\".inc\")" << "\n"
        << "\n";

  _fileMain->close();

  _file = new QFile(file, this);
  _file->open(QFile::WriteOnly | QFile::Truncate);

  _stream = new QTextStream(_file);

  *_stream << "// Include file generated by Bullet Physics Playground" << "\n";
  *_stream << QString("// %1 by %2").arg(timestamp, name) << "\n";

  if (!mPreSDL.isEmpty()) {
    *_stream << mPreSDL << "\n"
             << "\n";
  }

  if (_cam != nullptr) {

    *_stream << "#declare use_focal_blur = " << _cam->getUseFocalBlur()
    << "; // 0=off 1=low quality 10=high quality" << "\n"
    << "\n";

    if (_cam->getPreSDL().isNull()) {
      Vec pos = camera()->position();

      *_stream << "camera { " << "\n"
               << "  location < " << pos.x << ", " << pos.y << ", " << -pos.z
               << " >" << "\n"
	           << "  right image_width/image_height*x" << "\n";

      Vec look = ((Cam *)camera())->viewDirection() * 1000000 + camera()->position();
      *_stream << "  look_at <" << look.x << ", " << look.y << ", " << -look.z
			   << "> ";

      // Keep the view's vertical field of view whatever the render's aspect
      // ratio; the horizontal angle POV-Ray wants follows from it.
      *_stream << "  angle degrees(2*atan(tan(radians("
               << 180.0 * camera()->fieldOfView() / M_PI
               << ")/2)*image_width/image_height))" << "\n";

      *_stream << "  sky <" << _cam->getUpVector().x() << ", "
               << _cam->getUpVector().y() << ", " << -_cam->getUpVector().z()
               << ">" << "\n";

      *_stream << "#if(use_focal_blur)" << "\n"
               << "  aperture " << _cam->getFocalAperture() << "\n"
               << "  blur_samples 10*use_focal_blur" << "\n"
               << "  focal_point <" << _cam->getFocalPoint().x() << ", "
               << _cam->getFocalPoint().y() << ", " << -_cam->getFocalPoint().z()
               << "> " << "  confidence 0.9+(use_focal_blur*0.0085)" << "\n"
               << "  variance 1/(2000*use_focal_blur)" << "\n"
               << "#end" << "\n";

      *_stream << "}" << "\n"
               << "\n";
    } else {
      *_stream << _cam->getPreSDL() << "\n";
    }
  }

  QString fileMakefile = QString("%1%2GNUmakefile").arg(qPrintable(sceneDir)).arg(QDir::separator());

  qDebug() << "GNUmakefile: " << fileMakefile;

  _fileMakefile = new QFile(fileMakefile, this);
  if (!_fileMakefile->exists()) {
    _fileMakefile->open(QFile::WriteOnly | QFile::Truncate);

    QTextStream mk(_fileMakefile);
    mk << "# GNUmakefile generated by Bullet Physics Playground ---------------------------\n";
    mk << "\n";
    mk << "SCENE = $(shell basename `pwd`)\n";
    mk << "\n";
    mk << "include ../export.mk\n";
    mk << "\n";
    mk << "# EOF --------------------------------------------------------------------------\n";

    _fileMakefile->close();
  }

  foreach (Object *o, *_objects) {
    if (o->getPOVExport()) {
      Terrain *t = dynamic_cast<Terrain *>(o);
      if (t) {
        *_stream << t->toPOV(sceneDir);
        continue;
      }
#ifdef HAS_LIB_ASSIMP
      Mesh *m = dynamic_cast<Mesh *>(o);
      if (m) {
        *_stream << m->toPOV(sceneDir);
      } else {
        *_stream << o->toPOV();
      }
#else
      *_stream << o->toPOV();
#endif
    }
  }

  if (!mPostSDL.isEmpty()) {
    *_stream << "\n"
             << mPostSDL << "\n"
             << "\n";
  }

  if (_file != nullptr) {
    _file->close();
  }

  // free the objects allocated for this export immediately
  if (_stream) {
    delete _stream;
    _stream = nullptr;
  }
  if (_file) {
    if (_file->isOpen())
      _file->close();
    delete _file;
    _file = nullptr;
  }
  if (_fileMain) {
    if (_fileMain->isOpen())
      _fileMain->close();
    delete _fileMain;
    _fileMain = nullptr;
  }
  if (_fileINI) {
    if (_fileINI->isOpen())
      _fileINI->close();
    delete _fileINI;
    _fileINI = nullptr;
  }
  if (_fileMakefile) {
    if (_fileMakefile->isOpen())
      _fileMakefile->close();
    delete _fileMakefile;
    _fileMakefile = nullptr;
  }
}

// Frame rate export.mk encodes the exported frames at (ffmpeg's default for an
// image sequence), which the exported audio track keeps in step with.
static const int POV_EXPORT_FPS = 25;

// Header of a 16-bit PCM WAV holding dataBytes of samples.
static QByteArray wavHeader(int freq, int channels, quint32 dataBytes) {
  QByteArray h;
  QDataStream s(&h, QIODevice::WriteOnly);
  s.setByteOrder(QDataStream::LittleEndian);
  s.writeRawData("RIFF", 4);
  s << quint32(36 + dataBytes);
  s.writeRawData("WAVEfmt ", 8);
  s << quint32(16) << quint16(1) << quint16(channels) << quint32(freq)
    << quint32(freq * channels * 2) << quint16(channels * 2) << quint16(16);
  s.writeRawData("data", 4);
  s << dataBytes;
  return h;
}

void Viewer::saveWAV(const QString &fileWAV) {
  int freq, channels;
  Uint16 format;
  // The chunks hold their samples in the mixer's format; only 16-bit
  // little-endian PCM goes into the WAV as it is.
  if (!Mix_QuerySpec(&freq, &format, &channels) || format != AUDIO_S16LSB) {
    _wavEvents.clear();
    return;
  }

  // A new export: an older track no longer lines up with the frames.
  if (fileWAV != _wavFile || _firstFrame != _wavFirstFrame ||
      _frameNum < _wavFrame) {
    QFile::remove(fileWAV);
    _wavFile = fileWAV;
    _wavFirstFrame = _firstFrame;
    _wavWritten = -1;
    _wavMix.clear();
  }
  _wavFrame = _frameNum;

  if (_wavWritten < 0 && _wavEvents.empty())
    return; // nothing played yet, so no track

  QFile f(fileWAV);
  if (!f.open(QIODevice::ReadWrite)) {
    qWarning() << "saveWAV: cannot write" << fileWAV;
    _wavEvents.clear();
    return;
  }
  if (_wavWritten < 0)
    _wavWritten = 0;

  // first sample frame of exported frame n
  auto start = [&](int n) {
    return qint64(n - _firstFrame) * freq / POV_EXPORT_FPS;
  };

  // Appends the track up to sample frame end: the mix, then silence.
  auto append = [&](qint64 end) {
    qint64 n = (end - _wavWritten) * channels;
    if (n <= 0)
      return;
    std::vector<qint16> out(n, 0);
    qint64 m = std::min<qint64>(n, _wavMix.size());
    for (qint64 i = 0; i < m; ++i)
      out[i] = qBound(-32768, _wavMix[i], 32767);
    _wavMix.erase(_wavMix.begin(), _wavMix.begin() + m);
    f.seek(44 + _wavWritten * channels * 2);
    f.write((const char *)out.data(), n * 2);
    _wavWritten = end;
  };

  append(start(_frameNum)); // silence up to the first sound

  for (const WavEvent &e : _wavEvents) {
    const qint16 *src = (const qint16 *)e.chunk->abuf;
    qint64 len = e.chunk->alen / 2;
    qint64 at = (start(e.frame) - _wavWritten) * channels;
    if (at + len <= 0)
      continue;
    if ((qint64)_wavMix.size() < at + len)
      _wavMix.resize(at + len, 0);
    for (qint64 i = std::max<qint64>(0, -at); i < len; ++i)
      _wavMix[at + i] += int(src[i] * e.volume);
  }
  _wavEvents.clear();

  append(start(_frameNum + 1)); // this frame's share

  f.seek(0);
  f.write(wavHeader(freq, channels, quint32(_wavWritten * channels * 2)));
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

void Viewer::setCBOnKey(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onKey = fn;
  }
}

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

void Viewer::setCBOnParamChanged(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onParamChanged = fn;
  }
}

void Viewer::setCBOnHover(const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onHover = fn;
    setMouseTracking(true);          // movement without a button is reported
    if (!_hoverTimer) {
      _hoverTimer = new QTimer(this);
      _hoverTimer->setInterval(100);
      connect(_hoverTimer, &QTimer::timeout, this, [this]() { hoverTick(); });
    }
    _hoverTimer->start();
  } else {
    _cb_onHover = luabind::object();
    if (_hoverTimer) _hoverTimer->stop();
    hoverHide();
  }
}

void Viewer::hoverHide() {
  if (_hoverShown) {
    QToolTip::hideText();
    _hoverShown = false;
  }
}

void Viewer::hoverTick() {
  if (!_cb_onHover || !_hoverArmed || !dynamicsWorld) return;
  if (QApplication::mouseButtons() != Qt::NoButton) { hoverHide(); return; }
  if (!_hoverStill.isValid() || _hoverStill.elapsed() < 500) return;

  // a ray from the camera through the pointer (the ortho pane's camera if
  // the pointer is over one)
  qglviewer::Camera *cam = orthoCameraAt(_hoverPos);
  if (!cam) cam = camera();
  qglviewer::Vec orig, dir;
  cam->convertClickToLine(_hoverPos, orig, dir);
  const btScalar far = 1.0e6;
  btVector3 from(orig.x, orig.y, orig.z);
  btVector3 to(orig.x + dir.x * far, orig.y + dir.y * far, orig.z + dir.z * far);
  btCollisionWorld::ClosestRayResultCallback ray(from, to);
  // bpp adds bodies with its own collision groups: let the ray see them all
  // (an object made with collides = false has an empty mask and stays unseen)
  ray.m_collisionFilterGroup = -1;
  ray.m_collisionFilterMask = -1;
  dynamicsWorld->rayTest(from, to, ray);
  Object *hit = nullptr;
  if (ray.hasHit() && _objects) {
    for (Object *o : *_objects) {
      if (o && o->getRigidBody() &&
          static_cast<const btCollisionObject *>(o->getRigidBody()) == ray.m_collisionObject) {
        hit = o;
        break;
      }
    }
  }
  if (hit) {
    _hoverObj = hit;
    _hoverHitPt = ray.m_hitPointWorld;
    _hoverLastHit.restart();
  } else if (_hoverObj && _hoverLastHit.isValid() && _hoverLastHit.elapsed() < 1500 &&
             _objects && _objects->contains(_hoverObj)) {
    // sticky: a spinning or rocking object can slip out from under a resting
    // pointer for a moment -- keep reporting it for 1.5 s (no flicker)
    hit = _hoverObj;
  } else {
    _hoverObj = nullptr;
    hoverHide();
    return;
  }

  QString text;
  try {
    const btVector3 &p = _hoverHitPt;
    luabind::object res = luabind::call_function<luabind::object>(
        _cb_onHover, _frameNum, hit, (double)p.x(), (double)p.y(), (double)p.z());
    if (res.is_valid() && luabind::type(res) == LUA_TSTRING)
      text = QString::fromUtf8(luabind::object_cast<std::string>(res).c_str());
  } catch (const std::exception &e) {
    showLuaException(e, "onHover()");
    _cb_onHover = luabind::object();      // (don't repeat the error 10x a second)
  }
  if (text.isEmpty()) { hoverHide(); return; }
  // monospace so a script can line things up
  QToolTip::showText(mapToGlobal(_hoverPos + QPoint(16, 16)),
                     QString("<pre style='margin:0'>%1</pre>").arg(text.toHtmlEscaped()),
                     this, QRect(), 600000);
  _hoverShown = true;
}

void Viewer::leaveEvent(QEvent *e) {
  _hoverArmed = false;
  hoverHide();
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
  _params[name] = value;

  ParamInfo info;
  info.value = value;
  info.comment = comment;
  _paramInfo[name] = info;

  if (L) {
    lua_State *ls = L;
    lua_pushstring(ls, name.toUtf8().constData());

    switch (value.type()) {
    case QVariant::Int:
    case QVariant::LongLong:
      lua_pushinteger(ls, value.toInt());
      break;
    case QVariant::Double:
      lua_pushnumber(ls, value.toDouble());
      break;
    case QVariant::Bool:
      lua_pushboolean(ls, value.toBool());
      break;
    case QVariant::String:
      lua_pushstring(ls, value.toString().toUtf8().constData());
      break;
    default:
      lua_pushstring(ls, value.toString().toUtf8().constData());
      break;
    }

    //lua_settable(ls, LUA_GLOBALSINDEX);// Lua 5.1
	lua_setglobal(ls, name.toUtf8().constData()); // Lua 5.1 and 5.2
  }

  if (_cb_onParamChanged) {
    try {
      luabind::call_function<void>(_cb_onParamChanged, _frameNum, name, value);
    } catch (const std::exception &e) {
      showLuaException(e, "onParamChanged()");
    }
  }

  emit paramsChanged();
}

void Viewer::addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max) {
  addParam(name, value, min, max, 0.0, QString());
}

void Viewer::addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max, const btScalar &step) {
  addParam(name, value, min, max, step, QString());
}

void Viewer::addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max, const btScalar &step, const QString &comment) {
  _params[name] = QVariant(value);
  ParamInfo info;
  info.value = QVariant(value);
  info.min = min;
  info.max = max;
  info.step = step;
  info.comment = comment;
  info.hasRange = true;
  _paramInfo[name] = info;
  if (L) {
    lua_State *ls = L;
    lua_pushstring(ls, name.toUtf8().constData());
    // Use lua_pushnumber (not lua_pushinteger) so fractional defaults
    // (e.g. addParam("rate", 0.12, ...)) survive the round trip through
    // the Lua global that getParam() reads back, instead of being
    // truncated to 0.
    lua_pushnumber(ls, value);
    lua_setglobal(ls, name.toUtf8().constData());
  }

  if (_cb_onParamChanged) {
    try {
      luabind::call_function<void>(_cb_onParamChanged, _frameNum, name, value);
    } catch (const std::exception &e) {
      showLuaException(e, "onParamChanged()");
    }
  }

  emit paramsChanged();
}

ParamInfo Viewer::getParamInfo(const QString &name) const {
  return _paramInfo.value(name, ParamInfo());
}

QVariant Viewer::getParam(const QString &name) const {
  if (L) {
    lua_State *ls = L;
    lua_getglobal(ls, name.toUtf8().constData());
    int luaType = lua_type(ls, -1);
    if (luaType == LUA_TNUMBER) {
      double n = lua_tonumber(ls, -1);
      lua_pop(ls, 1);
      return QVariant(n);
    } else if (luaType == LUA_TSTRING) {
      const char *s = lua_tostring(ls, -1);
      lua_pop(ls, 1);
      return QVariant(QString(s));
    } else if (luaType == LUA_TBOOLEAN) {
      bool b = lua_toboolean(ls, -1);
      lua_pop(ls, 1);
      return QVariant(b);
    }
    lua_pop(ls, 1);
  }
  return _params.value(name);
}

QHash<QString, QVariant> Viewer::getParams() const {
  return _params;
}

void Viewer::clearParams() {
  _params.clear();
  emit paramsChanged();
}

void Viewer::addShortcut(const QString &keys, const luabind::object &fn) {
  if (luabind::type(fn) == LUA_TFUNCTION) {
    _cb_shortcuts->insert(keys, std::make_shared<luabind::object>(fn));
  }
}

void Viewer::removeShortcut(const QString &keys) {
  _cb_shortcuts->remove(keys);
}

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
  // XXX updateGLViewer();
}

void Viewer::animate() {
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

btScalar Viewer::getGLAmbientPercent() const { return _gl_ambient.length(); }

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
  return _gl_model_ambient.length();
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
  QString renderResolution =
      _settings->value("gui/renderResolution", "view size").toString();

  qDebug() << "renderResolution: " << renderResolution;

  int renderWidth, renderHeight;

  if (renderResolution.isEmpty() || renderResolution == "view size") {
    renderWidth = geometry().width();
    renderHeight = geometry().height();
  } else if (renderResolution.contains("x")) {
    QRegExp rx("(\\d+)");
    QString str = renderResolution;
    QStringList list;
    int pos = 0;

    while ((pos = rx.indexIn(str, pos)) != -1) {
      list << rx.cap(1);
      pos += rx.matchedLength();
    }
    renderWidth = list.at(0).toInt();
    renderHeight = list.at(1).toInt();
  } else {
    renderWidth = geometry().width();
    renderHeight = geometry().height();
  }

  savePOV(true);

  //    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
  //    for (int i = 0; i < env.toStringList().length(); i++) {
  //        qDebug() << env.toStringList().at(i);
  //    }

  QStringList args;

  QString sceneName;
  if (!_scriptName.isEmpty()) {
    QFileInfo fi(_scriptName);
    sceneName = fi.completeBaseName();
  } else {
    sceneName = "no_name";
  }

  QString cache =
      QStandardPaths::writableLocation(QStandardPaths::CacheLocation);

  QString defaultPovrayExe;
  QString defaultIncludes;

  QString pwd = startupWorkingDir();

#ifdef Q_OS_WIN
  defaultPovrayExe = QString("C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe");
  defaultIncludes  = QString("+L%1 +L%2\\includes").arg(cache, pwd);
#else
  defaultPovrayExe = QString("/usr/bin/povray");
  defaultIncludes  = QString("+L%1 +L%2/includes").arg(cache, pwd);
#endif

  QString systemPovExe = QStandardPaths::findExecutable(defaultPovrayExe);
  if (systemPovExe.isEmpty()) systemPovExe = "POV-Ray not found!";

  QString defaultPreview = QString("%1 -c +d -A +p +Q11 +GA -CC +FN10").arg(defaultIncludes);

  QString povray = _settings->value("povray/executable", systemPovExe).toString();
  QString opts =   _settings->value("povray/preview", defaultPreview).toString();

  args << opts.split(" ");

  args << QString("+W%1").arg(renderWidth);
  args << QString("+H%1").arg(renderHeight);

  QString desktop =
      QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
  QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd-hhmmss");
  QString fn = QString("%1").arg(_frameNum, 5, 10, QChar('0'));

  //// ~/Desktop/bpp-timestamp.png
  // QString png = QString("%1/bpp-%2.png").arg(desktop, timestamp);
  //// ~/Desktop/bpp-timestamp-sceneName-frameNumber.png
  QString png = QString("%1%2bpp-%3-%4-%5.png")
                    .arg(desktop, QDir::separator(), timestamp, sceneName, fn);

  args << "+F"; // turn output file on
  args << QString("+O%1").arg(png);

  args << QString("+K%1").arg(_frameNum); // pov clock is the frame number

  args << sceneName + ".pov";

  if(!povargs.isEmpty()) {
    args << povargs;
  }

  qDebug() << "executing " << povray << args;

  QDir dir(startupWorkingDir());

  QString defaultExportPath = QString("%1%2%3").arg(startupWorkingDir(), QDir::separator(), "export");

  QString exportDir = _settings->value("povray/export", defaultExportPath).toString();
  QString sceneDir =
      dir.absoluteFilePath(exportDir + QDir::separator() + sceneName);
  qDebug() << "exportDir: " << exportDir;
  qDebug() << "sceneDir: " << sceneDir;

#if USE_VFE
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
    QRegExp exitSwitch("\\s*/EXIT\\s*", Qt::CaseInsensitive);
    vfeArgs[0].replace(exitSwitch, " ");
    startVfeQuickRender(sceneName, sceneDir, vfeArgs);
    return;
  }
#endif // USE_VFE

  // Deliberately parentless: a QProcess still running when its parent is
  // destroyed gets kill()ed (and waited on) from within ~QProcess(), which
  // both kills povray out from under the user and crashes bpp by invoking
  // the finished-signal lambda below while this Viewer is mid-teardown. With
  // no parent, closing bpp neither touches this QProcess nor the povray
  // process it wraps; on a normal, non-crashing exit it simply outlives us.
  QProcess *p = new QProcess();
  p->setProgram(povray);
  p->setArguments(args);
  p->setWorkingDirectory(sceneDir);
  p->setProcessChannelMode(QProcess::MergedChannels);

  connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
          this, [this, p](int exitCode, QProcess::ExitStatus exitStatus) {
            if (exitCode != 0 || exitStatus == QProcess::CrashExit) {
              emitScriptOutput(
                  QString("POV-Ray failed (exit code %1):\n%2")
                      .arg(exitCode)
                      .arg(QString::fromLocal8Bit(p->readAll())));
            }
            p->deleteLater();
          });
  connect(p, &QProcess::errorOccurred, this,
          [this, p](QProcess::ProcessError) {
            if (p->error() == QProcess::FailedToStart) {
              emitScriptOutput(
                  QString("POV-Ray failed to start: %1").arg(p->errorString()));
              p->deleteLater();
            }
          });

  p->start();
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
  QStringList vfeIncludeCandidates;
  vfeIncludeCandidates << QDir(startupWorkingDir()).absoluteFilePath("../povray/distribution/include");
  // applicationDirPath() is bpp.exe's own directory (bpp/release or
  // bpp/debug), so povray/ as a sibling checkout of bpp/ needs two levels
  // up, not one -- this candidate only exists to cover launches where the
  // CWD isn't the bpp repo root (e.g. double-clicking the exe), so getting
  // its relative path wrong silently defeats the whole fallback.
  vfeIncludeCandidates << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../povray/distribution/include");
  for (const QString &candidate : vfeIncludeCandidates) {
    if (QDir(candidate).exists()) {
      opts.AddLibraryPath(QDir(candidate).absolutePath().toStdString());
      break;
    }
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
