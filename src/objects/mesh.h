#ifndef MESH_H
#define MESH_H

/**
 * @file mesh.h
 * @brief Triangle meshes loaded from model files through assimp.
 */

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

/**
 * @brief One entry of the shared mesh cache: geometry loaded from a file.
 *
 * Loading a model and building its GImpact shape is expensive, so the result
 * is cached under the file name and shared by every Mesh using it, with a
 * reference count deciding when it can go.
 */
class MeshCacheEntry {
public:
  /**
   * @brief Constructs an empty, unreferenced cache entry.
   */
  MeshCacheEntry()
      : m_shape(nullptr), m_mesh(nullptr), m_scene(nullptr), refCount(0),
        m_comOffset(0, 0, 0) {}

  /**
   * @brief Destroys the entry and the Bullet shape and mesh it holds.
   */
  ~MeshCacheEntry() {
    delete m_shape;
    delete m_mesh;
  }
  btGImpactMeshShape *m_shape; ///< Collision shape built from #m_mesh.
  btTriangleMesh *m_mesh;      ///< Triangles read from the file.
  const aiScene *m_scene;      ///< The assimp scene the mesh came from.
  int refCount;                ///< How many Mesh objects are using this entry.
  btVector3 m_comOffset;       ///< Shift applied to put the centre of mass at
                               ///< the origin.
};

/**
 * @brief A triangle mesh loaded from a model file.
 *
 * Uses assimp to read the file, so anything assimp supports can be dropped
 * into a scene, and a Bullet btGImpactMeshShape to collide with it, which
 * unlike Terrain's BVH shape also works for a mesh that moves.
 *
 * Geometry is shared: several Mesh objects loading the same file share one
 * reference-counted cache entry rather than each parsing and building their
 * own copy. The no-argument constructor is the exception - it builds its
 * geometry directly and owns it, which is what @c m_ownsMeshDirectly records.
 *
 * Exporting follows the same idea as Terrain: the mesh data is written once to
 * a file named after its content hash and included from every frame.
 */
class Mesh : public Object {
public:
  /**
   * @brief Loads a mesh from a file with a given mass.
   * @param filename     Path of the model file.
   * @param mass         Mass; 0 makes the mesh static.
   * @param centerOfMass Whether to shift the geometry so its centre of mass
   *                     sits at the body's origin.
   */
  Mesh(const QString &filename, btScalar mass, bool centerOfMass = true);

  /**
   * @brief Loads a static mesh from a file.
   * @param filename     Path of the model file.
   * @param centerOfMass Whether to shift the geometry so its centre of mass
   *                     sits at the body's origin.
   */
  Mesh(const QString &filename, bool centerOfMass = true);

  /**
   * @brief Constructs an empty mesh whose triangles are added by hand.
   *
   * The shape and triangle mesh are allocated directly rather than taken from
   * the cache, so this object owns and deletes them.
   */
  Mesh();

  /**
   * @brief Destroys the mesh, releasing or deleting its geometry.
   */
  ~Mesh();

  /**
   * @brief Returns the collision shape.
   * @return The GImpact shape, or null.
   */
  btGImpactMeshShape *getShape() const;

  /**
   * @brief Replaces the collision shape.
   * @param shape The new shape.
   */
  void setShape(btGImpactMeshShape *shape);

  /**
   * @brief Returns the triangle mesh the shape is built from.
   * @return The triangle mesh, or null.
   */
  btTriangleMesh *getTriangleMesh() const;

  /**
   * @brief Replaces the triangle mesh.
   * @param mesh The new triangle mesh.
   */
  void setTriangleMesh(btTriangleMesh *mesh);

  /**
   * @brief Sets the mesh's mass and recomputes its inertia.
   * @param mass The new mass; 0 makes the mesh static.
   */
  void setMass(btScalar mass) override;

  /**
   * @brief Drops the Bullet pointers without deleting anything.
   *
   * Called during teardown once Lua has freed the objects it adopted, so the
   * destructor does not touch memory that is already gone.
   */
  void luaRelease() {
    m_shape = nullptr;
    m_mesh = nullptr;
    body = nullptr;
    shape = nullptr;
  }

  /**
   * @brief Loads geometry from a model file, reusing the cache where possible.
   * @param filename     Path of the model file.
   * @param mass         Mass; 0 makes the mesh static.
   * @param centerOfMass Whether to shift the geometry so its centre of mass
   *                     sits at the body's origin.
   */
  void loadFile(const QString &filename, btScalar mass, bool centerOfMass = true);

  /**
   * @brief Rebuilds the rigid body from the current geometry.
   *
   * Used after the geometry has changed underneath an existing body, as when
   * OpenSCAD finishes generating one.
   *
   * @param world Dynamics world to take the old body out of and put the new
   *              one into. May be null when the body is not in a world yet.
   */
  void recreate(btDiscreteDynamicsWorld *world = nullptr);

  /**
   * @brief Registers the Mesh class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Mesh".
   */
  QString toString() const override;

  using Object::toPOV;

  /**
   * @brief Writes the mesh to a POV-Ray scene.
   *
   * The geometry is written once to a file named after its own content hash
   * and merely included from each frame, so a large mesh is not repeated in
   * every frame's include file.
   *
   * @param sceneDir Directory of the exported scene, where the shared mesh
   *                 include is written.
   * @return The SDL for this frame, which includes the shared mesh file.
   */
  QString toPOV(const QString &sceneDir) const;

  /**
   * @brief Writes the geometry as a POV-Ray @c mesh2 block.
   * @param s    The stream to write to.
   * @param hash Content hash used to name the declared mesh. Pass an empty
   *             string to emit the block unnamed, which is how the hash itself
   *             is computed in the first place.
   */
  void toMesh2(QTextStream *s, QString hash) const;

  /**
   * @brief Draws the mesh's triangles in its own frame.
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

protected:
  /// Geometry shared between Mesh objects, keyed by model file name.
  static QHash<QString, std::shared_ptr<MeshCacheEntry>> _meshCache;

  btGImpactMeshShape *m_shape; ///< Collision shape; usually owned by the cache.
  btTriangleMesh *m_mesh;      ///< Triangles; usually owned by the cache.
  const aiScene *m_scene;      ///< The assimp scene the geometry came from.
  QString m_filename;          ///< File the mesh was loaded from.
  btScalar m_mass;             ///< Mass the mesh was created with.
  btVector3 _comOffset;        ///< Shift applied to centre the mass.

  /**
   * @brief Whether this object owns its geometry outright.
   *
   * True only for the no-arg constructor, which allocates m_shape/m_mesh
   * directly instead of pulling them from the refcounted _meshCache; only
   * then does ~Mesh() own them and need to delete them itself.
   */
  bool m_ownsMeshDirectly = false;
};

#endif

#endif // MESH_H
