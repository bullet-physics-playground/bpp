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

  case Qt::Key_S :
    _simulate = !_simulate;
    break;
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

void Viewer::add4BBox(Object *o) {
  _all_objects.push_back(o);
}

void Viewer::add4BBox(QList<Object *> ol) {
  foreach (Object *o, ol) {
    _all_objects.push_back(o);
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
	  Dice *c0 = new Dice(0.99, 0.1);
	  c0->setPosition(10.0 + i - p / 2.0,
			  100.0 + 0.5 + k + p*3 - p / 2.0,
			  20.0 + j - p1 - p / 2.0);
	  //c0->setColor(qrand() % 255, qrand() % 255, qrand() % 255);
	  c0->setColor(pal->getRandomColor());
	  c0->setPovPhotons(true, true, true);
	  c0->body->setActivationState(DISABLE_DEACTIVATION);
	  //addObject(c0, COL_WALL, COL_WALL);

	  l[p].push_back(c0);
	  add4BBox(c0);
	}
      }
    }
  }
  */

  /*
  addObjects(l[1], COL_SHIP, COL_WALL | COL_SHIP);
  add4BBox(l[1]);


  mioSphere = new Sphere(4.0, 5.0);
  mioSphere->setPosition(100.0, 20, 20.0);
  mioSphere->setColor(255, 0, 0);
  addObject(mioSphere, COL_SHIP, COL_WALL | COL_SHIP );
  add4BBox(mioSphere);
  */

  for (int i = 5; i <= 25; i+=3) {
    Sphere *s0 = new Sphere(i / 1.5, i*i + 10.0);
    s0->setPosition(50.0 + i * i * 5.5, i, 20.0);
    s0->setColor(100, 100, 255);
    s0->setTexture("texture {T_Stone1 scale 4.0 }");
    s0->setLinearVelocity(btVector3(-30.0f, 0.0f, 0.0f));
    addObject(s0, COL_SHIP, COL_WALL | COL_SHIP );
    add4BBox(s0);
  }

  /*
  Sphere *s0 = new Sphere(8.0, 40.0);
  s0->setPosition(10.0, 120.0, 15.0);
  s0->setColor(100, 100, 255);
  s0->setTexture("texture {T_Stone1 scale 8.0 }");
  addObject(s0, COL_WALL, COL_WALL);
  add4BBox(s0);
  */

  double r = 7.97f;

  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 5; j++) {
      for (int k = 0; k < 15; k++) {

	double di, dj, dk = 0.0;

	double x = i * r + di;
	double y = 2.0 + k * r + dk;
	double z = j * r + dj;

	if (j == 0) z += 2.0;
	if (j == 4) z -= 2.0;

	Cube *c0 = new Cube(7.99, 4.0, 4.0, 1.0);
	c0->setPosition(x, y, z);
	c0->setColor(0xff, 0xfc, 0xce);
	c0->setTexture(" texture { T_Wood14 finish { specular 0.35 roughness 0.05 ambient 0.3 } translate x*1 rotate <15, 10, 0> translate y*2 scale 5.0 } ");
	c0->setPovPhotons(true, true, true);
	c0->body->setActivationState(DISABLE_DEACTIVATION);
	addObject(c0, COL_WALL, COL_WALL | COL_SHIP);
	add4BBox(c0);
      }
    }
  }

  for (int i = 0; i < 6; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 15; k++) {

	double di, dj, dk = 0.0;

	double x = i * r - 4.0 + di;
	if (i == 0) x += 2.0;
	if (i == 5) x -= 2.0;

	//if (k != 9 && j != 2) {
	Cube *c0 = new Cube(7.99, 4.0, 4.0, 1.0);
	c0->setPosition(x, 6.0 + k * r + dk, j * r + 4.0 + dj);
	c0->setRotation(btVector3(0, 1, 0), M_PI / 2.0);
	c0->setColor(0xff, 0xfc, 0xce);
	c0->setTexture(" texture { T_Wood14 finish { specular 0.35 roughness 0.05 ambient 0.3 } translate x*1 rotate <15, 10, 0> translate y*2 scale 15.0 } ");
	c0->setPovPhotons(true, true, true);
	c0->body->setActivationState(DISABLE_DEACTIVATION);
	addObject(c0, COL_WALL, COL_WALL | COL_SHIP);
	add4BBox(c0);
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
  loadPrefs();

  _savePNG = savePNG; _savePOV = savePOV; setSnapshotFormat("png");
  _simulate = false;

  collisionCfg = new btDefaultCollisionConfiguration();
  axisSweep = new btAxisSweep3(btVector3(-100,-100,-100), btVector3(100,100,100), 52800);
  dynamicsWorld = new btDiscreteDynamicsWorld(new btCollisionDispatcher(collisionCfg),
                                              axisSweep, new btSequentialImpulseConstraintSolver, collisionCfg);

  btOverlapFilterCallback * filterCallback = new FilterCallback(&mio);
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

  connect(&mio, SIGNAL(midiRecived(MidiEvent *)),
          this, SLOT(midiRecived(MidiEvent *)));

  mio.start();

  startAnimation();
}

void Viewer::midiRecived(MidiEvent *me) {
  QString m = QString(me->message);

  for (int i = 0; i < m.length(); i++) {
    std::cout << (int)(m.at(i).toAscii() ) << " ";
  }
  std::cout << endl;

  int lastMovedControllerType;
  
  if (m.size() == 3) {
    lastMovedControllerType = MidiIO::MidiCC;
    int ccNr = m.at(1).toAscii();
    int cc = m.at(2).toAscii();

    if (ccNr == 0) {
      QColor c = mioSphere->getColor();
      mioSphere->setColor(cc * 2, c.green(), c.blue());
    } else if (ccNr = 1) {
      QColor c = mioSphere->getColor();
      mioSphere->setColor(c.red(), cc * 2, c.blue());
    }

    //    qDebug() << cc << endl;
  }
}

void Viewer::loadPrefs() {
  QSettings s;
  QString portName = s.value("midiInPortName", "physics").toString();
  //  selectMIDIInputPort(portName);
}

void Viewer::savePrefs() {
  QSettings s;

  //  s.setValue("midiInPortName", midiInPortName);
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
  savePrefs();

  mio.stop();

  delete dynamicsWorld;
  delete collisionCfg;
  delete axisSweep;

  //qDeleteAll(_objects);
  qDeleteAll(_all_objects);
}

void Viewer::computeBoundingBox() {
  // Compute the bounding box
  getAABB(_all_objects, _aabb);

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
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  //  glClearColor(0.25, 0.25, 0.25, 0.0);
  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);
  //glPointSize(3.0);

  addObjects();

  computeBoundingBox();

  // add plane after bounding box calculation
  Plane *p = new Plane(0.0, 1.0, 0.0, 0.0, sceneRadius());
  p->setColor(255, 255, 255);
  p->setScale("scale 10.0");
  p->setPigment("pigment { checker color rgb <0.0,0.0,0.0>, color rgb <0.75,0.75,0.75> }");
  p->setFinish("finish { reflection 0.1 }");
  addObject(p, COL_WALL, COL_WALL | COL_SHIP);

  if (!restoreStateFromFile()) {
    showEntireScene();
  }

  glDisable(GL_COLOR_MATERIAL);

  glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 50.0);
  GLfloat specular_color[4] = { 0.8f, 0.8f, 0.8f, 1.0 };
  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR,  specular_color);
  
  float light0_pos[] = {200.0, 200.0, 200.0, 1.0f};
  GLfloat ambient[] = { 0.35f, 0.35f, 0.35f };
  GLfloat diffuse[] = { 0.3f, 0.3f, 0.5f , 1.0f};
  GLfloat specular[] = { 0.5f, 0.5f, 0.5f , 1.0f};

  GLfloat lmodel_ambient[] = { 0.4, 0.4, 0.4, 1.0 };
  GLfloat local_view[] = { 0.0 };

  //  glEnable(GL_LIGHTING);

  glEnable(GL_LIGHT0);

  //glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);

  glLightfv(GL_LIGHT1, GL_DIFFUSE, diffuse);	
  glLightfv(GL_LIGHT1, GL_SPECULAR, specular);	
  glLightfv(GL_LIGHT1, GL_POSITION, light0_pos);
  glLightfv(GL_LIGHT1, GL_AMBIENT, ambient);

  //  glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER, local_view);

  glEnable(GL_LIGHT1);

  // startAnimation();
}

void Viewer::draw() {

  float light0_pos[] = {200.0, 200.0, 200.0, 1.0f};
  float light1_pos[] = {0.0, 200.0, 200.0, 1.0f};
  // Directionnal light
  glLightfv(GL_LIGHT0, GL_POSITION, light0_pos);

  glLightfv(GL_LIGHT1, GL_POSITION, light1_pos);

  //  drawLight(GL_LIGHT0);
  //drawLight(GL_LIGHT1);

  //glDisable(GL_COLOR_MATERIAL);

  //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  //  glEnable(GL_LIGHTING);
  //  glEnable(GL_DEPTH_TEST);

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

  // glFlush();

  // glPopMatrix();
}

void Viewer::postDraw() {
  QGLViewer::postDraw();

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

}

void Viewer::startAnimation() {
  _time.start();
  QGLViewer::startAnimation();
}

void Viewer::stopAnimation() {
  QGLViewer::stopAnimation();
  updateGL();
}

void Viewer::animate() {
  static float nbSecondsByStep = 0.0004f;
  
  // Find the time elapsed between last time
  float nbSecsElapsed = 0.08; // 25 pics/sec
  // float nbSecsElapsed = 1.0 / 24.0;
  //  float nbSecsElapsed = _time.elapsed()/10.0f;
  
  //  if (rm != NULL)
  //  rm->animate();

  /*
   if (_frameNum == 60) {
     addObjects(l[2], COL_SHIP, COL_WALL | COL_SHIP);
   } else if (_frameNum == 120) {
     addObjects(l[3], COL_SHIP, COL_WALL | COL_SHIP);
   } else if (_frameNum == 180) {
     addObjects(l[4], COL_SHIP, COL_WALL | COL_SHIP);
   } else if (_frameNum == 240) {
     addObjects(l[5], COL_SHIP, COL_WALL | COL_SHIP);
   } else if (_frameNum == 300) {
     addObjects(l[6], COL_SHIP, COL_WALL | COL_SHIP);
   } else if (_frameNum == 360) {
     addObjects(l[7], COL_SHIP, COL_WALL | COL_SHIP);
   } else if (_frameNum == 420) {
     addObjects(l[8], COL_SHIP, COL_WALL | COL_SHIP);
   } else if (_frameNum == 480) {
     addObjects(l[9], COL_SHIP, COL_WALL | COL_SHIP);
   }

  */

  if (_simulate) {
    if (_savePNG) {
      QString file;
      file.sprintf("d01-%05d.png", _frameNum);
      saveSnapshot(file, true);
    }
    
    dynamicsWorld->stepSimulation(nbSecsElapsed, 10);

    int numManifolds = dynamicsWorld->getDispatcher()->getNumManifolds();
    for (int i=0;i<numManifolds;i++)
      {
	btPersistentManifold* contactManifold = dynamicsWorld->getDispatcher()->getManifoldByIndexInternal(i);
	btCollisionObject* obA = static_cast<btCollisionObject*>(contactManifold->getBody0());
	btCollisionObject* obB = static_cast<btCollisionObject*>(contactManifold->getBody1());

	btScalar vel = (obA->getInterpolationLinearVelocity() - obB->getInterpolationLinearVelocity()).length();

	//qDebug() << " velB " << obB->getInterpolationLinearVelocity().length();

	//	if (vel > 1.0) {
	
	
	int numContacts = contactManifold->getNumContacts();
	for (int j=0;j<numContacts;j++)
	  {
	    btManifoldPoint& pt = contactManifold->getContactPoint(j);

	    btScalar age = pt.m_lifeTime;
	    btScalar dist = pt.getDistance();
	    btScalar impulse = pt.m_appliedImpulse;

	    if (age == 3 && vel > 0.1 && impulse > 5.5) {
	      //qDebug() << "x age " << age << "vel " << vel << "impulse " << impulse;

	      QString msg; msg += 144; msg += qMin((int)(49 + impulse * 0.5), 127); msg += qMin((int) (127 * impulse / 20.0), 127);
	      mio.send(msg);

	    } else {
	      //qDebug() << "- age " << age << "vel " << vel << "impulse " << impulse;
	    }

	/*	    
	    if (pt.getDistance()<0.f && age < 5 && age > 1)
	      {

		const btVector3& ptA = pt.getPositionWorldOnA();
		const btVector3& ptB = pt.getPositionWorldOnB();
		const btVector3& normalOnB = pt.m_normalWorldOnB;

		if (pt.m_appliedImpulse > 10.0) {
		  
		  QString msg; msg += 144; msg += 48; msg += 127;
		  mio.send(msg);
		} else if (pt.m_appliedImpulse > 1) {
		  qDebug() << pt.m_appliedImpulse;

		  QString msg; msg += 144; msg += 51; msg += 127;
		  mio.send(msg);
		}

		//bool shipShip = (obA->m_collisionFilterGroup & COL_SHIP) != 0;
		//shipShip = shipShip && (obB->m_collisionFilterGroup & COL_SHIP);
	      }
	*/
	  }
	
	
      }

    _frameNum++;
  }

  // Restart the elapsed time counter
  _time.restart();
}
