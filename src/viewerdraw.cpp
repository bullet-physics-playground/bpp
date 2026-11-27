/**
 * @file viewerdraw.cpp
 * @brief How the Viewer draws its scene: init, draw, postDraw (the status
 *        dots), the passes (objects, shadow depth, constraints, culling,
 *        screen merging), and the settings scripts change them with
 *        (shadows, culling, v.showConstraints, the GL lights and
 *        materials).
 */

#include "viewer.h"
#include "lightpreview.h"
#include "viewer_p.h"

#include "constraintdraw.h"
#include "culling.h"
#include "glutils.h"
#include "shadowmap.h"
#include "objects/layer.h"
#include "objects/softbody.h"

#include <BulletSoftBody/btSoftRigidDynamicsWorld.h>

void Viewer::setShowConstraints(bool on) {
  // No mutex here (unlike the input-event setters above): Viewer::parse()
  // already holds `mutex` for a script's entire run, so a script setting
  // v.showConstraints at top level -- the natural place to do it -- would
  // deadlock against itself on a plain (non-recursive) QMutex. _showConstraints
  // is a single bool only ever read from the render thread in
  // drawConstraints(), same as the unlocked setTau/setErp/setCfm above.
  _showConstraints = on;
}

bool Viewer::showConstraints() const { return _showConstraints; }

// Shadows are a render-path setting a script will normally choose at top
// level, so like setShowConstraints() above these take no mutex: see the note
// there. _shadowMap exists from the constructor on, and only reaches for GL
// resources on the render thread, in renderShadowDepth() and
// drawSceneInternal().
void Viewer::setShadows(bool on) {
  if (_shadows == on)
    return;
  _shadows = on;
  emit shadowsChanged(on);
}

void Viewer::setShadowsPreference(bool on) {
  _shadowsPref = on;
  setShadows(on);
}

bool Viewer::shadowsPreference() const { return _shadowsPref; }

void Viewer::setShadowsFromScript(bool on) {
  if (on == _shadowsPref || _shadowsNoted)
    return;
  _shadowsNoted = true;
  const QString note =
      QString("(this script asked for shadows %1; your setting -- %2 -- is "
              "kept: View > Shadows. To keep one object out of the shadows, "
              "set its obj.castShadow = false)")
          .arg(on ? "on" : "off", _shadowsPref ? "on" : "off");
  // (headless, on stderr: a run's own output stays exactly what it was)
  if (isHeadless())
    fprintf(stderr, "%s\n", note.toUtf8().constData());
  else
    emitScriptOutput(note);
}

bool Viewer::shadows() const { return _shadows; }

void Viewer::setCulling(bool on) { _culling = on; }

bool Viewer::culling() const { return _culling; }

int Viewer::drawnObjects() const { return _drawnObjects; }

int Viewer::shadowCasters() const { return _shadowCasters; }

void Viewer::setShadowCache(bool on) { _shadowRecord.enabled = on; }

bool Viewer::shadowCache() const { return _shadowRecord.enabled; }

int Viewer::shadowCached() const { return _shadowRecord.cached(); }


void Viewer::setShadowSaved(bool on) { _shadowRecord.saveDepth = on; }

bool Viewer::shadowSaved() const { return _shadowRecord.saveDepth; }

bool Viewer::shadowFromSaved() const { return _shadowRecord.fromSaved(); }

void Viewer::setShadowMapSize(int px) { _shadowMap->setMapSize(px); }

int Viewer::shadowMapSize() const { return _shadowMap->mapSize(); }

void Viewer::setShadowSoftness(btScalar texels) {
  _shadowMap->setSoftness(texels);
}

btScalar Viewer::shadowSoftness() const {
  return btScalar(_shadowMap->softness());
}

void Viewer::setShadowDarkness(btScalar d) { _shadowMap->setDarkness(d); }

btScalar Viewer::shadowDarkness() const {
  return btScalar(_shadowMap->darkness());
}

void Viewer::init() {
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);

  computeBoundingBox();

  showEntireScene();
  _cameraPlaced = true;

  // Matches the POV-Ray light_source <500,500,-500> in includes/settings.inc.
  // POV-Ray is left-handed, OpenGL is right-handed, so Z is negated (see
  // Object::povMatrixFromGL()).
  _light0 = btVector4(500.0, 500.0, 500.0, 0.4);
  _light1 = btVector4(-200.0, 100.0, 200.0, 0.2);
  _light0Color = _light1Color = btVector4(1, 1, 1, 1);

  _gl_ambient = btVector3(0.2f, 0.2f, 0.2f);
  _gl_diffuse = btVector4(0.7f, 0.7f, 0.7f, 1.0f);
  _gl_specular = btVector4(1.0f, 1.0f, 1.0f, 1.0f);
  _gl_shininess = btScalar(100.0);
  _gl_specular_col = btVector4(1.0f, 1.0f, 1.0f, 1.0f);

  _gl_model_ambient = btVector4(0.2f, 0.2f, 0.2f, 1.0f);

  _initialCameraPosition = camera()->position();
  _initialCameraOrientation = camera()->orientation();
  _initialCameraHorizontalFieldOfView = camera()->horizontalFieldOfView();
  _initialCameraUpVector = camera()->upVector();

  // Turntable orbit: keep the camera aligned with the horizon during mouse
  // orbit (QGLViewer's "rotates around the up vector" mode).  Rotation is a
  // yaw around the scene up vector plus a pitch around the camera's right
  // axis, so the camera never rolls.  This only affects the mouse ROTATE
  // action; the SpaceNavigator keeps its own navigation paths.
  camera()->frame()->setRotatesAroundUpVector(true);
  camera()->frame()->setSceneUpVector(_initialCameraUpVector);
}

// A fixed-function light back as GL starts it: no cone, no fall-off.
void Viewer::lightPlain(GLenum light) {
  const GLfloat down[3] = {0.0f, 0.0f, -1.0f};
  glLightf(light, GL_SPOT_CUTOFF, 180.0f);
  glLightf(light, GL_SPOT_EXPONENT, 0.0f);
  glLightfv(light, GL_SPOT_DIRECTION, down);
  glLightf(light, GL_CONSTANT_ATTENUATION, 1.0f);
  glLightf(light, GL_LINEAR_ATTENUATION, 0.0f);
  glLightf(light, GL_QUADRATIC_ATTENUATION, 0.0f);
}

// The script's lights (v:add): the 8 lighting the camera most, as GL's
// lights 0 to 7, in that order (the shadow map's shader reads them the
// same way), and the strongest not shadowless casts the shadow
// (lightpreview.h). Called with the camera's matrices loaded, so the
// positions and directions are the world's.
void Viewer::useScriptLights() {
  _shadowFrom = nullptr;
  std::vector<const Light *> all;
  for (const auto &kept : _lights)
    all.push_back(kept.first);
  const qglviewer::Vec e = camera()->position();
  int shadow = -1;
  const Light *preferred = nullptr;
  if (_shadowChoice.is_valid())
    if (boost::optional<Light *> c = luabind::object_cast_nothrow<Light *>(_shadowChoice))
      preferred = *c;
  const std::vector<const Light *> shown =
      LightPreview::pick(all, btVector3(e.x, e.y, e.z), 8, shadow, preferred);

  const GLfloat none[4] = {0.0f, 0.0f, 0.0f, 1.0f};
  QVector4D shapes[8];
  for (int i = 0; i < 8; ++i) {
    const GLenum light = GL_LIGHT0 + i;
    LightPreview::GL g;
    if (i >= (int)shown.size() || !LightPreview::toGL(*shown[i], g)) {
      glDisable(light);
      continue;
    }
    glLightfv(light, GL_AMBIENT, none);
    glLightfv(light, GL_DIFFUSE, g.diffuse);
    glLightfv(light, GL_SPECULAR, g.specular);
    shapes[i] = QVector4D(g.shape[0], g.shape[1], g.shape[2], g.shape[3]);
    glLightfv(light, GL_POSITION, g.position);
    glLightfv(light, GL_SPOT_DIRECTION, g.spotDirection);
    glLightf(light, GL_SPOT_CUTOFF, g.spotCutoff);
    glLightf(light, GL_SPOT_EXPONENT, g.spotExponent);
    glLightf(light, GL_CONSTANT_ATTENUATION, g.constant);
    glLightf(light, GL_LINEAR_ATTENUATION, g.linear);
    glLightf(light, GL_QUADRATIC_ATTENUATION, g.quadratic);
    glEnable(light);
    if (i == shadow) {
      _shadowLight = btVector4(g.position[0], g.position[1], g.position[2], g.position[3]);
      // (a cylinder's shadow falls along its beam)
      if (LightPreview::shownKind(*shown[i]) == Light::Cylinder)
        _shadowLight = btVector4(-g.spotDirection[0], -g.spotDirection[1], -g.spotDirection[2], 0);
      _shadowFrom = shown[i];
    }
  }
  _shadowMap->setLights((int)shown.size(), _shadows ? shadow : -1, shapes);   // (drawn by the shader either way)
}

void Viewer::draw() {
  if (_frameTimingMs > 0)
    frameMark(FM_PAINT);
  _stepsSinceDraw = 0;
  _lastDrawNs = _wallTimer.nsecsElapsed();

  if (!mutex.tryLock())
    return;

  if (_parsing || !isVisible()) {
    mutex.unlock();
    return;
  }

  // (preDraw ran in animate(), once a frame, as without a window)
  _decorations.update();                // (the decorations to their parents: before anything reads places)

  QElapsedTimer dtAll;                  // (the drawing timer: all of draw())
  if (_drawTiming && !_quad.on())
    dtAll.start();
  _lf = LastFrame();

  computeBoundingBox();
  if (dtAll.isValid()) {
    _lf.box = dtAll.nsecsElapsed() / 1.0e6;
    _dtBox += _lf.box;
  }

  GLfloat light_ambient[] = {_gl_ambient.x(), _gl_ambient.y(), _gl_ambient.z()};
  GLfloat light_diffuse[] = {_gl_diffuse.x(), _gl_diffuse.y(), _gl_diffuse.z()};
  GLfloat light_specular[] = {_gl_specular.x(), _gl_specular.y(),
                              _gl_specular.z()};

  // light_position is NOT default value
  GLfloat light_position0[] = {_light0.x(), _light0.y(), _light0.z(),
                               _light0.w()};
  GLfloat light_position1[] = {_light1.x(), _light1.y(), _light1.z(),
                               _light1.w()};

  // (each light's own colour, see setGLLight0Color())
  GLfloat light_diffuse0[4], light_specular0[4];
  GLfloat light_diffuse1[4], light_specular1[4];
  for (int i = 0; i < 3; ++i) {
    light_diffuse0[i] = light_diffuse[i] * _light0Color[i];
    light_specular0[i] = light_specular[i] * _light0Color[i];
    light_diffuse1[i] = light_diffuse[i] * _light1Color[i];
    light_specular1[i] = light_specular[i] * _light1Color[i];
  }
  light_diffuse0[3] = light_specular0[3] = 1.0f;
  light_diffuse1[3] = light_specular1[3] = 1.0f;

  // The ambient light: with the two lights, each one's (v.glAmbient) and the
  // model's (v.glModelAmbient); with the script's own lights, the same total
  // on the model alone, standing in for the light radiosity bounces round.
  GLfloat model_ambient[4] = {_gl_model_ambient.x(), _gl_model_ambient.y(),
                              _gl_model_ambient.z(), _gl_model_ambient.w()};

  if (_lights.empty()) {
  glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse0);
  glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular0);
  glLightfv(GL_LIGHT0, GL_POSITION, light_position0);

  glLightfv(GL_LIGHT1, GL_AMBIENT, light_ambient);
  glLightfv(GL_LIGHT1, GL_DIFFUSE, light_diffuse1);
  glLightfv(GL_LIGHT1, GL_SPECULAR, light_specular1);
  glLightfv(GL_LIGHT1, GL_POSITION, light_position1);

  for (int i = 0; i < 2; ++i)             // (as GL starts: a script with lights may have changed them)
    lightPlain(GL_LIGHT0 + i);
  for (int i = 2; i < 8; ++i)
    glDisable(GL_LIGHT0 + i);
  _shadowLight = _light0;
  _shadowFrom = nullptr;
  _shadowMap->setLights(2, 0, nullptr);

  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHT1);
  } else {
    for (int i = 0; i < 3; ++i)
      model_ambient[i] += 2 * light_ambient[i];
    useScriptLights();
    glEnable(GL_LIGHTING);
  }

  glEnable(GL_COLOR_MATERIAL);
  glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);

  glShadeModel(GL_SMOOTH);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);

  glClearColor(btScalar(0), btScalar(0), btScalar(0), btScalar(1.0));

  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, model_ambient);

  glMaterialfv(GL_FRONT, GL_AMBIENT, _gl_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, _gl_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, _gl_specular);
  glMaterialf(GL_FRONT, GL_SHININESS, _gl_shininess);
  // (nothing glows but what says so: see Object::setEmission())
  const GLfloat noEmission[] = {0.0f, 0.0f, 0.0f, 1.0f};
  glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, noEmission);

  // (the drawing timer, when it's on: see setDrawTiming())
  QElapsedTimer dt;
  const bool timing = _drawTiming && !_quad.on();
  if (timing) {
    dtGpuCollect();
    dt.start();
  }

  {                                      // (see setScreenMerge())
    const ScreenMerge::Counts mc = _merge.update(*_objects);
    _lf.batches += mc.batches;
    _lf.recoloured += mc.recoloured;
    _lf.blanked += mc.blanked;
  }
  const qint64 tMerge = timing ? dt.nsecsElapsed() : 0;

  // What this frame can skip (see setCulling()), while the camera's own
  // matrices are loaded.
  cullObjects();
  qint64 tCull = timing ? dt.nsecsElapsed() : 0;

  // Fill the shadow map before anything is drawn for the screen: it needs the
  // camera's own matrices to be the ones currently loaded, and the whole scene
  // casts into one map that every quad-view pane then shares.
  if (timing)
    dtGpuBegin(0);
  renderShadowDepth();
  if (timing)
    dtGpuEnd();
  qint64 tShadow = timing ? dt.nsecsElapsed() : 0;

  if (_quad.on()) {
    _quad.draw([this](int i) { drawSceneInternal(i); });
    mutex.unlock();
    return;
  }

  if (manipulatedFrame() != nullptr) {
    glPushMatrix();
    glMultMatrixd(manipulatedFrame()->matrix());
  }

  glDisable(GL_CULL_FACE);
  if (timing)
    dtGpuBegin(1);
  drawSceneInternal(0);
  if (timing) {
    dtGpuEnd();
    if (!_dtNoGpu && _dtQueries[_dtSlot][0] != 0 && _dtQueries[_dtSlot][1] != 0)
      _dtPending[_dtSlot] = true;
    _dtSlot = (_dtSlot + 1) % 4;
    const qint64 tScreen = dt.nsecsElapsed();
    _dtCull += tCull / 1.0e6;
    _dtShadow += (tShadow - tCull) / 1.0e6;
    _dtScreen += (tScreen - tShadow) / 1.0e6;
    _lf.merge = tMerge / 1.0e6;
    _lf.cull = (tCull - tMerge) / 1.0e6;
    _lf.shadow = (tShadow - tCull) / 1.0e6;
    _lf.screen = (tScreen - tShadow) / 1.0e6;
  }

  if (manipulatedFrame() != nullptr) {
    glPopMatrix();
  }

  if (_snCamera->showOrbitAxis) {
    // Visualize the orbit/rotation centre as a small world-axis marker.
    qreal orbitDist = _snCamera->orbitDist;
    if (orbitDist <= 0.0) {
      orbitDist = (camera()->pivotPoint() - camera()->position()).norm();
    }
    if (orbitDist <= 0.0) {
      orbitDist = camera()->sceneRadius();
    }
    const qglviewer::Vec pivot =
        camera()->position() + camera()->viewDirection() * orbitDist;

    glPushMatrix();
    glTranslatef(pivot.x, pivot.y, pivot.z);
    QGLViewer::drawAxis(qMax(qreal(0.05), camera()->sceneRadius() * 0.1));
    glPopMatrix();
    glEnable(GL_LIGHTING);
  }

  if (dtAll.isValid()) {
    _lf.all = dtAll.nsecsElapsed() / 1.0e6;
    _dtDraw += _lf.all;
    ++_dtFrames;
    _lfDone = _lf;
  }

  mutex.unlock();
}

// The screen's merge (see setScreenMerge()).

void Viewer::setScreenMerge(bool on) { _merge.enabled = on; }

bool Viewer::screenMerge() const { return _merge.enabled; }

int Viewer::screenMerged() const { return _merge.drawn(); }

void Viewer::drawSceneInternal(int pass) {
  Q_UNUSED(pass)

  // The shader needs to get from the eye space it works in back out to the
  // light's, which takes the inverse of the camera's view matrix - and that is
  // exactly what is loaded right now, before any object pushes its own
  // transform on top.
  //
  // The script's own lights are drawn by the shader with shadows off too:
  // the fixed-function pipeline lights each corner and blends between them,
  // and a spot's pool or a lamp's fall-off across a floor of four corners
  // vanishes (the shader lights each pixel). Then shadows on and off differ
  // only by the shadow.
  bool shaded = false;
  if (_shadows || !_lights.empty()) {
    GLdouble camModelView[16];
    glGetDoublev(GL_MODELVIEW_MATRIX, camModelView);
    shaded = _shadowMap->bind(camModelView);
  }

  _merge.draw(_culled);
  drawObjects();

  if (shaded) {
    // Released before the constraint markers, which are flat unlit lines and
    // crosses and have no business being shaded.
    _shadowMap->release();
  }

  drawConstraints();
  drawLights();
}

void Viewer::drawObjects(bool shadowPass, bool skipFixed) {
  // btScalar m[16];
  btMatrix3x3 rot;
  rot.setIdentity();

  btVector3 minaabb(0, 0, 0), maxaabb(0, 0, 0);
  dynamicsWorld->getBroadphase()->getBroadphaseAabb(minaabb, maxaabb);

  //    minaabb-=btVector3(BT_LARGE_FLOAT,BT_LARGE_FLOAT,BT_LARGE_FLOAT);
  //    maxaabb+=btVector3(BT_LARGE_FLOAT,BT_LARGE_FLOAT,BT_LARGE_FLOAT);

  // For the screen, what can be seen through is drawn after everything else
  // (in the order it comes in), so whatever is behind it is there to be seen
  // through it; drawn before, what came after would paint over it.
  QVector<Object *> seeThrough;
  auto drawOne = [&](Object *o) {
    ++(shadowPass ? _shadowCasters : _drawnObjects);
    // SoftBody has no rigid body/motion-state, so Object::render() (which
    // requires one) would silently skip it. Render it directly instead.
    // (an object of a world drawn elsewhere: moved there)
    if (o->placed) {
      btScalar pm[16];
      o->place.getOpenGLMatrix(pm);
      glPushMatrix();
      glMultMatrixf(pm);
    }
    SoftBody *sb = dynamic_cast<SoftBody *>(o);
    if (sb != nullptr) {
      sb->renderWorld();
    } else {
      o->render(minaabb, maxaabb);
    }
    if (o->placed)
      glPopMatrix();
  };
  foreach (Object *o, *_objects) {
    // (what cullObjects() decided for this frame)
    if (_culled && !(shadowPass ? o->drawInShadow : o->drawOnScreen))
      continue;
    if (shadowPass && !o->getCastShadow())  // (see Object::setCastShadow())
      continue;
    if (skipFixed && o->shadowListed)
      continue;
    if (!shadowPass && o->mergeDrawn && _merge.ready())  // (drawn by _merge.draw())
      continue;
    // Layer visibility: skip objects on hidden layers
    if (!shadowPass && o->layer() && !o->layer()->isVisible())
      continue;
    if (!shadowPass && o->getTransparency() > 0.0) {
      seeThrough.append(o);
      continue;
    }
    drawOne(o);
  }
  for (Object *o : seeThrough)
    drawOne(o);
}

void Viewer::cullObjects() {
  _drawnObjects = 0;
  _shadowCasters = 0;
  _culled = _culling && !_quad.on() && manipulatedFrame() == nullptr;
  if (!_culled)
    return;

  const qglviewer::Vec c = camera()->sceneCenter();
  LightPreview::ShadowView sv;
  const bool radial = _shadowFrom != nullptr &&
      LightPreview::shadowView(*_shadowFrom, btVector3(c.x, c.y, c.z), camera()->sceneRadius(), sv);
  Culling::cull(*_objects, camera(), _shadows, _shadowLight, _shadowMap, radial);
}

void Viewer::renderShadowDepth() {
  if (!_shadows || !_shadowMap->hasShadowLight())   // (every light shadowless)
    return;

  const qglviewer::Vec c = camera()->sceneCenter();

  // (a script's lamp casts from where it is; v.glLight0, a cylinder or a
  // parallel light along one direction)
  LightPreview::ShadowView sv;
  const bool radial = _shadowFrom != nullptr &&
      LightPreview::shadowView(*_shadowFrom, btVector3(c.x, c.y, c.z), camera()->sceneRadius(), sv);
  const bool begun = radial
      ? _shadowMap->renderDepthBeginFrom(sv.eye, sv.look, sv.fov, sv.nearZ, sv.farZ)
      : _shadowMap->renderDepthBegin(_shadowLight, btVector3(c.x, c.y, c.z), camera()->sceneRadius());
  if (!begun)
    return;

  // Only the objects: a constraint marker is a hint about the scene, not part
  // of it, and should not throw a shadow across it. Anything a script draws
  // from an object's own render callback does cast, since that runs from
  // Object::render(). The fixed objects that have stayed put come from the
  // record (see ShadowRecord); the rest are drawn one by one.
  ShadowRecord::Counts rc;                // (see setShadowCache())
  const bool skipFixed =
      _shadowRecord.fill(*_objects, _shadowMap, dynamicsWorld->getBroadphase(), _culled, rc);
  _lf.recorded += rc.recorded;
  if (rc.depthSaved)
    _lf.depthSaved = true;
  drawObjects(true, skipFixed);

  _shadowMap->renderDepthEnd();
}

// The markers of the script's lights (v.showLights): a star where each is,
// in its colour, and its shape -- a spot's cone to its falloff, a
// cylinder's beam at its true width, a parallel light's arrow, an area
// light's rectangle (or circle) -- sized to the scene, as unlit lines.
void Viewer::drawLights() {
  if (!_showLights || _lights.empty())
    return;

  const btScalar s = btScalar(0.03 * camera()->sceneRadius());
  const int N = 24;
  // a circle of radius r around c, square to n
  auto circle = [N](const btVector3 &c, const btVector3 &n, btScalar r) {
    btVector3 u, w;
    btPlaneSpace1(n.normalized(), u, w);
    glBegin(GL_LINE_LOOP);
    for (int k = 0; k < N; ++k) {
      const btScalar a = btScalar(2 * M_PI * k / N);
      const btVector3 p = c + (u * btCos(a) + w * btSin(a)) * r;
      glVertex3f(p.x(), p.y(), p.z());
    }
    glEnd();
  };
  auto line = [](const btVector3 &a, const btVector3 &b) {
    glVertex3f(a.x(), a.y(), a.z());
    glVertex3f(b.x(), b.y(), b.z());
  };

  glPushAttrib(GL_ENABLE_BIT | GL_CURRENT_BIT | GL_LINE_BIT);
  glDisable(GL_LIGHTING);
  glDisable(GL_TEXTURE_2D);
  glEnable(GL_DEPTH_TEST);
  glLineWidth(1.5f);
  for (const auto &kept : _lights) {
    const Light &l = *kept.first;
    glColor3f(l.col.redF(), l.col.greenF(), l.col.blueF());
    const btVector3 &p = l.pos;
    btVector3 dir = l.point_at - l.pos;
    if (dir.length2() > 0)
      dir.normalize();
    else
      dir = btVector3(0, -1, 0);

    glBegin(GL_LINES);
    line(p - btVector3(s, 0, 0), p + btVector3(s, 0, 0));
    line(p - btVector3(0, s, 0), p + btVector3(0, s, 0));
    line(p - btVector3(0, 0, s), p + btVector3(0, 0, s));
    glEnd();

    // (what POV-Ray renders: a shadowless spot is a point light, a
    // shadowless cylinder a parallel one; lightpreview.h)
    switch (LightPreview::shownKind(l)) {
    case Light::Spot: {
      const btScalar len = 3 * s;
      const btScalar r = len * btTan(btRadians(btScalar(std::min(80.0, l.falloff))));
      btVector3 u, w;
      btPlaneSpace1(dir, u, w);
      glBegin(GL_LINES);
      for (const btVector3 &e : {u, -u, w, -w})
        line(p, p + dir * len + e * r);
      glEnd();
      circle(p + dir * len, dir, r);
      break;
    }
    case Light::Cylinder: {
      const btScalar len = 3 * s;
      const btScalar r = btScalar(l.falloff);
      btVector3 u, w;
      btPlaneSpace1(dir, u, w);
      glBegin(GL_LINES);
      for (const btVector3 &e : {u, -u, w, -w})
        line(p + e * r, p + dir * len + e * r);
      glEnd();
      circle(p, dir, r);
      circle(p + dir * len, dir, r);
      break;
    }
    case Light::Parallel: {
      const btVector3 tip = p + dir * (3 * s);
      btVector3 u, w;
      btPlaneSpace1(dir, u, w);
      glBegin(GL_LINES);
      line(p, tip);
      line(tip, tip - dir * s + u * (s / 2));
      line(tip, tip - dir * s - u * (s / 2));
      glEnd();
      break;
    }
    case Light::Point:
    case Light::Area:
      break;
    }

    if (l.n1 > 0 && l.n2 > 0) {                 // (any kind can be an area light)
      const btVector3 a = l.axis1 / 2, b = l.axis2 / 2;
      if (l.circular && a.cross(b).length2() > 0) {
        circle(p, a.cross(b), (a.length() + b.length()) / 2);
      } else {
        glBegin(GL_LINE_LOOP);
        for (const btVector3 &q : {p - a - b, p + a - b, p + a + b, p - a + b})
          glVertex3f(q.x(), q.y(), q.z());
        glEnd();
      }
    }
  }
  glPopAttrib();
}

// Renders every constraint via btDynamicsWorld::debugDrawConstraint(),
// which dispatches on the constraint's own type (hinge, point2point,
// slider, cone-twist, 6dof, gear, ...).
void Viewer::drawConstraints() {
  if (!_showConstraints)
    return;

  glEnable(GL_DEPTH_TEST);

  // Size each constraint's markers relative to the parts it connects
  // instead of the whole scene's AABB - a single far-away or oversized
  // object (a ground plane, a long road, ...) would otherwise blow up
  // every marker's size, even for small constraints elsewhere.
  foreach (btTypedConstraint *c, *_constraints) {
    // (one in a world drawn elsewhere: moved there)
    const int k = _conWorld.value(c, 0);
    const bool placed = k > 0 && k < (int)_worlds.size() && _worlds[k].placed;
    if (placed) {
      btScalar pm[16];
      _worlds[k].place.getOpenGLMatrix(pm);
      glPushMatrix();
      glMultMatrixf(pm);
    }
    ConstraintDraw::draw(c, ConstraintDraw::size(c));
    if (placed)
      glPopMatrix();
  }
}

void Viewer::postDraw() {
  if (_parsing)
    return QGLViewer::postDraw();

  if (_cb_postDraw) {
    try {
      luabind::call_function<void>(_cb_postDraw, _frameNum);
    } catch (const std::exception &e) {
      showLuaException(e, "postDraw()");
    }
  }

  // Red dot when EventRecorder is active

  if (animationIsStarted()) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(1.0, 0.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 20, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
  }

  if (_simulate) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 40, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
  }

  if (_savePOV) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 1.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 80, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
  }

  if (_deactivation) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(1.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width() - 100, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
  }

#if USE_VFE
  if (_vfePreviewVisible && (_vfeRenderActive || _vfePreviewTexture)) {
    drawVfePreview();
  }
#endif // USE_VFE

  if (_frameTimingMs > 0)
    frameMark(FM_AFTER_PAINT);
}

void Viewer::setGLShininess(const btScalar &s) { _gl_shininess = s; }

btScalar Viewer::getGLShininess() const { return _gl_shininess; }

void Viewer::setGLSpecularColor(const btVector4 &col) {
  _gl_specular_col = col;
}

btVector4 Viewer::getGLSpecularColor() const { return _gl_specular_col; }

void Viewer::setGLSpecularCol(const btScalar col) {
  _gl_specular_col = btVector4(col, col, col, col);
}

btScalar Viewer::getGLSpecularCol() const { return _gl_specular_col.length(); }

void Viewer::setGLLight0(const btVector4 &pos) { _light0 = pos; }

btVector4 Viewer::getGLLight0() const { return _light0; }

void Viewer::setGLLight1(const btVector4 &pos) { _light1 = pos; }

btVector4 Viewer::getGLLight1() const { return _light1; }

void Viewer::setGLLight0Color(const btVector4 &col) { _light0Color = col; }

btVector4 Viewer::getGLLight0Color() const { return _light0Color; }

void Viewer::setGLLight1Color(const btVector4 &col) { _light1Color = col; }

btVector4 Viewer::getGLLight1Color() const { return _light1Color; }

// Vector

void Viewer::setGLAmbient(const btVector3 &am) { _gl_ambient = am; }

btVector3 Viewer::getGLAmbient() const { return _gl_ambient; }

void Viewer::setGLDiffuse(const btVector4 &col) { _gl_diffuse = col; }

btVector4 Viewer::getGLDiffuse() const { return _gl_diffuse; }

void Viewer::setGLSpecular(const btVector4 &col) { _gl_specular = col; }

btVector4 Viewer::getGLSpecular() const { return _gl_specular; }

void Viewer::setGLModelAmbient(const btVector4 &am) { _gl_model_ambient = am; }

btVector4 Viewer::getGLModelAmbient() const { return _gl_model_ambient; }

// Percent

void Viewer::setGLAmbientPercent(const btScalar am) {
  _gl_ambient = btVector3(am, am, am);
}

btScalar Viewer::getGLAmbientPercent() const {
  return (_gl_ambient.x() + _gl_ambient.y() + _gl_ambient.z()) / 3;
}

void Viewer::setGLDiffusePercent(const btScalar col) {
  _gl_diffuse = btVector4(col, col, col, 1);
}

btScalar Viewer::getGLDiffusePercent() const { return _gl_diffuse.length(); }

void Viewer::setGLSpecularPercent(const btScalar col) {
  _gl_specular = btVector4(col, col, col, 1);
}

btScalar Viewer::getGLSpecularPercent() const { return _gl_specular.length(); }

void Viewer::setGLModelAmbientPercent(const btScalar am) {
  _gl_model_ambient = btVector4(am, am, am, 1);
}

btScalar Viewer::getGLModelAmbientPercent() const {
  return (_gl_model_ambient.x() + _gl_model_ambient.y() +
          _gl_model_ambient.z()) / 3;
}
