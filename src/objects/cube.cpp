#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "cube.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>

using namespace std;
#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Cube::Cube(const btVector3 &dim, btScalar mass) : Object() {
    init(dim.getX(), dim.getY(), dim.getZ(), mass);
}

Cube::Cube(btScalar width, btScalar height, btScalar depth, btScalar mass) : Object() {
    init(width, height, depth, mass);
}

void Cube::init(btScalar width, btScalar height, btScalar depth, btScalar mass) {
    lengths[0] = width;
    lengths[1] = height;
    lengths[2] = depth;

    shape = new btBoxShape(btVector3(width * .5, height * .5, depth * .5));

    btQuaternion qtn;
    btTransform trans;
    btDefaultMotionState *motionState;

    trans.setIdentity();
    qtn.setEuler(0.0, 0.0, 0.0);
    trans.setRotation(qtn);
    trans.setOrigin(btVector3(0, 0, 0));
    motionState = new btDefaultMotionState(trans);

    bool isDynamic = (mass != 0.f);
    btVector3 inertia(0, 0, 0);
    if (isDynamic)
        shape->calculateLocalInertia(mass,inertia);
    btRigidBody::btRigidBodyConstructionInfo bodyCI(mass, motionState, shape, inertia);

    body = new btRigidBody(bodyCI);
}

void Cube::luaBind(lua_State *s) {
    using namespace luabind;

    module(s)
            [
            class_<Cube,Object>("Cube")
            .def(constructor<>(), adopt(result))
            .def(constructor<btScalar, btScalar, btScalar, btScalar>(), adopt(result))
            .def(constructor<const btVector3&>(), adopt(result))
            .def(constructor<const btVector3&, btScalar>(), adopt(result))
            .def(tostring(const_self))
            ];
}

QString Cube::toString() const {
    return QString("Cube");
}

void Cube::toPOV(QTextStream *s) const {
    if (body != NULL && body->getMotionState() != NULL) {
        btTransform trans;

        body->getMotionState()->getWorldTransform(trans);
        trans.getOpenGLMatrix(matrix);
    }

    if (s != NULL) {
        if (mPreSDL == NULL) {
            *s << "box { <"
               << -lengths[0]/2.0 << ", "<< -lengths[1]/2.0 << ", " << -lengths[2]/2.0 << ">, <"
               <<  lengths[0]/2.0 << ", " << lengths[1]/2.0 << ", " <<  lengths[2]/2.0 << ">" << "\n";
        } else {
            *s << mPreSDL
               << "\n";
        }

        if (mSDL != NULL) {
            *s << mSDL
               << "\n";
        } else {
            *s << "  pigment { rgb <"
               << color[0]/255.0 << ", "
               << color[1]/255.0 << ", "
               << color[2]/255.0 << "> }"
               << "\n";
        }

        *s << "  matrix <" << matrix[0] << ","  << matrix[1] << ","  << matrix[2] << "," << "\n"
           << "          " << matrix[4] << ","  << matrix[5] << ","  << matrix[6] << ","  << "\n"
           << "          " << matrix[8] << ","  << matrix[9] << ","  << matrix[10] << "," << "\n"
           << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14] << ">" << "\n";

        if (mPostSDL == NULL) {
            *s << "}"
               << "\n"
               << "\n";
        } else {
            *s << mPostSDL
               << "\n";
        }
    }
}

void Cube::renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb) {
    Q_UNUSED(minaabb)
    Q_UNUSED(maxaabb)

    glScalef(lengths[0], lengths[1], lengths[2]);
    glColor3ubv(color);
    glutSolidCube(1.0f);
}
