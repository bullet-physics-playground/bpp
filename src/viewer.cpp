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
	 .def("cam", (void(Viewer::*)(Cam *))&Viewer::setCamera, adopt(luabind::result))
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
	 ];

  module(s)
	[
	 class_<btQuaternion>("btQuaternion")
	 .def(constructor<>())
     .def(constructor<const btVector3&, btScalar>())
	 .def(constructor<btScalar, btScalar, btScalar, btScalar>())
	 ];

  module(s)
	[
	 class_<btTransform>("btTransform")
	 .def(constructor<>())
     .def(constructor<const btQuaternion&, const btVector3&>())
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
  add4BBox(o);
  addConstraints(o->getConstraints());
}

void Viewer::addConstraints(QList<btTypedConstraint *> cons) {
  for (int i = 0; i < cons.size(); ++i) {
	dynamicsWorld->addConstraint(cons[i], true);
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
  void getAABB(const QList<Object *> *objects, btScalar aabb[6]) {
    btVector3 aabbMin, aabbMax;

	if (objects->size() > 0) {
	  objects->at(0)->body->getAabb(aabbMin, aabbMax);
	  aabb[0] = aabbMin[0]; aabb[1] = aabbMin[1]; aabb[2] = aabbMin[2];
	  aabb[3] = aabbMax[0]; aabb[4] = aabbMax[1]; aabb[5] = aabbMax[2];
	} else {
	  aabb[0] = -10; aabb[1] = -10; aabb[2] = -10;
	  aabb[3] = 10; aabb[4] = 10; aabb[5] = 10;
	}

	for (int i = 0; i < objects->size(); ++i) {
	  Object *o = objects->at(i);

	  if (o->toString() != QString("Plane")) {
		btVector3 oaabbmin, oaabbmax;
		o->body->getAabb(oaabbmin, oaabbmax);
		
		for (int i = 0; i < 3; ++i) {
		  aabb[  i] = qMin(aabb[  i], oaabbmin[  i]);
		  aabb[3+i] = qMax(aabb[3+i], oaabbmax[3+i]);
		}
	  }
    }
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
    kfi_.setInterpolationSpeed(kfi_.interpolationSpeed()+0.25);
    break;
  case Qt::Key_Minus :
    kfi_.setInterpolationSpeed(kfi_.interpolationSpeed()-0.25);
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

void Viewer::add4BBox(Object *o) {
  _all_objects->push_back(o);
}

void Viewer::add4BBox(QList<Object *> ol) {
  foreach (Object *o, ol) {
    _all_objects->push_back(o);
  }
}

void Viewer::removeObject(Object *o) {

  if (_objects->contains(o)) {
	_objects->removeAll(o);

	if (o->body != NULL)
	  dynamicsWorld->removeRigidBody(o->body);
  }

  if (_all_objects->contains(o))
	_all_objects->removeAll(o);

  delete o;

  // o = NULL;
}

void Viewer::addObject(Object *o, int type, int mask) {
  _objects->push_back(o);

  if (o->body != NULL) {
	if(!_deactivation){  
	  o->body->setActivationState(DISABLE_DEACTIVATION);
	}
	dynamicsWorld->addRigidBody(o->body, type, mask);
  }
}

void Viewer::addObjects(QList<Object *> ol, int type, int mask) {
  foreach (Object *o, ol) {
    _objects->push_back(o);

	if (o->body != NULL) {
          if(!_deactivation){  
	    o->body->setActivationState(DISABLE_DEACTIVATION);
	  }
	  dynamicsWorld->addRigidBody(o->body, type, mask);
	}
  }
}

void Viewer::addObjects() {

}

Viewer::Viewer(QWidget *, bool savePNG, bool savePOV) {
  _objects = new QList<Object *>();
  _all_objects = new QList<Object *>();

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

  nbKeyFrames = 10;

  setManipulatedFrame(new ManipulatedFrame());
  camera()->setType(Camera::PERSPECTIVE);
  
  loadPrefs();

  startAnimation();
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
	lua_close(L);
  }
  
  // invalidate function refs
  _cb_preDraw = luabind::object();
  _cb_postDraw = luabind::object();
  _cb_preSim = luabind::object();
  _cb_postSim = luabind::object();
  
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

  // qDebug() << "Viewer::parse end";

  _parsing = false;

  if (error) return false; else return true;
}

void Viewer::clear() {
  // qDebug() << "Viewer::clear()" << _objects->size();

  for (int i = 0; i < _objects->size(); ++i) {
	removeObject(_objects->at(i));
  }

  // remove all contact maifolds
  for (int i = dynamicsWorld->getNumCollisionObjects()-1; i>=0 ;i--) {
	btCollisionObject* obj = dynamicsWorld->getCollisionObjectArray()[i];

	btRigidBody* body = btRigidBody::upcast(obj);
	if (body && body->getMotionState()) {
	  delete body->getMotionState();
	}

	dynamicsWorld->removeCollisionObject( obj );

	delete obj;
  }

  _objects->clear();
  _all_objects->clear();

}

void Viewer::resetCamView() {
	
    camera()->setPosition(_initialCameraPosition);
    camera()->setOrientation(_initialCameraOrientation);
    updateGL();

}

void Viewer::loadPrefs() {
  QSettings s;
}

void Viewer::savePrefs() {
  QSettings s;
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
  savePrefs();

  delete [] _objects;
  delete [] _all_objects;
  delete dynamicsWorld;
  delete collisionCfg;
  delete axisSweep;

}

void Viewer::computeBoundingBox() {
  // Compute the bounding box
  getAABB(_objects, _aabb);

  btVector3 vmin(_aabb[0], _aabb[1], _aabb[2]);
  btVector3 vmax(_aabb[3], _aabb[4], _aabb[5]);

  btVector3 center = (vmin + vmax)/2.0f;
  setSceneRadius((vmax - vmin).length()*5.0);
  setSceneCenter((Vec)center);
}

void Viewer::init() {
    // qDebug() << "Viewer::init() 1";

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  //  glClearColor(0.25, 0.25, 0.25, 0.0);
  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);
  //glPointSize(3.0);

  addObjects();
  computeBoundingBox();

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

  // qDebug() << "Viewer::draw() 0";
  QMutexLocker locker(&mutex);
  // qDebug() << "Viewer::draw() 1";

  float light0_pos[] = {200.0, 200.0, 200.0, 1.0f};
  float light1_pos[] = {0.0, 200.0, 200.0, 1.0f};

  if(_cb_preDraw) {
	try {
	  luabind::call_function<void>(_cb_preDraw, _frameNum);
	} catch(const std::exception& e){
	  std::cout << e.what() << std::endl;
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
	  std::cout << e.what() << std::endl;
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
        std::cout << e.what() << std::endl;
      }
    }
    
    dynamicsWorld->stepSimulation(nbSecsElapsed, 10);

    if(_cb_postSim) {
      try {
        luabind::call_function<void>(_cb_postSim, _frameNum);
      } catch(const std::exception& e){
        std::cout << e.what() << std::endl;
      }
    }

    if (_frameNum > 10)
      emit postDrawShot(_frameNum);

     _frameNum++;
  }

  // Restart the elapsed time counter
  _time.restart();
}
