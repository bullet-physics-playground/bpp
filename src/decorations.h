#ifndef DECORATIONS_H
#define DECORATIONS_H

#include <QPointer>

#include <vector>

#include <LinearMath/btTransform.h>

#include "objects/object.h"

/**
 * @brief Decorations that follow a body (v:attach): look-only objects placed,
 * before each drawing and each POV-Ray export, at the place of the object
 * they are attached to, with the offset they had when attached.
 *
 * A decoration (Object::setDecoration, o.decoration = true before v:add) is
 * drawn, shadowed and exported like any object, but its body is never added
 * to Bullet's world: Bullet neither steps it nor tests it for collisions,
 * and v:rayTest and the mouse (hover, picking) never find it. update() writes
 * both its motion state (what drawing, culling and export read) and its
 * body's own transform (what its bounding box is taken from); Bullet never
 * syncs the two for a body outside the world. The parent is read through its
 * motion state, the place it is drawn at.
 *
 * Objects are held by QPointer: one deleted drops out at the next update().
 */
class Decorations {
public:
  /// From now on @p o follows @p parent, keeping the offset between them now (one parent at a time).
  void attach(Object *o, Object *parent);
  /// @p o no longer follows anything; it stays where it is.
  void detach(Object *o);
  /// Places every attached decoration at its parent's place. Viewer calls it once a frame, after the script's
  /// preDraw and before anything reads where objects are, and before each POV-Ray export.
  void update();
  /// Forgets every attachment.
  void clear() { _links.clear(); }

private:
  struct Link {
    QPointer<Object> o, parent;
    btTransform offset;   // o's place in its parent's frame
  };
  std::vector<Link> _links;
};

#endif // DECORATIONS_H
