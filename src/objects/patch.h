#ifndef PATCH_H
#define PATCH_H

/**
 * @file patch.h
 * @brief Patch primitive (bicubic surface).
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

#include <array>

/**
 * @brief A bicubic Bezier patch surface (Moray Patch equivalent).
 *
 * Defined by a 4x4 grid of control points. Can be used to create
 * smooth curved surfaces. Exports as a POV-Ray @c bicubic_patch.
 */
class Patch : public Object {
public:
  /**
   * @brief Constructs a flat patch.
   * @param size Size of the patch in X and Z directions.
   * @param mass Mass; 0 makes it static.
   */
  Patch(btScalar size = 2.0, btScalar mass = 1.0);

  /**
   * @brief Constructs a patch from control points.
   * @param points 16 control points (4x4 grid, row-major).
   * @param mass Mass; 0 makes it static.
   */
  Patch(const std::array<btVector3, 16> &points, btScalar mass = 1.0);

  /** @brief Destroys the patch. */
  ~Patch();

  std::array<btVector3, 16> controlPoints; ///< 4x4 control point grid.
  btScalar m_mass;                         ///< Mass of the patch.

  /**
   * @brief Sets a control point.
   * @param u Row index [0,3].
   * @param v Column index [0,3].
   * @param point New control point position.
   */
  void setControlPoint(int u, int v, const btVector3 &point);

  /**
   * @brief Gets a control point.
   * @param u Row index [0,3].
   * @param v Column index [0,3].
   * @return Control point position.
   */
  btVector3 getControlPoint(int u, int v) const;

  /**
   * @brief Evaluates the patch at parameters (u, v).
   * @param u Parameter along first direction [0,1].
   * @param v Parameter along second direction [0,1].
   * @return Position on the patch.
   */
  btVector3 evaluate(float u, float v) const;

  /**
   * @brief Rebuilds the collision mesh after control points change.
   */
  void rebuild();

  /**
   * @brief Registers the Patch class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /** @brief Returns the object's type name. */
  QString toString() const override;

  /** @brief Writes the patch to a POV-Ray scene as a @c bicubic_patch. */
  void toPOV(QTextStream *s) const override;

protected:
  /** @brief Draws the patch as a tessellated surface. */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

private:
  void init(const std::array<btVector3, 16> &points, btScalar mass);
  void buildMesh(int tessellation);
  btTriangleMesh *m_mesh = nullptr;
  std::vector<double> m_verts;   ///< Flat vertex array (x,y,z per vertex).
  std::vector<double> m_norms;   ///< Flat normal array.
  std::vector<unsigned int> m_idxs; ///< Triangle indices.
};

#endif // PATCH_H
