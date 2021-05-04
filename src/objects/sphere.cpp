#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "sphere.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Sphere::Sphere(btScalar pradius, btScalar mass) : Object()
{
    radius = pradius;

    shape = new btSphereShape(radius);

    btQuaternion qtn;
    btTransform trans;
    btDefaultMotionState *motionState;

    trans.setIdentity();
    qtn.setEuler(0.0, 0.0, 0.0);
    trans.setRotation(qtn);
    trans.setOrigin(btVector3(0, 0, 0));
    motionState = new btDefaultMotionState(trans);

    btVector3 inertia;
    shape->calculateLocalInertia(mass,inertia);
    body = new btRigidBody(mass, motionState, shape, inertia);
}

void Sphere::setRadius(btScalar pradius) {
    delete shape;

    radius = pradius;

    shape = new btSphereShape(radius);
}

btScalar Sphere::getRadius() const {
    return radius;
}

void Sphere::luaBind(lua_State *s) {
    using namespace luabind;

    module(s)
            [
            class_<Sphere,Object>("Sphere")
            .def(constructor<>(), adopt(result))
            .def(constructor<btScalar>(), adopt(result))
            .def(constructor<btScalar, btScalar>(), adopt(result))
            .property("radius", &Sphere::getRadius, &Sphere::setRadius)
            .def(tostring(const_self))
            ];
}

QString Sphere::toString() const {
    return QString("Sphere");
}

void Sphere::toPOV(QTextStream *s) const {
    if (body != NULL && body->getMotionState() != NULL) {
        btTransform trans;

        body->getMotionState()->getWorldTransform(trans);
        trans.getOpenGLMatrix(matrix);
    }

    if (s != NULL) {
        if (mPreSDL == NULL) {
            *s << "sphere { <.0,.0,.0>, " << radius << Qt::endl;
        } else {
            *s << mPreSDL << Qt::endl;
        }

        if (mSDL != NULL) {
            *s << mSDL
               << Qt::endl;
        } else {
            *s << "  pigment { rgb <"
               << color[0]/255.0 << ", "
               << color[1]/255.0 << ", "
               << color[2]/255.0 << "> }"
               << Qt::endl;
        }

        *s << "  matrix <" <<  matrix[0] << "," <<  matrix[1] << "," <<  matrix[2] << "," << Qt::endl
           << "          " <<  matrix[4] << "," <<  matrix[5] << "," <<  matrix[6] << "," << Qt::endl
           << "          " <<  matrix[8] << "," <<  matrix[9] << "," << matrix[10] << "," << Qt::endl
           << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14] << ">" << Qt::endl;

        if (mPostSDL == NULL) {
            *s << "}" << Qt::endl << Qt::endl;
        } else {
            *s << mPostSDL << Qt::endl;
        }
    }
}

void Sphere::renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb) {
    Q_UNUSED(minaabb)
    Q_UNUSED(maxaabb)

    glScalef(radius, radius, radius);
    glColor3ub(color[0], color[1], color[2]);
    glutSolidSphere(1.0f, 32, 16);
}
