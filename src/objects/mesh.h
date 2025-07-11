#ifndef MESH_H
#define MESH_H

#ifdef HAS_LIB_ASSIMP

// #include <GL/glew.h>

#ifdef WIN32
#include <windows.h>
#endif

#include "object.h"

#include "BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h"
#include "BulletCollision/Gimpact/btGImpactShape.h"
#include <btBulletDynamicsCommon.h>

#include <assimp/scene.h>

class Mesh : public Object {
public:
  Mesh(QString filename, btScalar mass);
  Mesh(QString filename);
  Mesh();
  ~Mesh();

  btGImpactMeshShape *getShape() const;
  void setShape(btGImpactMeshShape *shape);

  virtual void setMass(btScalar mass);

  void loadFile(QString filename, btScalar mass);

  static void luaBind(lua_State *s);
  virtual QString toString() const;
  virtual void toPOV(QTextStream *s) const;
  virtual void toMesh2(QTextStream *s) const;

  virtual void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb);

protected:
  btGImpactMeshShape *m_shape;
  btTriangleMesh *m_mesh;
  const aiScene *m_scene;
};

#endif

#endif // MESH_H
