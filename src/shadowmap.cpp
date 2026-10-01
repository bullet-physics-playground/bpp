/**
 * @file shadowmap.cpp
 * @brief Implementation of the interactive view's shadow mapping.
 */

#include "shadowmap.h"

#include "glutils.h"

#ifdef WIN32
#include <windows.h>
#endif

// Qt's own GL headers come first: they bring a glext.h of their own, and
// including the system one ahead of them clashes over GL_GLEXT_VERSION.
#include <QDebug>
#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>

#ifdef Q_OS_MAC
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

// GL/gl.h only promises OpenGL 1.1, so the tokens the depth texture and the
// framebuffer need are not necessarily declared. They are plain constants, so
// spelling out the few that are missing costs nothing and keeps this building
// against a bare 1.1 header.
#ifndef GL_CLAMP_TO_EDGE
#define GL_CLAMP_TO_EDGE 0x812F
#endif
#ifndef GL_DEPTH_COMPONENT24
#define GL_DEPTH_COMPONENT24 0x81A6
#endif
#ifndef GL_TEXTURE_COMPARE_MODE
#define GL_TEXTURE_COMPARE_MODE 0x884C
#endif
#ifndef GL_TEXTURE_COMPARE_FUNC
#define GL_TEXTURE_COMPARE_FUNC 0x884D
#endif
#ifndef GL_COMPARE_R_TO_TEXTURE
#define GL_COMPARE_R_TO_TEXTURE 0x884E
#endif
#ifndef GL_FRAMEBUFFER
#define GL_FRAMEBUFFER 0x8D40
#endif
#ifndef GL_FRAMEBUFFER_BINDING
#define GL_FRAMEBUFFER_BINDING 0x8CA6
#endif
#ifndef GL_FRAMEBUFFER_COMPLETE
#define GL_FRAMEBUFFER_COMPLETE 0x8CD5
#endif
#ifndef GL_DEPTH_ATTACHMENT
#define GL_DEPTH_ATTACHMENT 0x8D00
#endif
#ifndef GL_TEXTURE0
#define GL_TEXTURE0 0x84C0
#endif
#ifndef GL_TEXTURE1
#define GL_TEXTURE1 0x84C1
#endif

// The program bind() last bound, so glSceneShaderTextured() can reach it from
// the object code without that code having to know about ShadowMap. Only ever
// touched from the render thread, between bind() and release().
static QOpenGLShaderProgram *s_boundProgram = nullptr;

void glSceneShaderTextured(bool on) {
  if (s_boundProgram != nullptr) {
    // GLint, not bool: the setUniformValue() overloads take GLint, GLuint and
    // GLfloat, and a bool converts to each of them just as readily.
    s_boundProgram->setUniformValue("uUseTexture", GLint(on ? 1 : 0));
  }
}

// Reproduces what the fixed-function pipeline computed per vertex, but per
// fragment, and hands the fragment shader its position in the light's clip
// space as well.
//
// gl_ModelViewMatrix is the camera's view times the object's own transform, so
// multiplying eye space by uShadowMatrix -- which carries the inverse of the
// camera's view -- lands in the light's clip space whatever the object
// transform happens to be. That means no object has to know a shadow map
// exists.
static const char *kVertexShader =
    "#version 120\n"
    "uniform mat4 uShadowMatrix;\n"
    "varying vec3 vNormal;\n"
    "varying vec3 vEye;\n"
    "varying vec4 vShadowCoord;\n"
    "void main() {\n"
    "  vec4 eye = gl_ModelViewMatrix * gl_Vertex;\n"
    "  vEye = eye.xyz;\n"
    "  vNormal = gl_NormalMatrix * gl_Normal;\n"
    "  vShadowCoord = uShadowMatrix * eye;\n"
    "  gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;\n"
    "  gl_FrontColor = gl_Color;\n"
    "  gl_Position = gl_ProjectionMatrix * eye;\n"
    "}\n";

// Two lights, ambient plus diffuse from gl_Color (which is what
// glColorMaterial(GL_AMBIENT_AND_DIFFUSE) makes the fixed-function pipeline
// use) and specular from the material, then unit 0's texture modulated over
// the top the way GL_MODULATE did. Only light 0 is shadowed; light 1 is the
// fill light and has no depth map of its own.
//
// Unlike the fixed-function path this flips the normal on a back face, as
// GL_LIGHT_MODEL_TWO_SIDE would: nothing is back-face culled here, so without
// it the inside of an open shape goes black while POV-Ray lights it.
static const char *kFragmentShader =
    "#version 120\n"
    "uniform sampler2D uTexture;\n"
    "uniform sampler2DShadow uShadowMap;\n"
    "uniform bool uUseTexture;\n"
    "uniform bool uUseShadow;\n"
    "uniform float uDarkness;\n"
    "uniform float uTexelStep;\n"
    "varying vec3 vNormal;\n"
    "varying vec3 vEye;\n"
    "varying vec4 vShadowCoord;\n"
    "\n"
    "// 1.0 where light 0 reaches the fragment, 0.0 where it is blocked, and\n"
    "// the average of nine taps along the edge in between.\n"
    "float lightReaching() {\n"
    "  if (!uUseShadow || vShadowCoord.w <= 0.0) return 1.0;\n"
    "  vec3 c = vShadowCoord.xyz / vShadowCoord.w;\n"
    "  // Outside the depth map there is nothing recorded to be shadowed by.\n"
    "  if (c.x < 0.0 || c.x > 1.0 || c.y < 0.0 || c.y > 1.0 ||\n"
    "      c.z < 0.0 || c.z > 1.0) return 1.0;\n"
    "  float sum = 0.0;\n"
    "  for (int y = -1; y <= 1; y++) {\n"
    "    for (int x = -1; x <= 1; x++) {\n"
    "      vec2 o = vec2(float(x), float(y)) * uTexelStep;\n"
    "      sum += shadow2D(uShadowMap, vec3(c.xy + o, c.z)).r;\n"
    "    }\n"
    "  }\n"
    "  return sum / 9.0;\n"
    "}\n"
    "\n"
    "void main() {\n"
    "  vec3 N = normalize(vNormal);\n"
    "  if (!gl_FrontFacing) N = -N;\n"
    "  vec3 V = normalize(-vEye);\n"
    "  vec4 base = gl_Color;\n"
    "  float lit = mix(1.0 - uDarkness, 1.0, lightReaching());\n"
    "  vec3 col = gl_LightModel.ambient.rgb * base.rgb;\n"
    "  for (int i = 0; i < 2; i++) {\n"
    "    vec4 lp = gl_LightSource[i].position;\n"
    "    vec3 L = (lp.w == 0.0) ? normalize(lp.xyz)\n"
    "                           : normalize(lp.xyz / lp.w - vEye);\n"
    "    float ndl = max(dot(N, L), 0.0);\n"
    "    vec3 d = gl_LightSource[i].diffuse.rgb * base.rgb * ndl;\n"
    "    vec3 s = vec3(0.0);\n"
    "    if (ndl > 0.0) {\n"
    "      vec3 H = normalize(L + V);\n"
    "      float sh = gl_FrontMaterial.shininess;\n"
    "      // pow(x, 0.0) is undefined in GLSL, and a shininess of 0 is the\n"
    "      // fixed-function pipeline\'s way of saying the highlight is flat.\n"
    "      float hl = sh > 0.0 ? pow(max(dot(N, H), 0.0), sh) : 1.0;\n"
    "      s = gl_LightSource[i].specular.rgb * gl_FrontMaterial.specular.rgb * hl;\n"
    "    }\n"
    "    col += gl_LightSource[i].ambient.rgb * base.rgb;\n"
    "    col += (i == 0 ? lit : 1.0) * (d + s);\n"
    "  }\n"
    "  float alpha = base.a;\n"
    "  if (uUseTexture) {\n"
    "    vec4 t = texture2D(uTexture, gl_TexCoord[0].st);\n"
    "    col *= t.rgb;\n"
    "    alpha *= t.a;\n"
    "  }\n"
    "  gl_FragColor = vec4(col, alpha);\n"
    "}\n";

ShadowMap::ShadowMap()
    : _size(2048), _softness(1.0), _darkness(1.0), _tex(0), _fbo(0),
      _prog(nullptr), _ctx(nullptr), _epoch(0), _failed(false),
      _haveDepth(false), _sizeDirty(false), _savedFbo(0) {
  _savedViewport[0] = _savedViewport[1] = 0;
  _savedViewport[2] = _savedViewport[3] = 0;
}

ShadowMap::~ShadowMap() { destroy(); }

void ShadowMap::setMapSize(int px) {
  // Powers of two from 256 up: smaller than that is too coarse to read as a
  // shadow, and 8192 square already costs 64MB of depth.
  px = qBound(256, px, 8192);
  if (px == _size)
    return;
  _size = px;
  // The old texture can only be deleted with its context current, which it is
  // not here -- a script or a menu sets this, not the render thread. Leave that
  // to the next isAvailable().
  _sizeDirty = true;
}

int ShadowMap::mapSize() const { return _size; }

void ShadowMap::setSoftness(double texels) { _softness = qMax(0.0, texels); }

double ShadowMap::softness() const { return _softness; }

void ShadowMap::setDarkness(double d) { _darkness = qBound(0.0, d, 1.0); }

double ShadowMap::darkness() const { return _darkness; }

bool ShadowMap::isAvailable() {
  const void *ctx = glCacheContext();
  if (ctx == nullptr)
    return false;

  // A new context, or the old one destroyed, leaves the handles below naming
  // objects that no longer exist; start again rather than using them.
  if (ctx != _ctx || glCacheEpoch() != _epoch) {
    _tex = 0;
    _fbo = 0;
    delete _prog;
    _prog = nullptr;
    _ctx = ctx;
    _epoch = glCacheEpoch();
    _failed = false;
    _haveDepth = false;
  }

  // A resize asked for off the render thread could not drop the old texture
  // itself; here the context is current, so it can.
  if (_sizeDirty) {
    destroy();
    _sizeDirty = false;
    _failed = false;
  }

  if (_failed)
    return false;
  if (_prog != nullptr && _tex != 0 && _fbo != 0)
    return true;

  if (!create()) {
    destroy();
    _failed = true;
    return false;
  }
  return true;
}

bool ShadowMap::create() {
  QOpenGLContext *c = QOpenGLContext::currentContext();
  if (c == nullptr)
    return false;
  QOpenGLFunctions *f = c->functions();

  if (_tex == 0) {
    // Any error already queued belongs to someone else; the check after the
    // allocation below is only meaningful on an empty queue.
    while (glGetError() != GL_NO_ERROR) {
    }

    glGenTextures(1, &_tex);
    glBindTexture(GL_TEXTURE_2D, _tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, _size, _size, 0,
                 GL_DEPTH_COMPONENT, GL_FLOAT, nullptr);
    // GL_LINEAR on a comparison sampler averages the four neighbouring
    // comparisons in hardware, so each of the shader's nine taps is really
    // four -- the cheapest softening there is.
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // Clamped, so a fragment just off the edge of the map reads the edge
    // rather than wrapping round to the far side of the scene. The shader
    // rejects those fragments anyway; this keeps the edge tidy if it ever
    // does not.
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE,
                    GL_COMPARE_R_TO_TEXTURE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
    glBindTexture(GL_TEXTURE_2D, 0);

    if (glGetError() != GL_NO_ERROR) {
      qWarning() << "shadows: the GL context will not give a"
                 << _size << "square depth texture";
      return false;
    }
  }

  if (_fbo == 0) {
    GLint prevFbo = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);

    f->glGenFramebuffers(1, &_fbo);
    f->glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    f->glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_TEXTURE_2D, _tex, 0);
    // Depth only: there is no colour attachment to write to, and saying so
    // here rather than per pass keeps it with the framebuffer's own state.
    glDrawBuffer(GL_NONE);
    glReadBuffer(GL_NONE);

    const GLenum status = f->glCheckFramebufferStatus(GL_FRAMEBUFFER);
    f->glBindFramebuffer(GL_FRAMEBUFFER, (GLuint)prevFbo);

    if (status != GL_FRAMEBUFFER_COMPLETE) {
      qWarning() << "shadows: depth-only framebuffer incomplete, status"
                 << Qt::hex << status;
      return false;
    }
  }

  if (_prog == nullptr) {
    _prog = new QOpenGLShaderProgram();
    if (!_prog->addShaderFromSourceCode(QOpenGLShader::Vertex, kVertexShader) ||
        !_prog->addShaderFromSourceCode(QOpenGLShader::Fragment,
                                        kFragmentShader) ||
        !_prog->link()) {
      qWarning().noquote() << "shadows: shader would not build:\n"
                           << _prog->log();
      return false;
    }
  }

  return true;
}

void ShadowMap::destroy() {
  // Without a current context these handles cannot be deleted, and they do not
  // need to be: the context that owned them took them with it.
  if (glCacheContext() != nullptr && glCacheContext() == _ctx &&
      glCacheEpoch() == _epoch) {
    if (_fbo != 0) {
      QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
      f->glDeleteFramebuffers(1, &_fbo);
    }
    if (_tex != 0) {
      glDeleteTextures(1, &_tex);
    }
  }
  _fbo = 0;
  _tex = 0;
  delete _prog;
  _prog = nullptr;
  _haveDepth = false;
}

bool ShadowMap::renderDepthBegin(const btVector4 &lightPos,
                                 const btVector3 &sceneCenter,
                                 double sceneRadius) {
  _haveDepth = false;

  if (sceneRadius <= 0.0 || !isAvailable())
    return false;

  // The light as a direction pointing from the scene towards it. w is the
  // homogeneous coordinate glLightfv(GL_POSITION) takes, so w of 0 means the
  // vector already is a direction.
  QVector3D dir;
  if (lightPos.w() == 0.0) {
    dir = QVector3D(lightPos.x(), lightPos.y(), lightPos.z());
  } else {
    dir = QVector3D(lightPos.x() / lightPos.w(), lightPos.y() / lightPos.w(),
                    lightPos.z() / lightPos.w()) -
          QVector3D(sceneCenter.x(), sceneCenter.y(), sceneCenter.z());
  }
  if (dir.lengthSquared() <= 0.0f)
    return false;
  dir.normalize();

  // Any up vector will do as long as it is not along the light; picking the
  // axis the light leans on least keeps the cross product well conditioned.
  QVector3D up(0.0f, 1.0f, 0.0f);
  if (qAbs(dir.y()) > 0.99f)
    up = QVector3D(0.0f, 0.0f, 1.0f);

  // A hair of slack around the bounding sphere, so a surface exactly on it
  // does not fall outside the map and light up.
  const float r = float(sceneRadius) * 1.02f;
  const QVector3D center(sceneCenter.x(), sceneCenter.y(), sceneCenter.z());
  const QVector3D eye = center + dir * (3.0f * r);

  QMatrix4x4 view;
  view.lookAt(eye, center, up);

  QMatrix4x4 proj;
  proj.ortho(-r, r, -r, r, 0.5f * r, 5.5f * r);

  // Clip space runs -1..1 in each axis and a texture lookup wants 0..1.
  QMatrix4x4 bias;
  bias.translate(0.5f, 0.5f, 0.5f);
  bias.scale(0.5f, 0.5f, 0.5f);

  _lightMatrix = bias * proj * view;

  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();

  glGetIntegerv(GL_VIEWPORT, _savedViewport);
  GLint prevFbo = 0;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
  _savedFbo = prevFbo;

  f->glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
  glViewport(0, 0, _size, _size);

  glMatrixMode(GL_PROJECTION);
  glPushMatrix();
  glLoadMatrixf(proj.constData());
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix();
  glLoadMatrixf(view.constData());

  // Before the clear, not after: a masked depth buffer does not clear.
  glDepthMask(GL_TRUE);
  glClear(GL_DEPTH_BUFFER_BIT);

  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);
  // Pushes each polygon's recorded depth away from the light by a little more
  // than its own slope, which is what stops a lit surface shadowing itself in
  // a moire of its own texels. Sloped surfaces need the slope term; the
  // constant covers the flat ones.
  glEnable(GL_POLYGON_OFFSET_FILL);
  glPolygonOffset(2.5f, 8.0f);
  // Nothing in the scene is drawn with back faces culled, and the geometry is
  // not all closed, so culling here would lose the shadow of anything
  // single-sided. The polygon offset above does the work instead.
  glDisable(GL_CULL_FACE);
  // The depth pass records nothing but depth, so none of this matters to it
  // and all of it costs.
  glDisable(GL_LIGHTING);
  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);
  glShadeModel(GL_FLAT);

  _haveDepth = true;
  return true;
}

void ShadowMap::renderDepthEnd() {
  glMatrixMode(GL_PROJECTION);
  glPopMatrix();
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix();

  glDisable(GL_POLYGON_OFFSET_FILL);
  glPolygonOffset(0.0f, 0.0f);
  glShadeModel(GL_SMOOTH);
  glEnable(GL_LIGHTING);

  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
  f->glBindFramebuffer(GL_FRAMEBUFFER, (GLuint)_savedFbo);
  glViewport(_savedViewport[0], _savedViewport[1], _savedViewport[2],
             _savedViewport[3]);
}

bool ShadowMap::bind(const double cameraModelView[16]) {
  // isAvailable() is the gate: on true it has rebuilt anything the context
  // lost, so _prog is good.
  if (!isAvailable())
    return false;

  // OpenGL's matrices are column-major, QMatrix4x4's subscript is (row,
  // column).
  QMatrix4x4 camera;
  for (int col = 0; col < 4; col++) {
    for (int row = 0; row < 4; row++) {
      camera(row, col) = float(cameraModelView[col * 4 + row]);
    }
  }

  if (!_prog->bind())
    return false;

  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
  // Bound whether or not this frame managed to fill it: uUseShadow below stops
  // the shader reading it, and an unbound comparison sampler is the kind of
  // thing a driver grumbles about.
  f->glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, _tex);
  f->glActiveTexture(GL_TEXTURE0);

  _prog->setUniformValue("uTexture", GLint(0));
  _prog->setUniformValue("uShadowMap", GLint(1));
  _prog->setUniformValue("uUseTexture", GLint(0));
  _prog->setUniformValue("uUseShadow", GLint(_haveDepth ? 1 : 0));
  _prog->setUniformValue("uDarkness", float(_darkness));
  _prog->setUniformValue("uTexelStep", float(_softness / _size));
  _prog->setUniformValue("uShadowMatrix", _lightMatrix * camera.inverted());

  s_boundProgram = _prog;
  return true;
}

void ShadowMap::release() {
  if (_prog == nullptr)
    return;

  s_boundProgram = nullptr;

  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
  f->glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, 0);
  f->glActiveTexture(GL_TEXTURE0);

  _prog->release();
}
