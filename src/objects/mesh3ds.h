#ifndef Model3DS_H
#define Model3DS_H

// #include <GL/glew.h>

#ifdef WIN32
#include <windows.h>
#endif

#include "object.h"

#include <btBulletDynamicsCommon.h>
#include "BulletCollision/Gimpact/btGImpactShape.h"
#include "BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h"

#include <lib3ds/file.h>

class Mesh3DS : public Object {
public:
    Mesh3DS(QString filename, btScalar mass);

    static void luaBind(lua_State *s);
    QString toString() const;

    virtual void renderInLocalFrame(QTextStream *s);

protected:
    GLuint m_VertexVBO, m_NormalVBO;

    unsigned int m_TotalFaces;
    Lib3dsFile * m_model;
};

#endif
