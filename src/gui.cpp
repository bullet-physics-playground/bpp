#include "gui.h"

#define APP_VERSION QString("v1.0.1")
#define APP_NAME QString("physics")
#define APP_NAME_FULL tr("Bullet Physics Playground")

Gui::Gui(bool savePNG, bool savePOV, QWidget *parent) : QMainWindow(parent) {
  _fileSaved=true;
  _simulationRunning=false;
	
  ui.setupUi(this);

  setMinimumSize(800, 600);

  // setAttribute(Qt::WA_DeleteOnClose);
  // setWindowTitle(tr("%1 %2").arg(APP_NAME_FULL).arg(APP_VERSION));
  setWindowIcon(QIcon(":icons/icon.svg"));

  ui.viewer->setSavePNG(savePNG);
  ui.viewer->setSavePOV(savePOV);

  setAcceptDrops(true);

  settings = new QSettings("koppi.me", APP_NAME);

  createDock();

#ifdef WIN32_LINK_THEME
  if (!QIcon::hasThemeIcon("document-new")) {
    QIcon::setThemeName("humanity");
  }
#endif

  createActions();
  createMenus();
  setStatusBar( new QStatusBar(this) );

  createToolBar();

  this->savePNG = savePNG;
  this->savePOV = savePOV;

  connect(editor, SIGNAL(textChanged()), this, SLOT(scriptChanged()));

  connect(ui.viewer, SIGNAL(scriptHasOutput(QString)), this, SLOT(debug(QString)));
  connect(ui.viewer, SIGNAL(simulationStateChanged(bool)), this, SLOT(toggleSimButton(bool)));
  connect(ui.viewer, SIGNAL(POVStateChanged(bool)), this, SLOT(togglePOVButton(bool)));
  connect(ui.viewer, SIGNAL(PNGStateChanged(bool)), this, SLOT(togglePNGButton(bool)));
  connect(ui.viewer, SIGNAL(deactivationStateChanged(bool)), this, SLOT(toggleDeactivationButton(bool)));

  //  ui.cmdline->setFocus();

  //  connect(ui.cmdline, SIGNAL(execute(QString)), this, SLOT(command(QString)));

  loadSettings();

  connect(ui.viewer, SIGNAL(postDrawShot(int)), this, SLOT(postDraw(int)));

  QTimer::singleShot(0, this, SLOT(loadLastFile()));
  newFile();
}

void Gui::toggleSimButton(bool simRunning) {
  if(simRunning){
    QIcon playIcon = QIcon::fromTheme("media-playback-pause");	  
    playAction->setIcon(playIcon);
    playAction->setText(tr("Pause &Simulation"));
    playAction->setShortcut(tr("Ctrl+C"));
    playAction->setStatusTip(tr("Pause Simulation"));
    playAction->setChecked(true);
    _simulationRunning=true;
  }else{
    QIcon playIcon = QIcon::fromTheme("media-playback-start");
    playAction->setIcon(playIcon);
    playAction->setText(tr("&Run simulation.."));
    playAction->setShortcut(tr("Ctrl+P"));
    playAction->setStatusTip(tr("Run Simulation"));
    playAction->setChecked(false);
    _simulationRunning=false;
  }
}

void Gui::togglePOVButton(bool enabledPOV) {
  if(enabledPOV){
    povAction->setChecked(true);
  }else{
    povAction->setChecked(false);
  }
}

void Gui::togglePNGButton(bool enabledPNG) {
  if(enabledPNG){
    pngAction->setChecked(true);
  }else{
    pngAction->setChecked(false);
  }
}

void Gui::toggleDeactivationButton(bool enabledDeactivation) {
  if(enabledDeactivation){
    deactivationAction->setChecked(true);
  }else{
    deactivationAction->setChecked(false);
  }
}


void Gui::postDraw(int frame) {
  //QPixmap p = QPixmap::grabWidget(this);

  if (savePNG) {
	QPixmap p = QPixmap::grabWindow(this->winId());
	
	QString file;
	file.sprintf("screenshots/w-%05d.png", frame);
	
	qDebug() << "saving screenshot " << file;
	
	p.save(file, "png");
  }

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

  loadFile(filePath);

  event->acceptProposedAction();
}

void Gui::loadLastFile() {
  QString lastFile;

  settings->beginGroup( "mainwindow" );
  lastFile = settings->value( "lastFile", "").toString();
  settings->endGroup();

  if (lastFile != "") {
    loadFile(lastFile);
  } else {
    loadFile(":demo/00-objects.lua");
  }
}

void Gui::loadFile(const QString &path) {
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
  } else {
    setWindowTitle(tr("%1 %2").arg(APP_NAME_FULL).arg(APP_VERSION));
    statusBar()->showMessage(tr("Error loading File %1").arg(path), 5000);
  }

#ifndef QT_NO_CURSOR
  QApplication::restoreOverrideCursor();
#endif
}

void Gui::createToolBar() {
  myToolBar = new QToolBar(this);
  myToolBar->setWindowTitle("Toolbar Main");
  myToolBar->setObjectName("ToolBarMain");

  myToolBar->addAction( newAction );
  myToolBar->addAction( openAction );
  myToolBar->addAction( saveAction );
  myToolBar->addAction( saveAsAction );
  myToolBar->addSeparator();
  myToolBar->addAction( cutAction );
  myToolBar->addAction( copyAction );
  myToolBar->addAction( pasteAction );
  myToolBar->addAction( prefsAction );
  myToolBar->addSeparator();
  myToolBar->addAction( playAction );
  myToolBar->addAction( restartAction );
  myToolBar->addSeparator();
  myToolBar->addAction( povAction );
  myToolBar->addAction( pngAction );
  myToolBar->addAction( deactivationAction );
  myToolBar->addSeparator();
  myToolBar->addAction( resetAction );

  addToolBar( myToolBar );
}

void Gui::createActions() {
  QIcon newIcon = QIcon::fromTheme("document-new");
  newAction = new QAction(newIcon,tr("&New"), this);
  newAction->setShortcut(tr("Ctrl+N"));
  newAction->setStatusTip(tr("Create a new file"));
  connect(newAction, SIGNAL(triggered()), this, SLOT(newFile()));

  QIcon openIcon = QIcon::fromTheme("document-open" );
  openAction = new QAction(openIcon, tr("&Open..."), this);
  openAction->setShortcut(tr("Ctrl+O"));
  openAction->setStatusTip(tr("Open an existing file"));
  connect(openAction, SIGNAL(triggered()), this, SLOT(openFile()));

  QIcon saveIcon = QIcon::fromTheme("document-save" );
  saveAction = new QAction(saveIcon, tr("&Save.."), this);
  saveAction->setShortcut(tr("Ctrl+S"));
  saveAction->setStatusTip(tr("Save file"));
  connect(saveAction, SIGNAL(triggered()), this, SLOT(save()));

  QIcon saveAsIcon = QIcon::fromTheme("document-save-as" );
  saveAsAction = new QAction(saveAsIcon, tr("&Save As.."), this);
  saveAsAction->setShortcut(tr("Ctrl+A"));
  saveAsAction->setStatusTip(tr("Save file as.."));
  connect(saveAsAction, SIGNAL(triggered()), this, SLOT(saveAs()));

  cutAction = new QAction(QIcon::fromTheme("edit-cut"), tr("Cu&t"), this);
  cutAction->setShortcuts(QKeySequence::Cut);
  cutAction->setStatusTip(tr("Cut the current selection's contents to the clipboard"));
  connect(cutAction, SIGNAL(triggered()), editor, SLOT(cut()));

  copyAction = new QAction(QIcon::fromTheme("edit-copy"), tr("&Copy"), this);
  copyAction->setShortcuts(QKeySequence::Copy);
  copyAction->setStatusTip(tr("Copy the current selection's contents to the clipboard"));
  connect(copyAction, SIGNAL(triggered()), editor, SLOT(copy()));

  pasteAction = new QAction(QIcon::fromTheme("edit-paste"), tr("&Paste"), this);
  pasteAction->setShortcuts(QKeySequence::Paste);
  pasteAction->setStatusTip(tr("Paste the clipboard's contents into the current selection"));
  connect(pasteAction, SIGNAL(triggered()), editor, SLOT(paste()));
  cutAction->setEnabled(false);
  copyAction->setEnabled(false);
  connect(editor, SIGNAL(copyAvailable(bool)), cutAction, SLOT(setEnabled(bool)));
  connect(editor, SIGNAL(copyAvailable(bool)), copyAction, SLOT(setEnabled(bool)));

  prefsAction = new QAction(QIcon::fromTheme("preferences-system"), tr("&Preferences.."), this);
  prefsAction->setShortcut(tr("Ctrl+P"));
  prefsAction->setStatusTip(tr("Edit application preferences"));
  connect(prefsAction, SIGNAL(triggered()), this, SLOT(editPrefs()));

  exitAction = new QAction(tr("E&xit"), this);
  exitAction->setShortcut(tr("Ctrl+X"));
  exitAction->setStatusTip(tr("Exit the application"));
  connect(exitAction, SIGNAL(triggered()), this, SLOT(close()));

  aboutAction = new QAction(tr("&About"), this);
  aboutAction->setStatusTip(tr("Show the application's About box"));
  connect(aboutAction, SIGNAL(triggered()), this, SLOT(about()));

  QIcon playIcon = QIcon::fromTheme("media-playback-start");
  playAction = new QAction(playIcon,tr("&Run simulation.."), this);
  playAction->setShortcut(tr("Ctrl+P"));
  playAction->setStatusTip(tr("Run Simulation"));
  playAction->setCheckable(true);
  connect(playAction, SIGNAL(triggered()), this, SLOT( toggleSim() ));
  //connect(playAction, SIGNAL(triggered()), this, SLOT( runProgram() ));

  /*QIcon stopIcon = QIcon::fromTheme("media-playback-pause");
  stopAction = new QAction(stopIcon,tr("Pause &Simulation"), this);
  stopAction->setShortcut(tr("Ctrl+C"));
  stopAction->setStatusTip(tr("Pause Simulation"));
  stopAction->setCheckable(true);
  connect(stopAction, SIGNAL(triggered()), this, SLOT( stopProgram() ));*/

  QIcon restartIcon = QIcon::fromTheme("view-refresh");
  restartAction = new QAction(restartIcon,tr("&Restart Simulation"), this);
  restartAction->setShortcut(tr("Ctrl+R"));
  restartAction->setStatusTip(tr("Restart Simulation"));
  connect(restartAction, SIGNAL(triggered()), this, SLOT( rerunProgram() ));

  QIcon povIcon = QIcon(":icons/povray.png");
  povAction = new QAction(povIcon,tr("Toggle &POV export"), this);
  povAction->setShortcut(tr("Ctrl+R"));
  povAction->setStatusTip(tr("Toggle POV export"));
  povAction->setCheckable(true);
  connect(povAction, SIGNAL(triggered()), this, SLOT( toggleExport() ));

  QIcon pngIcon = QIcon::fromTheme("camera");
  pngAction = new QAction(pngIcon,tr("Toggle PNG &screenshot saving"), this);
  pngAction->setShortcut(tr("Ctrl+R"));
  pngAction->setStatusTip(tr("Toggle PNG screenshot saving"));
  pngAction->setCheckable(true);
  connect(pngAction, SIGNAL(triggered()), this, SLOT( toggleScreenshots() ));

  QIcon deactivationIcon = QIcon(":icons/deactivation.png");
  deactivationAction = new QAction(deactivationIcon,tr("Toggle &deactivation state"), this);
  deactivationAction->setShortcut(tr("Ctrl+R"));
  deactivationAction->setStatusTip(tr("Toggle deactivation state"));
  deactivationAction->setCheckable(true);
  deactivationAction->setChecked(true);
  connect(deactivationAction, SIGNAL(triggered()), this, SLOT( toggleDeactivationState() ));

  QIcon resetIcon = QIcon::fromTheme("go-home");
  resetAction = new QAction(resetIcon,tr("Reset &camera view to initial state"), this);
  resetAction->setShortcut(tr("Ctrl+R"));
  resetAction->setStatusTip(tr("Reset camera view to initial state"));
  connect(resetAction, SIGNAL(triggered()), this, SLOT( resetCamera() ));

  for (int i = 0; i < MAX_RECENT_FILES; ++i) {
    recentFileActions[i] = new QAction(this);
    recentFileActions[i]->setVisible(false);
    connect(recentFileActions[i], SIGNAL(triggered()),
            this, SLOT(openRecentFile()));
  }
}

void Gui::createMenus() {
  fileMenu = menuBar()->addMenu( tr("&File") );
  fileMenu->addAction( newAction );
  fileMenu->addAction( openAction );
  fileMenu->addSeparator();
  fileMenu->addAction( saveAction );
  fileMenu->addAction( saveAsAction );
  separatorAction = fileMenu->addSeparator();
  for (int i = 0; i < MAX_RECENT_FILES; ++i)
    fileMenu->addAction(recentFileActions[i]);
  fileMenu->addSeparator();
  fileMenu->addAction( exitAction );

  updateRecentFileActions();

  editMenu = new QMenu(tr("E&dit"));
  editAction = menuBar()->addMenu(editMenu);
  editMenu->addAction(cutAction);
  editMenu->addAction(copyAction);
  editMenu->addAction(pasteAction);
  editMenu->addSeparator();
  editMenu->addAction(prefsAction);

  helpMenu = new QMenu(tr("&Help"));
  helpAction = menuBar()->addMenu(helpMenu);
  helpMenu->addAction(aboutAction);
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

  separatorAction->setVisible(numRecentFiles > 0);
}

void Gui::setCurrentFile(const QString &fileName) {

  ui.viewer->setScriptName(strippedNameNoExt(editor->script_filename));

  if (editor->script_filename.isEmpty())
    setWindowTitle(tr("Recent Files"));
  else
    setWindowTitle(tr("%1 %2 - %3").arg(APP_NAME_FULL).arg(APP_VERSION).arg(strippedName(editor->script_filename)));

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

  debugText = new CodeEditor(this);
  dw1->setWidget(debugText);
  debugText->setReadOnly(true);

  addDockWidget(Qt::BottomDockWidgetArea, dw1);

  QDockWidget *dw2 = new QDockWidget(this);
  dw2->setObjectName("DockLUAScript");
  dw2->setWindowTitle("LUA Script");
  editor = new CodeEditor(this);
  dw2->setWidget(editor);

  addDockWidget(Qt::RightDockWidgetArea, dw2);

  // tabifyDockWidget(dw2, dw3);
}

void Gui::about() {
    QString txt =

    tr("<p><b>%1 (%2)</b></p>").arg(APP_NAME_FULL).arg(APP_VERSION) + \
    tr("<p>Build: %1 - %2</p>").arg(BUILDDATE).arg(BUILDTIME) + \
    tr("<p>&copy; 2008-2012 <a href=\"https://github.com/koppi\">Jakob Flierl</a></p>") + \
    tr("<p>&copy; 2012 <a href=\"http://ignorancia.org/\">Jaime Vives Piqueres</a></p>");

  QMessageBox::about(this, tr("About"), txt);
}

QString Gui::strippedName(const QString &fullFileName) {
  return QFileInfo(fullFileName).fileName();
}

QString Gui::strippedNameNoExt(const QString &fullFileName) {
  return QFileInfo(fullFileName).baseName();
}

void Gui::scriptChanged() {
  saveAction->setEnabled(true);
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

void Gui::newFile() {
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
  saveAction->setEnabled(false);
  _fileSaved=true;
}

void Gui::openFile(const QString& path) {
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
  saveAction->setEnabled(false);
  _fileSaved=true;
}

void Gui::save() {
  editor->save();
  saveAction->setEnabled(false);
  _fileSaved=true;
}

void Gui::saveAs() {
  editor->saveAs();
  setCurrentFile(editor->script_filename);
  saveAction->setEnabled(true);
  _fileSaved=true;
}

void Gui::saveFile(const QString& path) {
  editor->saveAs(path);
  setCurrentFile(editor->script_filename);
  saveAction->setEnabled(false);
  _fileSaved=true;
}

void Gui::editPrefs() {
}

void Gui::openRecentFile() {
  QAction *action = qobject_cast<QAction *>(sender());
  if (action) {
    loadFile(action->data().toString());
  }
}

void Gui::fontChanged(const QString& family, uint size) {
  editor->setFont(family, size);
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
      event->accept();
    }
  }else{
    saveSettings();
  }
}

void Gui::command(QString cmd) {
  log("> " + cmd);
  cmd = cmd.toLower();

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
}

void Gui::log(QString text) {
  // ui.cmdlog->appendPlainText(text);
}

void Gui::updateValues() {
}
