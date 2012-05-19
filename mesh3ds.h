#ifndef Model3DS_H
#define Model3DS_H

#include "mesh3ds.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <lib3ds.h>
#include "object.h"

class Mesh3DS : public Object {
 public:
  Mesh3DS(QString filename, btScalar mass);

  virtual void renderInLocalFrame(QTextStream *s) const;

 protected:
  int listref;
  GLuint count;
};

#endif
