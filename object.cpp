#include "object.h"
#include <GL/gl.h>

#include <QDebug>

using namespace std;

Object::Object() {
  photons_enable = false;
  photons_reflection = false;
  photons_refraction = false;
}

Object::~Object()
{
  delete shape;
  if (body != NULL)
    delete body->getMotionState();
  delete body;
}

void Object::setMass(btScalar _mass) {
  body->setMassProps(0, btVector3(0,0,0));
  body->updateInertiaTensor();
}

void Object::setColor(int r, int g, int b) {
  color[0] = r;
  color[1] = g;
  color[2] = b;
}

void Object::setColor(QColor col) {
  setColor(col.red(), col.green(), col.blue());
}

void Object::setPosition(btVector3 &v) {
  setPosition(v[0], v[1], v[2]);
}

void Object::setPosition(btScalar x, btScalar y, btScalar z) {
  if (body != NULL) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    trans.setOrigin(btVector3(x, y, z));
    delete body->getMotionState();
    body->setMotionState(new btDefaultMotionState(trans));
  }
}

void Object::setRotation(btVector3 axis, btScalar angle) {
  if (body != NULL) {
    btTransform trans;
    btQuaternion rot;
    body->getMotionState()->getWorldTransform(trans);
    rot = trans.getRotation();
    rot.setRotation(axis, angle);
    trans.setRotation(rot);
    delete body->getMotionState();
    body->setMotionState(new btDefaultMotionState(trans));
  }
}

void Object::setTransform(btTransform trans) {
  if (body != NULL) {
    delete body->getMotionState();
    body->setMotionState(new btDefaultMotionState(trans));
  } 
}

void Object::setRotation(btQuaternion r) {
  if (body != NULL) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    trans.setRotation(r);
    delete body->getMotionState();
    body->setMotionState(new btDefaultMotionState(trans));
  }
}

void Object::setPovPhotons(bool _photons_enable,
			   bool _photons_reflection,
			   bool _photons_refraction) {
  photons_enable = _photons_enable;
  photons_reflection = _photons_reflection;
  photons_refraction = _photons_refraction;
}

QString Object::getPovPhotons() const {
  QString tmp("");

  if (photons_enable) {
    tmp += "  photons {\n    target\n    reflection ";
    tmp += (photons_reflection) ? "on" : "off";
    tmp += "\n    refraction ";
    tmp += (photons_refraction) ? "on" : "off";
    tmp += "\n  }\n";
  }

  return tmp;
}


void Object::render(QTextStream *s) const
{
  renderInLocalFrame(s);
}
