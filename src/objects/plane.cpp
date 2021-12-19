#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "plane.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Plane::Plane(const btVector3 &dim, btScalar nConst, btScalar psize) : Object() {
    init(dim.getX(), dim.getY(), dim.getZ(), nConst, psize);
}

Plane::Plane(btScalar nx, btScalar ny, btScalar nz,
             btScalar nConst, btScalar psize) : Object() {
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

    module(s)
            [
            class_<Plane, Object>("Plane")
            .def(constructor<>(), adopt(result))
            .def(constructor<btScalar>(), adopt(result))
            .def(constructor<btScalar, btScalar>(), adopt(result))
            .def(constructor<btScalar, btScalar, btScalar>(), adopt(result))
            .def(constructor<btScalar, btScalar, btScalar, btScalar>(), adopt(result))
            .def(constructor<btScalar, btScalar, btScalar, btScalar, btScalar>(), adopt(result))
            .def(constructor<const btVector3&, btScalar, btScalar>(), adopt(result))
            .def(tostring(const_self))
            ];
}

QString Plane::toString() const {
    return QString("Plane");
}

void Plane::toPOV(QTextStream *s) const {
    if (body != NULL && body->getMotionState() != NULL) {
        btTransform trans;

        body->getMotionState()->getWorldTransform(trans);
        trans.getOpenGLMatrix(matrix);
    }

    if (s != NULL) {
        if (mPreSDL == NULL) {
            const btStaticPlaneShape* staticPlaneShape = static_cast<const btStaticPlaneShape*>(shape);
            const btVector3& planeNormal = staticPlaneShape->getPlaneNormal();
            btScalar planeConst = staticPlaneShape->getPlaneConstant();

            *s << "plane { <"
               << planeNormal[0] << ", "
               << planeNormal[1] << ", "
               << planeNormal[2] << ">, "
               << planeConst << endl;
        } else {
            *s << mPreSDL << endl;
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

        *s << "  matrix <" <<  matrix[0] << "," <<  matrix[1] << "," <<  matrix[2] << "," << endl
           << "          " <<  matrix[4] << "," <<  matrix[5] << "," <<  matrix[6] << "," << endl
           << "          " <<  matrix[8] << "," <<  matrix[9] << "," << matrix[10] << "," << endl
           << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14] << ">" << endl;

        if (mPostSDL == NULL) {
            *s << "}" << endl << endl;
        } else {
            *s << mPostSDL << endl;
        }
    }
}

void Plane::renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb) {
    Q_UNUSED(minaabb)
    Q_UNUSED(maxaabb)

    // qDebug() << "Plane::renderInLocalFrame";

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

    glColor3ubv(color);

    glBegin(GL_LINES);
    glVertex3f(pt0.getX(), pt0.getY(), pt0.getZ());
    glVertex3f(pt1.getX(), pt1.getY(), pt1.getZ());
    glVertex3f(pt2.getX(), pt2.getY(), pt2.getZ());
    glVertex3f(pt3.getX(), pt3.getY(), pt3.getZ());
    glEnd();

    glBegin(GL_TRIANGLES);
    glNormal3fv(planeNormal);
    glVertex3fv(pt0);
    glVertex3fv(pt1);
    glVertex3fv(pt2);
    glVertex3fv(pt2);
    glVertex3fv(pt1);
    glVertex3fv(pt0);
    glVertex3fv(pt0);
    glVertex3fv(pt1);
    glVertex3fv(pt3);
    glVertex3fv(pt3);
    glVertex3fv(pt1);
    glVertex3fv(pt0);
    glEnd();

}

void Plane::render(btVector3& minaabb, btVector3& maxaabb) {
    renderInLocalFrame(minaabb, maxaabb);
}

btScalar Plane::getSize() {
    return size;
}
