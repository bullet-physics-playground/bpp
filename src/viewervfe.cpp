/**
 * @file viewervfe.cpp
 * @brief The Viewer's embedded POV-Ray (USE_VFE): a quick render run in
 *        bpp, through POV-Ray's VFE, with its picture shown in the view as
 *        it comes; see the README. Without USE_VFE this file is empty, and
 *        QuickRender calls POV-Ray instead.
 */

#include "viewer.h"
#include "appenv.h"

#if USE_VFE
#include "povray/bppvfesession.h"
#include "povray/bppvfedisplay.h"

void Viewer::startVfeQuickRender(const QString &sceneName, const QString &sceneDir,
                                  const QStringList &args) {
  if (_vfeRenderActive) {
    emitScriptOutput("POV-Ray (VFE): cancelling current render to start a new one.");
    _vfePendingSceneName = sceneName;
    _vfePendingSceneDir = sceneDir;
    _vfePendingArgs = args;
    _vfeRestartPending = true;
    _vfeSession->CancelRender();
    return;
  }

  if (!_vfeSession) {
    _vfeSession.reset(new BppVfeSession());
    if (_vfeSession->Initialize(nullptr, nullptr) != vfe::vfeNoError) {
      emitScriptOutput(QString("POV-Ray (VFE) failed to initialize: %1")
                            .arg(_vfeSession->GetErrorString()));
      drainVfeMessages();
      _vfeSession.reset();
      return;
    }
    _vfeSession->SetDisplayCreator(
        [](unsigned int w, unsigned int h, vfe::vfeSession *s, bool visible) -> vfe::vfeDisplay * {
          return new BppVfeDisplay(w, h, s, visible);
        });
  }

  // StartRender() does not do this itself -- vfeSession::Clear() is
  // documented as the client's responsibility before each new render.
  // Without it, m_Failed/m_Succeeded/pixel counters carry over from
  // whatever the session's last render left them as (most visibly after a
  // cancelled render), so e.g. Failed() could still read true on this,
  // otherwise fully successful, render.
  _vfeSession->Clear();

  // Dropped, not acquired here: vfe creates the Display asynchronously on
  // its worker thread sometime after StartRender() returns, so there's
  // nothing to fetch yet. pollVfeRender() acquires it lazily once available.
  _vfeDisplay.reset();

  // Drop the previous render's preview texture so it doesn't linger on
  // screen (or, if this render is a different resolution, leave stale
  // glTexSubImage2D calls writing into a wrongly-sized texture) before the
  // new render's first pixels arrive. The actual GL deletion happens inside
  // drawVfePreview() -- see the comment on _vfePreviewNeedsReset in
  // viewer.h for why it can't happen here.
  _vfePreviewNeedsReset = true;

  vfe::vfeRenderOptions opts;

  // POV-Ray's own standard include library (colors.inc, textures.inc, etc)
  // isn't implicit for an embedded VFE session the way it is for a real
  // install (which resolves it via povray.conf/registry, none of which
  // exists here) -- add it explicitly. povray/distribution/include is the
  // sibling checkout's copy; this is a dev-tree assumption specific to this
  // prototype, not something that survives packaging.
  // POV-Ray's own standard include library (colors.inc, textures.inc, etc)
  // is not implicit for an embedded VFE session the way it is for a real
  // install. Try the obvious checkout-relative locations first, then walk
  // far enough up from the .app binary / launch directory to reach a
  // sibling povray/ checkout (bpp/release/bpp.app/Contents/MacOS needs
  // four levels up to land back at bpp/'s parent), and finally a few
  // install prefixes.
  QStringList vfeIncludeCandidates;
  vfeIncludeCandidates << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("povray-include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../povray-include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../povray/distribution/include")
                      << QDir(startupWorkingDir()).absoluteFilePath("../povray/distribution/include")
                      << QDir(startupWorkingDir()).absoluteFilePath("../povray/include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../../../povray/distribution/include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../../../povray/include")
                      << QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../../povray/distribution/include")
                      << "/opt/homebrew/share/povray-3.7/include"
                      << "/usr/local/share/povray-3.7/include"
                      << "/usr/share/povray-3.7/include"
                      << "/usr/share/povray/include"
                      << "/usr/share/bpp/includes";
  bool vfeIncludesAdded = false;
  for (const QString &candidate : vfeIncludeCandidates) {
    if (QDir(candidate).exists()) {
      opts.AddLibraryPath(QDir(candidate).absolutePath().toStdString());
      vfeIncludesAdded = true;
      break;
    }
  }
  Q_UNUSED(vfeIncludesAdded);

  // bpp's shipped include library (settings.inc, bpp_CIE.inc, etc.) is not
  // implicit in an embedded VFE session, so add every place it can live the
  // same way locateMeshFile/settingsIncPath do. Without this, a scene that
  // pulls in settings.inc/bpp_CIE.inc fails with "Cannot open include file".
  QStringList bppIncludeCandidates;
  QString appDir = QCoreApplication::applicationDirPath();
  bppIncludeCandidates << appDir + "/includes"
                      << appDir + "/../includes"
                      << appDir + "/../../includes"
                      << startupWorkingDir() + "/includes"
                      << "/Applications/bpp.app/Contents/includes"
                      << "/usr/local/share/bpp/includes"
                      << "/opt/homebrew/share/bpp/includes"
                      << "/usr/share/bpp/includes";
  for (const QString &dir : bppIncludeCandidates) {
    if (QDir(dir).exists())
      opts.AddLibraryPath(QDir(dir).absolutePath().toStdString());
  }

  // savePOV() writes a per-frame include (e.g. "00038.inc") alongside the
  // .pov file and the main .pov references it by bare relative name. The
  // real povray.exe finds it because QProcess::setWorkingDirectory(sceneDir)
  // makes sceneDir its CWD; POV-Ray does not otherwise search relative to
  // the directory of the file doing the including, so the embedded session
  // needs sceneDir added as a library path explicitly (verified: without
  // this, "Cannot open include file NNNNN.inc").
  opts.AddLibraryPath(sceneDir.toStdString());

  for (const QString &arg : args) {
    opts.AddCommand(arg.toStdString());
  }

  if (_vfeSession->SetOptions(opts) != vfe::vfeNoError) {
    emitScriptOutput(QString("POV-Ray (VFE) failed to set options: %1")
                          .arg(_vfeSession->GetErrorString()));
    drainVfeMessages();
    return;
  }

  _vfePreviewWidth = _vfeSession->GetRenderWidth();
  _vfePreviewHeight = _vfeSession->GetRenderHeight();

  if (_vfeSession->StartRender() != vfe::vfeNoError) {
    emitScriptOutput(QString("POV-Ray (VFE) failed to start render: %1")
                          .arg(_vfeSession->GetErrorString()));
    drainVfeMessages();
    return;
  }

  _vfeRenderActive = true;
  _vfePreviewVisible = true;

  if (!_vfePollTimer) {
    _vfePollTimer = new QTimer(this);
    _vfePollTimer->setInterval(33);
    connect(_vfePollTimer, &QTimer::timeout, this, &Viewer::pollVfeRender);
  }
  _vfePollTimer->start();
}

void Viewer::drainVfeMessages() {
  if (!_vfeSession) {
    return;
  }
  vfe::vfeSession::MessageType type;
  std::string msg;
  while (_vfeSession->GetNextCombinedMessage(type, msg)) {
    emitScriptOutput(QString::fromStdString(msg));
  }
}

void Viewer::pollVfeRender() {
  if (!_vfeSession) {
    _vfePollTimer->stop();
    return;
  }

  vfe::vfeStatusFlags flags = _vfeSession->GetStatus(true, 0);

  drainVfeMessages();

  // Lazily acquire the display once vfe has created it (see the comment in
  // startVfeQuickRender()). Once acquired, stop asking: GetDisplay() walks
  // vfe's internal view map with no locking of its own, so this is called
  // only until it first succeeds, not on every tick.
  if (_vfeRenderActive && _vfeDisplay.expired()) {
    _vfeDisplay = std::dynamic_pointer_cast<BppVfeDisplay>(_vfeSession->GetDisplay());
  }

  if (auto display = _vfeDisplay.lock()) {
    if (display->dirty()) {
      update();
    }
  }

  if (flags & vfe::stCriticalError) {
    emitScriptOutput("POV-Ray (VFE) hit a critical error; resetting session.");
    _vfeRestartPending = false; // a broken session isn't worth auto-retrying
    teardownVfeRender(true);
    update();
    return;
  }

  if (flags & vfe::stRenderShutdown) {
    _vfePollTimer->stop();
    _vfeRenderActive = false;
    if (_vfeSession->Failed()) {
      emitScriptOutput(QString("POV-Ray (VFE) render failed: %1")
                            .arg(_vfeSession->GetErrorString()));
    } else if (_vfeSession->OutputToFileSet()) {
      vfe::UCS2String outputFilename = _vfeSession->GetOutputFilename();
      emitScriptOutput(QString("POV-Ray (VFE): saved %1")
                            .arg(QString::fromUtf16(outputFilename.c_str(),
                                                     static_cast<int>(outputFilename.size()))));
    }
    update();

    if (_vfeRestartPending) {
      _vfeRestartPending = false;
      startVfeQuickRender(_vfePendingSceneName, _vfePendingSceneDir, _vfePendingArgs);
    }
  }
}

void Viewer::drawVfePreview() {
  // Deferred from startVfeQuickRender() -- see the comment on
  // _vfePreviewNeedsReset in viewer.h. postDraw() (our only caller) always
  // runs within a current GL context, unlike the keypress handler that set
  // this flag.
  if (_vfePreviewNeedsReset) {
    if (_vfePreviewTexture) {
      glDeleteTextures(1, &_vfePreviewTexture);
      _vfePreviewTexture = 0;
    }
    _vfePreviewNeedsReset = false;
  }

  // display is null once vfe has torn the render down (see the comment on
  // _vfeDisplay in viewer.h) -- that's expected after completion, not an
  // error: _vfePreviewTexture already holds the last frame, so there's
  // nothing left to pull, just keep showing what's on the GPU already.
  auto display = _vfeDisplay.lock();
  if (!display && !_vfePreviewTexture) {
    return;
  }
  if (_vfePreviewWidth <= 0 || _vfePreviewHeight <= 0) {
    return;
  }

  if (!_vfePreviewTexture) {
    // A null data pointer allocates storage without defining its content
    // (implementation-defined, not guaranteed black), which would show
    // whatever garbage happened to be in that GPU memory for the first
    // few frames; zero-fill explicitly so a fresh render starts blank.
    QByteArray blank(_vfePreviewWidth * _vfePreviewHeight * 4, '\0');
    glGenTextures(1, &_vfePreviewTexture);
    glBindTexture(GL_TEXTURE_2D, _vfePreviewTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _vfePreviewWidth, _vfePreviewHeight, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, blank.constData());
  } else {
    glBindTexture(GL_TEXTURE_2D, _vfePreviewTexture);
  }

  if (display && display->dirty()) {
    QImage snap = display->snapshot();
    if (snap.width() == _vfePreviewWidth && snap.height() == _vfePreviewHeight) {
      glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, snap.width(), snap.height(),
                       GL_RGBA, GL_UNSIGNED_BYTE, snap.constBits());
    }
  }

  startScreenCoordinatesSystem();
  glDisable(GL_LIGHTING);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_TEXTURE_2D);
  glColor3f(1.0, 1.0, 1.0);

  glBegin(GL_QUADS);
  glTexCoord2f(0.0f, 0.0f);
  glVertex2i(0, 0);
  glTexCoord2f(1.0f, 0.0f);
  glVertex2i(width(), 0);
  glTexCoord2f(1.0f, 1.0f);
  glVertex2i(width(), height());
  glTexCoord2f(0.0f, 1.0f);
  glVertex2i(0, height());
  glEnd();

  glDisable(GL_TEXTURE_2D);
  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);
  stopScreenCoordinatesSystem();
}

void Viewer::teardownVfeRender(bool shutdownSession) {
  if (_vfePollTimer) {
    _vfePollTimer->stop();
  }
  _vfeRenderActive = false;
  if (shutdownSession && _vfeSession) {
    _vfeSession->Shutdown();
    _vfeSession.reset();
    _vfeDisplay.reset();
  }
}

#endif // USE_VFE
