#ifndef HEIGHTFIELD_H
#define HEIGHTFIELD_H

/**
 * @file heightfield.h
 * @brief General heightfield primitive.
 *
 * A grid-based heightfield that can be used for terrain, water surfaces,
 * displacement mapping, etc. Supports creation from images, functions,
 * or raw height data. More flexible than Terrain for non-ground uses.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>
#include <BulletCollision/CollisionShapes/btHeightfieldTerrainShape.h>

#include <QImage>
#include <QString>
#include <functional>

/**
 * @brief A general heightfield primitive.
 *
 * Represents a 2D grid of height values that can be used for:
 * - Terrain (like the existing Terrain class)
 * - Water surfaces with wave simulation
 * - Displacement-mapped surfaces
 * - Cloth/soft body rest shapes
 *
 * Uses btHeightfieldTerrainShape for physics (efficient for large grids).
 * Can be dynamic (mass > 0) for soft-body-like behavior or static.
 */
class Heightfield : public Object {
public:
  /**
   * @brief Constructs an empty heightfield.
   * @param width  Number of vertices along X.
   * @param depth  Number of vertices along Z.
   * @param mass   Mass; 0 makes it static.
   */
  Heightfield(int width = 32, int depth = 32, btScalar mass = 0.0);

  /**
   * @brief Constructs a heightfield from a grayscale image.
   * @param image  Grayscale image where pixel value = height.
   * @param scale  World scale (width, height, depth).
   * @param mass   Mass; 0 makes it static.
   */
  Heightfield(const QImage &image, const btVector3 &scale = btVector3(1, 1, 1), btScalar mass = 0.0);

  /**
   * @brief Constructs a heightfield from a height function.
   * @param width     Number of vertices along X.
   * @param depth     Number of vertices along Z.
   * @param heightFn  Function (x, z) -> height, where x,z in [0,1].
   * @param scale     World scale.
   * @param mass      Mass; 0 makes it static.
   */
  Heightfield(int width, int depth,
              const std::function<float(float, float)> &heightFn,
              const btVector3 &scale = btVector3(1, 1, 1),
              btScalar mass = 0.0);

  /**
   * @brief Destroys the heightfield.
   */
  ~Heightfield();

  int width = 32;           ///< Number of vertices along X.
  int depth = 32;           ///< Number of vertices along Z.
  btVector3 scale = btVector3(1, 1, 1); ///< World scale (size in X, Y, Z).
  float minHeight = 0.0f;   ///< Minimum height value (for normalization).
  float maxHeight = 1.0f;   ///< Maximum height value.

  /**
   * @brief Sets height at a grid point.
   * @param x Grid X index [0, width-1].
   * @param z Grid Z index [0, depth-1].
   * @param height Height value.
   */
  void setHeight(int x, int z, float height);

  /**
   * @brief Gets height at a grid point.
   * @param x Grid X index.
   * @param z Grid Z index.
   * @return Height value.
   */
  float getHeight(int x, int z) const;

  /**
   * @brief Sets heights from a grayscale image.
   * @param image Grayscale image (will be resized to width x depth).
   * @param minH  Minimum world height (black pixel).
   * @param maxH  Maximum world height (white pixel).
   */
  void setFromImage(const QImage &image, float minH = 0.0f, float maxH = 1.0f);

  /**
   * @brief Sets heights from a function.
   * @param fn Function (x, z) -> height, where x,z in [0,1].
   * @param minH Minimum world height.
   * @param maxH Maximum world height.
   */
  void setFromFunction(const std::function<float(float, float)> &fn, float minH = 0.0f, float maxH = 1.0f);

  /**
   * @brief Rebuilds the physics shape after height changes.
   */
  void rebuild();

  /**
   * @brief Exports heightfield as a grayscale image.
   * @param file Output image file.
   * @return True on success.
   */
  bool exportHeightmap(const QString &file) const;

  /**
   * @brief Registers the Heightfield class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Heightfield".
   */
  QString toString() const override;

  /**
   * @brief Writes the heightfield to a POV-Ray scene as a height_field.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Draws the heightfield in its own frame.
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

private:
  std::vector<float> m_heights; ///< Flattened height grid (width * depth).
  btHeightfieldTerrainShape *m_hfShape = nullptr;

  void buildShape(btScalar mass);
  void generateMesh();
  void generateNormals();
  std::vector<btVector3> m_vertices;  ///< Generated vertices for rendering.
  std::vector<btVector3> m_normals;   ///< Generated normals.
  std::vector<int> m_indices;         ///< Triangle indices.
};

#endif // HEIGHTFIELD_H