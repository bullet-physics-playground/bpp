#include "plane.h"
#include <GL/glut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Plane::Plane(btVector3 dim, btScalar nConst, btScalar psize) {
  init(dim.getX(), dim.getY(), dim.getZ(), nConst, psize);
}

Plane::Plane(btScalar nx, btScalar ny, btScalar nz,
			 btScalar nConst, btScalar psize) {
  init(nx, ny, nz, nConst, psize);
}

void Plane::init(btScalar nx, btScalar ny, btScalar nz, btScalar nConst, btScalar psize) {
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

void Plane::setPigment(QString pigment) {
  mPigment = pigment;
}

void Plane::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Plane, Object>("Plane")
     .def(constructor<>(), adopt(result))
     .def(constructor<btScalar>(), adopt(result))
     .def(constructor<btScalar, btScalar>(), adopt(result))
     .def(constructor<btScalar, btScalar, btScalar>(), adopt(result))
     .def(constructor<btScalar, btScalar, btScalar, btScalar>(), adopt(result))
     .def(constructor<btScalar, btScalar, btScalar, btScalar, btScalar>(), adopt(result))
     .def(constructor<btVector3, btScalar, btScalar>(), adopt(result))
     .def(tostring(const_self))
     ];
}

QString Plane::toString() const {
  return QString("Plane");
}

void Plane::renderInLocalFrame(QTextStream *s) const
{

  // qDebug() << "Plane::renderInLocalFrame";

  GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
  GLfloat mat_ambient[] = { color[0] / 255.0, color[1] / 255.0, color[2] / 255.0, 1.0 };
  GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
  GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
  GLfloat no_shininess[] = { 0.0 };
  GLfloat low_shininess[] = { 5.0 };
  GLfloat high_shininess[] = { 100.0 };
  GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};

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

  glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
  glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
  glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);

  //  glColor3ubv(color);

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

    if (mTexture != NULL) {
      *s << mTexture << endl;
    } else if (mPigment != NULL) {
      *s << mPigment << endl;
    } else {
      *s << "  pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;
    }

    if (mScale != NULL) {
      *s << mScale << endl;
    }

    if (mFinish != NULL) {
      *s << mFinish << endl;
    }

    *s << "}" << endl << endl;
  }
}
