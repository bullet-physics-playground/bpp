#include "spacenavigatorcamera.h"

#include <QGLViewer/camera.h>
#include <QGLViewer/manipulatedCameraFrame.h>
#include <QSettings>
#include <QTimer>

#include <cmath>

namespace {
// SpaceNavigator input dead band (fraction of full deflection): deflections
// within this range of centre are treated as rest, so sensor noise and the
// cap's spring-back cannot drift the camera.  This plays the role of Blender's
// NDOF dead zone (GHOST_NDOFManager::setDeadZone), which is applied per axis
// with the same threshold.
const double kSnInputDeadBand = 0.06;
// Low-pass alpha for the shaped target velocity in report() and for easing
// resting axes to zero on the sustaining path.  The device reports at
// ~125 Hz, so a modest alpha gives a gradual velocity transition (smoother
// motion) while still tracking a new deflection within a few report intervals.
const double kSnLowPassAlpha = 0.4;
// Blender's translation/rotation sensitivities (wm_event_system.c
// attach_ndof_data): the GHOST layer normalises the raw device axes to +/-1
// and the WM scales them again by these factors (4.0 by default).  Tuned down
// to 2.0 so the same deflection drives the camera at half Blender's speed.
const double kSnSensitivity = 2.0;
// Target-velocity dead band used by the integrator.  The response is cubic
// and scaled by Blender's sensitivity kSnSensitivity, so any deflection above
// the input dead band produces a target velocity of at least
// kSnInputDeadBand^3 * kSnSensitivity; zeroing below that threshold stops the
// camera cleanly once the cap returns to rest without widening the physical
// dead zone.
const double kSnTargetDeadBand =
    kSnInputDeadBand * kSnInputDeadBand * kSnInputDeadBand * kSnSensitivity;
// Blender pans at NDOF_PIXELS_PER_SECOND screen pixels per second
// (view3d_navigate_view_ndof.c): the pan speed is pixsize * NDOF_PIXELS_PER_SECOND
// where pixsize is the world-space size of one screen pixel at the orbit depth.
const double kSnPixelsPerSecond = 600.0;
} // namespace

SpaceNavigatorCamera::SpaceNavigatorCamera(QObject *parent) : QObject(parent) {
  // Sustaining timer: each device report is integrated immediately in
  // report() (event-driven), and this timer keeps integrating the last target
  // while a deflection is held still, since the absolute device only reports
  // when the cap moves.  The interval matches the ~125 Hz USB report rate and
  // uses precise timing so sustained motion stays smooth.
  _timer = new QTimer(this);
  _timer->setInterval(8);
  _timer->setTimerType(Qt::PreciseTimer);
  connect(_timer, &QTimer::timeout, this, &SpaceNavigatorCamera::tick);
}

void SpaceNavigatorCamera::loadSettings(QSettings *settings) {
  mode = (settings->value("spacenavigator/navigationMode", 0).toInt() == 1)
             ? Object
             : Fly;
  lockHorizon = settings->value("spacenavigator/lockHorizon", lockHorizon).toBool();
  autoFlySpeed = settings->value("spacenavigator/autoFlySpeed", autoFlySpeed).toBool();
  showOrbitAxis = settings->value("spacenavigator/showOrbitAxis", showOrbitAxis).toBool();
  zoomForward = (settings->value("spacenavigator/zoomDirection", 0).toInt() == 0);
  panZoom = settings->value("spacenavigator/panZoom", panZoom).toBool();
}

qreal SpaceNavigatorCamera::elapsed() {
  const qint64 elapsedMs = _tickTimer.restart();
  return qMin(qreal(elapsedMs) / 1000.0, qreal(0.1));
}

bool SpaceNavigatorCamera::report(const SpaceNavigator::AxesNorm &axes,
                                  qglviewer::Camera *cam,
                                  const qglviewer::Vec &worldUp) {
  // Apply the current target velocity over the time elapsed since the previous
  // device report, so every report moves the camera immediately (event-driven,
  // like Blender's NDOF) rather than waiting for the next timer tick.  On the
  // first report there is no previous interval to apply, so the integration
  // baseline is established below instead.
  bool moved = false;
  if (_timer->isActive()) {
    const qreal dt = elapsed();
    if (cam != nullptr)
      moved = step(dt, false, cam, worldUp);
  }

  // Remember the raw deflection of this report so the sustaining path can tell
  // whether each axis is held or at rest once the device stops reporting.
  _lastInput = axes;

  // Dead band (input side): deflections within kSnInputDeadBand of the
  // centre are ignored so a resting controller does not drift.  A cubic
  // response curve (fine control near the centre, fast travel at full
  // deflection) scaled by Blender's sensitivity (see kSnSensitivity) turns the
  // deflection into a target velocity which is integrated over the real
  // elapsed time, so the camera moves smoothly no matter how irregularly the
  // device reports arrive.
  auto shave = [](double v) {
    return std::fabs(v) < kSnInputDeadBand ? 0.0 : v;
  };
  auto curve = [](double v) {
    return v * v * v * kSnSensitivity;
  };

  const double targetX = curve(shave(axes.x));
  const double targetY = curve(shave(axes.y));
  const double targetZ = curve(shave(axes.z));
  const double targetRX = curve(shave(axes.rx));
  const double targetRY = curve(shave(axes.ry));
  const double targetRZ = curve(shave(axes.rz));

  // Low-pass filter the target velocity to smooth out device packet jitter
  // and the cap's spring-back.
  const double alpha = kSnLowPassAlpha;
  _target.x = _target.x * (1.0 - alpha) + targetX * alpha;
  _target.y = _target.y * (1.0 - alpha) + targetY * alpha;
  _target.z = _target.z * (1.0 - alpha) + targetZ * alpha;
  _target.rx = _target.rx * (1.0 - alpha) + targetRX * alpha;
  _target.ry = _target.ry * (1.0 - alpha) + targetRY * alpha;
  _target.rz = _target.rz * (1.0 - alpha) + targetRZ * alpha;

  if (!_timer->isActive() &&
      !(_target.x == 0.0 && _target.y == 0.0 && _target.z == 0.0 &&
        _target.rx == 0.0 && _target.ry == 0.0 && _target.rz == 0.0)) {
    // First movement: establish the integration baseline and arm the
    // sustaining timer, which keeps integrating the held target while the cap
    // is at rest (the absolute device only reports when it moves).
    _tickTimer.start();
    _timer->start();
  }
  return moved;
}

bool SpaceNavigatorCamera::sustain(qglviewer::Camera *cam,
                                   const qglviewer::Vec &worldUp) {
  // Sustaining timer: the SpaceNavigator is an absolute device that only
  // reports a new value when the cap moves, so while a deflection is held
  // still no reports arrive.  The timer keeps integrating the last target
  // velocity at a fixed rate for as long as the cap is held, and eases the
  // target back to rest once the last report was within the input dead band
  // (see step()).  Motion stops cleanly when the eased target falls back
  // into the dead band and the timer is stopped there.
  const qreal dt = elapsed();
  return cam != nullptr && step(dt, true, cam, worldUp);
}

bool SpaceNavigatorCamera::step(qreal dt, bool sustained, qglviewer::Camera *cam,
                                const qglviewer::Vec &worldUp) {
  // Dead band (sustaining path): once the cap returns to rest the absolute
  // device stops reporting, so the low-pass decay in report() is cut short
  // and the target would freeze above the target dead band, leaving the
  // camera to drift forever on this sustaining timer.  Continue easing any
  // resting axis toward zero here, using the last raw deflection as the
  // rest/held discriminator (the same kSnInputDeadBand as the input shave).
  // Axes held above the dead band keep their velocity for as long as the cap
  // is held, and the event-driven path applies no extra decay (its low-pass
  // already chases every report), so held motion stays immediate.
  if (sustained) {
    const double decay = 1.0 - kSnLowPassAlpha;
    auto easeToRest = [&](double &target, double lastInput) {
      if (std::fabs(lastInput) < kSnInputDeadBand) {
        target *= decay;
      }
    };
    easeToRest(_target.x, _lastInput.x);
    easeToRest(_target.y, _lastInput.y);
    easeToRest(_target.z, _lastInput.z);
    easeToRest(_target.rx, _lastInput.rx);
    easeToRest(_target.ry, _lastInput.ry);
    easeToRest(_target.rz, _lastInput.rz);
  }

  // Dead band (target side): zero any component of the target velocity that
  // has eased back below what the input dead band can still produce, so the
  // camera comes to a clean rest instead of creeping.  Larger deflections are
  // kept as-is: the SpaceNavigator is an absolute device that only reports a
  // new value when the cap moves, so a held deflection produces no events and
  // the camera must keep moving at the last commanded velocity rather than
  // decay to a stop.
  if (std::fabs(_target.x) < kSnTargetDeadBand) _target.x = 0.0;
  if (std::fabs(_target.y) < kSnTargetDeadBand) _target.y = 0.0;
  if (std::fabs(_target.z) < kSnTargetDeadBand) _target.z = 0.0;
  if (std::fabs(_target.rx) < kSnTargetDeadBand) _target.rx = 0.0;
  if (std::fabs(_target.ry) < kSnTargetDeadBand) _target.ry = 0.0;
  if (std::fabs(_target.rz) < kSnTargetDeadBand) _target.rz = 0.0;

  const double tx = _target.x, ty = _target.y, tz = _target.z;
  const double rxp = _target.rx, ryp = _target.ry, rzp = _target.rz;
  if (tx == 0.0 && ty == 0.0 && tz == 0.0 && rxp == 0.0 && ryp == 0.0 &&
      rzp == 0.0) {
    _timer->stop();
    return false;
  }

  if (orbitDist <= 0.0) {
    orbitDist = (cam->pivotPoint() - cam->position()).norm();
  }
  if (orbitDist <= 0.0) {
    orbitDist = cam->sceneRadius();
  }
  const qreal sceneRadius = cam->sceneRadius() > 0.0
                                ? cam->sceneRadius()
                                : 1.0;
  const qreal dist = orbitDist > 0.0 ? orbitDist : sceneRadius;

  qglviewer::Vec right = cam->rightVector();
  qglviewer::Vec up = cam->upVector();
  qglviewer::Vec view = cam->viewDirection();

  // Blender pan speed: pixsize * NDOF_PIXELS_PER_SECOND, i.e. the world-space
  // extent of one screen pixel at the given depth times 600 pixels per second
  // (view3d_navigate_view_ndof.c view3d_ndof_pan_speed_calc_ex).  Computed
  // from a projection so it holds for perspective and orthographic cameras.
  // The view vectors are refreshed after a rotation so the pan happens in the
  // post-rotation view frame, as in Blender.
  auto panSpeedAt = [&](qreal depth) -> qreal {
    const qglviewer::Vec p = cam->projectedCoordinatesOf(
        cam->position() + view * depth);
    const qglviewer::Vec q = cam->projectedCoordinatesOf(
        cam->position() + view * depth + right);
    const qreal pixelsPerUnit = (q - p).norm();
    if (pixelsPerUnit < 1.0e-9) {
      return 0.0;
    }
    return (1.0 / pixelsPerUnit) * kSnPixelsPerSecond;
  };

  // The Y-axis translate direction toggles the cap sense of the forward/back
  // movement (the same pref that used to set the zoom/dolly direction).
  const qreal zoomSign = zoomForward ? 1.0 : -1.0;

  // Locked-horizon helper: after yaw/pitch the camera is re-rolled so its
  // up vector stays in the plane spanned by the reference up and the view
  // direction, i.e. the horizon stays level.
  auto enforceLockedHorizon = [&]() {
    if (!lockHorizon) {
      return;
    }
    const qglviewer::Vec viewDir = cam->viewDirection();
    qglviewer::Vec upNoRoll =
        worldUp - viewDir * (viewDir * worldUp);
    if (upNoRoll.norm() > 1.0e-6) {
      upNoRoll.normalize();
      cam->setUpVector(upNoRoll, true);
    }
  };

  if (mode == Fly) {
    // Fly mode: first-person navigation around the camera position.  The three
    // translation axes move the camera freely (X strafes right, Y translates
    // along the view direction, Z moves up/down).  Auto fly speed scales the
    // pan speed with the distance to the scene so navigation feels constant
    // whether you are close up or far away.
    const qreal depth = autoFlySpeed ? dist : sceneRadius;

    if (lockHorizon) {
      // Turntable rotation (yaw around the view up axis, pitch around the
      // right axis) with the device roll ignored; the horizon is then levelled
      // by enforceLockedHorizon, matching Blender's horizon-locked orbit.
      qglviewer::Quaternion rotation(
          qglviewer::Quaternion(qglviewer::Vec(0.0, 1.0, 0.0), rzp * dt) *
          qglviewer::Quaternion(cam->rightVector(), rxp * dt));
      cam->frame()->rotateAroundPoint(rotation, cam->position());
    } else {
      // Free rotation: a single axis-angle rotation around the device rotation
      // vector mapped into view space (Blender view3d_ndof_orbit).  Fly-mode
      // rotation vector: +rxp pitch, +rzp yaw, -ryp roll.
      qglviewer::Vec axisLocal = right * rxp + up * rzp - view * ryp;
      const double angle = std::sqrt(rxp * rxp + rzp * rzp + ryp * ryp) * dt;
      if (angle > 1.0e-6) {
        axisLocal.normalize();
        cam->frame()->rotateAroundPoint(
            qglviewer::Quaternion(axisLocal, angle), cam->position());
      }
    }

    // Refresh the view vectors: Blender pans in the post-rotation view frame.
    right = cam->rightVector();
    up = cam->upVector();
    view = cam->viewDirection();

    if (panZoom) {
      const qreal panSpeed = panSpeedAt(depth);
      cam->frame()->translate((right * (tx * panSpeed) +
                               view * (ty * zoomSign * panSpeed) +
                               up * (tz * panSpeed)) *
                              dt);
    }
    enforceLockedHorizon();
  } else {
    // Object mode: NDOF orbit around the view-centre pivot point.  The three
    // translation axes move the camera freely (X strafes right, Y translates
    // along the view direction, Z moves up/down); rotation happens around the
    // orbit centre, which follows the camera at orbitDist.
    const qglviewer::Vec pivot = cam->position() + view * dist;

    if (lockHorizon) {
      // Turntable rotation around the pivot (yaw around the view up axis,
      // pitch around the right axis); roll is ignored and the horizon is then
      // levelled by enforceLockedHorizon.
      qglviewer::Quaternion rotation(
          qglviewer::Quaternion(qglviewer::Vec(0.0, 1.0, 0.0), -rzp * dt) *
          qglviewer::Quaternion(cam->rightVector(), -rxp * dt));
      cam->frame()->rotateAroundPoint(rotation, pivot);
    } else {
      // Free rotation around the pivot.  Object-mode rotation vector:
      // -rxp pitch, -rzp yaw, +ryp roll (the Object mode inverts the
      // navigation axes, as in Blender's WM_event_ndof_rotation_get_for_navigation).
      qglviewer::Vec axisLocal = right * (-rxp) + up * (-rzp) + view * ryp;
      const double angle = std::sqrt(rxp * rxp + rzp * rzp + ryp * ryp) * dt;
      if (angle > 1.0e-6) {
        axisLocal.normalize();
        cam->frame()->rotateAroundPoint(
            qglviewer::Quaternion(axisLocal, angle), pivot);
      }
    }

    // Refresh the view vectors: Blender pans in the post-rotation view frame.
    right = cam->rightVector();
    up = cam->upVector();
    view = cam->viewDirection();

    if (panZoom) {
      // Pure translation on all three axes, computed from the projection at
      // the orbit depth so the apparent screen-space speed stays constant.
      // The Y component moves along the view direction (the same sense as the
      // Fly-mode dolly), Z moves up/down.
      const qreal panSpeed = panSpeedAt(dist);
      cam->frame()->translate((right * (tx * panSpeed) +
                               view * (ty * zoomSign * panSpeed) +
                               up * (tz * panSpeed)) *
                              dt);
    }
    enforceLockedHorizon();
  }
  return true;
}
