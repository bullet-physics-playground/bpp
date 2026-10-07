#include "glutils.h"

#include <cmath>
#include <cstdlib>

#include <QHash>
#include <QImage>
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
  // Poles on Y, and u running the opposite way round to phi, so that the
  // texture lands exactly where POV-Ray's uv_mapping puts it on a sphere:
  // u = 0.5 + atan2(z_pov, x)/2pi and v = 0.5 + asin(y/r)/pi, remembering
  // that POV's Z points the other way to this one (see povMatrixFromGL).
  // u decreases past 0 rather than wrapping, which keeps the strip free of a
  // seam where the texture would otherwise run backwards through a whole quad.
  for(int i = 0; i < stacks; i++) {
    glBegin(GL_QUAD_STRIP);
    for(int j = 0; j <= slices; j++) {
      double phi = j * 2 * M_PI / slices;
      double u = 0.5 - j / (double)slices;
      for (int k = 0; k < 2; k++) {
        double theta = (i + k) * M_PI / stacks;
        double x = sin(theta) * cos(phi) * radius;
        double y = cos(theta) * radius;
        double z = sin(theta) * sin(phi) * radius;
        glNormal3d(x/radius, y/radius, z/radius);
        glTexCoord2d(u, 1.0 - (i + k) / (double)stacks);
        glVertex3d(x, y, z);
      }
    }
    glEnd();
  }
}

static void solidCylinderDraw(double radius, double height, int slices, int stacks) {
    // Side wall: u once round the axis, v from one end to the other. The caps
    // take the image square-on, the way a lid sits on a tin. u increases with
    // the angle so that the image reads the right way round from outside --
    // the opposite way to the sphere, whose own parameterisation already turns
    // it (see solidSphereDraw).
    for (int i = 0; i < stacks; i++) {
        float z0 = (float)height * i / stacks;
        float z1 = (float)height * (i + 1) / stacks;

        glBegin(GL_TRIANGLE_STRIP);
        for (int j = 0; j <= slices; j++) {
            double theta = j * 2.0 * M_PI / slices;
            float x = (float)cos(theta);
            float y = (float)sin(theta);
            float u = 0.5f + (float)j / slices;

            glNormal3f(x, y, 0.0f);
            glTexCoord2f(u, (float)i / stacks);
            glVertex3f((float)radius * x, (float)radius * y, z0);
            glTexCoord2f(u, (float)(i + 1) / stacks);
            glVertex3f((float)radius * x, (float)radius * y, z1);
        }
        glEnd();
    }

    for (int side = 0; side < 2; side++) {
        float z = (side == 0) ? 0.0f : (float)height;
        float nz = (side == 0) ? -1.0f : 1.0f;

        glBegin(GL_TRIANGLE_FAN);
            glNormal3f(0.0f, 0.0f, nz);
            glTexCoord2f(0.5f, 0.5f);
            glVertex3f(0.0f, 0.0f, z);
            for (int j = 0; j <= slices; j++) {
                double theta = (side == 0) ? (j * 2.0 * M_PI / slices) : (-j * 2.0 * M_PI / slices);
                glTexCoord2f(0.5f + 0.5f * (float)cos(theta),
                             0.5f + 0.5f * (float)sin(theta));
                glVertex3f((float)radius * cos(theta), (float)radius * sin(theta), z);
            }
        glEnd();
    }
}

static void solidConeDraw(double radius, double height, int slices, int stacks) {
    // Same mapping as the cylinder: u once round the axis, v from the base up
    // to the apex, and the base disc taking the image square-on.
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
            float u = 0.5f + (float)j / slices;

            glNormal3f(x, y, (float)radius / (float)height);
            glTexCoord2f(u, (float)i / stacks);
            glVertex3f(r0 * x, r0 * y, z0);
            glTexCoord2f(u, (float)(i + 1) / stacks);
            glVertex3f(r1 * x, r1 * y, z1);
        }
        glEnd();
    }

    glBegin(GL_TRIANGLE_FAN);
    glNormal3f(0.0f, 0.0f, -1.0f);
    glTexCoord2f(0.5f, 0.5f);
    glVertex3f(0.0f, 0.0f, 0.0f);
    for (int j = 0; j <= slices; j++) {
        double theta = j * 2.0 * M_PI / slices;
        glTexCoord2f(0.5f + 0.5f * (float)cos(theta),
                     0.5f + 0.5f * (float)sin(theta));
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

static bool s_recording = false;

bool glRecordingList() { return s_recording; }

void glSetRecordingList(bool on) { s_recording = on; }

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
  if (s_recording || s_prims.size() >= 512) {  // (odd sizes, drawn once each: don't hoard)
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

// ---------------------------------------------------------------------------
// Texture caching. Objects name an image file and are drawn every frame, so
// each file is read and uploaded once and then shared, under the same
// context/epoch rules as the display lists above.
// ---------------------------------------------------------------------------

namespace {
struct TexEntry {
  GLuint id;       // 0 when the image would not load
  const void *ctx;
  unsigned epoch;
};
QHash<QString, TexEntry> s_textures;
} // namespace

unsigned glTextureFromFile(const QString &file) {
  const void *ctx = glCacheContext();
  if (ctx == nullptr) {
    return 0;
  }

  auto it = s_textures.find(file);
  if (it != s_textures.end()) {
    if (it->ctx == ctx && it->epoch == s_glEpoch) {
      return it->id;
    }
    s_textures.erase(it);               // its context has gone, and the texture with it
  }

  GLuint id = 0;
  QImage img(file);
  if (!img.isNull()) {
    // OpenGL's first row is the bottom of the texture and QImage's is the top,
    // so the image is flipped to read the way POV-Ray reads the same file.
    QImage rgba = img.convertToFormat(QImage::Format_RGBA8888).mirrored(false, true);
    glGenTextures(1, &id);
    glBindTexture(GL_TEXTURE_2D, id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, rgba.width(), rgba.height(), 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, rgba.constBits());
    glBindTexture(GL_TEXTURE_2D, 0);
  }

  // A file that would not load is cached as 0 as well, so the failure costs
  // one attempt instead of one per frame.
  s_textures.insert(file, TexEntry{id, ctx, s_glEpoch});
  return id;
}
