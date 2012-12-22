#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "viewer.h"

#include <QColor>

#include "lua_register.h"

#include "objects/object.h"
#include "objects/objects.h"
#include "objects/plane.h"
#include "objects/cube.h"
#include "objects/sphere.h"
#include "objects/cylinder.h"
#include "objects/mesh3ds.h"

#include "objects/palette.h"

#include "objects/cam.h"

#ifdef HAS_QEXTSERIAL
#include "qserial.h"
#endif

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>

using namespace std;

std::ostream& operator<<(std::ostream& ostream, const Viewer& v) {
  ostream << v.toString().toAscii().data();
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const btVector3& v) {
  ostream << "btVector3(" << v.x() << ", " << v.y() << ", " << v.z() << ")";
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const QString& s) {
  ostream << s.toAscii().data();
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const QColor& c) {
  ostream << "QColor(\"" << c.name().toAscii().data() << "\")";
  return ostream;
}

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

QString Viewer::toString() const {
  return QString("Viewer");
}

void Viewer::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
  [
   class_<Viewer>("Viewer")
   .def(constructor<>())
   .def("add", (void(Viewer::*)(Object *))&Viewer::addObject, adopt(_2))
   .def("remove", (void(Viewer::*)(Object *))&Viewer::removeObject, adopt(luabind::result))
   .def("addConstraint", (void(Viewer::*)(btTypedConstraint *))&Viewer::addConstraint, adopt(_2))
   .def("removeConstraint", (void(Viewer::*)(btTypedConstraint *))&Viewer::removeConstraint, adopt(_2))
   .def("createVehicleRaycaster", &Viewer::createVehicleRaycaster, adopt(luabind::result))
   .def("addVehicle", (void(Viewer::*)(btRaycastVehicle *))&Viewer::addVehicle, adopt(_2))
   .def("addShortcut", &Viewer::addShortcut, adopt(luabind::result))
   .def("removeShortcut", &Viewer::removeShortcut, adopt(luabind::result))
   .def("cam", (void(Viewer::*)(Cam *))&Viewer::setCamera, adopt(_2))
   .def("preDraw", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPreDraw, adopt(luabind::result))
   .def("postDraw", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPostDraw, adopt(luabind::result))
   .def("preSim", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPreSim, adopt(luabind::result))
   .def("postSim", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPostSim, adopt(luabind::result))
   .def("onCommand", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBOnCommand, adopt(luabind::result))
   .def(tostring(const_self))
  ];

  module(s)
	[
	 class_<btVector3>( "btVector3" )
	 .def(constructor<>())
	 .def(constructor<btScalar, btScalar, btScalar>())
   .def(const_self + const_self)
   .def(const_self - const_self)
   .def(const_self * other<btScalar>())
   .def(const_self / other<btScalar>())
   .def(const_self == const_self)
   .property("x", &btVector3::getX, &btVector3::setX)
	 .property("y", &btVector3::getY, &btVector3::setY)
	 .property("z", &btVector3::getZ, &btVector3::setZ)
	 .def( "getX", &btVector3::getX )
	 .def( "getY", &btVector3::getY )
	 .def( "getZ", &btVector3::getZ )
	 .def( "setX", &btVector3::setX )
	 .def( "setY", &btVector3::setY )
	 .def( "setZ", &btVector3::setZ )
   .def( "absolute", &btVector3::absolute )
   .def("angle", &btVector3::angle )
   .def("closestAxis", &btVector3::closestAxis )
   .def("cross", &btVector3::cross )
   .def("distance", &btVector3::distance )
   .def("distance2", &btVector3::distance2 )
   .def("dot", &btVector3::dot )
   .def("furthestAxis", &btVector3::furthestAxis )
   .def("fuzzyZero", &btVector3::fuzzyZero )
   .def("isZero", &btVector3::isZero )
   .def("length", &btVector3::length )
   .def("length2", &btVector3::length2 )
   .def("lerp", &btVector3::lerp )
   .def("maxAxis", &btVector3::maxAxis )
   .def("minAxis", &btVector3::minAxis )
   .def("normalize", &btVector3::normalize )
   .def("normalized", &btVector3::normalized )
   .def("rotate", &btVector3::rotate )
   .def("setZero", &btVector3::setZero )
   .def("triple", &btVector3::triple )
   .def(tostring(const_self))
   ];

  module(s)
	[
	 class_<btQuaternion>("btQuaternion")
	 .def(constructor<>())
   .def(constructor<const btVector3&, btScalar>())
	 .def(constructor<btScalar, btScalar, btScalar, btScalar>())
   .def("angle", &btQuaternion::angle )
   .def("dot", &btQuaternion::dot )
   .def("farthest", &btQuaternion::farthest )
   .def("getAngle", &btQuaternion::getAngle )
   .def("getAxis", &btQuaternion::getAxis )
   .def("getIdentity", &btQuaternion::getIdentity )
   .def("getW", &btQuaternion::getW )
   .def("getX", &btQuaternion::getX )
   .def("getY", &btQuaternion::getY )
   .def("getZ", &btQuaternion::getZ )
   .def("inverse", &btQuaternion::inverse )
   .def("length", &btQuaternion::length )
   .def("length2", &btQuaternion::length2 )
   .def("nearest", &btQuaternion::nearest )
   .def("normalize", &btQuaternion::normalize )
   .def("normalized", &btQuaternion::normalized )
   .def("setEuler", &btQuaternion::setEuler )
   .def("setEulerZYX", &btQuaternion::setEulerZYX )
   .def("setMax", &btQuaternion::setMax )
   .def("setMin", &btQuaternion::setMin )
   .def("setRotation", &btQuaternion::setRotation )
   .def("setW", &btQuaternion::setW )
   .def("setX", &btQuaternion::setX )
   .def("setY", &btQuaternion::setY )
   .def("setZ", &btQuaternion::setZ )
   .def("slerp", &btQuaternion::slerp )
   .def("w", &btQuaternion::w )
   .def("x", &btQuaternion::x )
   .def("y", &btQuaternion::y )
   .def("z", &btQuaternion::z )
   ];

  module(s)
  [
   class_<btRigidBody>("btRigidBody")
   ];

  module(s)
	[
	 class_<btTransform>("btTransform")
	 .def(constructor<>())
   .def(constructor<const btQuaternion&, const btVector3&>())
   .def("getIdentity", &btTransform::getIdentity )
   .def("getOpenGLMatrix", &btTransform::getOpenGLMatrix )
   .def("getRotation", &btTransform::getRotation )
   .def("inverse", &btTransform::inverse )
   .def("inverseTimes", &btTransform::inverseTimes )
   .def("invXform", &btTransform::invXform )
   .def("mult", &btTransform::mult )
   .def("setBasis", &btTransform::setBasis )
   .def("setFromOpenGLMatrix", &btTransform::setFromOpenGLMatrix )
   .def("setIdentity", &btTransform::setIdentity )
   .def("setOrigin", &btTransform::setOrigin )
   .def("setRotation", &btTransform::setRotation )
   ];

  module(s)
  [
   class_<btTypedConstraint>("btTypedConstraint")
  ];

  module(s)
  [
   class_<btPoint2PointConstraint,btTypedConstraint>("btPoint2PointConstraint")
   .def(constructor<btRigidBody&, btRigidBody&, const btVector3&, const btVector3&>())
   .def("setParam", &btPoint2PointConstraint::setParam)
   ];
   
  module(s)
  [
   class_<btHingeConstraint,btTypedConstraint>("btHingeConstraint")
   .def(constructor<btRigidBody&, btRigidBody&, const btVector3&, const btVector3&, const btVector3&, const btVector3&>())
   .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&>())
   .def("setAxis", &btHingeConstraint::setAxis)
   .def("setLimit", &btHingeConstraint::setLimit)
   .def("setParam", &btHingeConstraint::setParam)
   .def("enableAngularMotor", &btHingeConstraint::enableAngularMotor)
   ];

  module(s)
  [
   class_<btSliderConstraint,btTypedConstraint>("btSliderConstraint")
   .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&, bool>())
   .def("setLowerLinLimit", &btSliderConstraint::setLowerLinLimit)
   .def("setUpperLinLimit", &btSliderConstraint::setUpperLinLimit)
   .def("setLowerAngLimit", &btSliderConstraint::setLowerAngLimit)
   .def("setUpperAngLimit", &btSliderConstraint::setUpperAngLimit)
   .def("setSoftnessDirLin", &btSliderConstraint::setSoftnessDirLin)
   .def("setRestitutionDirLin", &btSliderConstraint::setRestitutionDirLin)
   .def("setDampingDirLin", &btSliderConstraint::setDampingDirLin)
   .def("setSoftnessDirAng", &btSliderConstraint::setSoftnessDirAng)
   .def("setRestitutionDirAng", &btSliderConstraint::setRestitutionDirAng)
   .def("setDampingDirAng", &btSliderConstraint::setDampingDirAng)
   .def("setSoftnessLimLin", &btSliderConstraint::setSoftnessLimLin)
   .def("setRestitutionLimLin", &btSliderConstraint::setRestitutionLimLin)
   .def("setDampingLimLin", &btSliderConstraint::setDampingLimLin)
   .def("setSoftnessLimAng", &btSliderConstraint::setSoftnessLimAng)
   .def("setRestitutionLimAng", &btSliderConstraint::setRestitutionLimAng)
   .def("setDampingLimAng", &btSliderConstraint::setDampingLimAng)
   .def("setSoftnessOrthoLin", &btSliderConstraint::setSoftnessOrthoLin)
   .def("setRestitutionOrthoLin", &btSliderConstraint::setRestitutionOrthoLin)
   .def("setDampingOrthoLin", &btSliderConstraint::setDampingOrthoLin)
   .def("setSoftnessOrthoAng", &btSliderConstraint::setSoftnessOrthoAng)
   .def("setRestitutionOrthoAng", &btSliderConstraint::setRestitutionOrthoAng)
   .def("setDampingOrthoAng", &btSliderConstraint::setDampingOrthoAng)
   .def("setParam", &btSliderConstraint::setParam)
   ];
   
  module(s)
  [
   class_<btGeneric6DofSpringConstraint,btTypedConstraint>("btGeneric6DofSpringConstraint")
   .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&, bool>())
   .def("enableSpring", &btGeneric6DofSpringConstraint::enableSpring)
   .def("setStiffness", &btGeneric6DofSpringConstraint::setStiffness)
   .def("setDamping", &btGeneric6DofSpringConstraint::setDamping)
   //.def("setEquilibriumPoint", &btGeneric6DofSpringConstraint::setEquilibriumPoint) // FIX ME: compilation error
   .def("setAxis", &btGeneric6DofSpringConstraint::setAxis)
   ];   

  module(s)
  [
   class_<btUniversalConstraint,btTypedConstraint>("btUniversalConstraint")
   .def(constructor<btRigidBody&, btRigidBody&, const btVector3&, const btVector3&, const btVector3&>())
   .def("setAxis", &btUniversalConstraint::setAxis)
   .def("setUpperLimit", &btHingeConstraint::setLimit)
   .def("setLowerLimit", &btHingeConstraint::setParam)
   ];

  module(s)
  [
   class_<btVehicleRaycaster>("btVehicleRaycaster")
  ];

  module(s)
  [
   class_<btDefaultVehicleRaycaster, btVehicleRaycaster>("btDefaultVehicleRaycaster")
  ];

  module(s)
  [
   class_<btRaycastVehicle::btVehicleTuning>("btVehicleTuning")
   .def(constructor<>())
   .def_readwrite("suspensionStiffness", &btRaycastVehicle::btVehicleTuning::m_suspensionStiffness)
   .def_readwrite("suspensionCompression", &btRaycastVehicle::btVehicleTuning::m_suspensionCompression)
   .def_readwrite("suspensionDamping", &btRaycastVehicle::btVehicleTuning::m_suspensionDamping)
   .def_readwrite("maxSuspensionTravelCm", &btRaycastVehicle::btVehicleTuning::m_maxSuspensionTravelCm)
   .def_readwrite("frictionSlip", &btRaycastVehicle::btVehicleTuning::m_frictionSlip)
   .def_readwrite("maxSuspensionForce", &btRaycastVehicle::btVehicleTuning::m_maxSuspensionForce)
  ];

  module(s)
  [
   class_<btRaycastVehicle>("btRaycastVehicle")
   .def(constructor<const btRaycastVehicle::btVehicleTuning&, btRigidBody*, btVehicleRaycaster*>())
  ];

  module(s)
	[
	 class_<QColor>("QColor")
	 .def(constructor<>())
	 .def(constructor<QString>())
	 .def(constructor<int, int, int>())
	 .def(constructor<int, int, int, int>())
	 .property("r", &QColor::red, &QColor::setRed)
	 .property("g", &QColor::green, &QColor::setGreen)
	 .property("b", &QColor::blue, &QColor::setBlue)
   .def(tostring(self))
	 ];

  module(s)
	[
	 class_<QString>("QString")
	 .def(constructor<>())
	 .def(constructor<const char *>())
     .def(tostring(self))
	 ];
}

void Viewer::addObject(Object* o) {
  addObject(o, o->getCol1(), o->getCol2()); 
  addConstraints(o->getConstraints());
}

void Viewer::removeObject(Object* o) {
  if (o->body != NULL)
    dynamicsWorld->removeRigidBody(o->body);

  _objects->remove(o);
}

void Viewer::addConstraint(btTypedConstraint *con) {
  dynamicsWorld->addConstraint(con, true);
  _constraints->insert(con);
}

void Viewer::removeConstraint(btTypedConstraint *con) {
  dynamicsWorld->removeConstraint(con);
  _constraints->remove(con);
}

void Viewer::addConstraints(QList<btTypedConstraint *> cons) {
  for (int i = 0; i < cons.size(); ++i) {
    addConstraint(cons[i]);
  }
}

btVehicleRaycaster* Viewer::createVehicleRaycaster() {
  return new btDefaultVehicleRaycaster(dynamicsWorld);
}

void Viewer::addVehicle(btRaycastVehicle *veh) {
  dynamicsWorld->addVehicle(veh);
  _raycast_vehicles->insert(veh);
}

void Viewer::luaBindInstance(lua_State *s) {
  using namespace luabind;

  globals(s)["v"] = this;
}

void report_errors(lua_State *L, int status)
{
  if ( status!=0 ) {
	std::cerr << "-- " << lua_tostring(L, -1) << std::endl;
    lua_pop(L, 1); // remove error message
  }
}

#define G 9.81f

using namespace qglviewer;

namespace {
void getAABB(QSet<Object *> *objects, btScalar aabb[6]) {
  btVector3 aabbMin, aabbMax;

  aabb[0] = -10; aabb[1] = -10; aabb[2] = -10;
  aabb[3] = 10; aabb[4] = 10; aabb[5] = 10;

  QSet<Object*>::iterator oi;
  for (oi = objects->begin(); oi != objects->end(); oi++) {
    Object *o = *oi;

	  if (o->toString() != QString("Plane")) {
      btVector3 oaabbmin, oaabbmax;
      o->body->getAabb(oaabbmin, oaabbmax);

      for (int i = 0; i < 3; ++i) {
        aabb[  i] = qMin(aabb[  i], oaabbmin[  i]);
        aabb[3+i] = qMax(aabb[3+i], oaabbmax[3+i]);
      }
	  }
  }
  // qDebug() << "getAABB()" << aabb[0] << aabb[1] << aabb[2] << aabb[3] << aabb[4] << aabb[5];
}
}

void Viewer::keyPressEvent(QKeyEvent *e) {
  int keyInt = e->key();
  Qt::Key key = static_cast<Qt::Key>(keyInt);

  if (key == Qt::Key_unknown) {
      qDebug() << "Unknown key from a macro probably";
      return;
  }

  // the user have clicked just and only the special keys Ctrl, Shift, Alt, Meta.
  if(key == Qt::Key_Control ||
      key == Qt::Key_Shift ||
      key == Qt::Key_Alt ||
      key == Qt::Key_Meta)
  {
      // qDebug() << "Single click of special key: Ctrl, Shift, Alt or Meta";
      // qDebug() << "New KeySequence:" << QKeySequence(keyInt).toString(QKeySequence::NativeText);
      // return;
  }

  // check for a combination of user clicks
  Qt::KeyboardModifiers modifiers = e->modifiers();
  QString keyText = e->text();
  // if the keyText is empty than it's a special key like F1, F5, ...
  //  qDebug() << "Pressed Key:" << keyText;

  QList<Qt::Key> modifiersList;
  if(modifiers & Qt::ShiftModifier)
      keyInt += Qt::SHIFT;
  if(modifiers & Qt::ControlModifier)
      keyInt += Qt::CTRL;
  if(modifiers & Qt::AltModifier)
      keyInt += Qt::ALT;
  if(modifiers & Qt::MetaModifier)
      keyInt += Qt::META;

  QString seq = QKeySequence(keyInt).toString(QKeySequence::NativeText);
  // qDebug() << "KeySequence:" << seq;

  if (_cb_shortcuts->contains(seq)) {
    try {
      luabind::call_function<void>(_cb_shortcuts->value(seq), _frameNum);
    } catch(const std::exception& ex){
      showLuaException(ex, QString("shortcut '%1' function").arg(seq));
    }

    return; // skip built in command if overridden by shortcut
  }

  switch (e->key()) {

  case Qt::Key_S :
    _simulate = !_simulate;
    emit simulationStateChanged(_simulate);
    break;
  case Qt::Key_P :
    _savePOV = !_savePOV;
    if(_savePOV){
      _firstFrame=_frameNum;
    }
    emit POVStateChanged(_savePOV);
    break;
  case Qt::Key_G :
    _savePNG = !_savePNG;
    emit PNGStateChanged(_savePNG);
    break;
  case Qt::Key_D :
    _deactivation = !_deactivation;
    emit deactivationStateChanged(_deactivation);
    break;
  case Qt::Key_R :
    parse(_scriptContent);
    break;
  case Qt::Key_C :
    resetCamView();
    break;
  default:
    QGLViewer::keyPressEvent(e);
  }
}

void Viewer::addObject(Object *o, int type, int mask) {
  _objects->insert(o);

  if (o->body != NULL) {
	if(!_deactivation){  
	  o->body->setActivationState(DISABLE_DEACTIVATION);
	}
	dynamicsWorld->addRigidBody(o->body, type, mask);
  }
}

void Viewer::addObjects(QList<Object *> ol, int type, int mask) {
  foreach (Object *o, ol) {
    addObject(o, type, mask);
  }
}

void Viewer::addObjects() {

}

Viewer::Viewer(QWidget *parent, bool savePNG, bool savePOV) : QGLViewer(parent)  {
  setAttribute(Qt::WA_DeleteOnClose);

  _objects = new QSet<Object *>();
  _constraints = new QSet<btTypedConstraint *>();
  _raycast_vehicles = new QSet<btRaycastVehicle *>();

  L = NULL;

  _savePNG = savePNG; _savePOV = savePOV; setSnapshotFormat("png");
  _simulate = false;
  _deactivation = true;

  collisionCfg = new btDefaultCollisionConfiguration();
  btBroadphaseInterface* broadphase = new btDbvtBroadphase();
  dynamicsWorld = new btDiscreteDynamicsWorld(new btCollisionDispatcher(collisionCfg), broadphase, new btSequentialImpulseConstraintSolver, collisionCfg);
  btCollisionDispatcher * dispatcher = static_cast<btCollisionDispatcher *>(dynamicsWorld ->getDispatcher());
  btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher);

  dynamicsWorld->setGravity(btVector3(0.0f, -G, 0.0f));

  _frameNum = 0;
  _firstFrame = 0;

  _cb_shortcuts = new QHash<QString, luabind::object>();
  
  loadPrefs();
  
  _cam=NULL;

  startAnimation();
}

void Viewer::close() {
  // qDebug() << "Viewer::close()";
  savePrefs();
  QGLViewer::close();
}

void Viewer::setCamera(Cam *cam) {
  _cam = cam;
  QGLViewer::setCamera( cam );
  // QGLViewer::setManipulatedFrame(cam->frame());
}

void Viewer::setSavePNG(bool png) {
  _savePNG = png;
}

void Viewer::setSavePOV(bool pov) {
  _savePOV = pov;
}

void Viewer::toggleSavePNG() {
  _savePNG = !_savePNG;
}

void Viewer::toggleSavePOV() {
  _savePOV = !_savePOV;
}

void Viewer::toggleDeactivation() {
  _deactivation = !_deactivation;
}

void Viewer::startSim() {
  _simulate = true;
}

void Viewer::stopSim() {
  _simulate = false;
}

void Viewer::restartSim() {
  parse(_scriptContent);
}

void Viewer::setScriptName(QString sn) {
  _scriptName = sn;	
}	

void Viewer::emitScriptOutput(const QString& out) {
  emit scriptHasOutput(out);
}

int Viewer::lua_print(lua_State* L) {

  Viewer* p = static_cast<Viewer*>(lua_touserdata(L, lua_upvalueindex(1)));

  if (p) {
	int n = lua_gettop(L);  /* number of arguments */
	
	int i;
	lua_getglobal(L, "tostring");
	for (i=1; i <= n; i++) {
	  const char *s;
	  lua_pushvalue(L, -1);  /* function to be called */
	  lua_pushvalue(L, i);   /* value to print */
	  lua_call(L, 1, 1);
	  s = lua_tostring(L, -1);  /* get result */
	  if (s == NULL)
		return luaL_error(L, LUA_QL("tostring") " must return a string to " LUA_QL("print"));
	  // if (i>1) p->emitScriptOutput(QString("\t"));
	  p->emitScriptOutput(QString(s));
	  lua_pop(L, 1);  /* pop result */
	}
	
	// p->emitScriptOutput(QString("\n"));
  } else {
	return luaL_error(L, "stack has no thread ref", "");
  }

  return 0;
}

bool Viewer::parse(QString txt) {
  emit scriptStopped();

  QMutexLocker locker(&mutex);
  
  _parsing = true;
  _has_exception = false;

  _scriptContent = txt;
	
  bool animStarted = animationIsStarted();

  if (animStarted) {
      stopAnimation();
  }

  emit scriptStarts();

  if (L != NULL) {
    clear();
    lua_gc(L, LUA_GCCOLLECT, 0); // collect garbage

    // invalidate function refs
    _cb_preDraw = luabind::object();
    _cb_postDraw = luabind::object();
    _cb_preSim = luabind::object();
    _cb_postSim = luabind::object();
    _cb_onCommand = luabind::object();

    lua_close(L);
  }
  
  // setup lua
  L = luaL_newstate();

  // open all standard Lua libs
  luaL_openlibs(L);

  // register non-object classes
  register_classes(L);

  // register all bpp classes
  Cam::luaBind(L);
  Object::luaBind(L);
  Objects::luaBind(L);
  Cube::luaBind(L);
  Cylinder::luaBind(L);
  Mesh3DS::luaBind(L);
  Palette::luaBind(L);
  Plane::luaBind(L);
  Sphere::luaBind(L);
  Viewer::luaBind(L);

#ifdef HAS_QEXTSERIAL
  QSerialPort::luaBind(L);
#endif

  luaBindInstance(L);

  lua_pushlightuserdata(L, (void*)this);
  lua_pushcclosure(L,  &Viewer::lua_print, 1);
  lua_setglobal(L, "print");

  int error = luaL_loadstring(L, txt.toAscii().constData())
	|| lua_pcall(L, 0, LUA_MULTRET, 0);

  if (error) {
	lua_error = tr("error: %1").arg(lua_tostring(L, -1));

	if (lua_error.contains(QRegExp(tr("stopping$")))) {
	  lua_error = tr("script stopped");
	  qDebug() << "lua run : script stopped";
	} else {
	  // qDebug() << QString("lua run : %1").arg(lua_error);
	  emit scriptHasOutput(lua_error);
	}
	
	lua_pop(L, 1);  /* pop error message from the stack */
  } else {
	lua_error = tr("ok");
  }

  // report_errors(L, error);
  // lua_close(L);

  _frameNum = 0; // reset frames counter
  _firstFrame = 0;

  if (animStarted) {
      startAnimation();
  }

  // qDebug() << "Viewer::parse() end";

  _parsing = false;

  return (error ? false : true);
}

void Viewer::clear() {
  // qDebug() << "Viewer::clear() objects: " << _objects->size();

  // remove all objects
  QSet<Object *>::const_iterator i = _objects->constBegin();
  while (i != _objects->constEnd()) {
    if ((*i)->body != NULL)
      dynamicsWorld->removeRigidBody((*i)->body);
    ++i;
  }

  _objects->clear();

  // remove all contact manifolds
  for (int i = dynamicsWorld->getNumCollisionObjects()-1; i>=0 ;i--) {
    btCollisionObject* obj = dynamicsWorld->getCollisionObjectArray()[i];

    btRigidBody* body = btRigidBody::upcast(obj);
    if (body && body->getMotionState()) {
      delete body->getMotionState();
    }

    dynamicsWorld->removeCollisionObject( obj );

    delete obj;
  }

  // remove all constraints
  QSet<btTypedConstraint *>::const_iterator it = _constraints->constBegin();
  while (it != _constraints->constEnd()) {
    dynamicsWorld->removeConstraint(*it);
    ++it;
  }

  _constraints->clear();
  _cb_shortcuts->clear();
}

void Viewer::resetCamView() {

    camera()->setPosition(_initialCameraPosition);
    camera()->setOrientation(_initialCameraOrientation);
    updateGL();

}

void Viewer::loadPrefs() {
  QGLViewer::restoreStateFromFile();
}

void Viewer::savePrefs() {
  // qDebug() << "Viewer::savePrefs()";
  QGLViewer::saveStateToFile();
}

void Viewer::openPovFile() {
  QString file;  	
  QString fileMain;  	
  QString fileINI;  	
  QDir sceneDir("export");

  QString sceneName;	
  if(!_scriptName.isEmpty()){
    sceneName=_scriptName;
  }else{
    sceneName="no_name.lua";
  }
  sceneDir.mkdir(qPrintable(sceneName));
  file.sprintf("export/%s/%s-%05d.inc", qPrintable(sceneName), qPrintable(sceneName), _frameNum);
  fileMain.sprintf("export/%s/%s.pov", qPrintable(sceneName), qPrintable(sceneName));
  fileINI.sprintf("export/%s/%s.ini", qPrintable(sceneName), qPrintable(sceneName));

  // qDebug() << "saving pov file:" << file;

  _fileINI = new QFile(fileINI);
  _fileINI->open(QFile::WriteOnly | QFile::Truncate);  
  _streamINI = new QTextStream(_fileINI);
  *_streamINI << "; Animation INI file generated by Bullet Physics Playground" << endl << endl;	
  *_streamINI << "Input_File_Name=" << sceneName << ".pov" << endl;
  *_streamINI << "Output_to_File=on" << endl;
  *_streamINI << "Pause_When_Done=off" << endl;
  *_streamINI << "Verbose=off" << endl;
  *_streamINI << "Display=on" << endl;
  *_streamINI << "+w720" << endl;
  *_streamINI << "+h480" << endl;
  *_streamINI << "+FN" << endl;
  *_streamINI << "+a +j0" << endl;
  *_streamINI << "+L../../includes" << endl << endl;
  *_streamINI << "Initial_Clock=" << _firstFrame << endl;
  *_streamINI << "Final_Clock=" << _frameNum << endl;
  *_streamINI << "Final_Frame=" << _frameNum << endl;  
  if (_fileINI != NULL) {
    _fileINI->close();
  }

  _fileMain = new QFile(fileMain);
  _fileMain->open(QFile::WriteOnly | QFile::Truncate);  
  _streamMain = new QTextStream(_fileMain);
  *_streamMain << "// Main POV file generated by Bullet Physics Playground" << endl << endl;	
  *_streamMain << "#include \"settings.inc\"" << endl << endl;
  *_streamMain << "#include concat(concat(\"" << sceneName << "-\",str(clock,-5,0)),\".inc\")" << endl << endl;
  if (_fileMain != NULL) {
    _fileMain->close();
  }
  
  _file = new QFile(file);
  _file->open(QFile::WriteOnly | QFile::Truncate);
  
  _stream = new QTextStream(_file);

  *_stream << "// Include file generated by Bullet Physics Playground" << endl << endl;	

  Vec pos = camera()->position();

  *_stream << "camera { " << endl;
  *_stream << "  location < " << pos.x << ", " << pos.y << ", " << pos.z << " >" << endl; 
  *_stream << "  right -image_width/image_height*x" << endl;

  #define _USE_MATH_DEFINES
  if (_cam != NULL) {
    btVector3 vLook = _cam->getLookAt();
    *_stream << "  look_at < " << vLook.x() << ", " << vLook.y() << ", " << vLook.z();
    *_stream << "> angle " << _cam->fieldOfView() * 180.0 / M_PI << endl;
    //// qDebug() << vLook.x() << vLook.y() << vLook.z();
  } else {
    Vec vDir = camera()->viewDirection();
    *_stream << "  look_at < " << pos.x + vDir.x << ", " << pos.y + vDir.y << ", " << pos.z + vDir.z;
    *_stream << "> angle " << camera()->fieldOfView() * 180.0 / M_PI << endl;
     // qDebug() << pos.x + vDir.x << pos.y + vDir.y << pos.z + vDir.z;
  }
  *_stream << "  }" << endl << endl;


}

void Viewer::closePovFile() {
  if (_file != NULL) {
    _file->close();
  }
}

Viewer::~Viewer() {
  // qDebug() << "Viewer::~Viewer()";
  delete _objects;
  delete dynamicsWorld;
  delete collisionCfg;
}

void Viewer::computeBoundingBox() {
  // Compute the bounding box
  getAABB(_objects, _aabb);

  btVector3 vmin(_aabb[0], _aabb[1], _aabb[2]);
  btVector3 vmax(_aabb[3], _aabb[4], _aabb[5]);

  btVector3 center = (vmin + vmax) / 2.0f;
  setSceneRadius((vmax - vmin).length() * 4.0);
  setSceneCenter(Vec(0.0,0.0,0.0));
}

void Viewer::init() {
    // qDebug() << "Viewer::init() 1";

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  //  glClearColor(0.25, 0.25, 0.25, 0.0);
  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);
  //glPointSize(3.0);

  // computeBoundingBox();

  if (!restoreStateFromFile()) {
    showEntireScene();
  }

  glDisable(GL_COLOR_MATERIAL);

  glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 25.0);
  GLfloat specular_color[4] = { 0.38f, 0.38f, 0.38f, 0.50 };
  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR,  specular_color);
  
  float light0_pos[] = {200.0, 200.0, 200.0, 0.50f};
  GLfloat ambient[] = { 0.35f, 0.35f, 0.35f };
  GLfloat diffuse[] = { 0.3f, 0.3f, 0.5f , 0.50f};
  GLfloat specular[] = { 0.5f, 0.5f, 0.5f , 0.50f};

  // GLfloat lmodel_ambient[] = { 0.4, 0.4, 0.4, 0.50 };
  // GLfloat local_view[] = { 0.0 };

  //  glEnable(GL_LIGHTING);

  glEnable(GL_LIGHT0);

  //glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);

  glLightfv(GL_LIGHT1, GL_DIFFUSE, diffuse);	
  glLightfv(GL_LIGHT1, GL_SPECULAR, specular);	
  glLightfv(GL_LIGHT1, GL_POSITION, light0_pos);
  glLightfv(GL_LIGHT1, GL_AMBIENT, ambient);

  //  glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER, local_view);

  glEnable(GL_LIGHT1);

  // qDebug() << "Viewer::init() end";
  _initialCameraPosition=camera()->position();
  _initialCameraOrientation=camera()->orientation();
}

void Viewer::draw() {

  if (_parsing) return;

  // Don't know if this is a good idea..
  computeBoundingBox();

  // qDebug() << "Viewer::draw() 0";
  QMutexLocker locker(&mutex);
  // qDebug() << "Viewer::draw() 1";

  float light0_pos[] = {200.0, 200.0, 200.0, 1.0f};
  float light1_pos[] = {0.0, 200.0, 200.0, 1.0f};

  if(_cb_preDraw) {
	try {
	  luabind::call_function<void>(_cb_preDraw, _frameNum);
	} catch(const std::exception& e){
    showLuaException(e, "v:preDraw()");
  }
  }

  // qDebug() << "Viewer::draw() 2";

  // Directionnal light
  glLightfv(GL_LIGHT0, GL_POSITION, light0_pos);
  glLightfv(GL_LIGHT1, GL_POSITION, light1_pos);

  //  drawLight(GL_LIGHT0);
  //drawLight(GL_LIGHT1);

  //glDisable(GL_COLOR_MATERIAL);

  //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  //  glEnable(GL_LIGHTING);
  //  glEnable(GL_DEPTH_TEST);

  if (manipulatedFrame() != NULL) {
	glPushMatrix();
	glMultMatrixd(manipulatedFrame()->matrix());
  }

  // qDebug() << "Viewer::draw() 3";

  if (_savePOV)
    openPovFile();

  // qDebug() << "Number of objects:" << _objects->size();
  
  // qDebug() << "Viewer::draw() 4";
  
  // for (int i = 0; i < _objects->size(); ++i) {
  //  Object *o = _objects->at(i);
  foreach (Object *o, *_objects) {
	if (_savePOV) {
	  o->renderInLocalFrame(_stream);
	} else {
	  o->renderInLocalFrame(NULL);
	}
  }
  
  if (_savePOV)
	closePovFile();

  // glFlush();

  if (manipulatedFrame() != NULL) {
	glPopMatrix();
  }

  // qDebug() << "Viewer::draw() end";
}

void Viewer::setCBPreDraw(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preDraw = fn;
  }
}

void Viewer::setCBPostDraw(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_postDraw = fn;
  }
}

void Viewer::setCBPreSim(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preSim = fn;
  }
}

void Viewer::setCBPostSim(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_postSim = fn;
  }
}

void Viewer::setCBOnCommand(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onCommand = fn;
  }
}

void Viewer::addShortcut(const QString &keys, const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_shortcuts->insert(keys, fn);
  }
}

void Viewer::removeShortcut(const QString &keys) {
  _cb_shortcuts->remove(keys);
}

void Viewer::postDraw() {
  QGLViewer::postDraw();

  if(_cb_postDraw) {
	try {
	  luabind::call_function<void>(_cb_postDraw, _frameNum);
	} catch(const std::exception& e){
    showLuaException(e, "v:postDraw()");
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
    glVertex2i(width()-20, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

  if (_simulate) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-40, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

  if (_savePNG) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 0.0, 1.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-60, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

  if (_savePOV) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 1.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-80, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

    if (_deactivation) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(1.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-100, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

}

void Viewer::startAnimation() {
  _time.start();
  QGLViewer::startAnimation();
}

void Viewer::stopAnimation() {
  QGLViewer::stopAnimation();
  //  updateGL();
}

void Viewer::animate() {
  QMutexLocker locker(&mutex);

  if (_has_exception) {
    return;
  }

  // emitScriptOutput("Viewer::animate() begin");

  // Find the time elapsed between last time
  float nbSecsElapsed = 0.08f; // 25 pics/sec
  // float nbSecsElapsed = 1.0 / 24.0;
  //  float nbSecsElapsed = _time.elapsed()/10.0f;

  if (_savePNG) {
    QDir sceneDir("screenshots");
    QString file;  	
    if(!_scriptName.isEmpty()){
      sceneDir.mkdir(qPrintable(_scriptName));
      file.sprintf("screenshots/%s/%s-%05d.png", qPrintable(_scriptName), qPrintable(_scriptName), _frameNum);
    }else{
      sceneDir.mkdir("no_name");
      file.sprintf("screenshots/no_name/no_name-%05d.png", _frameNum);
    }
    saveSnapshot(file, true);
  }
    
  if (_simulate) {

    if(_cb_preSim) {
      try {
        luabind::call_function<void>(_cb_preSim, _frameNum);
      } catch(const std::exception& e){
        showLuaException(e, "v:preSim()");
      }
    }
    
    dynamicsWorld->stepSimulation(nbSecsElapsed, 10);

    if(_cb_postSim) {
      try {
        luabind::call_function<void>(_cb_postSim, _frameNum);
      } catch(const std::exception& e){
        showLuaException(e, "v:postSim()");
      }
    }

    if (_frameNum > 10)
      emit postDrawShot(_frameNum);

     _frameNum++;
  }

  // Restart the elapsed time counter
  _time.restart();

  // emitScriptOutput("Viewer::animate() end");
}

void Viewer::command(QString cmd) {
  QMutexLocker locker(&mutex);

  // emitScriptOutput("Viewer::command() begin");

  if(_cb_onCommand) {
    try {
      luabind::call_function<void>(_cb_onCommand, cmd);
    } catch(const std::exception& e){
      showLuaException(e, "v:onCommand()");
    }
  }

  // emitScriptOutput("Viewer::command() end");
}

void Viewer::showLuaException(const std::exception &e, const QString& context) {
  _has_exception = true;

  // the error message should be on top of the stack
  QString luaWhat = QString("%1").arg(lua_tostring(L, -1));

  emitScriptOutput(QString("%1 in %2: %3").arg(e.what()).arg(context).arg(luaWhat));
}
