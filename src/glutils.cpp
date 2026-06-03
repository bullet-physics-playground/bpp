#include "glutils.h"

#include <cmath>
#include <cstdlib>

#include <QObject>

#ifdef Q_OS_MAC
#include <OpenGL/gl.h>
#else
#ifdef _WIN32
  #include <windows.h>
#endif
#include <GL/gl.h>
#endif

void solidCube(double sz)
{
	int i, j, idx, gray, flip, rotx;
	float vpos[3], norm[3];
	float rad = sz * 0.5f;

	glBegin(GL_QUADS);
	for(i=0; i<6; i++) {
		flip = i & 1;
		rotx = i >> 2;
		idx = (~i & 2) - rotx;
		norm[0] = norm[1] = norm[2] = 0.0f;
		norm[idx] = flip ^ ((i >> 1) & 1) ? -1 : 1;
		glNormal3fv(norm);
		vpos[idx] = norm[idx] * rad;
		for(j=0; j<4; j++) {
			gray = j ^ (j >> 1);
			vpos[i & 2] = (gray ^ flip) & 1 ? rad : -rad;
			vpos[rotx + 1] = (gray ^ (rotx << 1)) & 2 ? rad : -rad;
			glTexCoord2f(gray & 1, gray >> 1);
			glVertex3fv(vpos);
		}
	}
	glEnd();
}

void solidSphere(double radius, int slices, int stacks) {
  for(int i = 0; i < stacks; i++) {
    glBegin(GL_QUAD_STRIP);
    for(int j = 0; j <= slices; j++) {
      double theta = i * M_PI / stacks;
      double phi = j * 2 * M_PI / slices;
      double x = sin(theta) * cos(phi) * radius;
      double y = sin(theta) * sin(phi) * radius;
      double z = cos(theta) * radius;
      glNormal3d(x/radius, y/radius, z/radius);
      glVertex3d(x, y, z);
      theta = (i + 1) * M_PI / stacks;
      x = sin(theta) * cos(phi) * radius;
      y = sin(theta) * sin(phi) * radius;
      z = cos(theta) * radius;
      glNormal3d(x/radius, y/radius, z/radius);
      glVertex3d(x, y, z);
    }
    glEnd();
  }
}

void solidCylinder(double radius, double height, int slices, int stacks) {
    for (int i = 0; i < stacks; i++) {
        float z0 = (float)height * i / stacks;
        float z1 = (float)height * (i + 1) / stacks;

        glBegin(GL_TRIANGLE_STRIP);
        for (int j = 0; j <= slices; j++) {
            double theta = j * 2.0 * M_PI / slices;
            float x = (float)cos(theta);
            float y = (float)sin(theta);

            glNormal3f(x, y, 0.0f);
            glVertex3f((float)radius * x, (float)radius * y, z0);
            glVertex3f((float)radius * x, (float)radius * y, z1);
        }
        glEnd();
    }

    for (int side = 0; side < 2; side++) {
        float z = (side == 0) ? 0.0f : (float)height;
        float nz = (side == 0) ? -1.0f : 1.0f;

        glBegin(GL_TRIANGLE_FAN);
            glNormal3f(0.0f, 0.0f, nz);
            glVertex3f(0.0f, 0.0f, z);
            for (int j = 0; j <= slices; j++) {
                double theta = (side == 0) ? (j * 2.0 * M_PI / slices) : (-j * 2.0 * M_PI / slices);
                glVertex3f((float)radius * cos(theta), (float)radius * sin(theta), z);
            }
        glEnd();
    }
}

void solidCone(double radius, double height, int slices, int stacks) {
    for (int i = 0; i < stacks; i++) {
        float z0 = (float)height * i / stacks;
        float z1 = (float)height * (i + 1) / stacks;
        float r0 = (float)radius * (1.0f - (float)i / stacks);
        float r1 = (float)radius * (1.0f - (float)(i + 1) / stacks);

        glBegin(GL_TRIANGLE_STRIP);
        for (int j = 0; j <= slices; j++) {
            double theta = j * 2.0 * M_PI / slices;
            float x = (float)cos(theta);
            float y = (float)sin(theta);

            glNormal3f(x, y, (float)radius / (float)height);
            glVertex3f(r0 * x, r0 * y, z0);
            glVertex3f(r1 * x, r1 * y, z1);
        }
        glEnd();
    }

    glBegin(GL_TRIANGLE_FAN);
    glNormal3f(0.0f, 0.0f, -1.0f);
    glVertex3f(0.0f, 0.0f, 0.0f);
    for (int j = 0; j <= slices; j++) {
        double theta = j * 2.0 * M_PI / slices;
        glVertex3f((float)radius * cos(theta), (float)radius * sin(theta), 0.0f);
    }
    glEnd();
}
