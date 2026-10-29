#ifndef CSG_H
#define CSG_H

/**
 * @file csg.h
 * @brief CSG (Constructive Solid Geometry) framework.
 *
 * Provides CSG operations (union, difference, intersection) on objects.
 * Uses btCompoundShape for physics and POV-Ray CSG for rendering.
 * Inspired by Moray's CSG object system.
 */

#include "object.h"
#include "visitor.h"

#include <btBulletDynamicsCommon.h>
#include <vector>

/**
 * @brief CSG operation types.
 */
enum CsgOperation {
  CSG_UNION,        ///< Union (A + B)
  CSG_DIFFERENCE,   ///< Difference (A - B)
  CSG_INTERSECTION  ///< Intersection (A * B)
};

/**
 * @brief A node in the CSG tree.
 */
struct CsgNode {
  Object *object = nullptr;      ///< The object (leaf node)
  CsgOperation operation = CSG_UNION; ///< Operation for internal nodes
  CsgNode *left = nullptr;       ///< Left child
  CsgNode *right = nullptr;      ///< Right child
  btTransform transform;         ///< Local transform

  CsgNode() : transform(btTransform::getIdentity()) {}
  explicit CsgNode(Object *obj) : object(obj), transform(btTransform::getIdentity()) {}
  CsgNode(CsgOperation op, CsgNode *l, CsgNode *r) : operation(op), left(l), right(r), transform(btTransform::getIdentity()) {}

~CsgNode() {
    // Note: children are owned by Lua GC, not deleted here
    // object is not owned by CSG tree, caller manages it
}

  bool isLeaf() const { return object != nullptr; }
};

/**
 * @brief CSG Object - combines multiple objects using boolean operations.
 *
 * For physics: uses btCompoundShape containing all child shapes.
 * For rendering: exports POV-Ray CSG (union/difference/intersection).
 */
class CsgObject : public Object {
public:
  /**
   * @brief Constructs an empty CSG object.
   * @param mass Mass; 0 makes it static.
   */
  explicit CsgObject(btScalar mass = 1.0);

  /**
   * @brief Constructs a CSG object from a root node.
   * @param root Root of the CSG tree.
   * @param mass Mass; 0 makes it static.
   */
  CsgObject(CsgNode *root, btScalar mass = 1.0);

  /**
   * @brief Destroys the CSG object.
   */
  ~CsgObject();

  CsgNode *root = nullptr; ///< Root of the CSG tree.

  /**
   * @brief Sets the root node of the CSG tree.
   */
  void setRoot(CsgNode *newRoot) { root = newRoot; }

  /**
   * @brief Gets the root node of the CSG tree.
   */
  CsgNode *getRoot() const { return root; }

  /**
   * @brief Registers the CsgObject class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "CsgObject".
   */
  QString toString() const override;

  /**
   * @brief Writes the CSG object to a POV-Ray scene.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Builds the collision shape from the CSG tree.
   * @param mass Mass; 0 makes it static.
   */
  void buildCompoundShape(btScalar mass);

  /**
   * @brief Draws the CSG object in its own frame.
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

private:
  void writeCsgNode(QTextStream *s, const CsgNode *node, int depth) const;
  void renderCsgNode(const CsgNode *node) const;

  btCompoundShape *compoundShape = nullptr;
};

/**
 * @brief Helper functions for building CSG trees.
 */
namespace Csg {

/**
 * @brief Creates a union of two objects.
 * @return New CsgObject representing the union.
 */
inline CsgObject *uniteObj(Object *a, Object *b, btScalar mass) {
  return new CsgObject(new CsgNode(CSG_UNION, new CsgNode(a), new CsgNode(b)), mass);
}

/**
 * @brief Creates a difference of two objects (a - b).
 * @return New CsgObject representing the difference.
 */
inline CsgObject *subtractObj(Object *a, Object *b, btScalar mass) {
  return new CsgObject(new CsgNode(CSG_DIFFERENCE, new CsgNode(a), new CsgNode(b)), mass);
}

/**
 * @brief Creates an intersection of two objects.
 * @return New CsgObject representing the intersection.
 */
inline CsgObject *intersectObj(Object *a, Object *b, btScalar mass) {
  return new CsgObject(new CsgNode(CSG_INTERSECTION, new CsgNode(a), new CsgNode(b)), mass);
}

/**
 * @brief Creates a CSG object from a node tree.
 * @param root Root node of the CSG tree.
 * @param mass Mass of the resulting object.
 * @return New CsgObject.
 */
CsgObject *makeCsg(CsgNode *root, btScalar mass = 1.0);

} // namespace Csg

#endif // CSG_H