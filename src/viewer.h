#ifndef VIEWER_H
#define VIEWER_H

#include <lua.hpp>

#include <GL/glew.h>

#include <QGLViewer/qglviewer.h>
#include <QGLViewer/manipulatedFrame.h>

#include <btBulletDynamicsCommon.h>

#include "BulletDynamics/Vehicle/btRaycastVehicle.h"

#include <QMutex>
#include <QMutexLocker>

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QKeyEvent>
#include <QSettings>

#include "objects/cam.h"

#include "objects/sphere.h"

using namespace qglviewer;

class Object;
class Viewer;

std::ostream& operator<<(std::ostream&, const Viewer& v);

#include "lua_converters.h"

class Viewer : public QGLViewer
{
  Q_OBJECT;

 public:
  Viewer(QWidget *parent = NULL, bool savePNG = false, bool savePOV = false);
  ~Viewer();

  void setSavePNG(bool png);
  void setSavePOV(bool pov);
  void toggleSavePOV();
  void toggleSavePNG();
  void toggleDeactivation();
  void startSim();
  void stopSim();
  void restartSim();
  void resetCamView();

  void addObject(Object* o);
  void removeObject(Object* o);
  void setCamera(Cam* cam);

  static void luaBind(lua_State *s);
  void luaBindInstance(lua_State *s);
  virtual QString toString() const;
  void setScriptName(QString sn);

  void emitScriptOutput(const QString&);
  void emitClearOutput();
  static int lua_print(lua_State*);

  void addConstraints(QList<btTypedConstraint *> cons);
  void addConstraint(btTypedConstraint *con);
  void addVehicle(btRaycastVehicle *veh);
  void removeConstraint(btTypedConstraint *con);

  void addShortcut(const QString&, const luabind::object &fn);
  void removeShortcut(const QString&);

  btVehicleRaycaster* createVehicleRaycaster();

 public slots:
  void close();

  bool parse(QString txt);
  void clear();

  void setCBPreDraw(const luabind::object &fn);
  void setCBPostDraw(const luabind::object &fn);
  void setCBPreSim(const luabind::object &fn);
  void setCBPostSim(const luabind::object &fn);
  void setCBOnCommand(const luabind::object &fn);

  void keyPressEvent(QKeyEvent *e);

  void command(QString cmd);

  void showLuaException(const std::exception& e, const QString& context = "");

 signals:
  void scriptFinished();
  void scriptStarts();
  void scriptStopped();
  void scriptHasOutput(const QString&);

  void postDrawShot(int);
  void simulationStateChanged(bool);
  void POVStateChanged(bool);
  void PNGStateChanged(bool);
  void deactivationStateChanged(bool);

 protected:
  virtual void init();

  virtual void addObjects();

  void addObject(Object *o, int type, int mask);

  void addObjects(QList<Object *> ol, int type, int mask);

  virtual void startAnimation();
  virtual void stopAnimation();
  virtual void animate();
  virtual void draw();
  virtual void postDraw();

  void computeBoundingBox();

  void openPovFile();
  void closePovFile();

  void loadPrefs();
  void savePrefs();

 public:

  //  QList<Object*> l[13];

 private:
  lua_State *L;
  QString lua_error;

  Cam *_cam;
  Vec _initialCameraPosition;
  Quaternion _initialCameraOrientation;

  bool _simulate;

  Sphere *mioSphere;

//  ManipulatedFrame** keyFrame_;
//  KeyFrameInterpolator kfi_;
//  int nbKeyFrames;
//  int currentKF_;

  QSet<Object*> *_objects;
  QSet<btTypedConstraint*> *_constraints;
  QSet<btRaycastVehicle*> *_raycast_vehicles;

  btScalar           _aabb[6];

  btDefaultCollisionConfiguration *collisionCfg;
  btDiscreteDynamicsWorld *dynamicsWorld;

  QTime              _time;

  QTextStream      *_stream;
  QTextStream      *_streamMain;
  QTextStream      *_streamINI;

  int              _frameNum;
  int		   _firstFrame;

  QFile            *_file;
  QFile            *_fileMain;
  QFile            *_fileINI;

  bool               _savePNG;
  bool               _savePOV;
  bool		_deactivation;
  QString	_scriptName;
  QString	_scriptContent;

  QMutex mutex;

  // Lua callback functions
  luabind::object _cb_preDraw,_cb_postDraw;
  luabind::object _cb_preSim,_cb_postSim;
  luabind::object _cb_onCommand;

  QHash<QString, luabind::object> *_cb_shortcuts;

  bool _parsing;
  bool _has_exception;
};

#endif // VIEWER_H
