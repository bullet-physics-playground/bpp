#ifndef MESH_H
#define MESH_H

#ifdef HAS_LIB_ASSIMP

// #include <GL/glew.h>

#ifdef WIN32
#include <windows.h>
#endif

#include "object.h"

#include <btBulletDynamicsCommon.h>
#include "BulletCollision/Gimpact/btGImpactShape.h"
#include "BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h"

#include <assimp/scene.h>

class Mesh : public Object {
public:
    Mesh(QString filename, btScalar mass);
    Mesh(QString filename);
    Mesh();
    ~Mesh();

    btGImpactMeshShape* getShape() const;
    void setShape(btGImpactMeshShape *shape);

    virtual void setMass(btScalar mass);

    void loadFile(QString filename, btScalar mass);

    static void luaBind(lua_State *s);
    virtual QString toString() const;

    virtual void renderInLocalFrame(QTextStream *s, btVector3& minaabb, btVector3& maxaabb);

protected:
    GLuint m_VertexVBO, m_NormalVBO;

    btGImpactMeshShape *m_shape;
    btTriangleMesh     *m_mesh;
};

#endif

#endif
