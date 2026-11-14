/**
 * @file viewertiming.cpp
 * @brief The Viewer's timers, for finding where time goes: the drawing
 *        timer (v.drawTiming, v:drawTimingReport(), v:lastFrameDrawing())
 *        and frame timing (BPP_FRAME_TIMING, v.frameTiming).
 */

#include "viewer.h"
#include "glutils.h"

#include <QAbstractEventDispatcher>
#include <QMetaEnum>
#include <QOpenGLContext>

// The drawing timer. The graphics card's times come from timer queries
// (GL_TIME_ELAPSED, OpenGL 3.3 or ARB_timer_query), looked up by name so a
// context without them simply has none.
namespace {
typedef void(QOPENGLF_APIENTRYP DtGenQueries)(GLsizei, GLuint *);
typedef void(QOPENGLF_APIENTRYP DtBeginQuery)(GLenum, GLuint);
typedef void(QOPENGLF_APIENTRYP DtEndQuery)(GLenum);
typedef void(QOPENGLF_APIENTRYP DtGetQueryObjectuiv)(GLuint, GLenum, GLuint *);
const GLenum DT_TIME_ELAPSED = 0x88BF;
const GLenum DT_QUERY_RESULT = 0x8866;
const GLenum DT_QUERY_RESULT_AVAILABLE = 0x8867;
DtGenQueries dtGen = nullptr;
DtBeginQuery dtBegin = nullptr;
DtEndQuery dtEnd = nullptr;
DtGetQueryObjectuiv dtGet = nullptr;
} // namespace

void Viewer::setDrawTiming(bool on) { _drawTiming = on; }

bool Viewer::drawTiming() const { return _drawTiming; }

void Viewer::dtGpuBegin(int which) {
  if (_dtNoGpu)
    return;
  QOpenGLContext *c = QOpenGLContext::currentContext();
  if (c == nullptr)
    return;
  const void *ctx = glCacheContext();
  if (ctx != _dtCtx || glCacheEpoch() != _dtEpoch) {
    // (a new context: the old queries went with the old one)
    memset(_dtQueries, 0, sizeof(_dtQueries));
    memset(_dtPending, 0, sizeof(_dtPending));
    _dtCtx = ctx;
    _dtEpoch = glCacheEpoch();
    const QSurfaceFormat f = c->format();
    const bool has = (f.majorVersion() > 3 || (f.majorVersion() == 3 && f.minorVersion() >= 3)) ||
                     c->hasExtension("GL_ARB_timer_query");
    dtGen = reinterpret_cast<DtGenQueries>(c->getProcAddress("glGenQueries"));
    dtBegin = reinterpret_cast<DtBeginQuery>(c->getProcAddress("glBeginQuery"));
    dtEnd = reinterpret_cast<DtEndQuery>(c->getProcAddress("glEndQuery"));
    dtGet = reinterpret_cast<DtGetQueryObjectuiv>(c->getProcAddress("glGetQueryObjectuiv"));
    if (!has || !dtGen || !dtBegin || !dtEnd || !dtGet) {
      _dtNoGpu = true;
      return;
    }
  }
  unsigned &q = _dtQueries[_dtSlot][which];
  if (q == 0)
    dtGen(1, &q);
  dtBegin(DT_TIME_ELAPSED, q);
}

void Viewer::dtGpuEnd() {
  if (_dtNoGpu || dtEnd == nullptr || glCacheContext() != _dtCtx)
    return;
  dtEnd(DT_TIME_ELAPSED);
}

// The results of the frames before, whichever the card has finished (never
// waiting for one), and this frame's slot made ready.
void Viewer::dtGpuCollect() {
  if (_dtNoGpu || dtGet == nullptr || glCacheContext() != _dtCtx)
    return;
  for (int s = 0; s < 4; ++s) {
    if (!_dtPending[s])
      continue;
    GLuint ready0 = 0, ready1 = 0;
    dtGet(_dtQueries[s][0], DT_QUERY_RESULT_AVAILABLE, &ready0);
    dtGet(_dtQueries[s][1], DT_QUERY_RESULT_AVAILABLE, &ready1);
    if (!ready0 || !ready1) {
      if (s == _dtSlot)                  // (the ring has come round: drop it)
        _dtPending[s] = false;
      continue;
    }
    GLuint ns0 = 0, ns1 = 0;
    dtGet(_dtQueries[s][0], DT_QUERY_RESULT, &ns0);
    dtGet(_dtQueries[s][1], DT_QUERY_RESULT, &ns1);
    _dtShadowGpu += ns0 / 1.0e6;
    _dtScreenGpu += ns1 / 1.0e6;
    ++_dtGpuFrames;
    _dtPending[s] = false;
  }
}

QString Viewer::lastFrameDrawing() const {
  const LastFrame &f = _lfDone;
  if (f.all <= 0)
    return QString();
  QString merge = QString("merge %1").arg(f.merge, 0, 'f', 1);
  QStringList what;
  if (f.batches > 0)
    what << QString("%1 batch%2 made again").arg(f.batches).arg(f.batches == 1 ? "" : "es");
  if (f.recoloured > 0)
    what << QString("%1 recoloured").arg(f.recoloured);
  if (f.blanked > 0)
    what << QString("%1 with objects blanked").arg(f.blanked);
  if (!what.isEmpty())
    merge += " (" + what.join(", ") + ")";
  QString shadow = QString("shadow map %1").arg(f.shadow, 0, 'f', 1);
  QStringList sw;
  if (f.recorded > 0)
    sw << QString("record of %1 fixed objects made again").arg(f.recorded);
  if (f.depthSaved)
    sw << "saved depth made again";
  if (!sw.isEmpty())
    shadow += " (" + sw.join(", ") + ")";
  return QString("box %1, %2, cull %3, %4, screen %5, all %6")
      .arg(f.box, 0, 'f', 1)
      .arg(merge)
      .arg(f.cull, 0, 'f', 1)
      .arg(shadow)
      .arg(f.screen, 0, 'f', 1)
      .arg(f.all, 0, 'f', 1);
}

QString Viewer::drawTimingReport() {
  QString r;
  if (_dtFrames > 0) {
    const double n = _dtFrames;
    r = QString("processor: box %5, cull %1, shadow map %2, screen %3, all of draw %4")
            .arg(_dtCull / n, 0, 'f', 2)
            .arg(_dtShadow / n, 0, 'f', 2)
            .arg(_dtScreen / n, 0, 'f', 2)
            .arg(_dtDraw / n, 0, 'f', 2)
            .arg(_dtBox / n, 0, 'f', 2);
    if (_merge.made() > 0)
      r += QString(" (merge made %1 times)").arg(_merge.made());
    if (_dtGpuFrames > 0)
      r += QString("; graphics card: shadow map %1, screen %2")
               .arg(_dtShadowGpu / _dtGpuFrames, 0, 'f', 2)
               .arg(_dtScreenGpu / _dtGpuFrames, 0, 'f', 2);
    else if (_dtNoGpu)
      r += "; graphics card: no timers";
  }
  _dtCull = _dtShadow = _dtScreen = _dtDraw = _dtBox = 0;
  _merge.resetMade();
  _dtShadowGpu = _dtScreenGpu = 0;
  _dtFrames = _dtGpuFrames = 0;
  return r;
}

// ---------------------------------------------------------------------------
// Frame timing: where a late frame's time went.
//
// Each step of bpp's frame is marked with the time it starts: the animation
// step (scripts and physics), the drawing, every Qt event the application
// handles (seen through an event filter on the application) and the time
// Qt's event loop sits waiting for something to do (the event dispatcher's
// aboutToBlock/awake signals). A step lasts until the next mark. When the
// gap from one animation step to the next is over the threshold, the steps
// in between are added up by kind and the biggest are printed.
// ---------------------------------------------------------------------------

void Viewer::setFrameTiming(double ms) {
  _frameTimingMs = ms > 0 ? ms : 0;
  _frameTimingLast = -1;
  _frameMarks.clear();
  if (_frameTimingMs > 0 && !_frameTimingHooked) {
    _frameTimingHooked = true;
    _frameMarks.reserve(4096);
    qApp->installEventFilter(this);
    if (QAbstractEventDispatcher *d = QAbstractEventDispatcher::instance()) {
      connect(d, &QAbstractEventDispatcher::aboutToBlock, this, [this]() {
        if (_frameTimingMs > 0) frameMark(FM_WAITING);
      }, Qt::DirectConnection);
      connect(d, &QAbstractEventDispatcher::awake, this, [this]() {
        if (_frameTimingMs > 0) frameMark(FM_AWAKE);
      }, Qt::DirectConnection);
    }
  }
}

double Viewer::getFrameTiming() const { return _frameTimingMs; }

void Viewer::frameMark(int kind, int eventType, const char *cls,
                       const char *pcls) {
  if (_frameMarks.size() >= 100000)
    return; // never stopped by a missing animation step: just stop noting
  _frameMarks.append({_wallTimer.nsecsElapsed(), kind, eventType, cls, pcls});
}

bool Viewer::eventFilter(QObject *obj, QEvent *ev) {
  if (_frameTimingMs > 0 && obj && ev) {
    QObject *parent = obj->parent();
    frameMark(FM_EVENT, int(ev->type()), obj->metaObject()->className(),
              parent ? parent->metaObject()->className() : nullptr);
  }
  return QGLViewer::eventFilter(obj, ev);
}

void Viewer::frameTimingReport(qint64 now) {
  if (_frameMarks.isEmpty())
    return;
  // Add up the time after each mark, until the next one, by what it marks.
  QMap<QString, double> byStep; // ms
  QString longestStep;
  double longestMs = 0;
  QMetaEnum types = QMetaEnum::fromType<QEvent::Type>();
  for (int i = 0; i < _frameMarks.size(); i++) {
    const FrameMark &m = _frameMarks[i];
    qint64 end = i + 1 < _frameMarks.size() ? _frameMarks[i + 1].ns : now;
    double ms = (end - m.ns) / 1e6;
    QString step;
    switch (m.kind) {
    case FM_ANIMATE: step = "animation step (scripts, physics)"; break;
    case FM_AFTER_ANIMATE: step = "after the animation step"; break;
    case FM_PAINT: step = "drawing (with the preDraw/postDraw scripts)"; break;
    case FM_AFTER_PAINT: step = "after drawing (Qt shows the frame: compose, swap)"; break;
    case FM_WAITING: step = "event loop waiting (idle, or blocked in the system)"; break;
    case FM_AWAKE: step = "event loop woke up"; break;
    default: {
      const char *name = types.valueToKey(m.eventType);
      step = QString("event %1 -> %2%3")
                 .arg(name ? QString(name) : QString::number(m.eventType))
                 .arg(m.cls ? m.cls : "?")
                 .arg(m.pcls ? QString(" (in %1)").arg(m.pcls) : QString());
    }
    }
    byStep[step] += ms;
    if (ms > longestMs) {
      longestMs = ms;
      longestStep = step;
    }
  }
  QList<QPair<double, QString>> sorted;
  for (auto it = byStep.begin(); it != byStep.end(); ++it)
    sorted.append(qMakePair(it.value(), it.key()));
  std::sort(sorted.begin(), sorted.end(),
            [](const QPair<double, QString> &a, const QPair<double, QString> &b) {
              return a.first > b.first;
            });
  QString out = QString("FRAME TIMING: %1 ms between animation steps, ending at %2 "
                        "(%3 steps noted). Longest single step: %4 ms, %5. Largest totals:")
                    .arg((now - _frameTimingLast) / 1e6, 0, 'f', 0)
                    .arg(QTime::currentTime().toString("HH:mm:ss"))
                    .arg(_frameMarks.size())
                    .arg(longestMs, 0, 'f', 0)
                    .arg(longestStep);
  for (int i = 0; i < sorted.size() && i < 5; i++)
    out += QString("\n  %1 ms  %2").arg(sorted[i].first, 6, 'f', 1).arg(sorted[i].second);
  _frameTimingReports++;
  fprintf(stderr, "%s\n", out.toUtf8().constData());
  fflush(stderr);
  emitScriptOutput(out);
}
