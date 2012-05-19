#include "SpaceNavigatorCam.h"

#include <QGLViewer/camera.h>

#include <QDebug>

#ifdef SPACENAVIGATOR

SpaceNavigatorCam::SpaceNavigatorCam(Camera *_camera) {
  camera = _camera;

  sn = new SpaceNavigator();

  connect(sn, SIGNAL(moveRecived(SpaceNavigatorEvent *)),
	  this, SLOT(moveRecived(SpaceNavigatorEvent *)));

  connect(sn, SIGNAL(buttonRecived(SpaceNavigatorEvent *)),
	  this, SLOT(buttonRecived(SpaceNavigatorEvent *)));
}

void SpaceNavigatorCam::moveRecived(SpaceNavigatorEvent *e) {
  //qDebug() << "snav move t" << e->tx << ", " << e->ty << " ," << e->tz;
  //qDebug() << "snav move r" << e->rx << ", " << e->ry << " ," << e->rz;

  // translate
  {
    Vec trans(-e->tx / 2000.0, e->tz / 2000.0, -e->ty / 2000.0);
    translate(translationSensitivity()*trans);
  }

  // rotate
  {
    Vec trans = Vec(-e->rx / 200000.0, e->rz / 200000.0, -e->ry / 200000.0);
    trans = camera->frame()->orientation().rotate(trans);
    trans = transformOf(trans);
    
    Quaternion rot;
    
    rot[0] = trans[0]; rot[1] = trans[1]; rot[2] = trans[2];
    
    //#CONNECTION# These two methods should go together (spinning detection and activation)
    setSpinningQuaternion(rot);
    spin();
  }
}

void SpaceNavigatorCam::buttonRecived(SpaceNavigatorEvent *e) {
  qDebug() << "button";
}

#endif
