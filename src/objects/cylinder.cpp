#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "cylinder.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/freeglut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>

Cylinder::Cylinder(const btVector3& dim, btScalar mass) : Object() {
    init(dim.getX(), dim.getZ(), mass);
}

Cylinder::Cylinder(btScalar radius, btScalar depth,
                   btScalar mass) : Object() {

    init(radius, depth, mass);
}

void Cylinder::init(btScalar radius, btScalar depth,
                    btScalar mass) {

    lengths[0] = radius;
    lengths[1] = radius;
    lengths[2] = depth;

    shape = new btCylinderShapeZ(btVector3(radius, radius, depth*.5));

    btQuaternion qtn;
    btTransform trans;
    btDefaultMotionState *motionState;

    trans.setIdentity();
    qtn.setEuler(0.0, 0.0, 0.0);
    trans.setRotation(qtn);
    trans.setOrigin(btVector3(0,0,0));
    motionState = new btDefaultMotionState(trans);

    btVector3 inertia;
    shape->calculateLocalInertia(mass,inertia);
    body = new btRigidBody(mass, motionState, shape, inertia);

}

void Cylinder::luaBind(lua_State *s) {
    using namespace luabind;

    open(s);

    module(s)
            [
            class_<Cylinder, Object>("Cylinder")
            .def(constructor<>())
            .def(constructor<const btVector3&>())
            .def(constructor<const btVector3&, btScalar>())
            .def(constructor<btScalar, btScalar>())
            .def(constructor<btScalar, btScalar, btScalar>())
            .def(tostring(const_self))
            ];
}

QString Cylinder::toString() const {
    return QString("Cylinder");
}

void Cylinder::renderInLocalFrame(QTextStream *s, btVector3& minaabb, btVector3& maxaabb) {
    Q_UNUSED(minaabb)
    Q_UNUSED(maxaabb)

    GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
    GLfloat mat_ambient[] = { color[0] / 255.0f, color[1] / 255.0f, color[2] / 255.0f, 1.0 };
    GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
    GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
    // GLfloat no_shininess[] = { 0.0 };
    // GLfloat low_shininess[] = { 5.0 };
    GLfloat high_shininess[] = { 100.0 };
    // GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};

    // translate to match Bullet cylinder origin
    glTranslated(0,0,-lengths[2]*.5);
    glScalef(lengths[0], lengths[1], lengths[2]);

    glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
    glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
    glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);
    glColor3ubv(color);

    glutSolidCylinder(1, 1, 16, 16);

    if (s != NULL) {
        if (mPreSDL == NULL) {
            *s << "cylinder { "
               << -lengths[2]/2.0 << "*z, "
               << lengths[2]/2.0 << "*z, "
               << lengths[0]
               << endl;
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
