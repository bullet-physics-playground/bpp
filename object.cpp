#include "object.h"
#include <GL/gl.h>

#include <QDebug>

using namespace std;

std::ostream& operator<<(std::ostream& ostream, const Object& obj) {
  ostream << obj.toString().toAscii().data() << "[ rgb: " <<
	obj.getColor().red() << ", " << obj.getColor().green() << ", " <<
	obj.getColor().blue() << "]";

  return ostream;
}

#include <luabind/operator.hpp>

Object::Object(QObject *parent) : QObject(parent) {
  shape = 0;
  body = 0;

  photons_enable = false;
  photons_reflection = false;
  photons_refraction = false;
}

Object::~Object() {
  if (shape != NULL)
	delete shape;

  if (body != NULL) {
    delete body->getMotionState();
	delete body;
  }
}

QString Object::toString() const {
  return QString("Object");
}

void Object::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Object>("Object")
     .def(constructor<>())
     .def("setColor", (void(Object::*)(int, int, int))&Object::setColor)

	 .property("color",
			   (QColor(Object::*)(void))&Object::getColor,
			   (void(Object::*)(QColor))&Object::setColor)

	 .property("pos",
			   (btVector3(Object::*)(void))&Object::getPosition,
               (void(Object::*)(btVector3&))&Object::setPosition)

	 .property("trans",
			   (btTransform(Object::*)(void))&Object::getTransform,
               (void(Object::*)(btTransform&))&Object::setTransform)

	 .property("mass",
			   (btScalar(Object::*)(void))&Object::getMass,
			   (void(Object::*)(btScalar))&Object::setMass)

	 .property("vel",
			   (btVector3(Object::*)(void))&Object::getLinearVelocity,
			   (void(Object::*)(btVector3))&Object::setLinearVelocity)

	 // povray properties

	 .property("texture",
			   (QString(Object::*)(void))&Object::getTexture,
			   (void(Object::*)(QString))&Object::setTexture)

	 .property("finish",
			   (QString(Object::*)(void))&Object::getFinish,
			   (void(Object::*)(QString))&Object::setFinish)

	 .property("scale",
			   (QString(Object::*)(void))&Object::getScale,
			   (void(Object::*)(QString))&Object::setScale)

	 .def(tostring(const_self))
	 ];
}

void Object::renderInLocalFrame(QTextStream *s) const {
  Q_UNUSED(s);
}

void Object::setTexture(QString texture) {
  mTexture = texture;
}

QString Object::getTexture() const {
  return mTexture;
}

void Object::setScale(QString scale) {
  mScale = scale;
}

QString Object::getScale() const {
  return mScale;
}

void Object::setFinish(QString finish) {
  mFinish = finish;
}

QString Object::getFinish() const {
  return mFinish;
}

void Object::setMass(btScalar _mass) {
  body->setMassProps(_mass, btVector3(0,0,0));
  body->updateInertiaTensor();
}

void Object::setLinearVelocity(btVector3 vector) {
  body->setLinearVelocity(vector);
}

btVector3 Object::getLinearVelocity() const {
  return body->getLinearVelocity();
}

void Object::setColor(int r, int g, int b) {
  color[0] = r;
  color[1] = g;
  color[2] = b;
}

void Object::setColor(QColor col) {
  setColor(col.red(), col.green(), col.blue());
}

QColor Object::getColor() const {
  return QColor(color[0], color[1], color[2]);
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

btVector3 Object::getPosition() const {
  btTransform trans;
  body->getMotionState()->getWorldTransform(trans);
  return trans.getOrigin();
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

void Object::setRotation(btQuaternion r) {
  if (body != NULL) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    trans.setRotation(r);
    delete body->getMotionState();
    body->setMotionState(new btDefaultMotionState(trans));
  }
}

btQuaternion Object::getRotation() const {
  btTransform trans;
  body->getMotionState()->getWorldTransform(trans);
  return trans.getRotation();
}

void Object::setTransform(btTransform trans) {
  if (body != NULL) {
    delete body->getMotionState();
    body->setMotionState(new btDefaultMotionState(trans));
  } 
}

btTransform Object::getTransform() const {
  btTransform trans;
  body->getMotionState()->getWorldTransform(trans);
  return trans;
}

btScalar Object::getMass() const {
  return body->getInvMass();
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


void Object::render(QTextStream *s)
{
  renderInLocalFrame(s);
}
