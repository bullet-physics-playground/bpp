#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "viewer.h"

#include "coll.h"

#include <QColor>

#include "objects/object.h"
#include "objects/objects.h"
#include "objects/plane.h"
#include "objects/cube.h"
#include "objects/sphere.h"
#include "objects/cylinder.h"
#include "objects/mesh3ds.h"

#include "objects/palette.h"

#include "objects/cam.h"

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
  ostream << v.x() << v.y() << v.z();
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const QString& s) {
  ostream << s.toAscii().data();
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const QColor& c) {
  ostream << c.name().toAscii().data();
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
   .def("addConstraint", (void(Viewer::*)(btTypedConstraint *))&Viewer::addConstraint, adopt(_2))
   .def("cam", (void(Viewer::*)(Cam *))&Viewer::setCamera, adopt(_2))
   .def("preDraw", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPreDraw, adopt(luabind::result))
   .def("postDraw", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPostDraw, adopt(luabind::result))
   .def("preSim", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPreSim, adopt(luabind::result))
   .def("postSim", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPostSim, adopt(luabind::result))
   .def(tostring(const_self))
  ];

  module(s)
	[
	 class_<btVector3>( "btVector3" )
	 .def(constructor<>())
	 .def(constructor<btScalar, btScalar, btScalar>())
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
   ];
   
  module(s)
  [
   class_<btHingeConstraint,btTypedConstraint>("btHingeConstraint")
   .def(constructor<btRigidBody&, btRigidBody&, const btVector3&, const btVector3&, const btVector3&, const btVector3&>())
   .def("setAxis", &btHingeConstraint::setAxis)
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

void Viewer::addConstraint(btTypedConstraint *con) {
  dynamicsWorld->addConstraint(con, true);
  _constraints->insert(con);
}

void Viewer::addConstraints(QList<btTypedConstraint *> cons) {
  for (int i = 0; i < cons.size(); ++i) {
    addConstraint(cons[i]);
  }
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
  /*
  case Qt::Key_Left :
    currentKF_ = (currentKF_+nbKeyFrames-1) % nbKeyFrames;
    setManipulatedFrame(keyFrame_[currentKF_]);
    updateGL();
    break;
  case Qt::Key_Right :
    currentKF_ = (currentKF_+1) % nbKeyFrames;
    setManipulatedFrame(keyFrame_[currentKF_]);
    updateGL();
    break;
  */
    //  case Qt::Key_Return :
    // kfi_.toggleInterpolation();
    // break;
  case Qt::Key_Plus :
    // kfi_.setInterpolationSpeed(kfi_.interpolationSpeed()+0.25);
    break;
  case Qt::Key_Minus :
    // kfi_.setInterpolationSpeed(kfi_.interpolationSpeed()-0.25);
    break;
    /*
    case Qt::Key_Left :
      break;
    case Qt::Key_Right :
      break;
    case Qt::Key_Return :
      break;
    case Qt::Key_Plus :
      break;
    case Qt::Key_Minus :
      break;
    */
      //    case Qt::Key_C :
      // break;
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

  L = NULL;

  _savePNG = savePNG; _savePOV = savePOV; setSnapshotFormat("png");
  _simulate = false;
  _deactivation = true;

  collisionCfg = new btDefaultCollisionConfiguration();
  //axisSweep = new btAxisSweep3(btVector3(-100,-100,-100), btVector3(100,100,100), 52800);
  //dynamicsWorld = new btDiscreteDynamicsWorld(new btCollisionDispatcher(collisionCfg), axisSweep, new btSequentialImpulseConstraintSolver, collisionCfg);
  btBroadphaseInterface* broadphase = new btDbvtBroadphase();
  dynamicsWorld = new btDiscreteDynamicsWorld(new btCollisionDispatcher(collisionCfg), broadphase, new btSequentialImpulseConstraintSolver, collisionCfg);
  btCollisionDispatcher * dispatcher = static_cast<btCollisionDispatcher *>(dynamicsWorld ->getDispatcher());
  btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher);

  dynamicsWorld->setGravity(btVector3(0.0f, -G, 0.0f));

  _frameNum = 0;
  _firstFrame = 0;

//  nbKeyFrames = 10;

//  setManipulatedFrame(new ManipulatedFrame());
//  camera()->setType(Camera::PERSPECTIVE);
  
  loadPrefs();

  startAnimation();
}

void Viewer::close() {
  // qDebug() << "Viewer::close()";
  savePrefs();
  QGLViewer::close();
}

void Viewer::setCamera(Camera *cam) {
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
  _parsing = true;

  // qDebug() << "Viewer::parse 0";

  QMutexLocker locker(&mutex);
  
  // qDebug() << "Viewer::parse 1";
  
  _scriptContent = txt;
	
  bool animStarted = animationIsStarted();

  if (animStarted) {
      stopAnimation();
  }

  if (L != NULL) {
	clear();
	lua_gc(L, LUA_GCCOLLECT, 0); // collect garbage

  // invalidate function refs
  _cb_preDraw = luabind::object();
  _cb_postDraw = luabind::object();
  _cb_preSim = luabind::object();
  _cb_postSim = luabind::object();

  lua_close(L);
  }
  
  // qDeleteAll(*_objects);
  
  // qDebug() << "after lua_gc";

  // setup lua

  L = luaL_newstate();
  //  luaopen_io(L); // provides io.*
  luaL_openlibs(L);
  luaopen_math(L);
  // lua_load_environment(L);

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

  if (error) return false; else return true;
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
}

void Viewer::resetCamView() {

    camera()->setPosition(_initialCameraPosition);
    camera()->setOrientation(_initialCameraOrientation);
    updateGL();

}

void Viewer::loadPrefs() {
  QSettings s;

  QGLViewer::restoreStateFromFile();
}

void Viewer::savePrefs() {
  // qDebug() << "Viewer::savePrefs()";
  QSettings s;

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
    sceneName="no_name";
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
  Vec vDir = camera()->viewDirection();
  *_stream << "camera { " << endl;
  *_stream << "  location < " << pos.x << ", " << pos.y << ", " << pos.z << " >" << endl; 
  *_stream << "  right -image_width/image_height*x" << endl;
  *_stream << "  look_at < " << vDir.x << ", " << vDir.y << ", " << vDir.z << "> angle 39.6" << endl; 
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
  delete axisSweep;
}

void Viewer::computeBoundingBox() {
  // Compute the bounding box
  getAABB(_objects, _aabb);

  btVector3 vmin(_aabb[0], _aabb[1], _aabb[2]);
  btVector3 vmax(_aabb[3], _aabb[4], _aabb[5]);

  btVector3 center = (vmin + vmax) / 2.0f;
  setSceneRadius((vmax - vmin).length() * 2.0);
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
      emitScriptOutput(QString(e.what()));
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
    // qDebug() << "A function";
    _cb_preDraw = fn;
  } else {
    // qDebug() << "Not a function";
  }
}

void Viewer::setCBPostDraw(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    // qDebug() << "A function";
    _cb_postDraw = fn;
  } else {
    // qDebug() << "Not a function";
  }
}

void Viewer::setCBPreSim(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    // qDebug() << "A function";
    _cb_preSim = fn;
  } else {
    // qDebug() << "Not a function";
  }
}

void Viewer::setCBPostSim(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    // qDebug() << "A function";
    _cb_postSim = fn;
  } else {
    // qDebug() << "Not a function";
  }
}

void Viewer::postDraw() {
  QGLViewer::postDraw();

  if(_cb_postDraw) {
	try {
	  luabind::call_function<void>(_cb_postDraw, _frameNum);
	} catch(const std::exception& e){
      emitScriptOutput(QString("%1 %2").arg(e.what()).arg("in v:postDraw()"));
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
        emitScriptOutput(QString("%1 %2").arg(e.what()).arg("in v:preSim()"));
      }
    }
    
    dynamicsWorld->stepSimulation(nbSecsElapsed, 10);

    if(_cb_postSim) {
      try {
        luabind::call_function<void>(_cb_postSim, _frameNum);
      } catch(const std::exception& e){
        emitScriptOutput(QString("%1 %2").arg(e.what()).arg("in v:postSim()"));
      }
    }

    if (_frameNum > 10)
      emit postDrawShot(_frameNum);

     _frameNum++;
  }

  // Restart the elapsed time counter
  _time.restart();
}
