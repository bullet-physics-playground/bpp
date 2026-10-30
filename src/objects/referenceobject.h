#ifndef REFERENCEOBJECT_H
#define REFERENCEOBJECT_H

/**
 * @file referenceobject.h
 * @brief Object reference primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

#include <QString>

/**
 * @brief A reference to another object in the scene.
 *
 * Exports as a POV-Ray @c object reference to the target's declared name.
 * The reference itself has no collision shape; it inherits the target's
 * transform for display.
 */
class ReferenceObject : public Object {
public:
  /**
   * @brief Constructs an object reference.
   * @param targetName Name of the referenced object (POV-Ray identifier).
   * @param target     Pointer to the referenced Object, or nullptr.
   */
  ReferenceObject(const QString &targetName = "", Object *target = nullptr);

  /** @brief Destroys the reference object. */
  ~ReferenceObject();

  /** @brief Sets the referenced object's POV-Ray identifier name. */
  void setTargetName(const QString &name) { m_targetName = name; }

  /** @brief Returns the referenced object's POV-Ray identifier name. */
  QString getTargetName() const { return m_targetName; }

  /** @brief Sets the referenced Object pointer. */
  void setTarget(Object *target) { m_target = target; }

  /** @brief Returns the referenced Object pointer. */
  Object *getTarget() const { return m_target; }

  /**
   * @brief Registers the ReferenceObject class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /** @brief Returns the object's type name. */
  QString toString() const override;

  /** @brief Writes the reference to a POV-Ray scene as an @c object reference. */
  void toPOV(QTextStream *s) const override;

protected:
  /** @brief Draws nothing (reference has no geometry of its own). */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  QString m_targetName; ///< POV-Ray identifier of the referenced object.
  Object *m_target;     ///< Referenced Object pointer (non-owning).
};

#endif // REFERENCEOBJECT_H
