#ifndef SPACENAVIGATORCAMERA_H
#define SPACENAVIGATORCAMERA_H

#include <QElapsedTimer>
#include <QObject>
#include <QGLViewer/vec.h>

#include "spacenavigator.h"

class QSettings;
class QTimer;
namespace qglviewer {
class Camera;
}

/**
 * @brief Drives a camera from a 3D mouse (the SpaceNavigator), as Blender's
 * NDOF navigation does.
 *
 * Each normalised device report is shaped into a target velocity (dead band,
 * cubic response, low-pass) and the target is integrated over the real time
 * elapsed, so the camera moves at once on every report. The SpaceNavigator
 * is an absolute device that reports nothing while a deflection is held
 * still, so a sustaining timer (tick()) keeps integrating the last target
 * for as long as the cap is held, and eases resting axes back to zero once
 * it returns to centre. The owner forwards reports to report() and ticks to
 * sustain(), and redraws when either says the camera moved.
 *
 * The settings are plain members: the owner sets them (from the
 * preferences, the Preferences dialog or a script).
 */
class SpaceNavigatorCamera : public QObject {
  Q_OBJECT
public:
  /// How the 3D mouse drives the camera.
  enum Mode {
    Object, ///< Orbit the view-centre pivot.
    Fly     ///< First-person navigation around the camera's own position.
  };

  explicit SpaceNavigatorCamera(QObject *parent = nullptr);

  /// Reads the settings saved under "spacenavigator/" (defaults otherwise).
  void loadSettings(QSettings *settings);

  Mode mode = Fly;           ///< The mode in use.
  bool lockHorizon = true;   ///< Keep the horizon level while rotating.
  bool autoFlySpeed = true;  ///< Scale fly speed with the distance to the scene.
  bool showOrbitAxis = false; ///< Draw the orbit centre as an axis marker.
  bool zoomForward = true;   ///< Push the cap to move along the view direction.
  bool panZoom = true;       ///< Let the device translate the camera at all.

  /**
   * @brief Distance from the camera to the point the 3D mouse orbits around.
   *
   * Blender-style orbit distance: the distance from the camera to the
   * view-centre pivot the SpaceNavigator orbits around. 0 until it is next
   * taken from the view: the owner sets it back to 0 when the camera is
   * reset or the scene changes.
   */
  qreal orbitDist = 0.0;

  /**
   * @brief Takes a normalised device report.
   *
   * Integrates whatever was already commanded over the time since the
   * previous report, then shapes this report into a new target. The first
   * movement also starts the sustaining timer.
   *
   * @param axes    The normalised device axes.
   * @param cam     The camera to move (nullptr: none).
   * @param worldUp The up vector a locked horizon keeps level to.
   * @return True if the camera moved (the owner redraws).
   */
  bool report(const SpaceNavigator::AxesNorm &axes, qglviewer::Camera *cam,
              const qglviewer::Vec &worldUp);

  /**
   * @brief One tick of the sustaining timer: keeps moving the camera while a
   * deflection is held, easing resting axes back to zero.
   * @param cam     The camera to move (nullptr: the interval passes unused,
   *                as while a script has the device).
   * @param worldUp The up vector a locked horizon keeps level to.
   * @return True if the camera moved (the owner redraws).
   */
  bool sustain(qglviewer::Camera *cam, const qglviewer::Vec &worldUp);

  /// Forgets the target, so no residual deflection moves the camera (a
  /// script has taken the device over).
  void clearTarget() { _target = SpaceNavigator::AxesNorm(); }

  /**
   * @brief Moves the camera by the current target velocity over @p dt.
   *
   * In Fly mode the camera turns and moves about itself; in Object mode it
   * orbits the view-centre pivot. With the horizon locked, rotation is a
   * turntable yaw and pitch and the camera is re-rolled level afterwards.
   * Stops the sustaining timer once the target is back at rest.
   *
   * @param dt        Seconds to integrate over.
   * @param sustained True from the sustaining timer: resting axes are eased
   *                  back to zero.
   * @param cam       The camera to move.
   * @param worldUp   The up vector a locked horizon keeps level to.
   * @return True if the camera moved.
   */
  bool step(qreal dt, bool sustained, qglviewer::Camera *cam,
            const qglviewer::Vec &worldUp);

signals:
  /// The sustaining timer fired: the owner calls sustain().
  void tick();

private:
  /// The time since the previous report or tick, restarting the clock, so
  /// the two paths integrate disjoint intervals (clamped so a delayed tick
  /// cannot cause a jump).
  qreal elapsed();

  QTimer *_timer;            ///< The sustaining timer.
  QElapsedTimer _tickTimer;  ///< Measures each integration interval; shared
                             ///< by both paths.
  SpaceNavigator::AxesNorm _target;    ///< Current shaped target velocity.
  SpaceNavigator::AxesNorm _lastInput; ///< Raw deflection of the last report,
                                       ///< used to tell held axes from
                                       ///< resting ones.
};

#endif // SPACENAVIGATORCAMERA_H
