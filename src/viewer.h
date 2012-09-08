#ifndef VIEWER_H
#define VIEWER_H

#include <lua.hpp>

#include <QGLViewer/qglviewer.h>
#include <QGLViewer/manipulatedFrame.h>

#include <btBulletDynamicsCommon.h>

#include <QMutex>
#include <QMutexLocker>

#include <QFile>
#include <QTextStream>
#include <QKeyEvent>
#include <QSettings>

#include "objects/cam.h"

#include "objects/robots/rm.h"

#ifdef HAS_MIDI

#include "MidiIO.h"

#endif

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

  void addObject(Object* o);
  void setCamera(Camera* cam);

  static void luaBind(lua_State *s);
  void luaBindInstance(lua_State *s);
  virtual QString toString() const;

  void emitScriptOutput(const QString&);
  static int lua_print(lua_State*);

  void addConstraints(QList<btTypedConstraint *> cons);
 public slots:
  bool parse(QString txt);
  void clear();

  void setCBPreDraw(const luabind::object &fn);
  void setCBPostDraw(const luabind::object &fn);

 signals:
  void scriptFinished();
  void scriptStopped();
  void scriptHasOutput(const QString&);
  void postDrawShot(int);

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

#ifdef HAS_MIDI
 private slots:
  void midiRecived(MidiEvent *e);
#endif

 public:
  RM *rm;

  QList<Object*> l[10];

 private:
  lua_State *L;
  QString lua_error;

  Cam *_cam;

  bool _simulate;

  Sphere *mioSphere;

  ManipulatedFrame** keyFrame_;
  KeyFrameInterpolator kfi_;
  int nbKeyFrames;
  int currentKF_;

  QVector<Object*>   *_objects;
  QVector<Object*>   *_all_objects; // for bounding box calculation
  btScalar           _aabb[6];

  btDefaultCollisionConfiguration *collisionCfg;
  btAxisSweep3 *axisSweep;
  btDiscreteDynamicsWorld *dynamicsWorld;

  QTime              _time;

  QTextStream      *_stream;

  int              _frameNum;

  QFile            *_file;

  bool               _savePNG;
  bool               _savePOV;

#ifdef HAS_MIDI
  MidiIO mio;
#endif

  QMutex mutex;

  luabind::object _cb_preDraw;
  luabind::object _cb_postDraw;
};

#endif // VIEWER_H
