#include "prefs.h"

#include "gui.h"

#define APP_VERSION QString("v0.0.2")
#define APP_NAME QString("physics")
#define APP_NAME_FULL tr("Bullet Physics Playground")
#define APP_ORGANIZATION QString("koppi.me")

std::ostream& operator<<(std::ostream& ostream, const Gui& gui) {
  ostream << gui.toString().toAscii().data();
  return ostream;
}

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Gui::Gui(QWidget *parent) : QMainWindow(parent) {
  _fileSaved=true;
  _simulationRunning=false;

  ui.setupUi(this);

  settings = new QSettings(APP_ORGANIZATION, APP_NAME);

  ui.viewer->setSettings(settings);

  createDock();

  createActions();
  createMenus();
  setStatusBar( new QStatusBar(this) );

  connect(editor, SIGNAL(textChanged()), this, SLOT(scriptChanged()));

  // map user defined shortcuts to the viewer sub-window
  connect(editor, SIGNAL(keyPressed(QKeyEvent *)), ui.viewer, SLOT(keyPressEvent(QKeyEvent *)));
  connect(commandLine, SIGNAL(keyPressed(QKeyEvent *)), ui.viewer, SLOT(keyPressEvent(QKeyEvent *)));
  connect(debugText, SIGNAL(keyPressed(QKeyEvent *)), ui.viewer, SLOT(keyPressEvent(QKeyEvent *)));

  connect(ui.viewer, SIGNAL(scriptHasOutput(QString)), this, SLOT(debug(QString)));
  connect(ui.viewer, SIGNAL(scriptStarts()), this, SLOT(clearDebug()));
  connect(ui.viewer, SIGNAL(simulationStateChanged(bool)), this, SLOT(toggleSimButton(bool)));
  connect(ui.viewer, SIGNAL(POVStateChanged(bool)), this, SLOT(togglePOVExport(bool)));
  connect(ui.viewer, SIGNAL(PNGStateChanged(bool)), this, SLOT(toggleScreenshotExport(bool)));
  connect(ui.viewer, SIGNAL(deactivationStateChanged(bool)), this, SLOT(toggleDeactivation(bool)));

  connect(ui.viewer, SIGNAL(statusEvent(QString)), this, SLOT(setStatusBarText(QString)));

  connect(commandLine, SIGNAL(execute(QString)), this, SLOT(command(QString)));

  loadSettings();

  connect(ui.viewer, SIGNAL(postDrawShot(int)), this, SLOT(postDraw(int)));
  // commandLine->setFocus();

  fileNew();

  QTimer::singleShot(0, this, SLOT(loadLastFile()));
}

void Gui::toggleSimButton(bool simRunning) {
  if(simRunning){
    QIcon playIcon = QIcon::fromTheme("media-playback-pause");
    ui.actionToggleSim->setIcon(playIcon);
    ui.actionToggleSim->setText(tr("Pause &Simulation"));
    ui.actionToggleSim->setShortcut(tr("Ctrl+S"));
    ui.actionToggleSim->setStatusTip(tr("Pause Simulation"));
    ui.actionToggleSim->setChecked(true);
    _simulationRunning=true;
  }else{
    QIcon playIcon = QIcon::fromTheme("media-playback-start");
    ui.actionToggleSim->setIcon(playIcon);
    ui.actionToggleSim->setText(tr("&Run simulation.."));
    ui.actionToggleSim->setShortcut(tr("Ctrl+S"));
    ui.actionToggleSim->setStatusTip(tr("Run Simulation"));
    ui.actionToggleSim->setChecked(false);
    _simulationRunning=false;
  }
}

void Gui::togglePOVExport(bool p) {
  ui.viewer->toggleSavePOV(p);
  ui.actionTogglePOVExport->setChecked(p);
}

void Gui::toggleScreenshotExport(bool p) {
  ui.viewer->toggleSavePNG(p);

  ui.actionTogglePNGScreenshot->setChecked(p);
}

void Gui::toggleDeactivation(bool d) {
  ui.viewer->toggleDeactivation(d);
  ui.actionToggleDeactivation->setChecked(d);
}


void Gui::postDraw(int frame) {
  //QPixmap p = QPixmap::grabWidget(this);

  /*
  if (savePNG) {
    QPixmap p = QPixmap::grabWindow(this->winId());

    QString file;
    file.sprintf("screenshots/w-%05d.png", frame);

    qDebug() << "saving screenshot " << file;

    p.save(file, "png");
  }
  */

}

void Gui::dragEnterEvent(QDragEnterEvent *event) {
  if (event->mimeData()->hasFormat("text/uri-list")) {
    event->acceptProposedAction();
  }
}

void Gui::dropEvent(QDropEvent *event) {
  QList<QUrl> urls = event->mimeData()->urls();

  if (urls.isEmpty()) return;

  QString filePath = urls.first().toLocalFile();

  if (filePath.isEmpty()) return;

  fileLoad(filePath);

  event->acceptProposedAction();
}

void Gui::loadLastFile() {
  QString lastFile;

  settings->beginGroup( "mainwindow" );
  lastFile = settings->value( "lastFile", "").toString();
  settings->endGroup();

  if (lastFile != "") {
    fileLoad(lastFile);
  } else {
    fileLoad(":demo/00-objects.lua");
  }
}

void Gui::fileLoad(const QString &path) {
  QFile file(path);

  settings->beginGroup( "mainwindow" );
  settings->setValue( "lastFile", path);
  settings->endGroup();

#ifndef QT_NO_CURSOR
  QApplication::setOverrideCursor(Qt::WaitCursor);
#endif

  if (editor->load(path)) {
    setCurrentFile(path);
    setWindowTitle(tr("%1 - %2").arg(APP_NAME_FULL).arg(file.fileName()));
    parseEditor();
    statusBar()->showMessage(tr("File loaded"), 2000);
    _fileSaved = true;
    ui.actionSave->setEnabled(false);
  } else {
    setWindowTitle(tr("%1 %2").arg(APP_NAME_FULL).arg(APP_VERSION));
    statusBar()->showMessage(tr("Error loading File %1").arg(path), 5000);
  }

#ifndef QT_NO_CURSOR
  QApplication::restoreOverrideCursor();
#endif
}

void Gui::createActions() {
  for (int i = 0; i < MAX_RECENT_FILES; ++i) {
    recentFileActions[i] = new QAction(this);
    recentFileActions[i]->setVisible(false);
    connect(recentFileActions[i], SIGNAL(triggered()),
            this, SLOT(openRecentFile()));
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

  ui.viewer->setScriptName(strippedNameNoExt(editor->script_filename));

  if (editor->script_filename.isEmpty())
    setWindowTitle(tr("Recent Files"));
  else
    setWindowTitle(tr("%1 %2 - %3").arg(APP_NAME_FULL).arg(APP_VERSION).arg(strippedName(editor->script_filename)));

  if (fileName == "no_name") {
      return;
  }

  QStringList files = settings->value("recentFileList").toStringList();
  files.removeAll(fileName);
  files.prepend(fileName);
  while (files.size() > MAX_RECENT_FILES)
    files.removeLast();

  settings->setValue("recentFileList", files);

  foreach (QWidget *widget, QApplication::topLevelWidgets()) {
    Gui *mainWin = qobject_cast<Gui *>(widget);
    if (mainWin)
      mainWin->updateRecentFileActions();
  }
}

void Gui::createDock() {
  QDockWidget* dw1 = new QDockWidget(this);
  dw1->setObjectName("DockDebug");
  dw1->setWindowTitle("Debug");
  dw1->setTitleBarWidget(new QWidget(this));

  debugText = new CodeEditor(this, APP_ORGANIZATION, APP_NAME);
  dw1->setWidget(debugText);
  debugText->setReadOnly(true);

  addDockWidget(Qt::BottomDockWidgetArea, dw1);

  QDockWidget *dw2 = new QDockWidget(this);
  dw2->setObjectName("DockLUAScript");
  dw2->setWindowTitle("LUA Script");
  editor = new CodeEditor(this, APP_ORGANIZATION, APP_NAME);
  dw2->setWidget(editor);

  addDockWidget(Qt::RightDockWidgetArea, dw2);

  QDockWidget *dw3 = new QDockWidget(this);
  dw3->setObjectName("DockCommandLine");
  dw3->setWindowTitle("Command Line");
  commandLine = new CommandLine(this);
  dw3->setWidget(commandLine);

  // hide cmdline by default - the last state is restored via prefs or gui:showCommandLine() Lua function
  addDockWidget(Qt::RightDockWidgetArea, dw3);
  dw3->setVisible(false);
}

void Gui::helpAbout() {
    QString txt =

    tr("<p><b>%1 (%2)</b></p>").arg(APP_NAME_FULL).arg(APP_VERSION) + \
    tr("<p>Build: %1 - %2</p>").arg(BUILDDATE).arg(BUILDTIME) + \
    tr("<p>&copy; 2008-2013 <a href=\"http://github.com/koppi\">Jakob Flierl</a></p>") + \
    tr("<p>&copy; 2012-2013 <a href=\"http://ignorancia.org/\">Jaime Vives Piqueres</a></p>") + \
    tr("<p>Using: <ul><li>GLEW %1</li><li>OpenGL %2</li></ul></p>").
            arg((const char*) glewGetString(GLEW_VERSION)).
            arg((const char*) glGetString(GL_VERSION));

  QMessageBox::about(this, tr("About"), txt);
}

QString Gui::strippedName(const QString &fullFileName) {
  return QFileInfo(fullFileName).fileName();
}

QString Gui::strippedNameNoExt(const QString &fullFileName) {
  return QFileInfo(fullFileName).baseName();
}

void Gui::scriptChanged() {
  ui.actionSave->setEnabled(true);
  _fileSaved=false;
  parseEditor();
}

void Gui::parseEditor() {
  ui.viewer->parse(editor->toPlainText());
}

void Gui::animStarted() {
}

void Gui::animProgress(QString, int) {
}

void Gui::animFinished() {

}

void Gui::debug(QString txt) {
  debugText->appendLine(txt);
}

void Gui::clearDebug() {
  debugText->clear();
}

void Gui::fileNew() {
  if(!_fileSaved){
    msgBox = new QMessageBox(this);
    msgBox->setWindowTitle("Warning");
    msgBox->setText("Current file not saved: continue anyhow?");
    QPushButton *yesButton = msgBox->addButton(tr("Yes"), QMessageBox::ActionRole);
    msgBox->addButton(tr("No"), QMessageBox::ActionRole);
    msgBox->exec();
    if ((QPushButton*)msgBox->clickedButton() != yesButton){
    return;
    }
  }
  editor->clear();
  setCurrentFile(editor->script_filename);
  ui.actionSave->setEnabled(true);
  _fileSaved=true;
}

void Gui::fileOpen(const QString& path) {
  if(!_fileSaved){
    msgBox = new QMessageBox(this);
    msgBox->setWindowTitle("Warning");
    msgBox->setText("Current file not saved: continue anyhow?");
    QPushButton *yesButton = msgBox->addButton(tr("Yes"), QMessageBox::ActionRole);
    msgBox->addButton(tr("No"), QMessageBox::ActionRole);
    msgBox->exec();
    if ((QPushButton*)msgBox->clickedButton() != yesButton){
    return;
    }
  }
  editor->load(path);
  setCurrentFile(editor->script_filename);
  ui.actionSave->setEnabled(false);
  _fileSaved=true;
}

void Gui::fileSave() {
  if (editor->save()) {
    setCurrentFile(editor->script_filename);
    ui.actionSave->setEnabled(false);
    _fileSaved=true;
  } else {
    ui.actionSave->setEnabled(true);
    _fileSaved=false;
  }
}

void Gui::fileSaveAs() {
  if (editor->saveAs()) {
    setCurrentFile(editor->script_filename);
    ui.actionSave->setEnabled(false);
    _fileSaved=true;
  } else {
    ui.actionSave->setEnabled(true);
    _fileSaved=false;
  }
}

void Gui::fileSave(const QString& path) {
  if (editor->saveAs(path)) {
    setCurrentFile(editor->script_filename);
    ui.actionSave->setEnabled(false);
    _fileSaved=true;
  } else {
    ui.actionSave->setEnabled(true);
    _fileSaved=false;
  }
}

void Gui::editPreferences() {
  Prefs *p = new Prefs(this, 0, APP_ORGANIZATION, APP_NAME);

  connect(p, SIGNAL(fontChanged(QString, uint)),
          this, SLOT(fontChanged(QString, uint)));

  p->show();
}

void Gui::openRecentFile() {
  QAction *action = qobject_cast<QAction *>(sender());
  if (action) {
    fileLoad(action->data().toString());
  }
}

void Gui::fontChanged(const QString& family, uint size) {
  editor->setFont(family, size);
  debugText->setFont(family, size);
}

void Gui::loadSettings() {
  settings->beginGroup("gui");

  restoreGeometry(settings->value("geometry", saveGeometry() ).toByteArray());
  restoreState(settings->value("state", saveState() ).toByteArray());
  move(settings->value("pos", pos()).toPoint());
  resize(settings->value("size", size()).toSize());

  if ( settings->value("maximized", isMaximized() ).toBool()) {
    showMaximized();
  }

  settings->endGroup();
}

void Gui::saveSettings() {
  settings->beginGroup("gui");

  settings->setValue("geometry", saveGeometry());
  settings->setValue("state", saveState());
  settings->setValue("maximized", isMaximized());

  if ( !isMaximized() ) {
    settings->setValue("pos", pos());
    settings->setValue("size", size());
  }

  settings->endGroup();
}

void Gui::moveEvent(QMoveEvent *) {
}

void Gui::resizeEvent(QResizeEvent *) {
}

void Gui::closeEvent(QCloseEvent * event) {
  // qDebug() << "Gui::closeEvent";
  if(!_fileSaved){
    event->ignore();
    msgBox = new QMessageBox(this);
    msgBox->setWindowTitle("Warning");
    msgBox->setText("File not saved: exit anyhow?");
    QPushButton *yesButton = msgBox->addButton(tr("Yes"), QMessageBox::ActionRole);
    msgBox->addButton(tr("No"), QMessageBox::ActionRole);
    msgBox->exec();
    if ((QPushButton*)msgBox->clickedButton() == yesButton){
      saveSettings();
      ui.viewer->close();
      event->accept();
    }
  }else{
    saveSettings();
    ui.viewer->close();
  }
}

void Gui::command(QString cmd) {
  // log("> " + cmd);

  /*
  if (cmd.startsWith("home")) {
    log("moving into home position.");
    ui.viewer->rm->cmdHome();
  } else if (cmd.startsWith("m")) {
    QStringList s = cmd.split(" ");
    double x = s.at(1).toDouble();
    double y = s.at(2).toDouble();
    double z = s.at(3).toDouble();

    log(QString("moving to <%1, %2, %3>.").arg(x).arg(y).arg(z));

    ui.viewer->rm->cmdMoveTo(x, y, z);
  } else if (cmd.startsWith("?") || cmd.startsWith("help")) {
    log("available commands:");
    log(" - home ");
    log(" - move [x][y][z] move end effector to <x,y,z>");
    }*/

  ui.viewer->command(cmd);
}

void Gui::log(QString text) {
  debugText->appendLine(text);
}

QString Gui::toString() const {
  return QString("Gui");
}

void Gui::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
  [
   class_<Gui>("Gui")
   .def(constructor<>())
   .def(tostring(const_self))
  ];
}

void Gui::setStatusBarText(QString msg) {
    statusBar()->showMessage(msg);
}
