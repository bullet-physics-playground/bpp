#ifndef HOVER_H
#define HOVER_H

#include <QElapsedTimer>
#include <QPoint>
#include <QSet>

#include <exception>
#include <functional>
#include <vector>

#include <LinearMath/btTransform.h>
#include <LinearMath/btVector3.h>
#include <luabind/object.hpp>

class Object;
class QWidget;
class btSoftRigidDynamicsWorld;
namespace qglviewer {
class Camera;
}

/**
 * @brief The hover: a tooltip by the resting mouse pointer, with what a
 * script's v:onHover(function(N, obj, x, y, z) ... end) says about the
 * object under it.
 *
 * The viewer reports the mouse's movement, clicks, keys and wheel turns,
 * and calls tick() every 100 ms; once the pointer has rested half a second
 * a tick casts a ray through it and asks the hook about what it hits,
 * nearest first. The nearest object with something to say gets the
 * tooltip; one that collides and has nothing to say is in the way and ends
 * the search, one that doesn't collide is looked through. An object that
 * slips out from under the pointer (spinning, rocking) keeps the tooltip
 * for 1.5 s. Any button, wheel turn, key press or movement hides it.
 */
class Hover {
public:
  /// A world to cast the ray in, and where it's drawn (null: where it is).
  struct World {
    btSoftRigidDynamicsWorld *world;
    const btTransform *place;
  };

  /** @param view The 3D view the tooltip belongs to. */
  explicit Hover(QWidget *view);

  /** @brief Sets the hook; anything but a Lua function clears it. */
  void setCallback(const luabind::object &fn);

  /** @brief Drops the hook and hides the tooltip (a script ends). */
  void clear();

  /** @brief The mouse moved over the view, with these buttons down. */
  void mouseMoved(const QPoint &pos, Qt::MouseButtons buttons);

  /** @brief A click, or the pointer left the view: hide until it moves. */
  void disarm();

  /** @brief A key or wheel turn: hide until the pointer rests again. */
  void interrupt();

  /** @brief Hides the tooltip. */
  void hide();

  /** @brief Where the pointer rests, in the view's coordinates. */
  QPoint pos() const { return _pos; }

  /**
   * @brief Every 100 ms: shows or refreshes the tooltip if the pointer
   * rests on an object the hook has something to say about.
   * @param cam      The camera the pointer looks through (an ortho pane's,
   *                 if it's over one).
   * @param worlds   The worlds to cast the ray in.
   * @param objects  The scene's objects.
   * @param frameNum The frame, passed to the hook.
   * @param onError  Shows an error the hook raised (the hook is dropped).
   */
  void tick(const qglviewer::Camera *cam, const std::vector<World> &worlds,
            const QSet<Object *> *objects, int frameNum,
            const std::function<void(const std::exception &)> &onError);

private:
  QWidget *_view;
  luabind::object _cb;           ///< Called when the mouse rests on an object.
  QElapsedTimer _still;          ///< Time since the mouse last moved.
  QPoint _pos;                   ///< Where the mouse rests (widget coords).
  bool _armed = false;           ///< Mouse is over the view with no button down.
  bool _shown = false;           ///< A hover tooltip is showing.
  Object *_obj = nullptr;        ///< Last object found under the resting mouse.
  btVector3 _hitPt;              ///< Where the ray last hit it.
  QElapsedTimer _lastHit;        ///< Time since the ray last hit it.
};

#endif // HOVER_H
