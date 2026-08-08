#ifndef OBJECT_H
#define OBJECT_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>

#include <QColor>
#include <QTextStream>
#include <iostream>

#include <btBulletDynamicsCommon.h>

#include <qgl.h>

#include <vector>

class Object;

std::ostream &operator<<(std::ostream &, const Object &obj);
bool operator==(const Object &a, const Object &b);

#define BIT(x) (1 << (x))

enum collisiontypes {
  COL_NOTHING = 0,     //<Collide with nothing
  COL_SHIP = BIT(1),   //<Collide with ships
  COL_WALL = BIT(2),   //<Collide with walls
  COL_POWERUP = BIT(3) //<Collide with powerups
};

#include "lua_converters.h" // for Lua QString => string mapping

class Object : public QObject {
  Q_OBJECT;

public:
  Object(QObject *parent = nullptr, btScalar pmass = 0);
  virtual ~Object();

  void setColor(int r, int g, int b);
  void setColor(const QColor &col);
  void setColor(const QString &c);

  QColor getColor() const;
  QString getColorString() const;

  // 0.0 = fully opaque, 1.0 = fully transparent -- matches POV-Ray's own
  // rgbt transmit channel directly, so povPigment() can pass it straight
  // through with no remapping.
  void setTransparency(btScalar t);
  btScalar getTransparency() const;

  void setPosition(btScalar x, btScalar y, btScalar z);
  void setPosition(const btVector3 &v);

  btVector3 getPosition() const;

  void setRotation(const btVector3 &axis, btScalar angle);
  void setRotation(const btQuaternion &rot);
  btQuaternion getRotation() const;

  void setTransform(const btTransform &trans);
  btTransform getTransform() const;

  virtual void setMass(btScalar mass);
  btScalar getMass() const;

  void setFriction(btScalar friction);
  btScalar getFriction() const;

  void setRestitution(btScalar restitution);
  btScalar getRestitution() const;

  void setLinearDamping(btScalar linearDamping);
  void setAngularDamping(btScalar angularDamping);

  void setDamping(btScalar linearDamping, btScalar angularDamping);

  btScalar getLinearDamping() const;
  btScalar getAngularDamping() const;

  void setLinearVelocity(const btVector3 &vector);
  btVector3 getLinearVelocity() const;

  void setRigidBody(btRigidBody *b);
  btRigidBody *getRigidBody() const;

  void setCollisionShape(btCollisionShape *s);
  btCollisionShape *getCollisionShape() const;

  // POV-Ray properties

  void setPovPhotons(bool _photons_enable = false,
                     bool _photons_reflection = false,
                     bool _photons_refraction = false);

  virtual QString getPovPhotons() const;

  void setPOVExport(bool onoff);
  bool getPOVExport() const;

  void setPreSDL(const QString &pre_sdl);
  QString getPreSDL() const;

  void setSDL(const QString &sdl);
  QString getSDL() const;

  void setPostSDL(const QString &post_sdl);
  QString getPostSDL() const;

  btRigidBody *body;
  btCollisionShape *shape;
  bool _ownsBody;

  static void luaBind(lua_State *s);

  virtual QString toString() const;

  virtual void toPOV(QTextStream *s) const;
  virtual QString toPOV() const;

  void render(btVector3 &minaabb, btVector3 &maxaabb);
  void setRenderFunction(const luabind::object &fn);
  luabind::object getRenderFunction() const;

  virtual void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb);
  virtual void renderInLocalFramePre(btVector3 &minaabb, btVector3 &maxaabb);
  virtual void renderInLocalFramePost(btVector3 &minaabb, btVector3 &maxaabb);

  QList<btTypedConstraint *> getConstraints() const;

  void setCollisionTypes(collisiontypes col1, collisiontypes col2);
  collisiontypes getCol1() const;
  collisiontypes getCol2() const;

  static void povMatrixFromGL(const float *gl, float *pov);

protected:
  // Shared by every derived object's toPOV()/renderInLocalFrame(): writes
  // the standard "pigment { rgbt <r,g,b,t> }" line (used whenever there's
  // no custom .sdl override) and applies color+alpha as the current GL
  // color, respectively -- centralizing these means transparency support
  // doesn't have to be re-implemented in each of the ~10 primitive types.
  void povPigment(QTextStream *s) const;
  void glApplyColor() const;

  unsigned char color[3];
  btScalar transparency;

  bool photons_enable;
  bool photons_reflection;
  bool photons_refraction;

  QString mTexture;
  bool mPOVExport;
  QString mPreSDL;
  QString mSDL;
  QString mPostSDL;

  QList<btTypedConstraint *> _constraints;

  collisiontypes col1;
  collisiontypes col2;

  luabind::object _cb_render;

  mutable GLfloat matrix[16];

  std::vector<void**> _luabindWeakPtrs;

public:
  void registerLuabindWeakPtr(void** p);
  void preDestructor();
};

#endif // OBJECT_H
