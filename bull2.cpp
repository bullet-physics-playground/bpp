#include <GL/glut.h>
#include "btBulletDynamicsCommon.h"

static float time = 0.0;

static btScalar matrix[16];
static btTransform trans;

static btDiscreteDynamicsWorld *dynamicsWorld;
static btRigidBody *box1, *box2;


static void draw(void)
{
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  //*** draw box1 
  glColor3f(0.0, 0.0, 1.0);
  glPushMatrix();
  box1->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(matrix);
  glMultMatrixf(matrix);
  glutSolidCube(40);
  glPopMatrix();

  //*** draw box2
  glColor3f(1.0, 1.0, 0.0);
  glPushMatrix();
  box2->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(matrix);
  glMultMatrixf(matrix);
  glutSolidCube(10);
  glPopMatrix();

  glutSwapBuffers();
}


static void timer(void)
{
  float dtime = time;
  time = glutGet(GLUT_ELAPSED_TIME) / 500.0;
  dtime = time - dtime;

  if(dynamicsWorld)
    dynamicsWorld->stepSimulation(dtime, 10);

  glutPostRedisplay();
}


int main(int argc, char** argv)
{
  //*** init Bullet Physics
  btQuaternion qtn;

  btCollisionShape *shape;
  btDefaultMotionState *motionState; 

  btDefaultCollisionConfiguration *collisionCfg = new btDefaultCollisionConfiguration();

  btAxisSweep3 *axisSweep = new btAxisSweep3(btVector3(-100,-100,-100), btVector3(100,100,100), 128);

  dynamicsWorld = new btDiscreteDynamicsWorld(new btCollisionDispatcher(collisionCfg), 
					      axisSweep, new btSequentialImpulseConstraintSolver, collisionCfg);

  dynamicsWorld->setGravity(btVector3(0, -10, 0));


  //*** box1 - STATIC / mass=btScalar(0.0)
  shape = new btBoxShape(btVector3(20,20,20));
  
  trans.setIdentity();
  qtn.setEuler(0, 0.25, -0.05);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, -20, 0));
  motionState = new btDefaultMotionState(trans);

  box1 = new btRigidBody(btScalar(0.0), motionState, shape, btVector3(0,0,0));
  dynamicsWorld->addRigidBody(box1);

  //*** box2 - DYNAMIC / mass=btScalar(1.0) 
  shape = new btBoxShape(btVector3(5,5,5));
  
  trans.setIdentity();
  qtn.setEuler(0.8, 0.7, 0.4);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(-10, 50, 0));
  motionState = new btDefaultMotionState(trans);

  box2 = new btRigidBody(btScalar(1.0), motionState, shape, btVector3(1,1,1));
  dynamicsWorld->addRigidBody(box2);


  //*** init GLUT 
  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
  glutCreateWindow("Jumpin' little BoX");

  glutDisplayFunc(draw);
  glutIdleFunc(timer);


  //*** init OpenGL
  glEnable(GL_CULL_FACE);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHTING);
  glEnable(GL_COLOR_MATERIAL);

  glMatrixMode(GL_PROJECTION);
  gluPerspective( 50.0, 1.0, 20.0, 100.0);
  glMatrixMode(GL_MODELVIEW);
  gluLookAt(0.0, 5.0, 90.0, 0.0, 8.0, 0.0, 0.0, 1.0, 0.0); 

  glutMainLoop();

  delete shape;
  delete motionState;
  delete collisionCfg;
  delete axisSweep;
}
