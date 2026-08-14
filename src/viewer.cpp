#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "viewer.h"
#include "prefs.h"

#include "appenv.h"

#include <memory>

#include <QColor>
#include <QMessageBox>
#include <QTextCodec>

#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>

#include "lua_bullet.h"

#include "glutils.h"

#ifdef HAS_LUA_QT
#include "lua_register.h"
#endif

#include "objects/cone.h"
#include "objects/cube.h"
#include "objects/cylinder.h"
#include "objects/object.h"
#include "objects/objects.h"
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

#include <boost/exception/all.hpp>
#include <boost/exception/info.hpp>
#include <boost/throw_exception.hpp>

#include <cstdlib>
#include <cmath>

#if defined(Q_OS_LINUX)
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

using stack_info = boost::error_info<struct tag_stack_str, std::string>;

using namespace std;

// Forwards Bullet's constraint debug-draw geometry (btDynamicsWorld::debugDrawConstraint())
// to immediate-mode OpenGL lines. Only drawLine() is used for constraint visualization.
class GLDebugDrawer : public btIDebugDraw {
public:
  void drawLine(const btVector3 &from, const btVector3 &to,
                const btVector3 &color) override {
    glColor3f(color.x(), color.y(), color.z());
    glBegin(GL_LINES);
    glVertex3d(from.x(), from.y(), from.z());
    glVertex3d(to.x(), to.y(), to.z());
    glEnd();
  }

  void drawContactPoint(const btVector3 &, const btVector3 &, btScalar, int,
                        const btVector3 &) override {}
  void reportErrorWarning(const char *warningString) override {
    qWarning() << warningString;
  }
  void draw3dText(const btVector3 &, const char *) override {}
  void setDebugMode(int mode) override { _debugMode = mode; }
  int getDebugMode() const override { return _debugMode; }

private:
  int _debugMode = 0;
};

std::ostream &operator<<(std::ostream &ostream, const Viewer &v) {
  ostream << v.toString().toUtf8().data();
  return ostream;
}

// luabind's comparison policy needs an operator== reachable via ADL for
// every class registered with it (see the identity-operator comment in
// lua_bullet.cpp for why this matters). Viewer/JoystickInfo have no natural
// value equality, so fall back to identity; QColor already has a real
// operator== from Qt, and SpaceNavigator::Axes is a plain field struct.
bool operator==(const Viewer &a, const Viewer &b) { return &a == &b; }

bool operator==(const JoystickInfo &a, const JoystickInfo &b) {
  return &a == &b;
}

bool operator==(const SpaceNavigator::Axes &a, const SpaceNavigator::Axes &b) {
  return a.x == b.x && a.y == b.y && a.z == b.z && a.rx == b.rx &&
         a.ry == b.ry && a.rz == b.rz;
}

std::ostream &operator<<(std::ostream &ostream, const QString &s) {
  ostream << s.toUtf8().data();
  return ostream;
}

std::ostream &operator<<(std::ostream &ostream, const QColor &c) {
  ostream << "QColor(\"" << c.name().toUtf8().data() << "\")";
  return ostream;
}

std::ostream &operator<<(std::ostream &ostream, const JoystickInfo &ji) {
  Q_UNUSED(ji)
  ostream << "JoystickInfo()"; // XXX
  return ostream;
}

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
           .def("add", (void(Viewer::*)(Object *)) & Viewer::addObject,
                adopt(_2))
           .def("remove",
                (Object * (Viewer::*)(Object *)) &
                    Viewer::removeObject)
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
            .def("addParam", (void(Viewer::*)(const QString &, const QVariant &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const QVariant &, const QString &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const btScalar &, const btScalar &, const btScalar &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const btScalar &, const btScalar &, const btScalar &, const btScalar &)) & Viewer::addParam)
            .def("addParam", (void(Viewer::*)(const QString &, const btScalar &, const btScalar &, const btScalar &, const btScalar &, const QString &)) & Viewer::addParam)
            .def("getParam", &Viewer::getParam)
            .def("getParams", &Viewer::getParams)
            .def("getTime", &Viewer::getTime)
            .def("savePrefs", &Viewer::setPrefs)
           .def("loadPrefs", &Viewer::getPrefs)
           .def("clearDebugText", &Viewer::clearDebugText)
           .def("setHelpText", &Viewer::setHelpText)

           .def("quickRender",
                (void(Viewer::*)(QString povargs)) & Viewer::onQuickRender)

           .property("cam", &Viewer::getCamera, &Viewer::setCamera)

           .property("gravity", &Viewer::getGravity, &Viewer::setGravity)

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

           // http://bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
           .property("timeStep", &Viewer::getTimeStep, &Viewer::setTimeStep)
           .property("maxSubSteps", &Viewer::getMaxSubSteps,
                     &Viewer::setMaxSubSteps)
           .property("fixedTimeStep", &Viewer::getFixedTimeStep,
                     &Viewer::setFixedTimeStep)

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

Object *Viewer::removeObject(Object *o) {
  if (o == nullptr)
    return nullptr;

  if (o->body != nullptr)
    dynamicsWorld->removeRigidBody(o->body);

  SoftBody *sb = dynamic_cast<SoftBody *>(o);
  if (sb != nullptr && sb->getSoftBody() != nullptr)
    dynamicsWorld->removeSoftBody(sb->getSoftBody());

  _objects->remove(o);
  o->setParent(0);

  return o;
}

void Viewer::setTau(btScalar tau) {
  dynamicsWorld->getSolverInfo().m_tau = tau;
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

    Object *oa = ownerOf(manifold->getBody0());
    Object *ob = ownerOf(manifold->getBody1());

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

void report_errors(lua_State *L, int status) {
  if (status != 0) {
    std::cerr << "-- " << lua_tostring(L, -1) << "\n";
    lua_pop(L, 1); // remove error message
  }
}

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
      o->body->getAabb(oaabbmin, oaabbmax);

      if ("Plane" == o->toString()) {
        btScalar s = ((Plane *)o)->getSize();
        oaabbmin[0] = -s;
        oaabbmin[1] = -s;
        oaabbmin[2] = -s;

        oaabbmax[0] = s;
        oaabbmax[1] = s;
        oaabbmax[2] = s;
      }

      if (isfinite(o->getPosition().x()) && isfinite(o->getPosition().y()) &&
          isfinite(o->getPosition().z())) {
        oaabbmin -= o->getPosition();
        oaabbmax += o->getPosition();
      }

      for (int i = 0; i < 3; ++i) {
        aabb[i] = qMin(aabb[i], oaabbmin[i]);
        aabb[3 + i] = qMax(aabb[3 + i], oaabbmax[i]);
      }
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

void Viewer::keyPressEvent(QKeyEvent *e) {
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
  default:
    QGLViewer::keyPressEvent(e);
  }
}

void Viewer::mousePressEvent(QMouseEvent *e) {
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

  if (o->body != nullptr) {
    if (!_deactivation) {
      o->body->setActivationState(DISABLE_DEACTIVATION);
    }
    dynamicsWorld->addRigidBody(o->body, type, mask);
  }

  SoftBody *sb = dynamic_cast<SoftBody *>(o);
  if (sb != nullptr && sb->getSoftBody() != nullptr)
    dynamicsWorld->addSoftBody(sb->getSoftBody(), type, mask);
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

btScalar Viewer::getTime() const { return _wallTimer.elapsed() / 1000.0; }

Viewer::Viewer(QWidget *parent, QSettings *settings, bool savePOV)
    : QGLViewer() {
  Q_UNUSED(parent);

  _settings = settings;

  _wallTimer.start();

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
  dispatcher = new btCollisionDispatcher(collisionCfg);
  solver = new btSequentialImpulseConstraintSolver();

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

  btCollisionDispatcher *dispatcher_ptr = dispatcher;
  btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher_ptr);

  _frameNum = 1;
  _firstFrame = 1;

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
    _cb_onParamChanged = luabind::object();
    _cb_onSpaceNavigator = luabind::object();

    if (_cb_shortcuts) {
      for (auto it = _cb_shortcuts->begin(); it != _cb_shortcuts->end(); ++it) {
        it->reset();
      }
      _cb_shortcuts->clear();
    }

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

    // Stop Lua GC to prevent collection of Bullet Physics objects (btRigidBody,
    // btGImpactMeshShape, btTriangleMesh, etc.) that C++ holds raw pointers to.
    // Lua's unique_ptr holders would delete these objects, leaving C++ with
    // dangling pointers. GC will only run during lua_close() after we release
    // all object ownership.
    lua_gc(L, LUA_GCSTOP, 0);

    // register all bpp classes
    LuaBullet::luaBind(L);

    Cam::luaBind(L);
    Object::luaBind(L);
    Objects::luaBind(L);
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

  // After script execution, Lua GC is stopped (stopped above after luaL_openlibs).
  // This prevents Lua from garbage-collecting Bullet Physics objects (btRigidBody,
  // btGImpactMeshShape, etc.) that C++ holds raw pointers to via Object properties.
  // These objects would be collected by Lua GC when local Lua variables go out of
  // scope, leaving C++ with dangling pointers.

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

void Viewer::clear() {
  // qDebug() << "Viewer::clear() objects: " << _objects->size();

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
  dispatcher = new btCollisionDispatcher(collisionCfg);
  solver = new btSequentialImpulseConstraintSolver();

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
  _cb_onSpaceNavigator = luabind::object();
  _cb_onParamChanged = luabind::object();

  // Clear shortcuts BEFORE closing Lua state.
  // The shared_ptr<luabind::object> destructors call luaL_unref.
  if (_cb_shortcuts) {
    _cb_shortcuts->clear();
    delete _cb_shortcuts;
    _cb_shortcuts = nullptr;
  }

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

  computeBoundingBox();

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
  drawSceneInternal(0);

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

  mutex.unlock();
}

void Viewer::drawSceneInternal(int pass) {
  Q_UNUSED(pass)
  // btScalar m[16];
  btMatrix3x3 rot;
  rot.setIdentity();

  btVector3 minaabb(0, 0, 0), maxaabb(0, 0, 0);
  dynamicsWorld->getBroadphase()->getBroadphaseAabb(minaabb, maxaabb);

  //    minaabb-=btVector3(BT_LARGE_FLOAT,BT_LARGE_FLOAT,BT_LARGE_FLOAT);
  //    maxaabb+=btVector3(BT_LARGE_FLOAT,BT_LARGE_FLOAT,BT_LARGE_FLOAT);

  foreach (Object *o, *_objects) {
    // SoftBody has no rigid body/motion-state, so Object::render() (which
    // requires one) would silently skip it. Render it directly instead.
    SoftBody *sb = dynamic_cast<SoftBody *>(o);
    if (sb != nullptr) {
      sb->renderWorld();
    } else {
      o->render(minaabb, maxaabb);
    }
  }

  drawConstraints();
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

  if (!pwdDir.exists(exportDir)) {
    if (!pwdDir.mkpath(exportDir)) {
      QMessageBox msgBox;
      msgBox.setText(tr("Unable to create directory %1.").arg(exportDir));
      msgBox.exec();
      return;
    }
  }

  QString sceneDir =
      pwdDir.absoluteFilePath(exportDir + QDir::separator() + sceneName);

  qDebug() << "sceneDir: " << sceneDir;

  if (!pwdDir.exists(sceneDir)) {
    if (!pwdDir.mkpath(sceneDir)) {
      QMessageBox msgBox;
      msgBox.setText(tr("Unable to create directory %1.").arg(sceneDir));
      msgBox.exec();
      return;
    }
  }

  QString fn = QString("%1").arg(_frameNum, 5, 10, QChar('0'));
  QString file = QString("%1%2%3.inc").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(fn);
  QString fileMain = QString("%1%2%3.pov").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));
  QString fileINI = QString("%1%2%3.ini").arg(qPrintable(sceneDir)).arg(QDir::separator()).arg(qPrintable(sceneName));

  qDebug() << "POV-Ray file: " << file;

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

  _fileINI->close();

  _fileMain = new QFile(fileMain, this);
  _fileMain->open(QFile::WriteOnly | QFile::Truncate);

  QTextStream smain(_fileMain);
  smain << "// Main POV file generated by Bullet Physics Playground" << "\n";
  smain << QString("// %1 by %2").arg(timestamp, name) << "\n"
        << "\n";

  smain << "#version 3.7;" << "\n"
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

      *_stream << "  angle " << 180.0 * camera()->horizontalFieldOfView() / M_PI
               << "\n";

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
  QMutexLocker locker(&mutex);

  if (_has_exception || _parsing) {
    return;
  }

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

void Viewer::setPrefs(QString key, QString value) {
  _settings->beginGroup("lua");
  _settings->setValue(key, value);
  _settings->endGroup();
}

QString Viewer::getPrefs(QString key, QString defaultValue) const {
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

  QProcess *p = new QProcess(this);
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
