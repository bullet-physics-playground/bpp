#ifndef VIEWER_H
#define VIEWER_H

#include <lua.hpp>

#include <QGLViewer/qglviewer.h>
#include <QGLViewer/manipulatedFrame.h>

#include <btBulletDynamicsCommon.h>

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

namespace luabind
{
  template <>
  struct default_converter<unsigned long long>
	: native_converter_base<unsigned long long>
  {
    static int compute_score(lua_State* L, int index) {
	  return lua_type(L, index) == LUA_TNUMBER ? 0 : -1;
    }

    unsigned long long from(lua_State* L, int index) {
	  return static_cast<unsigned long long>(lua_tonumber(L, index));
    }

    void to(lua_State* L, unsigned long long value) {
	  lua_pushnumber(L, static_cast<lua_Number>(value));
    }
  };

  template <>
  struct default_converter<unsigned long long const>
	: default_converter<unsigned long long>
  {};

  template <>
  struct default_converter<unsigned long long const&>
	: default_converter<unsigned long long>
  {};

}
  
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
  void setCamera(Camera* cam);

  static void luaBind(lua_State *s);
  void luaBindInstance(lua_State *s);
  virtual QString toString() const;
  void setScriptName(QString sn);

  void emitScriptOutput(const QString&);
  static int lua_print(lua_State*);

  void addConstraints(QList<btTypedConstraint *> cons);
 public slots:
  bool parse(QString txt);
  void clear();

  void setCBPreDraw(const luabind::object &fn);
  void setCBPostDraw(const luabind::object &fn);
  void setCBPreSim(const luabind::object &fn);
  void setCBPostSim(const luabind::object &fn);

 signals:
  void scriptFinished();
  void scriptStopped();
  void scriptHasOutput(const QString&);
  void postDrawShot(int);
  void simulationStateChanged(bool);
  void POVStateChanged(bool);
  void PNGStateChanged(bool);
  void deactivationStateChanged(bool);

 protected:
  virtual void init();

  virtual void keyPressEvent(QKeyEvent *e);

  virtual void addObjects();

  void addObject(Object *o, int type, int mask);
  void removeObject(Object *o);

  void addObjects(QList<Object *> ol, int type, int mask);

  void add4BBox(Object *o);
  void add4BBox(QList<Object *> ol);

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

  ManipulatedFrame** keyFrame_;
  KeyFrameInterpolator kfi_;
  int nbKeyFrames;
  int currentKF_;

  QList<Object*>   *_objects;
  QList<Object*>   *_all_objects; // for bounding box calculation
  btScalar           _aabb[6];

  btDefaultCollisionConfiguration *collisionCfg;
  btAxisSweep3 *axisSweep;
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

  luabind::object _cb_preDraw,_cb_postDraw;
  luabind::object _cb_preSim,_cb_postSim;

  bool _parsing;
};

#endif // VIEWER_H
