#ifndef OBJECT_H
#define OBJECT_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>

#include <QColor>
#include <QTextStream>

#include <btBulletDynamicsCommon.h>

class Object;

std::ostream& operator<<(std::ostream&, const Object& obj);

class Object : public QObject {
 Q_OBJECT;

 public:
  Object(QObject *parent = NULL);
  virtual ~Object();

  void render(QTextStream *s);
  void setColor(int r, int g, int b);
  void setColor(QColor col);

  QColor getColor() const;

  void setPosition(btScalar x, btScalar y, btScalar z);
  void setPosition(btVector3& v);

  btVector3 getPosition() const;

  void setRotation(btVector3 axis, btScalar angle);
  void setRotation(btQuaternion rot);
  btQuaternion getRotation() const;

  void setTransform(btTransform trans);
  btTransform getTransform() const;

  void setMass(btScalar mass);
  btScalar getMass() const;

  void setLinearVelocity(btVector3 vector);
  btVector3 getLinearVelocity() const;

  void setPovPhotons(bool _photons_enable = false,
		     bool _photons_reflection = false,
		     bool _photons_refraction = false);

  virtual QString getPovPhotons() const;

  void setTexture(QString texture);
  QString getTexture() const;

  void setFinish(QString finish);
  QString getFinish() const;

  void setScale(QString scale);
  QString getScale() const;

  btRigidBody      *body;
  btCollisionShape *shape;

  static void luaBind(lua_State *s);

  virtual QString toString() const;

 protected:
  virtual void renderInLocalFrame(QTextStream *s) const;
	
  unsigned char color[3];

  bool photons_enable;
  bool photons_reflection;
  bool photons_refraction;

  QString mTexture;
  QString mScale;
  QString mFinish;
};

#endif // OBJECT_H
