#ifndef OBJECT_H
#define OBJECT_H

#include <QColor>
#include <QTextStream>

#include <btBulletDynamicsCommon.h>

class Object {
 public:
  Object();
  virtual ~Object();
  void render(QTextStream *s) const;
  void setColor(int r, int g, int b);
  void setColor(QColor col);
  void setPosition(btScalar x, btScalar y, btScalar z);
  void setPosition(btVector3 &v);
  void setRotation(btVector3 axis, btScalar angle);
  void setRotation(btQuaternion rot);
  void setTransform(btTransform trans);
  void setMass(btScalar mass);

  void setPovPhotons(bool _photons_enable = false,
		     bool _photons_reflection = false,
		     bool _photons_refraction = false);

  virtual QString getPovPhotons() const;

  btRigidBody      *body;
  btCollisionShape *shape;
 protected:
  virtual void renderInLocalFrame(QTextStream *s) const = 0;
	
  unsigned char color[3];

  bool photons_enable;
  bool photons_reflection;
  bool photons_refraction;
};

#endif // OBJECT_H
