#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "object.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>

#include <boost/shared_ptr.hpp>
#include <luabind/adopt_policy.hpp>

using namespace std;

std::ostream& operator<<(std::ostream& ostream, const Object& obj) {
    ostream << obj.toString().toUtf8().data() << "[ rgb: " <<
               obj.getColor().red() << ", " << obj.getColor().green() << ", " <<
               obj.getColor().blue() << "]";

    return ostream;
}

#include <luabind/operator.hpp>

Object::Object(QObject *parent, btScalar pmass) : QObject(parent) {
    Q_UNUSED(pmass)

    // qDebug() << "Object::Object()";

    mPOVExport = true;

    shape = 0;
    body  = 0;

    setColor(0.5,0.5,0.5);

    photons_enable = false;
    photons_reflection = false;
    photons_refraction = false;

    setCollisionTypes(COL_WALL, COL_WALL);

    _cb_render = luabind::object();
}

Object::~Object() {

    // qDebug() << "Object::~Object()";

    if (shape != NULL) {
        // delete shape;
        // FIXME shape = NULL;
    }

    if (body != NULL) {
        // delete body;
        // FIXME body = NULL;
    }
}

void Object::setCollisionTypes(collisiontypes col1, collisiontypes col2) {
    this->col1 = col1;
    this->col2 = col2;
}

collisiontypes Object::getCol1() const {
    return col1;
}

collisiontypes Object::getCol2() const {
    return col2;
}

QList<btTypedConstraint *> Object::getConstraints() {
    return _constraints;
}

QString Object::toString() const {
    return QString("Object");
}

void Object::toPOV(QTextStream *s) const {
    if (body != NULL && body->getMotionState() != NULL) {
        btTransform trans;

        body->getMotionState()->getWorldTransform(trans);
        trans.getOpenGLMatrix(matrix);
    }

    if (s != NULL) {
        if (mPreSDL == NULL) {
            *s << "sphere { <0,0,0>, 1" << endl;
        } else {
            *s << mPreSDL
               << endl;
        }

        if (mSDL != NULL) {
            *s << mSDL
               << endl;
        } else {
            *s << "  pigment { rgb <"
               << color[0]/255.0 << ", "
               << color[1]/255.0 << ", "
               << color[2]/255.0 << "> }"
               << endl;
        }

        *s << "  matrix <" << matrix[0] << ","  << matrix[1] << ","  << matrix[2] << "," << endl
           << "          " << matrix[4] << ","  << matrix[5] << ","  << matrix[6] << ","  << endl
           << "          " << matrix[8] << ","  << matrix[9] << ","  << matrix[10] << "," << endl
           << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14] << ">" << endl;

        if (mPostSDL == NULL) {
            *s << "}"
               << endl
               << endl;
        } else {
            *s << mPostSDL
               << endl;
        }
    }
}

void Object::luaBind(lua_State *s) {
    using namespace luabind;

    open(s);

    module(s)
            [
            class_<Object>("Object")
            .def(constructor<>(), adopt(result))
            .def(constructor<QObject *>(), adopt(result))
            .def(constructor<QObject *, btScalar>(), adopt(result))
            .def("setColor", (void(Object::*)(QColor))&Object::setColor)
            .def("setColor", (void(Object::*)(QString))&Object::setColor)
            .def("setColor", (void(Object::*)(int, int, int))&Object::setColor)

            .property("color",
                      (QColor(Object::*)(void))&Object::getColor,
                      (void(Object::*)(QColor))&Object::setColor)

            .property("col",
                      (QString(Object::*)(void))&Object::getColorString,
                      (void(Object::*)(QString))&Object::setColor)

            .property("pos",
                      (btVector3(Object::*)(void))&Object::getPosition,
                      (void(Object::*)(const btVector3&))&Object::setPosition)

            .property("trans",
                      (btTransform(Object::*)(void))&Object::getTransform,
                      (void(Object::*)(const btTransform&))&Object::setTransform)

            .property("mass",
                      (btScalar(Object::*)(void))&Object::getMass,
                      (void(Object::*)(btScalar))&Object::setMass)

            .property("vel",
                      (btVector3(Object::*)(void))&Object::getLinearVelocity,
                      (void(Object::*)(const btVector3&))&Object::setLinearVelocity)

            .property("friction",
                      (btScalar(Object::*)(void))&Object::getFriction,
                      (void(Object::*)(btScalar))&Object::setFriction)

            .property("restitution",
                      (btScalar(Object::*)(void))&Object::getRestitution,
                      (void(Object::*)(btScalar))&Object::setRestitution)

            .property("damp_lin",
                      (btScalar(Object::*)(void))&Object::getLinearDamping,
                      (void(Object::*)(btScalar))&Object::setLinearDamping)

            .property("damp_ang",
                      (btScalar(Object::*)(void))&Object::getAngularDamping,
                      (void(Object::*)(btScalar))&Object::setAngularDamping)

            // povray properties

            .property("pov_export",
                      (bool(Object::*)(void))&Object::getPOVExport,
                      (void(Object::*)(bool))&Object::setPOVExport)

            .property("pre_sdl",
                      (QString(Object::*)(void))&Object::getPreSDL,
                      (void(Object::*)(QString))&Object::setPreSDL)

            .property("sdl",
                      (QString(Object::*)(void))&Object::getSDL,
                      (void(Object::*)(QString))&Object::setSDL)

            .property("post_sdl",
                      (QString(Object::*)(void))&Object::getPostSDL,
                      (void(Object::*)(QString))&Object::setPostSDL)

            .def("getRigidBody", &Object::getRigidBody)
            .def("setRigidBody", &Object::setRigidBody)

            .property("body", &Object::getRigidBody, &Object::setRigidBody)

            .def("getCollisionShape", &Object::getCollisionShape)
            .def("setCollisionShape", &Object::setCollisionShape)

            .property("shape", &Object::getCollisionShape, &Object::setCollisionShape)

            .def("setRenderFunction", &Object::setRenderFunction)
            .def("getRenderFunction", &Object::getRenderFunction)

            .property("render", &Object::getRenderFunction, &Object::setRenderFunction)

            .def("toPOV", (QString(Object::*)() const)&Object::toPOV)
            .property("pov", (QString(Object::*)() const)&Object::toPOV)

            .def(tostring(const_self))
            ];
}

void Object::renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb) {
    Q_UNUSED(minaabb)
    Q_UNUSED(maxaabb)

    glScalef(0.5, 0.5, 0.5);
    glColor3ub(color[0], color[1], color[2]);
    glutSolidSphere(1.0f, 32, 16);
}

void Object::renderInLocalFramePre(btVector3& oaabbmin, btVector3& oaabbmax) {
    btTransform trans;

    if (isfinite(oaabbmin[0]) && isfinite(oaabbmin[1]) && isfinite(oaabbmin[2]) &&
            isfinite(oaabbmax[3]) && isfinite(oaabbmax[4]) && isfinite(oaabbmax[5])) {
        // qDebug() << toString() << (body->getMotionState());

        if (body != NULL && body->getMotionState() != NULL
                //&& typeid(body->getMotionState()) == typeid(btDefaultMotionState) //XXX
                ) {
            body->getMotionState()->getWorldTransform(trans);
            trans.getOpenGLMatrix(matrix);
            glPushMatrix();
            glMultMatrixf(matrix);
        }

        glEnable(GL_NORMALIZE);

        if (_cb_render) {
            luabind::call_function<void>(_cb_render, this);
        }
    }
}

void Object::renderInLocalFramePost(btVector3& oaabbmin, btVector3& oaabbmax) {
    if (isfinite(oaabbmin[0]) && isfinite(oaabbmin[1]) && isfinite(oaabbmin[2]) &&
            isfinite(oaabbmax[3]) && isfinite(oaabbmax[4]) && isfinite(oaabbmax[5])) {
        if (body)
            glPopMatrix();
    }
}

void Object::setPostSDL(QString post_sdl) {
    mPostSDL = post_sdl;
}

QString Object::getPostSDL() const {
    return mPostSDL;
}

void Object::setPreSDL(QString pre_sdl) {
    mPreSDL = pre_sdl;
}

QString Object::getPreSDL() const {
    return mPreSDL;
}

void Object::setSDL(QString sdl) {
    mSDL = sdl;
}

QString Object::getSDL() const {
    return mSDL;
}

void Object::setMass(btScalar _mass) {
    if (body != NULL && shape != NULL) {
        btVector3 inertia;
        shape->calculateLocalInertia(_mass,inertia);
        body->setMassProps(_mass, inertia);
    }
}

void Object::setFriction(btScalar friction) {
    if (body != NULL) body->setFriction(friction);
}

btScalar Object::getFriction() const {
    if (body != NULL) return body->getFriction(); else return 0;
}

void Object::setRestitution(btScalar restitution) {
    if (body != NULL) body->setRestitution(restitution);
}

btScalar Object::getRestitution() const {
    if (body != NULL) return body->getRestitution(); else return 0;
}

void Object::setLinearDamping(btScalar linearDamping) {
    if (body != NULL) body->setDamping(linearDamping, getAngularDamping());
}

void Object::setAngularDamping(btScalar angularDamping) {
    if (body != NULL) body->setDamping(getLinearDamping(), angularDamping);
}

void Object::setDamping(btScalar linearDamping, btScalar angularDamping) {
    if (body != NULL) body->setDamping(linearDamping, angularDamping);
}

btScalar Object::getLinearDamping() const {
    if (body != NULL) return body->getLinearDamping(); else return 0;
}

btScalar Object::getAngularDamping() const {
    if (body != NULL) return body->getAngularDamping(); else return 0;
}

void Object::setLinearVelocity(const btVector3 &vector) {
    if (body != NULL) body->setLinearVelocity(vector);
}

btVector3 Object::getLinearVelocity() const {
    if (body != NULL) return body->getLinearVelocity(); else return btVector3();
}

void Object::setRigidBody(btRigidBody *b) {
    body = b;
}

btRigidBody* Object::getRigidBody() const {
    return body;
}

void Object::setCollisionShape(btCollisionShape *s) {
    shape = s;
}

btCollisionShape* Object::getCollisionShape() {
    return shape;
}

void Object::setColor(int r, int g, int b) {
    color[0] = r;
    color[1] = g;
    color[2] = b;
}

void Object::setColor(QString col) {
    setColor(QColor(col));
}

void Object::setColor(QColor col) {
    setColor(col.red(), col.green(), col.blue());
}

QColor Object::getColor() const {
    return QColor(color[0], color[1], color[2]);
}

QString Object::getColorString() const {
    return getColor().name();
}

void Object::setPosition(const btVector3& v) {
    setPosition(v[0], v[1], v[2]);
}

void Object::setPosition(btScalar x, btScalar y, btScalar z) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    trans.setOrigin(btVector3(x, y, z));
    delete body->getMotionState();
    body->setMotionState(new btDefaultMotionState(trans));
}

btVector3 Object::getPosition() const {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    return trans.getOrigin();
}

void Object::setRotation(const btVector3& axis, btScalar angle) {
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

void Object::setRotation(const btQuaternion &r) {
    if (body != NULL) {
        btTransform trans;
        body->getMotionState()->getWorldTransform(trans);
        trans.setRotation(r);
        delete body->getMotionState();
        body->setMotionState(new btDefaultMotionState(trans));
    }
}

btQuaternion Object::getRotation() const {
    if (body != NULL) {
        btTransform trans;
        body->getMotionState()->getWorldTransform(trans);
        return trans.getRotation();
    } else {
        return btQuaternion();
    }
}

void Object::setTransform(const btTransform &trans) {
    if (body != NULL) {
        delete body->getMotionState();
        body->setMotionState(new btDefaultMotionState(trans));
    }
}

btTransform Object::getTransform() const {
    if (body != NULL) {
        btTransform trans;
        body->getMotionState()->getWorldTransform(trans);
        return trans;
    } else {
        return btTransform();
    }
}

btScalar Object::getMass() const {
    if (body != NULL) return body->getInvMass(); else return 0;
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

void Object::render(btVector3& minaabb, btVector3& maxaabb) {
    if (body) {
        renderInLocalFramePre(minaabb, maxaabb);
        renderInLocalFrame(minaabb, maxaabb);
        renderInLocalFramePost(minaabb, maxaabb);
    }
}

void Object::setRenderFunction(const luabind::object &fn) {
    if (luabind::type(fn) == LUA_TFUNCTION) {
        _cb_render = fn;
    }
}

luabind::object Object::getRenderFunction() const {
    return _cb_render;
}

QString Object::toPOV() const {
    btTransform trans;

    if (body != NULL && body->getMotionState() != NULL
            //&& typeid(body->getMotionState()) == typeid(btDefaultMotionState) //XXX
            ) {
        body->getMotionState()->getWorldTransform(trans);
        trans.getOpenGLMatrix(matrix);
    }

    QByteArray *data = new QByteArray();
    QTextStream* s = new QTextStream(data);

    toPOV(s);

    s->flush();

    QString str = QString::fromStdString(data->toStdString());
    delete data;
    return str;
}

void Object::setPOVExport(bool onoff) {
    mPOVExport = onoff;
}

bool Object::getPOVExport() {
    return mPOVExport;
}
