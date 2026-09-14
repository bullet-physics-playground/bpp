#ifndef TERRAIN_H
#define TERRAIN_H

/**
 * @file terrain.h
 * @brief Static concave ground mesh built from Lua-supplied triangles.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

#include <QHash>

#include <array>

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
   * @brief Colours a single triangle, overriding the terrain's own colour.
   *
   * The triangle is addressed by the 0-based index Bullet hands back in
   * addTriangle() call order -- triangle N is the Nth addTriangle() call.
   * Lets a script mark individual terrain cells, a walker's footprint trail
   * say, by recolouring existing mesh geometry instead of spawning extra
   * static bodies: a trail of separate Cube markers keeps adding rigid
   * bodies, and draw calls, for the life of the run, while this recolours
   * triangles that are already part of the one terrain body and already
   * drawn every frame. Triangles with no explicit colour fall back to the
   * terrain's own colour at render time.
   *
   * @note Affects the real-time OpenGL viewer only -- toPOV() and toMesh2()
   *       still export the terrain in its single base colour.
   *
   * @param index The triangle's index, in addTriangle() call order.
   * @param r     Red, 0 to 255; values outside the range are clamped.
   * @param g     Green, 0 to 255; values outside the range are clamped.
   * @param b     Blue, 0 to 255; values outside the range are clamped.
   */
  void setTriangleColor(int index, int r, int g, int b);

  /**
   * @brief Colours a single triangle from a name or hex string.
   * @param index The triangle's index, in addTriangle() call order.
   * @param col   Anything QColor accepts, such as @c "red" or @c "#ff8800".
   */
  void setTriangleColor(int index, const QString &col);

  /**
   * @brief Returns a triangle's colour as a hex string.
   * @param index The triangle's index, in addTriangle() call order.
   * @return The triangle's own colour in @c "#rrggbb" form, or the
   *         terrain's colour if that triangle has no override.
   */
  QString getTriangleColor(int index) const;

  /**
   * @brief Drops every per-triangle colour override.
   */
  void clearTriangleColors();

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

  /**
   * @brief Per-triangle colour overrides, keyed by triangle index.
   *
   * Sparse on purpose: a trail marks a tiny fraction of a mesh that can be
   * thousands of triangles, so a hash keyed by triangle index costs nothing
   * for the overwhelming majority of uncoloured triangles, unlike a vector
   * sized to getNumTriangles().
   */
  QHash<int, std::array<unsigned char, 3>> m_triColors;
};

#endif // TERRAIN_H
