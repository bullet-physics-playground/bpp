#ifndef TERRAIN_H
#define TERRAIN_H

/**
 * @file terrain.h
 * @brief Static concave ground mesh built from Lua-supplied triangles.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A static, concave triangle mesh, typically a bumpy floor.
 *
 * Static concave ground mesh backed by btBvhTriangleMeshShape -- Bullet's
 * BVH-accelerated shape for immovable triangle meshes. Unlike Mesh (which
 * wraps btGImpactMeshShape for arbitrary, potentially-dynamic assimp
 * meshes), Terrain is always static (mass 0, never moves after build()) and
 * is built directly from Lua-supplied triangles rather than loaded from a
 * file, which is what lets the BVH tree be built once and reused: a much
 * better fit for a bumpy floor than GImpact, which is meant for meshes that
 * might move and is markedly slower/less stable as a static collider.
 *
 * Build one by calling addTriangle() for each face and then build() once.
 */
class Terrain : public Object {
public:
  /**
   * @brief Constructs an empty terrain with no triangles yet.
   */
  Terrain();

  /**
   * @brief Destroys the terrain, its BVH shape and its triangle mesh.
   */
  ~Terrain();

  /**
   * @brief Adds one triangle to the mesh being accumulated.
   *
   * Accumulates one triangle into the pending mesh. Call build() once all
   * triangles have been added -- the BVH tree is constructed there, not
   * incrementally, since rebuilding it per-triangle would be wasteful.
   *
   * @param v0 First corner.
   * @param v1 Second corner.
   * @param v2 Third corner.
   */
  void addTriangle(const btVector3 &v0, const btVector3 &v1,
                    const btVector3 &v2);

  /**
   * @brief Turns the accumulated triangles into a collidable shape.
   *
   * Finalizes the accumulated triangles into a btBvhTriangleMeshShape and
   * creates the (static, mass 0) rigid body. Safe to call again after
   * adding more triangles -- rebuilds the shape and body from scratch.
   */
  void build();

  /**
   * @brief Returns how many triangles the mesh holds.
   * @return The triangle count.
   */
  int getNumTriangles() const;

  /**
   * @brief Registers the Terrain class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Terrain".
   */
  QString toString() const override;

  using Object::toPOV;

  /**
   * @brief Writes the terrain to a POV-Ray scene.
   *
   * The terrain never moves and is typically large, so - exactly as for Mesh -
   * the mesh data is written once to a file named after its own content hash
   * and merely included from each frame, rather than being repeated inline in
   * every frame's include file.
   *
   * @param sceneDir Directory of the exported scene, where the shared mesh
   *                 include is written.
   * @return The SDL for this frame, which includes the shared mesh file.
   */
  QString toPOV(const QString &sceneDir) const;

  /**
   * @brief Writes the triangles as a POV-Ray @c mesh2 block.
   * @param s    The stream to write to.
   * @param hash Content hash used to name the declared mesh. Pass an empty
   *             string to emit the block unnamed, which is how the hash
   *             itself is computed in the first place.
   */
  void toMesh2(QTextStream *s, QString hash) const;

  /**
   * @brief Draws the terrain's triangles in its own frame.
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

protected:
  btTriangleMesh *m_mesh;          ///< The accumulated triangles.
  btBvhTriangleMeshShape *m_shape; ///< BVH shape built from #m_mesh by build().
};

#endif // TERRAIN_H
