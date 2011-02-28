#include "viewer.h"

#include "collisionfilter.h"

#include "object.h"
#include "plane.h"
#include "cube.h"
#include "cubeaxes.h"
#include "sphere.h"
#include "cylinder.h"
#include "mesh3ds.h"
#include "rm.h"
#include "rm1.h"

#include "palette.h"
#include "dice.h"

#include "SpaceNavigatorCam.h"

#include <GL/glut.h>

#include <QDebug>

#define G 9.81

using namespace std;
using namespace qglviewer;

#define BIT(x) (1<<(x))

enum collisiontypes {
  COL_NOTHING = 0, //<Collide with nothing
  COL_SHIP = BIT(1), //<Collide with ships
  COL_WALL = BIT(2), //<Collide with walls
  COL_POWERUP = BIT(3) //<Collide with powerups
};

namespace {
  void getAABB(const QVector<Object *>& objects, btScalar aabb[6]) {
    btVector3 aabbMin, aabbMax;
    objects[0]->body->getAabb(aabbMin, aabbMax);
    aabb[0] = aabbMin[0];
    aabb[1] = aabbMin[1];
    aabb[2] = aabbMin[2];

    aabb[3] = aabbMax[0];
    aabb[4] = aabbMax[1];
    aabb[5] = aabbMax[2];
    
    foreach (Object *o, objects) {
      btVector3 oaabbmin, oaabbmax;
      o->body->getAabb(oaabbmin, oaabbmax);
      for (int i = 0; i<3; ++i) {
	aabb[  i] = qMin(aabb[  i], oaabbmin[  i]);
	aabb[3+i] = qMax(aabb[3+i], oaabbmax[3+i]);

      }
    }
  }
}

void Viewer::keyPressEvent(QKeyEvent *e) {
  switch (e->key()) {

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

void Viewer::addObject(Object *o, int type, int mask) {
  _objects.push_back(o);
  dynamicsWorld->addRigidBody(o->body, type, mask);
}

void Viewer::addObjects(QList<Object *> ol, int type, int mask) {
  foreach (Object *o, ol) {
    _objects.push_back(o);
    dynamicsWorld->addRigidBody(o->body, type, mask);
  }

  computeBoundingBox();
}

void Viewer::addObjects() {

  /*
  Palette *pal = new Palette("color_ggl.gpl");

  int p1 = 0;

  for (int p = 1; p <= 9; p++) {

    p1 += p;

    for (int i = 0; i < p; i++) {
      for (int j = 0; j < p; j++) {
	for (int k = 0; k < p; k++) {
	  Dice *c0 = new Dice(0.99, 1.0);
	  c0->setPosition(i - p / 2.0,
			  30.0 + 0.5 + k + p*3 - p / 2.0,
			  j - p1 - p / 2.0);
	  //c0->setColor(qrand() % 255, qrand() % 255, qrand() % 255);
	  c0->setColor(pal->getRandomColor());
	  c0->setPovPhotons(true, true, true);
	  c0->body->setActivationState(DISABLE_DEACTIVATION);
	  //addObject(c0, COL_WALL, COL_WALL);

	  l[p].push_back(c0);
	}
      }
    }
  }

  addObjects(l[1], COL_WALL, COL_WALL);
  */

  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 10; k++) {

	double di, dj, dk = 0.0;

	Cube *c0 = new Cube(4.0, 1.0, 1.0, 1.0);
	c0->setPosition(i * 4.0 + di, 0.5 + k * 2.0 + dk, j * 4.0 + dj);
	c0->setColor(100, 100, 100);
	c0->setPovPhotons(true, true, true);
	//c0->body->setActivationState(DISABLE_DEACTIVATION);
	addObject(c0, COL_WALL, COL_WALL);
      }
    }
  }

  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 3; j++) {
      for (int k = 0; k < 10; k++) {

	double di, dj, dk = 0.0;

	//if (k != 9 && j != 2) {
	  Cube *c0 = new Cube(4.0, 1.0, 1.0, 1.0);
	  c0->setPosition(i * 4.0 - 2.0 + di, 1.5 + k * 2.0 + dk, j * 4.0 + 2.0 + dj);
	  c0->setRotation(btVector3(0, 1, 0), M_PI / 2.0);
	  c0->setColor(200, 200, 200);
	  c0->setPovPhotons(true, true, true);
	  //c0->body->setActivationState(DISABLE_DEACTIVATION);
	  addObject(c0, COL_WALL, COL_WALL);
	  //}
      }
    }
  }

  /*
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      for (int k = 0; k < 30; k++) {
	Dice *c0 = new Dice(0.99, 1.0);
	c0->setPosition(i, 30.0 + 0.5 + k, j);
	c0->setColor(pal->getRandomColor());
	c0->setPovPhotons(true, true, true);
	c0->body->setActivationState(DISABLE_DEACTIVATION);
	addObject(c0, COL_WALL, COL_WALL);
      }
    }
    }*/

  /*
  Cube *c1 = new Cube(2.0, 1.0, 1.0, 0.0);
  c1->setPosition(1.5, 0.5, 0.0);
  c1->setColor(255, 100, 100);
  addObject(c1, COL_WALL, COL_WALL);

  Cube *c2 = new Cube(1.0, 2.0, 1.0, 0.0);
  c2->setPosition(0.0, 2.0, 0.0);
  c2->setColor(100, 255, 100);
  addObject(c2, COL_WALL, COL_WALL);

  Cube *c3 = new Cube(1.0, 1.0, 2.0, 0.0);
  c3->setPosition(0.0, 0.5, 1.5);
  c3->setColor(100, 100, 255);
  addObject(c3, COL_WALL, COL_WALL);

  Cube *a = new Cube(1.0, 2.0, 1.0, 1.0);
  a->setPosition(10.0, 1.0, 0.0);
  a->setColor(100, 100, 255);
  a->body->setActivationState(DISABLE_DEACTIVATION);
  addObject(a, COL_WALL, COL_WALL);

  Cube *b = new Cube(1.0, 1.0, 2.0, 1.0);
  b->setPosition(10.0, 1.5, 1.5);
  b->setColor(100, 255, 100);
  b->body->setActivationState(DISABLE_DEACTIVATION);
  addObject(b, COL_WALL, COL_WALL);

  btVector3 pivA1(0.0, 0.5, 0.0);
  btVector3 axisA1(.0, 0.0, 1.0);
  btVector3 pivB1(0.0, 0.0, -1.5);
  btVector3 axisB1(.0, 0.0, 1.0);

  btHingeConstraint *j1 = new btHingeConstraint(*a->body, *b->body, pivA1, pivB1, axisA1, axisB1);
  j1->enableAngularMotor(true, 0.5, 100);
  dynamicsWorld->addConstraint(j1, true);

  Cube *c = new Cube(1.0, 2.0, 1.0, 1.0);
  c->setPosition(10.0, 1.5+1.5, 2.0);
  c->setColor(100, 255, 255);
  c->body->setActivationState(DISABLE_DEACTIVATION);
  addObject(c, COL_WALL, COL_WALL);

  btVector3 pivA2(0., 1.5, 0.5);
  btVector3 axisA2(.0, 1.0, 0.0);
  btVector3 pivB2(0.0, 0.0, 0.0);
  btVector3 axisB2(.0, 1.0, 0.0);

  btHingeConstraint *j2 = new btHingeConstraint(*b->body, *c->body, pivA2, pivB2, axisA2, axisB2);
  j2->enableAngularMotor(true, 0.5, 100);
  dynamicsWorld->addConstraint(j2, true);
*/

  /*
  Sphere *c4 = new Sphere(.5, 1.0);
  c4->setPosition(3.0, 3.0, 3.0);
  c4->setColor(100, 100, 255);
  addObject(c4, COL_WALL, COL_NOTHING); */

  //Cylinder *c5 = new Cylinder(1.0, 1.0, 1.0, 1.0);
  //c5->setPosition(5.0, 5.5, 1.5);
  //  c5->setRotation(btVector3(1, 0, 0), 45.0);
  //c5->setColor(100, 100, 255);
  //addObject(c5, COL_WALL, COL_NOTHING);

  /*
  rm = new RM1();
  addObject(rm->rm0, COL_WALL, COL_NOTHING);
  addObject(rm->rm1, COL_WALL, COL_NOTHING);
  addObject(rm->rm2, COL_WALL, COL_NOTHING);
  addObject(rm->rm3, COL_WALL, COL_NOTHING);
  addObject(rm->rm4, COL_WALL, COL_NOTHING);
  addObject(rm->rm5, COL_WALL, COL_WALL);

  addObject(rm->cube, COL_WALL, COL_NOTHING);

  dynamicsWorld->addConstraint(rm->rmJoint0, true);
  dynamicsWorld->addConstraint(rm->rmJoint1, true);
  dynamicsWorld->addConstraint(rm->rmJoint2, true);
  dynamicsWorld->addConstraint(rm->rmJoint3, true);
  dynamicsWorld->addConstraint(rm->rmJoint4, true);
  */
}

Viewer::Viewer(QWidget *, bool savePNG, bool savePOV) {
  _savePNG = savePNG; _savePOV = savePOV; setSnapshotFormat("png");

  collisionCfg = new btDefaultCollisionConfiguration();
  axisSweep = new btAxisSweep3(btVector3(-100,-100,-100), btVector3(100,100,100), 52800);
  dynamicsWorld = new btDiscreteDynamicsWorld(new btCollisionDispatcher(collisionCfg),
                                              axisSweep, new btSequentialImpulseConstraintSolver, collisionCfg);

  btOverlapFilterCallback * filterCallback = new FilterCallback();
  dynamicsWorld->getPairCache()->setOverlapFilterCallback(filterCallback);

  dynamicsWorld->setGravity(btVector3(0, -G, 0));

  _frameNum = 0;

  nbKeyFrames = 10;

  SpaceNavigatorCam *cam = new SpaceNavigatorCam(camera());

  // camera()->setType(Camera::ORTHOGRAPHIC);

  //setManipulatedFrame( cam );

  //  Frame* myFrame = new Frame();
  //kfi_.setFrame(cam);
  //  kfi_.setLoopInterpolation();

  /*
  keyFrame_ = new ManipulatedFrame*[nbKeyFrames];

  for (int i=0; i<nbKeyFrames; i++)
    {
      keyFrame_[i] = new ManipulatedFrame();
      keyFrame_[i]->setPosition( 0.0, -5.0, 12.0 * i - 60.0);
      kfi_.addKeyFrame(keyFrame_[i]);
    }

  currentKF_ = 0;

  kfi_.setInterpolationSpeed(.33);
  */

  //  setManipulatedFrame(keyFrame_[currentKF_]);

  /*
  setMouseTracking(true);

  connect(&kfi_, SIGNAL(interpolated()), SLOT(updateGL()));
  kfi_.startInterpolation();
  */
}

void Viewer::openPovFile() {
  QString file;
  file.sprintf("d02-%05d.pov", _frameNum);

  _file = new QFile(file);
  _file->open(QFile::WriteOnly | QFile::Truncate);
  
  _stream = new QTextStream(_file);

  *_stream << "#include \"colors.inc\"" << endl;

  *_stream << "#include \"dice.inc\"" << endl;
  *_stream << "#include \"settings.inc\"" << endl << endl;

  Vec pos = camera()->position();
  Vec vDir = camera()->viewDirection();

  //  *_stream << "global_settings {assumed_gamma 1.0}" << endl;

  *_stream << "camera { " << endl;
  *_stream << "  location < 0, 0 ,0 >" << endl;
  *_stream << "  right -16/9*x" << endl;
  *_stream << "  look_at < " << vDir.x << ", " << vDir.y << ", " << vDir.z << "> angle 66" << endl;
  *_stream << "  translate < " << pos.x << ", " << pos.y << ", " << pos.z << " >" << endl;
  *_stream << "}" << endl << endl;

  // *_stream << "light_source { <100,200,100> color 1 }" << endl;
  // *_stream << "light_source { <100,200,200> color 1 }" << endl << endl;
}

void Viewer::closePovFile() {
  if (_file != NULL) {
    _file->close();
  }
}

Viewer::~Viewer() {
  delete dynamicsWorld;
  delete collisionCfg;
  delete axisSweep;

  qDeleteAll(_objects);
}

void Viewer::computeBoundingBox() {
  // Compute the bounding box
  getAABB(_objects, _aabb);

  btVector3 min(_aabb[0], _aabb[1], _aabb[2]); 
  btVector3 max(_aabb[3], _aabb[4], _aabb[5]);

  //btVector3 min(-30, -30, -30); 
  //btVector3 max(30, 30, 30);
  btVector3 center = (min+max)/2.0f;
  center[3] = 0.0f;

  setSceneRadius((max-min).length()*2.0);
  setSceneCenter((Vec)center);
}

void Viewer::init() {

  addObjects();

  GLfloat ambient[] = { 0.3f, 0.3f, 0.3f };
  GLfloat diffuse[] = { 0.1f, 0.1f, 0.1f , 1.0f};
  GLfloat specular[] = { 0.0f, 0.0f, 0.0f , 1.0f};
  glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);	
  glLightfv(GL_LIGHT0, GL_SPECULAR, specular);	
  
  float light0_pos[] = {100.0, 200.0, 100.0, 0.0};
  glLightfv(GL_LIGHT0, GL_POSITION, light0_pos);
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_COLOR_MATERIAL);
  
  glPointSize(3.0);
  
  glClearColor(0.25, 0.25, 0.25, 0.0);
  
  computeBoundingBox();

  // add plane after bounding box calculation
  Plane *p = new Plane(0.0, 1.0, 0.0, 0.0, sceneRadius());
  p->setColor(255, 255, 255);
  addObject(p, COL_WALL, COL_WALL);

  if (!restoreStateFromFile()) {
    showEntireScene();
  }

  // startAnimation();
}

void Viewer::draw() {

  //glPushMatrix();
  //glMultMatrixd(manipulatedFrame()->matrix());

  /*
  for (int i=0; i<nbKeyFrames; ++i) {
    glPushMatrix();
    glMultMatrixd(kfi_.keyFrame(i).matrix());
    
    if ((i == currentKF_) || (keyFrame_[i]->grabsMouse()))
      drawAxis(3.0f);
    else
      drawAxis(2.0f);
    
    glPopMatrix();
    }*/

  //glMultMatrixd(kfi_.frame()->matrix());
  //drawAxis(10.0f);
  //glPopMatrix();

  //  kfi_.drawPath(5, 10);

  if (_savePOV)
    openPovFile();

  foreach (Object *o,_objects) {
    if (_savePOV)
      o->render(_stream);
    else
      o->render(NULL);
  }

  if (_savePOV)
    closePovFile();

  // glPopMatrix();
}

void Viewer::postDraw() {
  QGLViewer::postDraw();

  // Red dot when EventRecorder is active
  startScreenCoordinatesSystem();
  glDisable(GL_LIGHTING);
  glDisable(GL_DEPTH_TEST);
  glPointSize(12.0);
  glColor3f(1.0, 0.0, 0.0);
  glBegin(GL_POINTS);
  glVertex2i(width()-20, 20);
  glEnd();
  glEnable(GL_DEPTH_TEST);
  stopScreenCoordinatesSystem();
  // restore foregroundColor
  qglColor(foregroundColor());
}

void Viewer::startAnimation() {
  _time.start();
  QGLViewer::startAnimation();
}

void Viewer::animate() {
  static float nbSecondsByStep = 0.0004f;
  
  // Find the time elapsed between last time
  float nbSecsElapsed = 0.08; // 25 pics/sec
  //float nbSecsElapsed = 0.0125;
  //  float nbSecsElapsed = _time.elapsed()/10.0f;
  
  if (_savePNG) {
    QString file;
    file.sprintf("d01-%05d.png", _frameNum);
    saveSnapshot(file, true);
  }

  //  if (rm != NULL)
  //  rm->animate();

  /*
  if (_frameNum == 60) {
    addObjects(l[2], COL_WALL, COL_WALL);
  } else if (_frameNum == 120) {
    addObjects(l[3], COL_WALL, COL_WALL);
  } else if (_frameNum == 180) {
    addObjects(l[4], COL_WALL, COL_WALL);
  } else if (_frameNum == 240) {
    addObjects(l[5], COL_WALL, COL_WALL);
  } else if (_frameNum == 300) {
    addObjects(l[6], COL_WALL, COL_WALL);
  } else if (_frameNum == 360) {
    addObjects(l[7], COL_WALL, COL_WALL);
  } else if (_frameNum == 420) {
    addObjects(l[8], COL_WALL, COL_WALL);
  } else if (_frameNum == 480) {
    addObjects(l[9], COL_WALL, COL_WALL);
    }*/

  _frameNum++;
  dynamicsWorld->stepSimulation(nbSecsElapsed, 10);

  // Restart the elapsed time counter
  _time.restart();
}
