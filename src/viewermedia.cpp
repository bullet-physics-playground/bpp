/**
 * @file viewermedia.cpp
 * @brief The Viewer's streamed music, question dialog and background
 *        downloads, for scripts: v:loadMusic() and friends, v:ask(),
 *        v:download() and v:dataDir().
 */

#include "viewer.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QEventLoop>
#include <QFileInfo>
#include <QGuiApplication>
#include <QMessageBox>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPushButton>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTimer>

#include <luabind/luabind.hpp>

#include <cmath>

// Headless

void Viewer::setHeadless(bool on) { _headless = on; }

bool Viewer::isHeadless() const {
  // (an offscreen or minimal platform has no screen to show a dialog on)
  const QString p = QGuiApplication::platformName();
  return _headless || p == "offscreen" || p == "minimal";
}

// Music

bool Viewer::loadMusic(const QString &path) {
  if (!_audioAvailable || isHeadless())
    return false;
  freeMusic();
  _music = Mix_LoadMUS(path.toUtf8().constData());
  if (_music == nullptr) {
    qWarning() << "loadMusic: failed to load" << path << ":" << Mix_GetError();
    return false;
  }
  return true;
}

bool Viewer::playMusic() { return playMusic(0.0); }

bool Viewer::playMusic(double startSeconds) {
  if (!_audioAvailable || _music == nullptr)
    return false;
  if (startSeconds < 0)
    startSeconds = 0;
  Mix_VolumeMusic((int)std::lround(_musicVolume * MIX_MAX_VOLUME));
  // (seeks before the first sample is mixed, unlike Mix_PlayMusic() followed
  // by Mix_SetMusicPosition(), which lets a few ms of the start through)
  if (Mix_FadeInMusicPos(_music, 0, 0, startSeconds) < 0) {
    qWarning() << "playMusic: cannot play from" << startSeconds << "s:"
               << Mix_GetError();
    return false;
  }
  _musicStart = startSeconds;
  _musicClock.start();
  _musicPaused = false;
  return true;
}

void Viewer::stopMusic() {
  if (!_audioAvailable)
    return;
  Mix_HaltMusic();
  _musicPaused = false;
}

void Viewer::pauseMusic() {
  if (!musicPlaying())
    return;
  _musicStart = musicPosition(); // (where the fallback clock carries on from)
  Mix_PauseMusic();
  _musicPaused = true;
}

void Viewer::resumeMusic() {
  if (!_audioAvailable || !_musicPaused)
    return;
  Mix_ResumeMusic();
  _musicClock.start();
  _musicPaused = false;
}

void Viewer::fadeMusicTo(double volume, double seconds) {
  volume = qBound(0.0, volume, 1.0);
  if (!_audioAvailable || isHeadless()) {
    _musicVolume = volume;
    return;
  }
  if (seconds <= 0) {
    if (_musicFadeTimer)
      _musicFadeTimer->stop();
    _musicVolume = volume;
    Mix_VolumeMusic((int)std::lround(volume * MIX_MAX_VOLUME));
    return;
  }
  if (_musicFadeTimer == nullptr) {
    _musicFadeTimer = new QTimer(this);
    _musicFadeTimer->setInterval(20);
    connect(_musicFadeTimer, &QTimer::timeout, this, &Viewer::musicFadeStep);
  }
  _musicFadeFrom = _musicVolume;
  _musicFadeTo = volume;
  _musicFadeSecs = seconds;
  _musicFadeClock.start();
  _musicFadeTimer->start();
}

void Viewer::musicFadeStep() {
  double t = _musicFadeClock.nsecsElapsed() / 1e9 / _musicFadeSecs;
  if (t >= 1.0) {
    t = 1.0;
    _musicFadeTimer->stop();
  }
  _musicVolume = _musicFadeFrom + (_musicFadeTo - _musicFadeFrom) * t;
  Mix_VolumeMusic((int)std::lround(_musicVolume * MIX_MAX_VOLUME));
}

double Viewer::musicPosition() {
  if (!_audioAvailable || _music == nullptr || !Mix_PlayingMusic())
    return 0.0;
  if (_musicPaused)
    return _musicStart;
#if SDL_MIXER_VERSION_ATLEAST(2, 6, 0)
  double p = Mix_GetMusicPosition(_music);
  if (p >= 0)
    return p;
#endif
  // (an older SDL_mixer, or a decoder that cannot tell)
  return _musicStart + _musicClock.nsecsElapsed() / 1e9;
}

bool Viewer::musicPlaying() {
  return _audioAvailable && _music != nullptr && Mix_PlayingMusic() &&
         !_musicPaused;
}

void Viewer::freeMusic() {
  if (_musicFadeTimer)
    _musicFadeTimer->stop();
  _musicVolume = 1.0;
  if (!_audioAvailable)
    return;
  if (_music != nullptr) {
    Mix_HaltMusic();
    Mix_FreeMusic(_music);
    _music = nullptr;
  }
  _musicPaused = false;
  Mix_VolumeMusic(MIX_MAX_VOLUME);
}

// Questions

namespace {

// "Don't ask again", "Never", "Never ask again", ...
bool isRememberButton(const QString &label) {
  return label.contains("again", Qt::CaseInsensitive) ||
         label.contains("never", Qt::CaseInsensitive);
}

// The answer when nobody answers (headless, Esc, closing the box): the first
// button that reads like "not now", else the last one that is not "don't
// ask again", else the first. Counting from 1.
int askDefault(const QStringList &labels) {
  static const QRegularExpression notNow(
      "\\b(not now|later|cancel|skip|no)\\b",
      QRegularExpression::CaseInsensitiveOption);
  for (int i = 0; i < labels.size(); ++i)
    if (!isRememberButton(labels[i]) && notNow.match(labels[i]).hasMatch())
      return i + 1;
  for (int i = labels.size() - 1; i >= 0; --i)
    if (!isRememberButton(labels[i]))
      return i + 1;
  return 1;
}

QStringList buttonLabels(const luabind::object &buttons) {
  QStringList labels;
  if (luabind::type(buttons) == LUA_TTABLE) {
    for (int i = 1;; ++i) {
      luabind::object b = buttons[i];
      if (luabind::type(b) == LUA_TNIL)
        break;
      labels << QString::fromUtf8(luabind::object_cast<std::string>(b).c_str());
    }
  } else if (luabind::type(buttons) == LUA_TSTRING) {
    labels << QString::fromUtf8(
        luabind::object_cast<std::string>(buttons).c_str());
  }
  if (labels.isEmpty())
    labels << "OK";
  return labels;
}

} // namespace

int Viewer::ask(const QString &title, const QString &text,
                const luabind::object &buttons) {
  return ask(title, text, buttons, QString());
}

int Viewer::ask(const QString &title, const QString &text,
                const luabind::object &buttons, const QString &rememberKey) {
  const QStringList labels = buttonLabels(buttons);

  if (!rememberKey.isEmpty()) {
    int r = remembered(rememberKey);
    if (r >= 1 && r <= labels.size())
      return r;
  }

  const int fallback = askDefault(labels);
  if (isHeadless())
    return fallback;

  QMessageBox box(QMessageBox::Question, title, text, QMessageBox::NoButton,
                  this);
  QList<QPushButton *> pushed;
  for (const QString &l : labels)
    pushed << box.addButton(l, QMessageBox::ActionRole);
  box.setDefaultButton(pushed.first());
  box.setEscapeButton(pushed[fallback - 1]);

  // The script that asks holds the simulation's mutex (it runs from parse()
  // or from a callback in animate()), and the box's event loop would call
  // animate() and the device handlers, which lock it too: they wait for the
  // box instead (see _holdSim), and the world does not step meanwhile.
  ++_holdSim;
  box.exec();
  --_holdSim;

  int chosen = pushed.indexOf(qobject_cast<QPushButton *>(box.clickedButton())) + 1;
  if (chosen <= 0)
    chosen = fallback;

  if (!rememberKey.isEmpty() && isRememberButton(labels[chosen - 1]) &&
      _settings != nullptr) {
    _settings->setValue("ask/" + rememberKey, chosen);
    _settings->sync();
  }
  return chosen;
}

int Viewer::remembered(const QString &key) const {
  if (_settings == nullptr || key.isEmpty())
    return 0;
  return _settings->value("ask/" + key, 0).toInt();
}

void Viewer::forget(const QString &key) {
  if (_settings == nullptr || key.isEmpty())
    return;
  _settings->remove("ask/" + key);
  _settings->sync();
}

// Downloads

int Viewer::download(const QString &url, const QString &path) {
  for (auto &kv : _downloads)
    if (kv.second.path == path && kv.second.state == "running")
      return kv.first;

  const int id = _nextDownloadId++;
  Download &d = _downloads[id];
  d.path = path;
  d.state = "failed";

  const QUrl u(url);
  if (path.isEmpty() || !u.isValid() || u.scheme().isEmpty()) {
    d.error = "bad url or path";
    return id;
  }

  QDir().mkpath(QFileInfo(path).absolutePath());
  d.file = new QFile(path + ".part");
  if (!d.file->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
    d.error = d.file->errorString();
    delete d.file;
    d.file = nullptr;
    return id;
  }

  if (_nam == nullptr)
    _nam = new QNetworkAccessManager(this);

  QNetworkRequest req(u);
  // (Wikimedia refuses requests without a descriptive User-Agent)
  req.setHeader(QNetworkRequest::UserAgentHeader,
                QString("bpp/%1 (Bullet Physics Playground; "
                        "https://github.com/bullet-physics-playground/bpp)")
                    .arg(QCoreApplication::applicationVersion()));
  req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                   QNetworkRequest::NoLessSafeRedirectPolicy);
  // (uncompressed, so the bytes received can be checked against the
  // Content-Length the server announces)
  req.setRawHeader("Accept-Encoding", "identity");

  d.state = "running";
  d.reply = _nam->get(req);
  QNetworkReply *reply = d.reply;
  connect(reply, &QNetworkReply::readyRead, this, [this, id]() {
    Download &d = _downloads[id];
    if (d.reply == nullptr || d.file == nullptr)
      return;
    const QByteArray data = d.reply->readAll();
    if (d.file->write(data) != data.size()) {
      d.error = d.file->errorString();
      d.reply->abort();
      return;
    }
    d.bytes += data.size();
  });
  connect(reply, &QNetworkReply::downloadProgress, this,
          [this, id](qint64, qint64 total) {
            if (total >= 0)
              _downloads[id].total = total;
          });
  connect(reply, &QNetworkReply::finished, this,
          [this, id]() { downloadFinished(id); });
  return id;
}

void Viewer::downloadFinished(int id) {
  Download &d = _downloads[id];
  QNetworkReply *reply = d.reply;
  if (reply == nullptr)
    return;

  const QByteArray rest = reply->readAll();
  if (!rest.isEmpty() && d.file->write(rest) == rest.size())
    d.bytes += rest.size();
  d.file->close();

  const QString part = d.file->fileName();
  QString error = d.error;
  const int status =
      reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
  bool ok = false;
  const qint64 expected = reply->header(QNetworkRequest::ContentLengthHeader)
                              .toLongLong(&ok);
  if (!error.isEmpty()) {
    // (a write failed, see download())
  } else if (reply->error() != QNetworkReply::NoError) {
    error = reply->errorString();
  } else if (status != 0 && status != 200) {
    error = QString("HTTP status %1").arg(status);
  } else if (ok && expected != d.bytes) {
    error = QString("size mismatch: got %1 of %2 bytes")
                .arg(d.bytes)
                .arg(expected);
  } else {
    if (QFile::exists(d.path))
      QFile::remove(d.path);
    if (!QFile::rename(part, d.path))
      error = QString("cannot rename %1 to %2").arg(part, d.path);
  }

  if (ok)
    d.total = expected;
  if (error.isEmpty()) {
    d.state = "done";
  } else {
    d.state = "failed";
    d.error = error;
    QFile::remove(part);
  }

  delete d.file;
  d.file = nullptr;
  d.reply = nullptr;
  reply->deleteLater();
}

luabind::object Viewer::downloadState(int id) {
  auto it = _downloads.find(id);

  // With no event loop (a headless run) nothing would ever arrive: let the
  // network's events in for a moment, with the simulation held as for ask().
  if (it != _downloads.end() && it->second.state == "running" && isHeadless()) {
    ++_holdSim;
    QEventLoop loop;
    QTimer::singleShot(20, &loop, &QEventLoop::quit);
    loop.exec(QEventLoop::ExcludeUserInputEvents);
    --_holdSim;
  }

  luabind::object t = luabind::newtable(L);
  if (it == _downloads.end()) {
    t["state"] = "failed";
    t["bytes"] = 0;
    t["total"] = -1;
    t["error"] = "no such download";
    return t;
  }
  const Download &d = it->second;
  t["state"] = d.state.toStdString();
  t["bytes"] = (double)d.bytes;
  t["total"] = (double)d.total;
  t["error"] = d.error.toStdString();
  return t;
}

void Viewer::freeDownloads() {
  for (auto &kv : _downloads) {
    Download &d = kv.second;
    if (d.reply != nullptr) {
      d.reply->disconnect(this);
      d.reply->abort();
      d.reply->deleteLater();
      d.reply = nullptr;
    }
    if (d.file != nullptr) {
      d.file->close();
      QFile::remove(d.file->fileName());
      delete d.file;
      d.file = nullptr;
    }
  }
  _downloads.clear();
}

QString Viewer::dataDir() const {
  const QString dir =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir().mkpath(dir);
  return dir;
}
