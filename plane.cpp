#include "plane.h"
#include <GL/glut.h>

#include <QDebug>

using namespace std;

Plane::Plane(btScalar nx, btScalar ny, btScalar nz, btScalar nConst, btScalar psize)
{
  size = psize;

  shape = new btStaticPlaneShape(btVector3(nx, ny, nz), nConst);

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  body = new btRigidBody(0.0, motionState, shape, btVector3(.0, .0, .0));
}

void Plane::renderInLocalFrame(QTextStream *s) const
{
  const btStaticPlaneShape* staticPlaneShape = static_cast<const btStaticPlaneShape*>(shape);
  btScalar planeConst = staticPlaneShape->getPlaneConstant();
  const btVector3& planeNormal = staticPlaneShape->getPlaneNormal();
  btVector3 planeOrigin = planeNormal * planeConst;
  btVector3 vec0,vec1;
  btPlaneSpace1(planeNormal,vec0,vec1);
  btScalar vecLen = size;
  btVector3 pt0 = planeOrigin - vec0*vecLen;
  btVector3 pt1 = planeOrigin + vec0*vecLen;
  btVector3 pt2 = planeOrigin - vec1*vecLen;
  btVector3 pt3 = planeOrigin + vec1*vecLen;

  glBegin(GL_TRIANGLES);
  glColor3ubv(color);
  glNormal3fv(planeNormal);
  glVertex3fv(pt0);
  glVertex3fv(pt1);
  glVertex3fv(pt2);
  glVertex3fv(pt0);
  glVertex3fv(pt1);
  glVertex3fv(pt3);
  glEnd();

  if (s != NULL) {
    *s << "plane { <" << planeNormal[0] << ", " << planeNormal[1] << ", " << planeNormal[2] << ">, " << planeConst << "\n";
    *s << "  pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;
    *s << "}" << endl << endl;
  }
}
