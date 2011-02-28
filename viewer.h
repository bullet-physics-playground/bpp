#ifndef VIEWER_H
#define VIEWER_H

#include <QGLViewer/qglviewer.h>
#include <QGLViewer/manipulatedFrame.h>

#include <btBulletDynamicsCommon.h>

#include <QFile>
#include <QTextStream>
#include <QKeyEvent>

#include "rm1.h"

using namespace qglviewer;

class Object;

class Viewer : public QGLViewer
{
  Q_OBJECT;

 public:
  Viewer(QWidget *parent=NULL, bool savePNG=false, bool savePOV=false);
  ~Viewer();

 protected:
  virtual void init();

  virtual void keyPressEvent(QKeyEvent *e);

  virtual void addObjects();

  void addObject(Object *o, int type, int mask);
  void addObjects(QList<Object *> ol, int type, int mask);

  virtual void startAnimation();
  virtual void animate();
  virtual void draw();
  virtual void postDraw();

  void computeBoundingBox();

  void openPovFile();
  void closePovFile();

 public:
  RM1 *rm;

  QList<Object*> l[10];

 private:
  ManipulatedFrame** keyFrame_;
  KeyFrameInterpolator kfi_;
  int nbKeyFrames;
  int currentKF_;

  QVector<Object*>   _objects;
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
};

#endif // VIEWER_H
