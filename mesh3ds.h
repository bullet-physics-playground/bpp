#ifndef Model3DS_H
#define Model3DS_H

#include "mesh3ds.h"

#include <GL/gl.h>

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
