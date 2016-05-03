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

    open(s);

    module(s)
            [
            class_<Sphere,Object>("Sphere")
            .def(constructor<>())
            .def(constructor<btScalar>())
            .def(constructor<btScalar, btScalar>())
            .property("radius", &Sphere::getRadius, &Sphere::setRadius)
            .def(tostring(const_self))
            ];
}

QString Sphere::toString() const {
    return QString("Sphere");
}

void Sphere::renderInLocalFrame(QTextStream *s) {
    GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
    GLfloat mat_ambient[] = { color[0] / 255.0f, color[1] / 255.0f, color[2] / 255.0f, 1.0 };
    GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
    GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
    // GLfloat no_shininess[] = { 10.0 };
    // GLfloat low_shininess[] = { 5.0 };
    GLfloat high_shininess[] = { 100.0 };
    // GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};

    glScalef(radius, radius, radius);
    //  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
    glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
    glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);

    glColor3ubv(color);

    glutSolidSphere(1.0f, 64, 32);

    if (s != NULL) {
        if (mPreSDL == NULL) {
            *s << "sphere { <.0,.0,.0>, " << radius << endl;
            if (mTexture == NULL) {
                *s << "  pigment { rgb <"
                   << color[0]/255.0 << ", "
                   << color[1]/255.0 << ", "
                   << color[2]/255.0 << "> }" << endl;
            } else {
                *s << mTexture << endl;
            }
        } else {
            *s << mPreSDL << endl;
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
