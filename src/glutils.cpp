#include "glutils.h"

#include <cmath>
#include <cstdlib>

#include <QObject>
#include <QOpenGLContext>
#include <QSet>
#include <map>
#include <tuple>

#ifdef Q_OS_MAC
#include <OpenGL/gl.h>
#else
#ifdef _WIN32
  #include <windows.h>
#endif
#include <GL/gl.h>
#endif

static void solidCubeDraw(double sz)
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

static void solidSphereDraw(double radius, int slices, int stacks) {
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

static void solidCylinderDraw(double radius, double height, int slices, int stacks) {
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

static void solidConeDraw(double radius, double height, int slices, int stacks) {
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

// ---------------------------------------------------------------------------
// Display-list caching. The primitives are drawn with the same few sizes over
// and over (objects draw a unit shape and scale it), so each distinct call is
// compiled once into a display list and replayed after that: one call instead
// of hundreds of vertices, normals and sines and cosines every frame.
// ---------------------------------------------------------------------------

static unsigned s_glEpoch = 0;

unsigned glCacheEpoch() { return s_glEpoch; }

const void *glCacheContext() {
  QOpenGLContext *c = QOpenGLContext::currentContext();
  if (c == nullptr)
    return nullptr;
  static QSet<QOpenGLContext *> hooked;
  if (!hooked.contains(c)) {
    hooked.insert(c);
    QObject::connect(c, &QOpenGLContext::aboutToBeDestroyed, [c]() {
      hooked.remove(c);
      ++s_glEpoch;
    });
  }
  return c;
}

namespace {
typedef std::tuple<int, double, double, int, int> PrimKey;
struct PrimList {
  GLuint list;
  const void *ctx;
  unsigned epoch;
};
std::map<PrimKey, PrimList> s_prims;

template <class Draw>
void cachedPrimitive(const PrimKey &key, Draw draw) {
  const void *ctx = glCacheContext();
  if (ctx == nullptr) {
    draw();
    return;
  }
  auto it = s_prims.find(key);
  if (it != s_prims.end()) {
    if (it->second.ctx == ctx && it->second.epoch == s_glEpoch) {
      glCallList(it->second.list);
      return;
    }
    s_prims.erase(it);                  // its context has gone, and the list with it
  }
  if (s_prims.size() >= 512) {          // odd sizes, drawn once each: don't hoard
    draw();
    return;
  }
  GLuint list = glGenLists(1);
  if (list == 0) {
    draw();
    return;
  }
  glNewList(list, GL_COMPILE);
  draw();
  glEndList();
  s_prims[key] = PrimList{list, ctx, s_glEpoch};
  glCallList(list);
}
} // namespace

void solidCube(double sz) {
  cachedPrimitive(PrimKey(0, sz, 0, 0, 0), [=]() { solidCubeDraw(sz); });
}

void solidSphere(double radius, int slices, int stacks) {
  cachedPrimitive(PrimKey(1, radius, 0, slices, stacks),
                  [=]() { solidSphereDraw(radius, slices, stacks); });
}

void solidCylinder(double radius, double height, int slices, int stacks) {
  cachedPrimitive(PrimKey(2, radius, height, slices, stacks),
                  [=]() { solidCylinderDraw(radius, height, slices, stacks); });
}

void solidCone(double radius, double height, int slices, int stacks) {
  cachedPrimitive(PrimKey(3, radius, height, slices, stacks),
                  [=]() { solidConeDraw(radius, height, slices, stacks); });
}
