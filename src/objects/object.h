#ifndef OBJECT_H
#define OBJECT_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>

#include <QColor>
#include <QTextStream>

#include <btBulletDynamicsCommon.h>

#include <qgl.h>

class Object;

std::ostream& operator<<(std::ostream&, const Object& obj);

#define BIT(x) (1<<(x))

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
    Object(QObject *parent = 0);
    virtual ~Object();

    void setColor(int r, int g, int b);
    void setColor(QColor col);
    void setColor(QString c);

    QColor getColor() const;
    QString getColorString() const;

    void setPosition(btScalar x, btScalar y, btScalar z);
    void setPosition(const btVector3& v);

    btVector3 getPosition() const;

    void setRotation(const btVector3& axis, btScalar angle);
    void setRotation(const btQuaternion& rot);
    btQuaternion getRotation() const;

    void setTransform(const btTransform& trans);
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

    void setLinearVelocity(const btVector3& vector);
    btVector3 getLinearVelocity() const;

    void setRigidBody(btRigidBody *b);
    btRigidBody* getRigidBody() const;

    void setCollisionShape(btCollisionShape* s);
    btCollisionShape* getCollisionShape();

    // POV-Ray properties

    void setPovPhotons(bool _photons_enable = false,
                       bool _photons_reflection = false,
                       bool _photons_refraction = false);

    virtual QString getPovPhotons() const;

    void setTexture(QString texture);
    QString getTexture() const;

    void setPOVExport(bool onoff);
    bool getPOVExport();

    void setPreSDL(QString pre_sdl);
    QString getPreSDL() const;

    void setSDL(QString sdl);
    QString getSDL() const;

    void setPostSDL(QString post_sdl);
    QString getPostSDL() const;

    btRigidBody      *body;
    btCollisionShape *shape;

    static void luaBind(lua_State *s);

    virtual QString toString() const;

    virtual void toPOV(QTextStream *s) const;
    virtual QString toPOV() const;

    void render(btVector3& minaabb, btVector3& maxaabb);
    void setRenderFunction(const luabind::object &fn);
    luabind::object getRenderFunction() const;

    virtual void renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb);
    virtual void renderInLocalFramePre(btVector3& minaabb, btVector3& maxaabb);
    virtual void renderInLocalFramePost(btVector3& minaabb, btVector3& maxaabb);

    QList<btTypedConstraint*> getConstraints();

    void setCollisionTypes(collisiontypes col1, collisiontypes col2);
    collisiontypes getCol1() const;
    collisiontypes getCol2() const;
protected:

    unsigned char color[3];

    bool photons_enable;
    bool photons_reflection;
    bool photons_refraction;

    QString mTexture;
    bool mPOVExport;
    QString mPreSDL;
    QString mSDL;
    QString mPostSDL;

    QList<btTypedConstraint*> _constraints;

    collisiontypes col1;
    collisiontypes col2;

    luabind::object _cb_render;

    mutable GLfloat matrix[16];
};

#endif // OBJECT_H
