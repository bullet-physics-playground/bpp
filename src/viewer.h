#ifndef VIEWER_H
#define VIEWER_H

#include <lua.hpp>

#include <QGLViewer/manipulatedCameraFrame.h>
#include <QGLViewer/manipulatedFrame.h>
#include <QGLViewer/qglviewer.h>

#include <btBulletDynamicsCommon.h>

#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QKeyEvent>
#include <QMutex>
#include <QMutexLocker>
#include <QSettings>
#include <QTextStream>
#include <map>
#include <functional>
#include <luabind/object.hpp>

#include "objects/cam.h"

#include "objects/sphere.h"

#include "joystick/joystickhandler.h"
#include "joystick/joystickinterfacesdl.h"

#include "spacenavigator/spacenavigator.h"

using namespace qglviewer;

class Object;
class Viewer;
class QTimer;

struct ParamInfo {
  QVariant value;
  btScalar min = 0.0;
  btScalar max = 100.0;
  bool hasRange = false;
};

std::ostream &operator<<(std::ostream &, const Viewer &v);

class Viewer : public QGLViewer {
  Q_OBJECT;

public:
  Viewer(QWidget *parent = nullptr, QSettings *settings = nullptr,
         bool savePOV = false);
  ~Viewer();

  void setSavePOV(bool pov);
  void toggleSavePOV(bool savePOV);
  void toggleDeactivation(bool deactivation);

  // http://bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
  void setTimeStep(btScalar ts);
  btScalar getTimeStep();

  void setMaxSubSteps(int steps);
  int getMaxSubSteps();

  void setFixedTimeStep(btScalar fts);
  btScalar getFixedTimeStep();

  void startSim();
  void stopSim();
  void restartSim();

  void resetCamView();

  void setTau(btScalar tau);
  void setErp(btScalar erp);
  void setErp2(btScalar erp);
  void setCfm(btScalar cfm);
  
  void addObject(Object *o);
  Object *removeObject(Object *o);
  void addObjectBody(Object *o);
  void setCamera(Cam *cam);
  Cam *getCamera();

  static void luaBind(lua_State *s);
  // static void luabind_error(lua_State *s);
  void luaBindInstance(lua_State *s);
  virtual QString toString() const;
  void setScriptName(QString sn);
  void setScriptBasePath(QString sbp);

  void emitScriptOutput(const QString &);
  void emitClearOutput();
  static int lua_print(lua_State *);

  void addConstraints(QList<btTypedConstraint *> cons);
  void addConstraint(btTypedConstraint *con);
  void addVehicle(btRaycastVehicle *veh);
  btTypedConstraint *removeConstraint(btTypedConstraint *con);

  void addShortcut(const QString &, const luabind::object &fn);
  void removeShortcut(const QString &);

  btVehicleRaycaster *createVehicleRaycaster();

  // OpenGL properties
  void setGLShininess(const btScalar &);
  btScalar getGLShininess() const;

  void setGLSpecularColor(const btVector4 &);
  btVector4 getGLSpecularColor() const;

  void setGLSpecularCol(const btScalar);
  btScalar getGLSpecularCol() const;

  void setGLLight0(const btVector4 &);
  btVector4 getGLLight0() const;

  void setGLLight1(const btVector4 &);
  btVector4 getGLLight1() const;

  void setGLAmbient(const btVector3 &);
  btVector3 getGLAmbient() const;

  void setGLDiffuse(const btVector4 &);
  btVector4 getGLDiffuse() const;

  void setGLSpecular(const btVector4 &);
  btVector4 getGLSpecular() const;

  void setGLModelAmbient(const btVector4 &);
  btVector4 getGLModelAmbient() const;

  void setGLModelAmbientPercent(const btScalar);
  btScalar getGLModelAmbientPercent() const;

  void setGLAmbientPercent(const btScalar);
  btScalar getGLAmbientPercent() const;

  void setGLDiffusePercent(const btScalar);
  btScalar getGLDiffusePercent() const;

  void setGLSpecularPercent(const btScalar);
  btScalar getGLSpecularPercent() const;

#if (QT_VERSION >= QT_VERSION_CHECK(5, 4, 0))
  void setBackgroundColor(const QColor &color) {
    glClearColor(color.redF(), color.greenF(), color.blueF(), color.alphaF());
  }
#else
  void setBackgroundColor(const QColor &color) { qglClearColor(color); }
#endif

  // POV-Ray properties
  void setPreSDL(const QString &);
  QString getPreSDL() const;

  void setPostSDL(const QString &);
  QString getPostSDL() const;

  void setPOVSettingsInc(QString pov_settings_inc);
  QString getPOVSettingsInc();

  void setSettings(QSettings *settings);

  void setPrefs(QString key, QString value);
  QString getPrefs(QString key, QString defaultValue) const;

  virtual void startAnimation();
  virtual void stopAnimation();
  virtual void animate();
  virtual void draw();
  virtual void postDraw();

public slots:
  void close();

  bool parse(QString txt);
  void clear();

  void setCBPreStart(const luabind::object &fn);
  void setCBPreDraw(const luabind::object &fn);
  void setCBPostDraw(const luabind::object &fn);
  void setCBPreSim(const luabind::object &fn);
  void setCBPostSim(const luabind::object &fn);
  void setCBPreStop(const luabind::object &fn);
  void setCBOnCommand(const luabind::object &fn);
  void setCBOnJoystick(const luabind::object &fn);
  void setCBOnSpaceNavigator(const luabind::object &fn);
  void setCBCycleObject(const luabind::object &fn);
  void setCBOnParamChanged(const luabind::object &fn);

  void addParam(const QString &name, const QVariant &value);
  void addParam(const QString &name, const btScalar &value, const btScalar &min, const btScalar &max);
  QVariant getParam(const QString &name) const;
  QHash<QString, QVariant> getParams() const;
  void clearParams();

  ParamInfo getParamInfo(const QString &name) const;

  void keyPressEvent(QKeyEvent *e);

  void command(QString cmd);

  void showLuaException(const std::exception &e, const QString &context = "");

  void onQuickRender();
  void onQuickRender(QString povargs);

  void onJoystickData(const JoystickInfo &ji);

  void onSpaceNavigatorAxes(const SpaceNavigator::Axes &axes);
  void onSpaceNavigatorNorm(const SpaceNavigator::AxesNorm &axes);
  void onSpaceNavigatorButton(int button, bool pressed);
  void onSpaceNavigatorTick();
  void integrateSpaceNavigator(bool sustained = false);

  // SpaceNavigator navigation settings
  void setSpaceNavigatorMode(int mode);
  int spaceNavigatorMode() const;
  void setSpaceNavigatorLockHorizon(bool on);
  bool spaceNavigatorLockHorizon() const;
  void setSpaceNavigatorAutoFlySpeed(bool on);
  bool spaceNavigatorAutoFlySpeed() const;
  void setSpaceNavigatorShowOrbitAxis(bool on);
  bool spaceNavigatorShowOrbitAxis() const;
  void setSpaceNavigatorZoomDirection(bool forward);
  bool spaceNavigatorZoomForward() const;
  void setSpaceNavigatorPanZoom(bool on);
  bool spaceNavigatorPanZoom() const;

  void setShowConstraints(bool on);
  bool showConstraints() const;

  void updateGLViewer() {
#if QGLVIEWER_VERSION < 0x020700
    this->updateGL();
#else
    this->update();
#endif
  };

signals:
  void cycleObject(int direction);
  void frameUpdate(int frameNum);
  void statusEvent(const QString &);

  void scriptFinished();
  void scriptStarts();
  void scriptStopped();
  void scriptHasOutput(const QString &);

  void postDrawShot(int);
  void simulationStateChanged(bool);
  void POVStateChanged(bool);
  void PNGStateChanged(bool);
  void deactivationStateChanged(bool);

  void clearDebugText();
  void paramsChanged();

protected:
  virtual void init();

  void setGravity(btVector3 gravity);
  btVector3 getGravity();

  virtual void addObjects();

  void addObject(Object *o, int type, int mask);

  void addObjects(QList<Object *> ol, int type, int mask);

  void drawSceneInternal(int pass);

  void computeBoundingBox();

  void savePOV(bool force = false);

public:
  //  QList<Object*> l[13];

private:
  lua_State *L;
  QString lua_error;

  Cam *_cam;
  Vec _initialCameraPosition;
  Quaternion _initialCameraOrientation;
  btScalar _initialCameraHorizontalFieldOfView;
  Vec _initialCameraUpVector;

  bool _simulate;

  Sphere *mioSphere;

  //  ManipulatedFrame** keyFrame_;
  //  KeyFrameInterpolator kfi_;
  //  int nbKeyFrames;
  //  int currentKF_;

  QSet<Object *> *_objects;
  QSet<btTypedConstraint *> *_constraints;
  QSet<btRaycastVehicle *> *_raycast_vehicles;
  // btRaycastVehicle doesn't own/delete its raycaster, so track the ones we
  // hand out from createVehicleRaycaster() ourselves.
  QSet<btVehicleRaycaster *> *_vehicle_raycasters;
  // Store raw Lua registry references (not luabind::object) to avoid
  // use-after-free when Lua state is destroyed.
  std::map<Object*, int> _luabindRegistry;

  btScalar _aabb[6];

  btDefaultCollisionConfiguration *collisionCfg;
  btDiscreteDynamicsWorld *dynamicsWorld;

  // Keep ownership of Bullet subcomponents so we can delete them explicitly
  btBroadphaseInterface *broadphase;
  btCollisionDispatcher *dispatcher;
  btConstraintSolver *solver;

  // Draws constraints (hinge axes, slider axes, pivots, ...), modelled on
  // btDiscreteDynamicsWorld::debugDrawConstraint() but implemented directly
  // so we control size/color per constraint type.
  btIDebugDraw *_debugDrawer;
  bool _showConstraints;
  void drawConstraints();
  void drawConstraint(btTypedConstraint *c, btScalar size);
  btScalar constraintDrawSize(btTypedConstraint *c);
  void drawConstraintFrame(const btTransform &t, btScalar size);
  void drawConstraintAxis(const btTransform &t, int axis, btScalar size,
                          const btVector3 &color);
  void drawConstraintPoint(const btVector3 &p, btScalar size,
                           const btVector3 &color);
  void drawConstraintCylinder(const btVector3 &from, const btVector3 &to,
                              btScalar radius, const btVector3 &color);

  QElapsedTimer _timer;

  QTextStream *_stream;

  int _frameNum;
  int _firstFrame;

  QFile *_file;
  QFile *_fileMain;
  QFile *_fileINI;
  QFile *_fileMakefile;

  bool _savePOV;
  bool _deactivation;
  QString _scriptName;
  QString _scriptBasePath;
  QString _scriptContent;

  QMutex mutex;
  QMutex cammutex;

  // Lua callback functions
  luabind::object _cb_preStart;
  luabind::object _cb_preDraw, _cb_postDraw;
  luabind::object _cb_preSim, _cb_postSim;
  luabind::object _cb_preStop;
  luabind::object _cb_onCommand;
  luabind::object _cb_onJoystick;
  luabind::object _cb_onSpaceNavigator;
  luabind::object _cb_cycleObject;
  luabind::object _cb_onParamChanged;

  #include <memory>

  QHash<QString, std::shared_ptr<luabind::object>> *_cb_shortcuts;

  bool _parsing;
  bool _has_exception;

  // OpenGL properties
  btScalar _gl_shininess;
  btVector4 _gl_specular_col;

  btVector4 _light0;
  btVector4 _light1;

  btVector3 _gl_ambient;
  btVector4 _gl_diffuse, _gl_specular;

  btVector4 _gl_model_ambient;

  // POV-Ray properties
  QString mPreSDL;
  QString mPostSDL;

  QString _pov_settings_inc;

  QSettings *_settings;

  // bulletphysics.org/mediawiki-1.5.8/index.php/Stepping_the_World
  btScalar _timeStep;
  int _maxSubSteps;
  btScalar _fixedTimeStep;

  // joystick handler
  JoystickInterfaceSDL *_joystickInterface;
  JoystickHandler _joystickHandler;

  // SpaceNavigator 3D mouse
  SpaceNavigator *_spaceNavigator;

  // SpaceNavigator navigation mode (Object/Orbit vs Fly/First-person)
  enum SpaceNavigatorMode {
    SN_MODE_OBJECT,
    SN_MODE_FLY
  };
  SpaceNavigatorMode _snMode;

  // SpaceNavigator navigation settings (editable from the Preferences
  // dialog and via the Lua sn* properties).
  bool _snLockHorizon;
  bool _snAutoFlySpeed;
  bool _snShowOrbitAxis;
  bool _snZoomForward;
  bool _snPanZoom;

  // Blender-style orbit distance: the distance from the camera to the
  // view-centre pivot the SpaceNavigator orbits around.  Reinitialised from
  // the scene when the camera is reset or the scene changes.
  qreal _snOrbitDist;

  // 3D mouse integration: the current shaped deflection is held in _snTarget
  // (a target velocity in units of full deflection).  Each device report
  // integrates the target over the time elapsed since the previous report
  // (event-driven, like Blender's NDOF), so navigation responds immediately.
  // _snTimer is a sustaining timer only: the SpaceNavigator is an absolute
  // device that reports nothing while a deflection is held still, so the
  // timer keeps integrating the last target at a fixed rate and the camera
  // keeps moving for as long as the cap is held.  Motion stops when the cap
  // returns to rest: the last report's deflection is remembered in
  // _snLastInput, the sustaining path eases resting axes back to zero (the
  // event path has already shaped them through the dead band and low-pass),
  // and the eased target is stopped once it falls back into the target dead
  // band.  _snTickTimer is shared by both paths so the integrated time
  // intervals never overlap.
  QTimer *_snTimer;
  QElapsedTimer _snTickTimer;
  SpaceNavigator::AxesNorm _snTarget;
  SpaceNavigator::AxesNorm _snLastInput;

   // parameter storage for Lua scripts
   QHash<QString, QVariant> _params;
   QHash<QString, ParamInfo> _paramInfo;
};

#endif // VIEWER_H
