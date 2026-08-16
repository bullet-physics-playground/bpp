#include "appenv.h"
#include "prefs.h"

#include <Qt>

#include "gui.h"

#include <QActionGroup>
#include <QFile>
#include <QProgressBar>
#include <QDir>
#include <QFileInfo>
#include <QRegExp>

std::ostream &operator<<(std::ostream &ostream, const Gui &gui) {
  ostream << gui.toString().toUtf8().data();
  return ostream;
}

Gui::Gui(QSettings *s, QWidget *parent) : QMainWindow(parent), msgBox(nullptr) {

  _fileSaved = true;
  _simulationRunning = false;

  ui.setupUi(this);

  this->settings = s;
  ui.viewer->setSettings(s);

  createDock();

  createActions();
  createMenus();
  setStatusBar(new QStatusBar(this));

  progressBar = new QProgressBar(statusBar());
  progressBar->setObjectName("bppProgressBar");
  progressBar->setRange(0, 0);
  progressBar->setMaximumWidth(200);
  progressBar->setMaximumHeight(16);
  progressBar->hide();
  statusBar()->addPermanentWidget(progressBar);

  frameLabel = new QLabel("frame 0", statusBar());
  frameLabel->setObjectName("bppFrameLabel");
  frameLabel->setMinimumWidth(100);
  statusBar()->addPermanentWidget(frameLabel);

  renderSettings = new QComboBox(ui.toolBarView);

  QStringList renderSettingsList;
  renderSettingsList << "view size";
  renderSettingsList << "  426x240 (240p)";
  renderSettingsList << " 1280x720 (720p)";
  renderSettingsList << "1920x1080 (1080p)";
  renderSettingsList << "1080x1920 TikTok (9:16)";
  renderSettingsList << "3840x2160 YouTube 4K";
  renderSettingsList << "4480x2520 Apple M1";
  renderSettingsList << "5120x2880 Apple 5K";
  renderSettingsList << "7680x4320 YouTube 8K";
  renderSettingsList << "3470x2442 DIN A4 landscape 300dpi 5mm margin";
  renderSettingsList << "6780x4725 DIN A4 landscape 600dpi 5mm margin";
  renderSettingsList << "  600x800 portrait (3:4)";

  renderSettings->addItems(renderSettingsList);
  renderSettings->setEditable(true);
  renderSettings->lineEdit()->setReadOnly(true);
  renderSettings->lineEdit()->setAlignment(Qt::AlignRight);
  for (int i = 0; i < renderSettings->count(); i++)
    renderSettings->setItemData(i, Qt::AlignRight, Qt::TextAlignmentRole);

  ui.toolBarView->addWidget(renderSettings);
  ui.toolBarView->addAction(ui.actionQuickRender);

  connect(editor, &CodeEditor::textChanged, this, &Gui::scriptChanged);

  connect(ui.actionQuickRender, &QAction::triggered, ui.viewer, [this]() { ui.viewer->onQuickRender(); });

  connect(editor, &CodeEditor::keyPressed, ui.viewer,
          &Viewer::keyPressEvent);
  connect(commandLine, &CommandLine::keyPressed, ui.viewer,
          &Viewer::keyPressEvent);
  connect(debugText, &CodeEditor::keyPressed, ui.viewer,
          &Viewer::keyPressEvent);

  connect(ui.viewer, &Viewer::scriptHasOutput, this, &Gui::debug);
  connect(ui.viewer, &Viewer::scriptStarts, this, &Gui::clearDebug);
  connect(ui.viewer, &Viewer::scriptStarts, this,
          [this]() { showProgressBar(tr("Parsing script, please be patient ...")); });
  connect(ui.viewer, &Viewer::scriptFinished, this,
          [this]() { hideProgressBar(); });
  connect(ui.viewer, &Viewer::simulationStateChanged, this,
          &Gui::toggleSimButton);
  connect(ui.viewer, &Viewer::POVStateChanged, this, &Gui::togglePOVExport);
  connect(ui.viewer, &Viewer::deactivationStateChanged, this,
          &Gui::toggleDeactivation);

  connect(ui.viewer, &Viewer::statusEvent, this, &Gui::setStatusBarText);

  connect(ui.viewer, &Viewer::clearDebugText, debugText, &CodeEditor::clear);

  connect(ui.viewer, &Viewer::helpTextChanged, shortcutsText, &CodeEditor::setPlainText);

  connect(commandLine, &CommandLine::execute, this, &Gui::command);

  connect(renderSettings, &QComboBox::currentTextChanged, this, &Gui::saveSettings);

  loadSettings();

  connect(ui.viewer, &Viewer::postDrawShot, this, &Gui::postDraw);
  connect(ui.viewer, &Viewer::frameUpdate, this, &Gui::updateFrameLabel);
  connect(ui.viewer, &Viewer::paramsChanged, this, &Gui::updateParamsTable);
  commandLine->setFocus();

fileNew();

  QTimer::singleShot(500, this, &Gui::setFullscreenActionState);

  bool openLast = settings->value("gui/openlastfile", false).toBool();
  if (!openLast) {
    openLast = settings->value("openlastfile", false).toBool();
    if (openLast) {
      settings->setValue("gui/openlastfile", true);
    }
  }
  if (openLast) {
    QTimer::singleShot(0, this, &Gui::loadLastFile);
  }
}

Gui::~Gui() = default;

void Gui::setFullscreenActionState() {
  ui.action_Full_screen->setChecked(isFullScreen());
}

void Gui::toggleFullscreen() {
  if (isFullScreen()) {
    showNormal();
  } else {
    showFullScreen();
  }
}

void Gui::toggleSimButton(bool simRunning) {
  if (simRunning) {
    QIcon playIcon = QIcon::fromTheme("media-playback-pause");
    ui.actionToggleSim->setIcon(playIcon);
    ui.actionToggleSim->setText(tr("Pause &Simulation"));
    ui.actionToggleSim->setShortcut(tr("Ctrl+S"));
    ui.actionToggleSim->setStatusTip(tr("Pause Simulation"));
    ui.actionToggleSim->setChecked(true);
    _simulationRunning = true;
  } else {
    QIcon playIcon = QIcon::fromTheme("media-playback-start");
    ui.actionToggleSim->setIcon(playIcon);
    ui.actionToggleSim->setText(tr("&Run simulation.."));
    ui.actionToggleSim->setShortcut(tr("Ctrl+S"));
    ui.actionToggleSim->setStatusTip(tr("Run Simulation"));
    ui.actionToggleSim->setChecked(false);
    _simulationRunning = false;
  }
}

void Gui::togglePOVExport(bool p) {
  ui.viewer->toggleSavePOV(p);
  ui.actionTogglePOVExport->setChecked(p);
}

void Gui::toggleDeactivation(bool d) {
  ui.viewer->toggleDeactivation(d);
  ui.actionToggleDeactivation->setChecked(d);
}

void Gui::toggleShowConstraints(bool checked) {
  ui.viewer->setShowConstraints(checked);
}

void Gui::postDraw(int /* frame */) {
  // QPixmap p = QPixmap::grabWidget(this);

  /*
if (savePNG) {
  QPixmap p = QPixmap::grabWindow(this->winId());

  QString file;
  file.asprintf("screenshots/w-%05d.png", frame);

  qDebug() << "saving screenshot " << file;

  p.save(file, "png");
}
*/
  Camera *c = ui.viewer->camera();

  QString txt;
  QTextStream s(&txt);

  Vec up = c->upVector();
  s << "v.cam:setUpVector(btVector3(" << up.x << ", " << up.y << ", " << up.z << "), true)" << "\n";
  s << "v.cam.up   = btVector3(" << up.x << ", " << up.y << ", " << up.z << ")" << "\n";

  Vec pos = c->position();
  s << "v.cam.pos  = btVector3(" << pos.x << ", " << pos.y << ", " << pos.z << ")" << "\n";

  Vec look =
      ((Cam *)c)->viewDirection() * 1000000 + c->position();
  s << "v.cam.look = btVector3(" << look.x << ", " << look.y << ", " << look.z << ")" << "\n";

  camText->setPlainText(txt);
}

void Gui::dragEnterEvent(QDragEnterEvent *event) {
  if (event->mimeData()->hasFormat("text/uri-list")) {
    event->acceptProposedAction();
  }
}

void Gui::dropEvent(QDropEvent *event) {
  QList<QUrl> urls = event->mimeData()->urls();

  if (urls.isEmpty())
    return;

  QString filePath = urls.first().toLocalFile();

  if (filePath.isEmpty())
    return;

  fileLoad(filePath);

  event->acceptProposedAction();
}

void Gui::loadLastFile() {
  bool openLast = settings->value("gui/openlastfile", false).toBool();
  if (!openLast) {
    openLast = settings->value("openlastfile", false).toBool();
  }
  if (!openLast) return;

  QString lastFile;

  settings->beginGroup("mainwindow");
  lastFile = settings->value("lastFile", "").toString();
  settings->endGroup();

  if (lastFile != "") {
    fileLoad(lastFile);
  }
}

void Gui::fileLoad(const QString &path) {
  QFile file(path);

  QString filePath = path;
  if (!filePath.isEmpty() && filePath != "no_name")
    filePath = QFileInfo(filePath).absoluteFilePath();

  settings->beginGroup("mainwindow");
  settings->setValue("lastFile", filePath);
  settings->endGroup();
  settings->sync();

#ifndef QT_NO_CURSOR
  QApplication::setOverrideCursor(Qt::WaitCursor);
#endif

  editor->blockSignals(true);
  bool loaded = editor->load(path);
  editor->blockSignals(false);

  if (loaded) {
    setCurrentFile(path);
    setWindowTitle(tr("%1 - %2")
                       .arg(QCoreApplication::applicationName())
                       .arg(file.fileName()));
    parseEditor();
    statusBar()->showMessage(tr("File loaded"), 2000);
    _fileSaved = true;
    ui.actionSave->setEnabled(false);
  } else {
    setWindowTitle(tr("%1 %2")
                       .arg(QCoreApplication::applicationName())
                       .arg(QCoreApplication::applicationVersion()));
    statusBar()->showMessage(tr("Error loading file %1").arg(path), 5000);
  }

#ifndef QT_NO_CURSOR
  QApplication::restoreOverrideCursor();
#endif
}

void Gui::createActions() {
  for (int i = 0; i < MAX_RECENT_FILES; ++i) {
    recentFileActions[i] = new QAction(this);
    recentFileActions[i]->setVisible(false);
    connect(recentFileActions[i], SIGNAL(triggered()), this,
            SLOT(openRecentFile()));
  }
}

void Gui::createMenus() {
  for (int i = 0; i < MAX_RECENT_FILES; ++i)
    ui.menuFile->addAction(recentFileActions[i]);

  actionSeparator = ui.menuFile->addSeparator();

  ui.menuFile->addAction(ui.actionExit);

  createPovrayMenu();

  updateRecentFileActions();
}

namespace {

struct PovrayOption {
  int value;
  const char *label;
};

struct PovraySetting {
  const char *name;        // #declare name in includes/settings.inc
  const char *label;       // menu entry / submenu title
  const char *description; // status bar / tooltip text
  bool toggle;             // true: single checkable action (0/1)
                            // false: submenu of exclusive radio-style actions
  QVector<PovrayOption> options; // used when !toggle
};

const QVector<PovraySetting> &povraySettings() {
  static const QVector<PovraySetting> settings = {
      {"use_lightsys", "Enable / disable LightSYS rendering system",
       "Use the LightSys physically-based sun/sky lighting system instead "
       "of simple fixed point lights",
       true,
       {}},
      {"use_rad", "Radiosity",
       "Radiosity (indirect lighting) quality", false,
       {{0, "Off"}, {1, "Outdoor, low quality"}, {2, "Outdoor, high quality"}}},
      {"use_lightsys_setting", "LightSys light preset",
       "LightSys area-light color preset (only used with LightSys and "
       "area light both on)",
       false,
       {{0, "Daylight fluorescent"}, {1, "Cool fluorescent"}}},
      {"use_cie_whitepoint", "CIE white point",
       "CIE color-system white point / film response adaptation (only "
       "used with LightSys)",
       false,
       {{0, "Off"},
        {1, "Illuminant B"},
        {2, "Daylight film"},
        {3, "Indoor film"}}},
      {"use_lightsys_light1", "Secondary LightSys fill light",
       "Secondary LightSys light matching the interactive view's "
       "GL_LIGHT1 (only used with LightSys)",
       true,
       {}},
      {"use_area_light", "Area light (soft shadows)",
       "Render the main light as a soft area light for soft shadows, "
       "instead of a hard point light",
       true,
       {}},
      {"use_background", "Background",
       "Background behind objects that don't hit any geometry", false,
       {{0, "None (sky)"}, {1, "Black"}, {2, "White"}}},
      {"use_clouds", "Clouds / sky", "Sky and cloud rendering style", false,
       {{0, "Off"},
        {1, "Simple cloud plane"},
        {2, "Fast realistic clouds"},
        {3, "Gradient sky dome"}}},
      {"use_plane", "Ground plane", "Add a textured ground plane to the render",
       true,
       {}},
      {"use_plane_tex", "Ground plane texture",
       "Ground plane texture (only used when the ground plane is on)",
       false,
       {{0, "Plain"}, {1, "Grass"}, {2, "Glossy white"}}},
      {"use_photons", "Photon mapping",
       "Photon mapping quality for caustics and reflections", false,
       {{0, "Off"}, {1, "Normal"}, {2, "Fine"}}},
  };
  return settings;
}

} // namespace

void Gui::createPovrayMenu() {
  QMenu *menuPovray = new QMenu(tr("&POV-Ray"), this);
  ui.menubar->insertMenu(ui.menuHelp->menuAction(), menuPovray);

  auto addSetting = [this, menuPovray](const PovraySetting &setting) {
    if (setting.toggle) {
      QAction *action = menuPovray->addAction(tr(setting.label));
      action->setCheckable(true);
      action->setChecked(readPovraySetting(setting.name, 0) != 0);
      action->setStatusTip(tr(setting.description));
      action->setToolTip(tr(setting.description));
      QString name = setting.name;
      connect(action, &QAction::toggled, this, [this, name](bool checked) {
        writePovraySetting(name, checked ? 1 : 0);
      });
      return;
    }

    QMenu *sub = menuPovray->addMenu(tr(setting.label));
    sub->setStatusTip(tr(setting.description));
    sub->setToolTip(tr(setting.description));
    QActionGroup *group = new QActionGroup(sub);
    group->setExclusive(true);
    int current = readPovraySetting(setting.name, setting.options.first().value);
    QString name = setting.name;
    for (const PovrayOption &opt : setting.options) {
      QAction *a = sub->addAction(tr(opt.label));
      a->setCheckable(true);
      a->setChecked(opt.value == current);
      a->setStatusTip(tr(setting.description));
      a->setToolTip(tr(setting.description));
      group->addAction(a);
      int value = opt.value;
      connect(a, &QAction::triggered, this, [this, name, value]() {
        writePovraySetting(name, value);
      });
    }
  };

  const QVector<PovraySetting> &settings = povraySettings();
  addSetting(settings.first()); // use_lightsys: the headline toggle
  menuPovray->addSeparator();
  for (int i = 1; i < settings.size(); i++) {
    addSetting(settings.at(i));
  }
}

QString Gui::povraySettingsPath() const {
  return startupWorkingDir() + QDir::separator() + "includes" +
         QDir::separator() + "settings.inc";
}

int Gui::readPovraySetting(const QString &name, int defaultValue) const {
  QFile file(povraySettingsPath());
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return defaultValue;
  }
  QRegExp rx(QString("^\\s*#declare\\s+%1\\s*=\\s*(-?\\d+)\\s*;").arg(name));
  while (!file.atEnd()) {
    QString line = QString::fromUtf8(file.readLine());
    if (rx.indexIn(line) >= 0) {
      return rx.cap(1).toInt();
    }
  }
  return defaultValue;
}

void Gui::writePovraySetting(const QString &name, int value) {
  QString path = povraySettingsPath();
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return;
  }
  QString content = QString::fromUtf8(file.readAll());
  file.close();

  QRegExp rx(QString("(#declare\\s+%1\\s*=\\s*)-?\\d+(\\s*;)").arg(name));
  if (rx.indexIn(content) < 0) {
    return; // setting not found in the file, don't touch it
  }
  content.replace(rx, QString("\\1%1\\2").arg(value));

  QFile out(path);
  if (!out.open(QIODevice::WriteOnly | QIODevice::Text)) {
    return;
  }
  out.write(content.toUtf8());
}

void Gui::updateRecentFileActions() {
  QStringList files = settings->value("recentFileList").toStringList();

  int numRecentFiles = qMin(files.size(), (int)MAX_RECENT_FILES);

  for (int i = 0; i < numRecentFiles; ++i) {
    QString text = tr("&%1 %2").arg(i + 1).arg(strippedName(files[i]));
    recentFileActions[i]->setText(text);
    recentFileActions[i]->setData(files[i]);
    recentFileActions[i]->setVisible(true);
  }
  for (int j = numRecentFiles; j < MAX_RECENT_FILES; ++j)
    recentFileActions[j]->setVisible(false);

  actionSeparator->setVisible(numRecentFiles > 0);
}

void Gui::setCurrentFile(const QString &fileName) {

  QString filePath = fileName;
  if (!filePath.isEmpty() && filePath != "no_name")
    filePath = QFileInfo(filePath).absoluteFilePath();

  QString scriptFile = editor->scriptFile();

  ui.viewer->setScriptName(strippedNameNoExt(scriptFile));

  if (!scriptFile.isEmpty() && scriptFile != "no_name") {
    QFileInfo fi(scriptFile);
    if (fi.exists()) {
      QString dir = QDir::toNativeSeparators(fi.absolutePath());
      QDir::setCurrent(dir);
      ui.viewer->setScriptBasePath(dir);
    }
  }

  if (scriptFile.isEmpty())
    setWindowTitle(tr("Recent Files"));
  else
    setWindowTitle(tr("%1 %2 - %3")
                       .arg(QCoreApplication::applicationName())
                       .arg(QCoreApplication::applicationVersion())
                       .arg(strippedName(scriptFile)));

  if (filePath == "no_name") {
    return;
  }

  QStringList files = settings->value("recentFileList").toStringList();
  files.removeAll(filePath);
  files.prepend(filePath);
  while (files.size() > MAX_RECENT_FILES)
    files.removeLast();

  settings->setValue("recentFileList", files);
  settings->sync();

  foreach (QWidget *widget, QApplication::topLevelWidgets()) {
    Gui *mainWin = qobject_cast<Gui *>(widget);
    if (mainWin)
      mainWin->updateRecentFileActions();
  }
}

void Gui::createDock() {
  QDockWidget *dw1 = new QDockWidget(this);
  dw1->setObjectName("DockDebug");
  dw1->setWindowTitle("Debug");
  dw1->setTitleBarWidget(new QWidget(this));

  debugText = new CodeEditor(settings, this);
  dw1->setWidget(debugText);
  debugText->setReadOnly(true);

  addDockWidget(Qt::BottomDockWidgetArea, dw1);

  QDockWidget *dw2 = new QDockWidget(this);
  dw2->setObjectName("DockLUAScript");
  dw2->setWindowTitle("LUA Script");
  editor = new CodeEditor(settings, this);
  dw2->setWidget(editor);

  addDockWidget(Qt::RightDockWidgetArea, dw2);
  dockLUAScript = dw2;

  QDockWidget *dw3 = new QDockWidget(this);
  dw3->setObjectName("DockCommandLine");
  dw3->setWindowTitle("Command Line");
  commandLine = new CommandLine(this);
  dw3->setWidget(commandLine);

  addDockWidget(Qt::RightDockWidgetArea, dw3);

  QDockWidget *dw4 = new QDockWidget(this);
  dw4->setObjectName("CamText");
  dw4->setWindowTitle(tr("Camera Info"));
  camText = new CodeEditor(settings, this);
  dw4->setWidget(camText);
  camText->setReadOnly(true);

  addDockWidget(Qt::RightDockWidgetArea, dw4);

  QDockWidget *dw5 = new QDockWidget(this);
  dw5->setObjectName("DockParams");
  dw5->setWindowTitle("Parameters");
  paramsTable = new QTableWidget(0, 2, this);
  paramsTable->setHorizontalHeaderLabels(QStringList() << "Name" << "Value");
  paramsTable->horizontalHeader()->setStretchLastSection(true);
  paramsTable->setItemDelegate(new QItemDelegate());
  dw5->setWidget(paramsTable);
  addDockWidget(Qt::RightDockWidgetArea, dw5);
  dockParams = dw5;
  paramsTable->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(paramsTable, &QTableWidget::cellChanged, this, &Gui::onParamsTableCellChanged);
  paramsTable->viewport()->setMouseTracking(true);
  paramsTable->viewport()->installEventFilter(this);

  connect(dw5, &QDockWidget::topLevelChanged, this, [dw5](bool floating) {
    dw5->setWindowFlag(Qt::WindowStaysOnTopHint, floating);
    dw5->show();
  });

  connect(paramsTable, &QTableWidget::customContextMenuRequested, this, [this, dw5](const QPoint &pos) {
    QMenu menu;
    QAction *dockAction = menu.addAction(tr("Dock to Main Window"));
    dockAction->setEnabled(dw5->isFloating());
    if (menu.exec(paramsTable->viewport()->mapToGlobal(pos)) == dockAction) {
      dw5->setFloating(false);
    }
  });

  QDockWidget *dw6 = new QDockWidget(this);
  dw6->setObjectName("DockShortcuts");
  dw6->setWindowTitle("Shortcuts");
  shortcutsText = new CodeEditor(settings, this);
  shortcutsText->setReadOnly(true);
  dw6->setWidget(shortcutsText);
  addDockWidget(Qt::BottomDockWidgetArea, dw6);
  dockShortcuts = dw6;
}

void Gui::helpAbout() {
  QString txt =
      tr("<p><b>%1 (%2)</b></p>")
          .arg(QCoreApplication::applicationName())
          .arg(QCoreApplication::applicationVersion()) +
      tr("<p>Build: %1 - %2</p>").arg(BUILDDATE).arg(BUILDTIME) +
      tr("<p>%1 Bullet: %2</p>").arg(LUA_VERSION).arg(BULLET_VERSION) +
      tr("<p>GLEW:&nbsp;%1 GL&nbsp;Renderer:&nbsp;%2 "
         "GL&nbsp;Vendor:&nbsp;%3</p>")
          .arg((char *)glGetString(GL_VERSION))
          .arg((char *)glGetString(GL_RENDERER))
          .arg((char *)glGetString(GL_VENDOR)) +
      tr("<p>&copy; 2008-%1 <a href=\"http://github.com/koppi\">Jakob "         "Flierl</a></p>")          .arg(QDate::currentDate().year()) +
      tr("<p>&copy; 2012-2016 <a href=\"http://ignorancia.org/\">Jaime Vives "
         "Piqueres</a></p>");

  QMessageBox::about(this, tr("About"), txt);
}

void Gui::helpHomepage() {
  QDesktopServices::openUrl(
      QUrl("https://github.com/bullet-physics-playground"));
}

void Gui::helpIssues() {
  QDesktopServices::openUrl(
      QUrl("https://github.com/bullet-physics-playground/bpp/issues"));
}

void Gui::helpWiki() {
  QDesktopServices::openUrl(
      QUrl("https://github.com/bullet-physics-playground/bpp/wiki"));
}

void Gui::helpChat() {
  QDesktopServices::openUrl(
      QUrl("https://gitter.im/bullet-physics-playground/bpp"));
}

QString Gui::strippedName(const QString &fullFileName) {
  return QFileInfo(fullFileName).fileName();
}

QString Gui::strippedNameNoExt(const QString &fullFileName) {
  return QFileInfo(fullFileName).baseName();
}

void Gui::scriptChanged() {
  static QString oldText;

  if (oldText != editor->toPlainText()) {
    oldText = editor->toPlainText();
    ui.actionSave->setEnabled(true);
    _fileSaved = false;
    parseEditor();
  } else {
    // qDebug() << "Warning: Gui::scriptChanged() called, but editor text the
    // same." << "\n";
  }
}

void Gui::parseEditor() { ui.viewer->parse(editor->toPlainText()); }

void Gui::animStarted() {}

void Gui::animProgress(const QString &, int) {}

void Gui::animFinished() {}

void Gui::updateFrameLabel(int frameNum) {
  frameLabel->setText(QString("frame %1").arg(frameNum));
}

void Gui::debug(const QString &txt) { debugText->appendLine(txt); }

void Gui::clearDebug() { debugText->clear(); }

void Gui::fileNew() {
  editor->clear();
  ui.viewer->clearParams();
  setCurrentFile(editor->scriptFile());
  ui.actionSave->setEnabled(true);
  _fileSaved = true;
}

void Gui::fileOpen(const QString &path) {
  if (!_fileSaved) {
    settings->beginGroup("gui");
    bool dontask = settings->value("dont_ask_unsaved_changes", false).toBool();
    settings->endGroup();

    if (!dontask) {
      msgBox = new QMessageBox(this);
      msgBox->setWindowTitle(tr("Unsaved changes"));
      msgBox->setText(tr("File '%1'\n\nnot saved: continue anyhow?\n")
                          .arg(editor->scriptFile()));
      // msgBox->setIcon(QMessageBox::Icon::Question);
      msgBox->addButton(QMessageBox::No);
      msgBox->addButton(QMessageBox::Yes);
      msgBox->setDefaultButton(QMessageBox::No);

      QCheckBox *check =
          new QCheckBox(tr("Don't show this message again."), this);
      msgBox->setCheckBox(check);

      int32_t answer = msgBox->exec();

      settings->beginGroup("gui");
      settings->setValue("dont_ask_unsaved_changes", check->isChecked());
      settings->endGroup();
      settings->sync();

      msgBox->deleteLater();
      msgBox = nullptr;

      if (answer == QMessageBox::No) {
        return;
      }
    }
  }

  editor->blockSignals(true);
  editor->load(path);
  editor->blockSignals(false);
  ui.viewer->clearParams();
  setCurrentFile(editor->scriptFile());
  ui.actionSave->setEnabled(false);

  _fileSaved = true;

  parseEditor();
}

void Gui::fileReload() {
  editor->blockSignals(true);
  editor->load(editor->scriptFile());
  editor->blockSignals(false);
  ui.viewer->clearParams();
  setCurrentFile(editor->scriptFile());
  ui.actionSave->setEnabled(false);

  _fileSaved = true;

  parseEditor();
}

void Gui::fileSave() {
  if (editor->save()) {
    setCurrentFile(editor->scriptFile());
    ui.actionSave->setEnabled(false);
    _fileSaved = true;
  } else {
    ui.actionSave->setEnabled(true);
    _fileSaved = false;
  }
}

void Gui::fileSaveAs() {
  if (editor->saveAs()) {
    setCurrentFile(editor->scriptFile());
    ui.actionSave->setEnabled(false);
    _fileSaved = true;
  } else {
    ui.actionSave->setEnabled(true);
    _fileSaved = false;
  }
}

void Gui::fileSave(const QString &path) {
  if (editor->saveAs(path)) {
    setCurrentFile(editor->scriptFile());
    ui.actionSave->setEnabled(false);
    _fileSaved = true;
  } else {
    ui.actionSave->setEnabled(true);
    _fileSaved = false;
  }
}

void Gui::editPreferences() {
  Prefs *p = new Prefs(settings, this);
  p->setAttribute(Qt::WA_DeleteOnClose);

  connect(p, SIGNAL(fontChanged(QString, uint)), this,
          SLOT(fontChanged(QString, uint)));
  connect(p, SIGNAL(checkOpenLastFileChanged(bool)), this,
          SLOT(setOpenLastFile(bool)));

  // SpaceNavigator 3D mouse navigation settings
  connect(p, &Prefs::snNavigationModeChanged, ui.viewer,
          &Viewer::setSpaceNavigatorMode);
  connect(p, &Prefs::snLockHorizonChanged, ui.viewer,
          &Viewer::setSpaceNavigatorLockHorizon);
  connect(p, &Prefs::snAutoFlySpeedChanged, ui.viewer,
          &Viewer::setSpaceNavigatorAutoFlySpeed);
  connect(p, &Prefs::snShowOrbitAxisChanged, ui.viewer,
          &Viewer::setSpaceNavigatorShowOrbitAxis);
  connect(p, &Prefs::snZoomDirectionChanged, ui.viewer,
          &Viewer::setSpaceNavigatorZoomDirection);
  connect(p, &Prefs::snPanZoomChanged, ui.viewer,
          &Viewer::setSpaceNavigatorPanZoom);

  p->show();
}

void Gui::openRecentFile() {
  QAction *action = qobject_cast<QAction *>(sender());
  if (action) {
    fileLoad(action->data().toString());
  }
}

void Gui::setOpenLastFile(bool checked) {
  settings->setValue("gui/openlastfile", checked);
}

void Gui::fontChanged(const QString &family, uint size) {
  editor->setFont(family, size);
  debugText->setFont(family, size);
  camText->setFont(family, size);
  shortcutsText->setFont(family, size);
}

void Gui::loadSettings() {

  settings->beginGroup("gui");

  if (settings->value("openlastwindowstate", true).toBool()) {
    restoreGeometry(settings->value("geometry", saveGeometry()).toByteArray());
    restoreState(settings->value("state", saveState()).toByteArray());

    if (settings->value("fullscreen", isFullScreen()).toBool()) {
      showFullScreen();
    } else {
      showNormal();
    }

    if (settings->value("maximized", isMaximized()).toBool()) {
      showMaximized();
    }

    // restoreState() redistributes dock/splitter sizes to fit whatever the
    // window's actual size ends up being, which can differ slightly from
    // session to session (window manager chrome, screen changes, etc.) and
    // doesn't reliably preserve this dock's exact width. Re-assert it
    // explicitly so it doesn't drift.
    //
    // loadSettings() itself runs from the Gui constructor, before main()
    // calls show() on it, so resizeDocks() has no real window/layout
    // geometry to work with yet and silently has no effect. Defer it to
    // the next event loop iteration (same trick used for loadLastFile()
    // below), by which point the window is actually shown.
    int luaWidth = settings->value("luaScriptDockWidth", -1).toInt();
    if (luaWidth > 0) {
      QTimer::singleShot(0, this, [this, luaWidth]() {
        resizeDocks({dockLUAScript}, {luaWidth}, Qt::Horizontal);
      });
    }
  }

  // The Parameters panel is essential (it's how you actually control a
  // running simulation), so unlike other docks it's never left to whatever
  // a prior session happened to save -- always force it visible on launch.
  dockParams->setVisible(true);
  // Same reasoning for Shortcuts: it's meant to be an always-visible
  // reference (replacing what used to be an in-scene HUD some scripts
  // built for themselves), not something that silently stays closed
  // because a previous session happened to leave it that way.
  dockShortcuts->setVisible(true);

  {
    QSignalBlocker blocker(renderSettings);
    renderSettings->setCurrentIndex(renderSettings->findText(
        settings->value("renderResolution", "view size").toString()));
  }

  ui.actionToggleDeactivation->setChecked(
      settings->value("deactivationState", true).toBool());

  ui.actionShowConstraints->setChecked(
      settings->value("showConstraints", true).toBool());

  settings->endGroup();
}

void Gui::saveSettings() {
  settings->beginGroup("gui");

  // qDebug() << settings->value("openlastwindowstate", true).toBool();

  if (settings->value("openlastwindowstate", true).toBool()) {

    settings->setValue("geometry", saveGeometry());
    settings->setValue("state", saveState());
    settings->setValue("fullscreen", isFullScreen());
    settings->setValue("maximized", isMaximized());
    settings->setValue("luaScriptDockWidth", dockLUAScript->width());
  }

  QString renderRes = renderSettings->currentText();
  if (renderRes.isEmpty()) {
    renderRes = settings->value("renderResolution", "view size").toString();
  }
  settings->setValue("renderResolution", renderRes);

  settings->setValue("deactivationState",
                     ui.actionToggleDeactivation->isChecked());

  settings->setValue("showConstraints", ui.actionShowConstraints->isChecked());

  settings->endGroup();

  settings->sync();
}

void Gui::moveEvent(QMoveEvent *) {}

void Gui::resizeEvent(QResizeEvent *) {}

void Gui::closeEvent(QCloseEvent *event) {
  // qDebug() << "Gui::closeEvent";
  if (!_fileSaved) {
    event->ignore();

    settings->beginGroup("gui");
    bool dontask = settings->value("dont_ask_unsaved_changes", false).toBool();
    settings->endGroup();

    if (!dontask) {
      msgBox = new QMessageBox(this);
      msgBox->setWindowTitle(tr("Unsaved changes"));
      msgBox->setText(tr("File '%1'\n\nnot saved: exit anyhow?\n")
                          .arg(editor->scriptFile()));
      // msgBox->setIcon(QMessageBox::Icon::Question);
      msgBox->addButton(QMessageBox::No);
      msgBox->addButton(QMessageBox::Yes);
      msgBox->setDefaultButton(QMessageBox::No);

      QCheckBox *check =
          new QCheckBox(tr("Don't show this message again."), this);
      msgBox->setCheckBox(check);

      int32_t answer = msgBox->exec();

      settings->beginGroup("gui");
      settings->setValue("dont_ask_unsaved_changes", check->isChecked());
      settings->endGroup();
      settings->sync();

      msgBox->deleteLater();
      msgBox = nullptr;

      if (answer == QMessageBox::Yes) {
        statusBar()->showMessage(tr("Saving preferences..."));
        statusBar()->repaint();
        saveSettings();
        ui.viewer->close();
        event->accept();
      }
    } else {
      statusBar()->showMessage(tr("Saving preferences..."));
      statusBar()->repaint();
      saveSettings();
      ui.viewer->close();
      event->accept();
    }
  } else {
    statusBar()->showMessage(tr("Saving preferences..."));
    statusBar()->repaint();
    saveSettings();
    ui.viewer->close();
    event->accept();
  }
}

void Gui::command(const QString &cmd) { ui.viewer->command(cmd); }

void Gui::log(const QString &text) { debugText->appendLine(text); }

QString Gui::toString() const { return QString("Gui"); }

void Gui::setStatusBarText(const QString &msg) { statusBar()->showMessage(msg); }

void Gui::showProgressBar(const QString &message) {
  if (!message.isEmpty())
    statusBar()->showMessage(message);
  progressBar->show();
  progressBar->repaint();
}

void Gui::hideProgressBar() {
  progressBar->hide();
  statusBar()->clearMessage();
  statusBar()->repaint();
}

static QString paramTooltip(const QVariant &value, const ParamInfo &info) {
  QString tooltip = info.comment;
  if (!tooltip.isEmpty()) tooltip += "\n";
  tooltip += QString("Value: %1").arg(value.toString());
  if (info.hasRange) {
    tooltip += QString("\nMin: %1  Max: %2").arg(info.min).arg(info.max);
  }
  return tooltip;
}

void Gui::updateParamsTable() {
  if (!paramsTable || !ui.viewer) return;

  QSignalBlocker blocker(paramsTable);

  QHash<QString, QVariant> params = ui.viewer->getParams();

  QStringList names = params.keys();
  names.sort(Qt::CaseInsensitive);

  // If the set/order of param names hasn't changed since the last refresh,
  // update the existing items/widgets in place instead of tearing down and
  // recreating the whole table -- rebuilding on every tick (e.g. while
  // dragging a slider) made the table flicker and interrupted the drag.
  bool sameLayout = (paramsTable->rowCount() == names.size());
  for (int i = 0; sameLayout && i < names.size(); ++i) {
    QTableWidgetItem *nameItem = paramsTable->item(i, 0);
    if (!nameItem || nameItem->text() != names[i]) sameLayout = false;
  }

  if (!sameLayout) {
    paramsTable->clearContents();
    paramsTable->setRowCount(names.size());
  }

  int row = 0;
  for (const QString &name : names) {
    QVariant value = params.value(name);
    ParamInfo info = ui.viewer->getParamInfo(name);
    QString tooltip = paramTooltip(value, info);

    if (sameLayout) {
      paramsTable->item(row, 0)->setToolTip(tooltip);

      if (info.hasRange) {
        double scale = (info.step > 0.0) ? (1.0 / info.step) : 100.0;
        QSlider *slider = qobject_cast<QSlider *>(paramsTable->cellWidget(row, 1));
        QSignalBlocker sliderBlocker(slider);
        slider->setMinimum(qRound(info.min * scale));
        slider->setMaximum(qRound(info.max * scale));
        slider->setValue(qRound(value.toDouble() * scale));
        slider->setProperty("paramScale", scale);
        slider->setToolTip(tooltip);
      } else if (value.type() == QVariant::Bool) {
        QCheckBox *checkBox = paramsTable->cellWidget(row, 1)->findChild<QCheckBox *>();
        QSignalBlocker checkBoxBlocker(checkBox);
        checkBox->setChecked(value.toBool());
        checkBox->setToolTip(tooltip);
      } else {
        QTableWidgetItem *valueItem = paramsTable->item(row, 1);
        valueItem->setText(value.toString());
        valueItem->setData(Qt::UserRole, value);
      }

      row++;
      continue;
    }

    QTableWidgetItem *nameItem = new QTableWidgetItem(name);
    nameItem->setFlags(nameItem->flags() & ~Qt::ItemIsEditable);
    nameItem->setToolTip(tooltip);
    paramsTable->setItem(row, 0, nameItem);

    if (info.hasRange) {
      double scale = (info.step > 0.0) ? (1.0 / info.step) : 100.0;
      QSlider *slider = new QSlider(Qt::Horizontal);
      slider->setObjectName(name);
      slider->setMinimum(qRound(info.min * scale));
      slider->setMaximum(qRound(info.max * scale));
      slider->setValue(qRound(value.toDouble() * scale));
      slider->setProperty("paramName", name);
      slider->setProperty("paramScale", scale);
      slider->setToolTip(tooltip);
      slider->setMouseTracking(true);
      slider->installEventFilter(this);
      connect(slider, &QSlider::valueChanged, this, &Gui::onParamSliderChanged);
      paramsTable->setCellWidget(row, 1, slider);
    } else if (value.type() == QVariant::Bool) {
      QCheckBox *checkBox = new QCheckBox();
      checkBox->setChecked(value.toBool());
      checkBox->setProperty("paramName", name);
      checkBox->setToolTip(tooltip);
      checkBox->setMouseTracking(true);
      checkBox->installEventFilter(this);
      connect(checkBox, &QCheckBox::toggled, this, &Gui::onParamCheckBoxChanged);

      QWidget *cell = new QWidget();
      QHBoxLayout *layout = new QHBoxLayout(cell);
      layout->addWidget(checkBox);
      layout->setAlignment(Qt::AlignCenter);
      layout->setContentsMargins(0, 0, 0, 0);
      paramsTable->setCellWidget(row, 1, cell);
    } else {
      QTableWidgetItem *valueItem = new QTableWidgetItem(value.toString());
      valueItem->setData(Qt::UserRole, value);
      paramsTable->setItem(row, 1, valueItem);
    }

    row++;
  }

  paramsTable->resizeColumnToContents(0);
}

void Gui::onParamsTableCellChanged(int row, int column) {
  if (!paramsTable || !ui.viewer || column != 1) return;

  QTableWidgetItem *nameItem = paramsTable->item(row, 0);
  QTableWidgetItem *valueItem = paramsTable->item(row, 1);

  if (!nameItem || !valueItem) return;

  QString name = nameItem->text();
  QVariant oldValue = valueItem->data(Qt::UserRole);
  QString newValueStr = valueItem->text();

  QVariant newValue;
  if (oldValue.type() == QVariant::Int) {
    newValue = QVariant(newValueStr.toInt());
  } else if (oldValue.type() == QVariant::Double) {
    newValue = QVariant(newValueStr.toDouble());
  } else if (oldValue.type() == QVariant::Bool) {
    newValue = QVariant(newValueStr.toLower() == "true");
  } else {
    newValue = QVariant(newValueStr);
  }

  qDebug() << "GUI cellChanged: " << name << " = " << newValue;
  ui.viewer->addParam(name, newValue);
}

void Gui::onParamSliderChanged(int value) {
  QSlider *slider = qobject_cast<QSlider *>(sender());
  if (!slider || !ui.viewer) return;

  QString name = slider->property("paramName").toString();
  double scale = slider->property("paramScale").toDouble();
  ParamInfo info = ui.viewer->getParamInfo(name);

  // Snap to the exact configured bounds at the ends of the slider -- the
  // int-position <-> btScalar (float) round trip through scale can drift by
  // a hair, which otherwise makes the slider look like it never quite
  // reaches its real min/max.
  double newValue;
  if (value == slider->minimum()) newValue = info.min;
  else if (value == slider->maximum()) newValue = info.max;
  else newValue = value / scale;

  ui.viewer->addParam(name, newValue, info.min, info.max, info.step, info.comment);
}

void Gui::onParamCheckBoxChanged(bool checked) {
  QCheckBox *checkBox = qobject_cast<QCheckBox *>(sender());
  if (!checkBox || !ui.viewer) return;

  QString name = checkBox->property("paramName").toString();
  ui.viewer->addParam(name, QVariant(checked));
}

// Qt's default tooltip only repositions when a fresh QEvent::ToolTip fires,
// which is suppressed while the cursor stays within the same item/widget --
// so it goes stale as the mouse keeps moving across a wide row. Explicitly
// re-showing it on every mouse move keeps it glued to the cursor instead.
bool Gui::eventFilter(QObject *obj, QEvent *event) {
  if (event->type() == QEvent::MouseMove) {
    if (obj == paramsTable->viewport()) {
      QMouseEvent *me = static_cast<QMouseEvent *>(event);
      QTableWidgetItem *item = paramsTable->itemAt(me->pos());
      if (item && !item->toolTip().isEmpty()) {
        QToolTip::showText(paramsTable->viewport()->mapToGlobal(me->pos()), item->toolTip(), paramsTable);
      }
    } else if (QWidget *w = qobject_cast<QWidget *>(obj)) {
      if (!w->toolTip().isEmpty()) {
        QToolTip::showText(QCursor::pos(), w->toolTip(), w);
      }
    }
  }
  return QMainWindow::eventFilter(obj, event);
}
