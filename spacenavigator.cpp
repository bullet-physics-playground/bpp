#include "spacenavigator.h"

#include <GL/gl.h>

using namespace std;

SpaceNavigator::SpaceNavigator(QObject *parent) : QThread(parent) {
  stopThread = false;

  if (spnav_open() == -1) {
    qDebug() << "failed to connect to spacenav daemon";
    connected = false;
  } else {
    connected = true;
    start();
  }
}

SpaceNavigator::~SpaceNavigator()
{
  stopThread = true;
}

void SpaceNavigator::run() {

  if (connected) {
    while (!stopThread && spnav_wait_event(&sev)) {
      if (sev.type == SPNAV_EVENT_MOTION) {
	emit moveRecived(new SpaceNavigatorEvent(sev.motion.rx, sev.motion.ry, sev.motion.rz,
						 sev.motion.x,  sev.motion.y, sev.motion.z)); 
      } else {
	emit buttonRecived(new SpaceNavigatorEvent(sev.button.bnum, sev.button.press));
      }
    }
  }
  
  spnav_close();
}
