#ifndef MESH_H
#define MESH_H

#ifdef HAS_LIB_ASSIMP

// #include <GL/glew.h>

#ifdef WIN32
#include <windows.h>
#endif

#include "object.h"

#include <QHash>
#include <memory>

#include "BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h"
#include "BulletCollision/Gimpact/btGImpactShape.h"
#include <btBulletDynamicsCommon.h>

#include <assimp/cimport.h>
#include <assimp/scene.h>

class MeshCacheEntry {
public:
  MeshCacheEntry()
      : m_shape(nullptr), m_mesh(nullptr), m_scene(nullptr), refCount(0),
        m_comOffset(0, 0, 0) {}
  ~MeshCacheEntry() {
    delete m_shape;
    delete m_mesh;
  }
  btGImpactMeshShape *m_shape;
  btTriangleMesh *m_mesh;
  const aiScene *m_scene;
  int refCount;
  btVector3 m_comOffset;
};

class Mesh : public Object {
public:
  Mesh(const QString &filename, btScalar mass, bool centerOfMass = true);
  Mesh(const QString &filename, bool centerOfMass = true);
  Mesh();
  ~Mesh();

  btGImpactMeshShape *getShape() const;
  void setShape(btGImpactMeshShape *shape);

  btTriangleMesh *getTriangleMesh() const;
  void setTriangleMesh(btTriangleMesh *mesh);

  void setMass(btScalar mass) override;

  void luaRelease() {
    m_shape = nullptr;
    m_mesh = nullptr;
    body = nullptr;
    shape = nullptr;
  }

  void loadFile(const QString &filename, btScalar mass, bool centerOfMass = true);

  void recreate(btDiscreteDynamicsWorld *world = nullptr);

  static void luaBind(lua_State *s);
  QString toString() const override;
  QString toPOV(const QString &sceneDir) const;
  void toMesh2(QTextStream *s, QString hash) const;

  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

protected:
  static QHash<QString, std::shared_ptr<MeshCacheEntry>> _meshCache;

  btGImpactMeshShape *m_shape;
  btTriangleMesh *m_mesh;
  const aiScene *m_scene;
  QString m_filename;
  btScalar m_mass;
  btVector3 _comOffset;

  // True only for the no-arg constructor, which allocates m_shape/m_mesh
  // directly instead of pulling them from the refcounted _meshCache; only
  // then does ~Mesh() own them and need to delete them itself.
  bool m_ownsMeshDirectly = false;
};

#endif

#endif // MESH_H
