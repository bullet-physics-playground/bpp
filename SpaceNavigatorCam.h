#ifndef SPACE_NAVIGATOR_CAM_H
#define SPACE_NAVIGATOR_CAM_H

#include <QGLViewer/manipulatedCameraFrame.h>

#include "spacenavigator.h"

using namespace qglviewer;

class SpaceNavigatorCam : public ManipulatedCameraFrame {
  Q_OBJECT;

 public:
  SpaceNavigatorCam(Camera *cam);
  virtual ~SpaceNavigatorCam() {};

 private slots:
  void moveRecived(SpaceNavigatorEvent *e);
  void buttonRecived(SpaceNavigatorEvent *e);

 private:
  Camera *camera;

  SpaceNavigator *sn;
};

#endif
