#ifndef BEZIERPATCH_H
#define BEZIERPATCH_H

/**
 * @file bezierpatch.h
 * @brief Bezier patch primitive.
 *
 * A bicubic Bezier patch surface, similar to Moray's Patch object.
 * Uses a 4x4 grid of control points.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

#include <array>

/**
 * @brief A bicubic Bezier patch.
 *
 * Defined by a 4x4 grid of control points. Can be used to create
 * smooth curved surfaces. Exports as a POV-Ray bicubic_patch.
 */
class BezierPatch : public Object {
public:
  /**
   * @brief Constructs a flat Bezier patch.
   * @param size Size of the patch in X and Z directions.
   * @param mass Mass; 0 makes it static.
   */
  BezierPatch(btScalar size = 2.0, btScalar mass = 1.0);

  /**
   * @brief Constructs a Bezier patch from control points.
   * @param points 16 control points (4x4 grid, row-major: u=rows, v=cols).
   * @param mass Mass; 0 makes it static.
   */
  BezierPatch(const std::array<btVector3, 16> &points, btScalar mass = 1.0);

  /**
   * @brief Destroys the Bezier patch.
   */
  ~BezierPatch();

  std::array<btVector3, 16> controlPoints; ///< 4x4 control point grid.
  btScalar m_mass; ///< Mass of the patch.

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
   * @brief Rebuilds the mesh after control points change.
   */
  void rebuild();

  /**
   * @brief Registers the BezierPatch class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "BezierPatch".
   */
  QString toString() const override;

  /**
   * @brief Writes the Bezier patch to a POV-Ray scene.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Draws the Bezier patch in its own frame.
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

private:
  void init(const std::array<btVector3, 16> &points, btScalar mass);
  void buildMesh(int tessellation);
  btTriangleMesh *m_mesh = nullptr;
  std::vector<double> m_verts;   ///< Flat vertex array (x,y,z per vertex) for GL drawing.
  std::vector<double> m_norms;   ///< Flat normal array for GL drawing.
  std::vector<unsigned int> m_idxs;  ///< Triangle indices for GL drawing.
};

#endif // BEZIERPATCH_H