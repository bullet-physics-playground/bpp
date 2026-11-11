#ifndef QUADVIEW_H
#define QUADVIEW_H

#include <QPoint>
#include <QRect>
#include <QVector>

#include <functional>

class QGLViewer;
namespace qglviewer {
class Camera;
}

/**
 * @brief The quad view: Tab splits the 3D view into four panes, a
 * CAD-style layout (perspective, top, front, right) as in AutoCAD or Maya.
 *
 * The perspective pane is the view's own camera; the other three are fixed
 * orthographic cameras, framed on the scene the first time the quad view is
 * shown (and on a camera reset), then left to the user: a drag in a pane
 * pans it, the wheel zooms it.
 */
class QuadView {
public:
  /**
   * @brief One quad-view pane: which camera renders it, and where.
   */
  struct Pane {
    qglviewer::Camera *cam; ///< Camera that renders this pane.
    QRect rect; ///< The pane's rectangle in widget coordinates, that is Qt's
                ///< convention with the origin top-left.
  };

  /** @param view The 3D view, whose camera is the perspective pane. */
  explicit QuadView(QGLViewer *view);
  ~QuadView();

  QuadView(const QuadView &) = delete;
  QuadView &operator=(const QuadView &) = delete;

  /** @brief True while the four panes are shown instead of one view. */
  bool on() const { return _on; }

  /**
   * @brief Tab: switches between one view and four panes. The first time the
   * panes are shown the ortho cameras are framed on the scene; later they
   * keep the user's own pan and zoom.
   */
  void toggle();

  /**
   * @brief Re-frames the three fixed orthographic cameras on the scene.
   *
   * Keeps their view direction and up vector, set once in the constructor, and
   * just slides them along that direction so the whole scene is in frame.
   * Called when quad view is first switched on and on a camera reset, not
   * every frame, so it does not fight the user's own pan and zoom afterwards.
   */
  void fit();

  /**
   * @brief Returns the current quad-view pane layout.
   *
   * Perspective top-left (the interactive camera()), top top-right, front
   * bottom-left, right bottom-right - the classic AutoCAD/Maya four-view
   * layout. Rectangles are in widget coordinates, that is Qt's convention with
   * the origin top-left and y down, shared by draw(), which flips to OpenGL's
   * bottom-left-origin viewport, and cameraAt(), which hit-tests mouse events
   * directly against these.
   *
   * @return The four panes, in that order.
   */
  QVector<Pane> panes() const;

  /**
   * @brief Returns the orthographic camera under a widget position.
   * @param pos Position in widget coordinates.
   * @return The camera, or null when quad view is off or @p pos is over the
   *         perspective pane, where camera()'s own default mouse handling
   *         already applies.
   */
  qglviewer::Camera *cameraAt(const QPoint &pos) const;

  /**
   * @brief A button pressed: starts panning if it's over an ortho pane.
   * @return True if it did (the press is the quad view's).
   */
  bool startPan(const QPoint &pos);

  /**
   * @brief The mouse moved: pans the pane being dragged, if any.
   * @return True while panning (the move is the quad view's).
   */
  bool pan(const QPoint &pos);

  /**
   * @brief The button released: ends a pan.
   * @return True if one was going on (the release is the quad view's).
   */
  bool endPan();

  /**
   * @brief The wheel: zooms the ortho pane under the pointer, if any.
   * @param pos   Where the pointer is, in widget coordinates.
   * @param delta The wheel's turn (QWheelEvent::angleDelta().y()).
   * @return True if it did (the turn is the quad view's).
   */
  bool zoom(const QPoint &pos, int delta);

  /**
   * @brief Renders the scene once per pane.
   *
   * Each pane gets its own viewport and camera. The full-window viewport and
   * the main camera's screen size are restored afterwards, because postDraw()'s
   * screen-space overlays and the next frame's mouse handling both assume the
   * whole widget.
   *
   * @param drawScene Draws the scene with the current camera; given the
   *                  pane's number.
   */
  void draw(const std::function<void(int)> &drawScene);

private:
  QGLViewer *_view;

  /// True while the 4-pane quad view is shown instead of one view.
  bool _on = false;

  /**
   * @brief Whether the ortho cameras have been framed on the scene yet.
   *
   * Set once fit() has auto-framed the ortho cameras for the first time, so
   * later Tab toggles remember the user's own pan/zoom in those views instead
   * of re-framing every time.
   */
  bool _fitted = false;
  qglviewer::Camera *_camTop;   ///< Fixed orthographic view from above.
  qglviewer::Camera *_camFront; ///< Fixed orthographic view from the front.
  qglviewer::Camera *_camRight; ///< Fixed orthographic view from the right.

  /// Active pan drag on one of the ortho panes (nullptr when not panning).
  qglviewer::Camera *_panCamera = nullptr;
  QPoint _panLastPos; ///< Pointer position at the last pan step.
};

#endif // QUADVIEW_H
