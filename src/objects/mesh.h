#ifndef MESH_H
#define MESH_H

#include <GL/glew.h>

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
  ~Mesh();
  
  static void luaBind(lua_State *s);
  QString toString() const;

  virtual void renderInLocalFrame(QTextStream *s);

 protected:
  const aiScene *m_scene;
  
  GLuint m_VertexVBO, m_NormalVBO;
};

#endif
