// Viewer's Lua bindings: the Viewer class as scripts see it (v), and the
// small classes its methods hand them (QColor, QString, JoystickInfo,
// SpaceNavigatorAxes), with the comparison and stream operators luabind
// needs for them.

#include "viewer.h"

#include <QColor>
#include <QString>

#include <ostream>

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

#include "lua_converters.h"

// QColor's red()/green()/blue() getters are noexcept in Qt6, which old
// Boost (used by luabind) cannot decompose. Use non-noexcept wrappers.
int qcolor_r(QColor const &c) { return c.red(); }
int qcolor_g(QColor const &c) { return c.green(); }
int qcolor_b(QColor const &c) { return c.blue(); }
void qcolor_set_r(QColor &c, int v) { c.setRed(v); }
void qcolor_set_g(QColor &c, int v) { c.setGreen(v); }
void qcolor_set_b(QColor &c, int v) { c.setBlue(v); }

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
 * @brief Writes a JoystickInfo's axes and buttons to a stream, as
 *        @c JoystickInfo(axes={0, -120}, buttons={0, 1}).
 * @param ostream The stream to write to.
 * @param ji      The report.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const JoystickInfo &ji) {
  ostream << "JoystickInfo(axes={";
  const QList<int> axes = ji.getAxisValues();
  for (int i = 0; i < axes.size(); i++)
    ostream << (i ? ", " : "") << axes[i];
  ostream << "}, buttons={";
  const QList<bool> buttons = ji.getButtonValues();
  for (int i = 0; i < buttons.size(); i++)
    ostream << (i ? ", " : "") << (buttons[i] ? 1 : 0);
  ostream << "})";
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
           .def("setSolver", &Viewer::setSolver)
           .def("setSolverInfo", &Viewer::setSolverInfo)
           .def("setThreads", &Viewer::setThreads)
           .def("attach", &Viewer::attach)
           .def("detach", &Viewer::detach)
           .property("solver", &Viewer::solverKind)
           .property("solverFallbacks", &Viewer::solverFallbacks)
           .def("eachContact",
                (void(Viewer::*)(const luabind::object &)) &
                    Viewer::eachContact)
           .def("rayTest",
                (btScalar(Viewer::*)(const btVector3 &, const btVector3 &)) &
                    Viewer::rayTest)
           .def("rayTest",
                (btScalar(Viewer::*)(const btVector3 &, const btVector3 &,
                                     const luabind::object &)) &
                    Viewer::rayTest)
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
            .def("showParams", &Viewer::showParams)
            .def("getTime", &Viewer::getTime)
            .def("stepSimulation", &Viewer::stepSimulation)
            .def("newWorld", &Viewer::newWorld)
            .def("useWorld", &Viewer::useWorld)
            .def("currentWorld", &Viewer::currentWorld)
            .def("placeWorld", &Viewer::placeWorld)
            .def("savePrefs", &Viewer::setPrefs)
           .def("loadPrefs", &Viewer::getPrefs)
           .def("clearDebugText", &Viewer::clearDebugText)
           .def("setHelpText", &Viewer::setHelpText)
           .property("statusText", &Viewer::getStatusText, &Viewer::setStatusText)

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

           // (the user's: a script's assignment is noted and ignored)
           .property("shadows", &Viewer::shadows,
                     &Viewer::setShadowsFromScript)
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
           .def("lastFrameDrawing", &Viewer::lastFrameDrawing)
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
           // continuous synthesised voices, e.g. rotors (also no-ops
           // without audio)
           .def("setTone", (void(Viewer::*)(int, double, double)) & Viewer::setTone)
           .def("setTone", (void(Viewer::*)(int, double, double, double)) & Viewer::setTone)
           .def("setToneTimbre", &Viewer::setToneTimbre)
           .def("silenceTones", &Viewer::silenceTones)
           // streamed music (no-ops returning false/0 without audio or
           // headless), see viewermedia.cpp
           .def("loadMusic", &Viewer::loadMusic)
           .def("playMusic", (bool(Viewer::*)()) & Viewer::playMusic)
           .def("playMusic", (bool(Viewer::*)(double)) & Viewer::playMusic)
           .def("stopMusic", &Viewer::stopMusic)
           .def("pauseMusic", &Viewer::pauseMusic)
           .def("resumeMusic", &Viewer::resumeMusic)
           .def("fadeMusicTo", &Viewer::fadeMusicTo)
           .def("musicPosition", &Viewer::musicPosition)
           .def("musicPlaying", &Viewer::musicPlaying)
           // a question for the visitor, and remembered answers
           .def("ask", (int(Viewer::*)(const QString &, const QString &,
                                       const luabind::object &)) &
                           Viewer::ask)
           .def("ask", (int(Viewer::*)(const QString &, const QString &,
                                       const luabind::object &,
                                       const QString &)) &
                           Viewer::ask)
           .def("remembered", &Viewer::remembered)
           .def("forget", &Viewer::forget)
           // background downloads
           .def("download", &Viewer::download)
           .def("downloadState", &Viewer::downloadState)
           .def("dataDir", &Viewer::dataDir)

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
           .property("glLight0Color", &Viewer::getGLLight0Color,
                     &Viewer::setGLLight0Color)
           .property("glLight1Color", &Viewer::getGLLight1Color,
                     &Viewer::setGLLight1Color)

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
                .property("r", &qcolor_r, &qcolor_set_r)
                .property("g", &qcolor_g, &qcolor_set_g)
                .property("b", &qcolor_b, &qcolor_set_b)
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
