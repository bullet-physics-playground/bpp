#ifndef TERRAIN_H
#define TERRAIN_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

// Static concave ground mesh backed by btBvhTriangleMeshShape -- Bullet's
// BVH-accelerated shape for immovable triangle meshes. Unlike Mesh (which
// wraps btGImpactMeshShape for arbitrary, potentially-dynamic assimp
// meshes), Terrain is always static (mass 0, never moves after build()) and
// is built directly from Lua-supplied triangles rather than loaded from a
// file, which is what lets the BVH tree be built once and reused: a much
// better fit for a bumpy floor than GImpact, which is meant for meshes that
// might move and is markedly slower/less stable as a static collider.
class Terrain : public Object {
public:
  Terrain();
  ~Terrain();

  // Accumulates one triangle into the pending mesh. Call build() once all
  // triangles have been added -- the BVH tree is constructed there, not
  // incrementally, since rebuilding it per-triangle would be wasteful.
  void addTriangle(const btVector3 &v0, const btVector3 &v1,
                    const btVector3 &v2);

  // Finalizes the accumulated triangles into a btBvhTriangleMeshShape and
  // creates the (static, mass 0) rigid body. Safe to call again after
  // adding more triangles -- rebuilds the shape and body from scratch.
  void build();

  int getNumTriangles() const;

  static void luaBind(lua_State *s);
  QString toString() const override;
  using Object::toPOV;
  QString toPOV(const QString &sceneDir) const;
  void toMesh2(QTextStream *s, QString hash) const;

  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

protected:
  btTriangleMesh *m_mesh;
  btBvhTriangleMeshShape *m_shape;
};

#endif // TERRAIN_H
