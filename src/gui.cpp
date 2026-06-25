#include "prefs.h"

#include <Qt>

#include "gui.h"

#include <QProgressBar>
#include <QDir>
#include <QFileInfo>

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

  settings->beginGroup("mainwindow");
  settings->setValue("lastFile", path);
  settings->endGroup();
  settings->sync();

#ifndef QT_NO_CURSOR
  QApplication::setOverrideCursor(Qt::WaitCursor);
#endif

  if (editor->load(path)) {
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

  updateRecentFileActions();
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

  if (fileName == "no_name") {
    return;
  }

  QStringList files = settings->value("recentFileList").toStringList();
  files.removeAll(fileName);
  files.prepend(fileName);
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
  paramsTable->setItemDelegate(new QItemDelegate());
  dw5->setWidget(paramsTable);
  addDockWidget(Qt::RightDockWidgetArea, dw5);
  paramsTable->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(paramsTable, &QTableWidget::cellChanged, this, &Gui::onParamsTableCellChanged);
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

      if (answer == QMessageBox::No) {
        return;
      }
    }
  }

  editor->load(path);
  ui.viewer->clearParams();
  setCurrentFile(editor->scriptFile());
  ui.actionSave->setEnabled(false);

  _fileSaved = true;
}

void Gui::fileReload() {
  editor->blockSignals(true);
  editor->load(editor->scriptFile());
  editor->blockSignals(false);
  ui.viewer->clearParams();
  setCurrentFile(editor->scriptFile());
  ui.actionSave->setEnabled(false);

  _fileSaved = true;
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

  connect(p, SIGNAL(fontChanged(QString, uint)), this,
          SLOT(fontChanged(QString, uint)));
  connect(p, SIGNAL(checkOpenLastFileChanged(bool)), this,
          SLOT(setOpenLastFile(bool)));

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
}

void Gui::loadSettings() {

  settings->beginGroup("gui");

  if (settings->value("openlastwindowstate", true).toBool()) {
    restoreGeometry(settings->value("geometry", saveGeometry()).toByteArray());
    restoreState(settings->value("state", saveState()).toByteArray());
    move(settings->value("pos", pos()).toPoint());
    resize(settings->value("size", size()).toSize());

    if (settings->value("fullscreen", isFullScreen()).toBool()) {
      showFullScreen();
    } else {
      showNormal();
    }

    if (settings->value("maximized", isMaximized()).toBool()) {
      showMaximized();
    }
  }

  renderSettings->setCurrentIndex(renderSettings->findText(
      settings->value("renderResolution", "view size").toString()));

  ui.actionToggleDeactivation->setChecked(
      settings->value("deactivationState", true).toBool());

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

    if (!isMaximized() && !isFullScreen()) {
      settings->setValue("pos", pos());
      settings->setValue("size", size());
    }
  }

  QString renderRes = renderSettings->currentText();
  if (renderRes.isEmpty()) {
    renderRes = settings->value("renderResolution", "view size").toString();
  }
  settings->setValue("renderResolution", renderRes);

  settings->setValue("deactivationState",
                     ui.actionToggleDeactivation->isChecked());

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

      if (answer == QMessageBox::Yes) {
        saveSettings();
        ui.viewer->close();
        event->accept();
      }
    } else {
      saveSettings();
      ui.viewer->close();
      event->accept();
    }
  } else {
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

void Gui::updateParamsTable() {
  if (!paramsTable || !ui.viewer) return;

  QSignalBlocker blocker(paramsTable);

  QHash<QString, QVariant> params = ui.viewer->getParams();

  paramsTable->setRowCount(params.size());

  int row = 0;
  for (auto it = params.constBegin(); it != params.constEnd(); ++it) {
    QTableWidgetItem *nameItem = new QTableWidgetItem(it.key());
    nameItem->setFlags(nameItem->flags() & ~Qt::ItemIsEditable);
    paramsTable->setItem(row, 0, nameItem);

    ParamInfo info = ui.viewer->getParamInfo(it.key());
    if (info.hasRange) {
      QSlider *slider = new QSlider(Qt::Horizontal);
      slider->setObjectName(it.key());
      slider->setMinimum(info.min * 100);
      slider->setMaximum(info.max * 100);
      slider->setValue(it.value().toDouble() * 100);
      slider->setProperty("paramName", it.key());
      connect(slider, &QSlider::valueChanged, this, &Gui::onParamSliderChanged);
      paramsTable->setCellWidget(row, 1, slider);
    } else {
      QTableWidgetItem *valueItem = new QTableWidgetItem(it.value().toString());
      valueItem->setData(Qt::UserRole, it.value());
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
  ui.viewer->addParam(name, QVariant(value/100.0));
}
