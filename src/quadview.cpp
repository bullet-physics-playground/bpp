#include "quadview.h"

#include <QGLViewer/camera.h>
#include <QGLViewer/qglviewer.h>

#include <cmath>

QuadView::QuadView(QGLViewer *view) : _view(view) {
  _camTop = new qglviewer::Camera();
  _camTop->setType(qglviewer::Camera::ORTHOGRAPHIC);
  _camTop->setViewDirection(qglviewer::Vec(0, -1, 0));
  _camTop->setUpVector(qglviewer::Vec(0, 0, -1));

  _camFront = new qglviewer::Camera();
  _camFront->setType(qglviewer::Camera::ORTHOGRAPHIC);
  _camFront->setViewDirection(qglviewer::Vec(0, 0, -1));
  _camFront->setUpVector(qglviewer::Vec(0, 1, 0));

  _camRight = new qglviewer::Camera();
  _camRight->setType(qglviewer::Camera::ORTHOGRAPHIC);
  _camRight->setViewDirection(qglviewer::Vec(-1, 0, 0));
  _camRight->setUpVector(qglviewer::Vec(0, 1, 0));
}

QuadView::~QuadView() {
  delete _camTop;
  delete _camFront;
  delete _camRight;
}

void QuadView::toggle() {
  _on = !_on;
  if (_on && !_fitted) {
    // Auto-frame the ortho cameras only the first time quad view is
    // shown, so later toggles remember any pan/zoom the user applied.
    fit();
    _fitted = true;
  }
}

// Re-frames the three fixed orthographic cameras on the current scene,
// keeping their view direction/up vector (set once, in the constructor)
// and just sliding them along that direction so the whole scene is in
// frame - the same thing fitSphere() is for. Called once when quad view
// is switched on (and on 'C' reset), not every frame, so it doesn't fight
// the user's own pan/zoom in those views afterwards.
void QuadView::fit() {
  const qglviewer::Vec center = _view->camera()->sceneCenter();
  const qreal radius = _view->camera()->sceneRadius();

  for (qglviewer::Camera *cam : {_camTop, _camFront, _camRight}) {
    cam->setSceneCenter(center);
    cam->setSceneRadius(radius);
    cam->setPivotPoint(center);
    cam->fitSphere(center, radius);
  }
}

// The current quad-view pane layout: perspective (top-left, the
// interactive camera()), top (top-right), front (bottom-left), right
// (bottom-right) - the classic AutoCAD/Maya 4-view layout. Rectangles are
// in widget coordinates (Qt convention: origin top-left, y down), shared
// by draw() (which flips to OpenGL's bottom-left-origin viewport)
// and cameraAt() (which hit-tests mouse events directly against
// these).
QVector<QuadView::Pane> QuadView::panes() const {
  const int w = _view->width();
  const int h = _view->height();
  const int leftW = w / 2;
  const int rightW = w - leftW;
  const int topH = h / 2;
  const int bottomH = h - topH;

  return {
      {_view->camera(), QRect(0, 0, leftW, topH)},     // top-left: perspective
      {_camTop, QRect(leftW, 0, rightW, topH)},         // top-right: top
      {_camFront, QRect(0, topH, leftW, bottomH)},      // bottom-left: front
      {_camRight, QRect(leftW, topH, rightW, bottomH)}, // bottom-right: right
  };
}

// The ortho camera under widget position pos, or nullptr when quad view
// is off or pos is over the perspective pane (where camera()'s own
// default mouse handling already applies).
qglviewer::Camera *QuadView::cameraAt(const QPoint &pos) const {
  if (!_on) return nullptr;

  for (const Pane &p : panes()) {
    if (p.cam != _view->camera() && p.rect.contains(pos)) {
      return p.cam;
    }
  }
  return nullptr;
}

// Splits the viewport into the 4 quadView panes and renders the scene
// once per pane, each with its own camera and clipped to its own
// rectangle.
void QuadView::draw(const std::function<void(int)> &drawScene) {
  const int w = _view->width();
  const int h = _view->height();
  const QVector<Pane> panes = this->panes();

  for (int i = 0; i < panes.size(); i++) {
    const Pane &p = panes[i];
    // glViewport() takes the bottom-left corner; p.rect.y() is measured
    // from the top, so flip it.
    const int glX = p.rect.x();
    const int glY = h - p.rect.y() - p.rect.height();
    glViewport(glX, glY, p.rect.width(), p.rect.height());

    p.cam->setScreenWidthAndHeight(p.rect.width(), p.rect.height());
    p.cam->loadProjectionMatrix();
    p.cam->loadModelViewMatrix();

    glDisable(GL_CULL_FACE);
    drawScene(i);
  }

  // Restore the full-window viewport and camera() state: postDraw()'s
  // screen-coordinate overlays (record/simulate/save/deactivation dots)
  // assume the whole widget, and the next frame's mouse handling assumes
  // camera()'s screen size matches the widget again.
  glViewport(0, 0, w, h);
  _view->camera()->setScreenWidthAndHeight(w, h);
  _view->camera()->loadProjectionMatrix();
  _view->camera()->loadModelViewMatrix();
}

bool QuadView::startPan(const QPoint &pos) {
  qglviewer::Camera *cam = cameraAt(pos);
  if (cam) {
    _panCamera = cam;
    _panLastPos = pos;
    return true;
  }
  return false;
}

bool QuadView::pan(const QPoint &pos) {
  if (_panCamera) {
    const QPoint delta = pos - _panLastPos;
    _panLastPos = pos;

    if (!delta.isNull()) {
      // Convert screen-pixel movement to world units at the pane's current
      // zoom level (screenHeight() is this camera's pane height, set each
      // time draw() renders it).
      GLdouble halfWidth, halfHeight;
      _panCamera->getOrthoWidthHeight(halfWidth, halfHeight);
      const int paneHeight = _panCamera->screenHeight();
      const qreal unitsPerPixel =
          (paneHeight > 0) ? (2.0 * halfHeight / paneHeight) : 0.0;

      const qglviewer::Vec translation =
          -_panCamera->rightVector() * (delta.x() * unitsPerPixel) +
          _panCamera->upVector() * (delta.y() * unitsPerPixel);

      _panCamera->setPosition(_panCamera->position() + translation);
      _panCamera->setPivotPoint(_panCamera->pivotPoint() + translation);
      _view->update();
    }
    return true;
  }
  return false;
}

bool QuadView::endPan() {
  if (_panCamera) {
    _panCamera = nullptr;
    return true;
  }
  return false;
}

bool QuadView::zoom(const QPoint &pos, int delta) {
  qglviewer::Camera *cam = cameraAt(pos);
  if (cam) {
    // One wheel "click" is 120 (QWheelEvent::angleDelta() units); each
    // click zooms by 10%, scrolling the camera towards/away from its
    // pivot along its own view direction.
    const qreal notches = delta / 120.0;
    const qreal factor = pow(0.9, notches);
    const qglviewer::Vec pivot = cam->pivotPoint();
    cam->setPosition(pivot + (cam->position() - pivot) * factor);
    return true;
  }
  return false;
}
