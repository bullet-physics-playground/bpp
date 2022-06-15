#include "prefs.h"

#include <Qt>

#include "gui.h"

std::ostream& operator<<(std::ostream& ostream, const Gui& gui) {
    ostream << gui.toString().toUtf8().data();
    return ostream;
}

Gui::Gui(QSettings *s, QWidget *parent) : QMainWindow(parent) {

    _fileSaved=true;
    _simulationRunning=false;

    ui.setupUi(this);

    this->settings = s;
    ui.viewer->setSettings(s);

    createDock();

    createActions();
    createMenus();
    setStatusBar( new QStatusBar(this) );

    renderSettings = new QComboBox(ui.toolBarView);

    QStringList settings;
    settings << "view size";
    settings << "  426x240";
    settings << "  640x360";
    settings << " 1280x720";
    settings << "1920x1080";
    settings << "2560x1440";
    settings << "3840x2160";

    renderSettings->addItems(settings);
    renderSettings->setEditable(true);
    renderSettings->lineEdit()->setReadOnly(true);
    renderSettings->lineEdit()->setAlignment(Qt::AlignRight);
    for (int i = 0; i < renderSettings->count(); i++)
        renderSettings->setItemData(i, Qt::AlignRight, Qt::TextAlignmentRole);

    ui.toolBarView->addWidget(renderSettings);
    ui.toolBarView->addAction(ui.actionQuickRender);

    connect(editor, SIGNAL(textChanged()), this, SLOT(scriptChanged()));

    connect(ui.actionQuickRender, SIGNAL(triggered()), ui.viewer, SLOT(onQuickRender()));

    // map user defined shortcuts to the viewer sub-window
    connect(editor, SIGNAL(keyPressed(QKeyEvent *)), ui.viewer, SLOT(keyPressEvent(QKeyEvent *)));
    connect(commandLine, SIGNAL(keyPressed(QKeyEvent *)), ui.viewer, SLOT(keyPressEvent(QKeyEvent *)));
    connect(debugText, SIGNAL(keyPressed(QKeyEvent *)), ui.viewer, SLOT(keyPressEvent(QKeyEvent *)));

    connect(ui.viewer, SIGNAL(scriptHasOutput(QString)), this, SLOT(debug(QString)));
    connect(ui.viewer, SIGNAL(scriptStarts()), this, SLOT(clearDebug()));
    connect(ui.viewer, SIGNAL(simulationStateChanged(bool)), this, SLOT(toggleSimButton(bool)));
    connect(ui.viewer, SIGNAL(POVStateChanged(bool)), this, SLOT(togglePOVExport(bool)));
    connect(ui.viewer, SIGNAL(deactivationStateChanged(bool)), this, SLOT(toggleDeactivation(bool)));

    connect(ui.viewer, SIGNAL(statusEvent(QString)), this, SLOT(setStatusBarText(QString)));

    connect(ui.viewer, SIGNAL(clearDebugText()), debugText, SLOT(clear()));

    connect(commandLine, SIGNAL(execute(QString)), this, SLOT(command(QString)));

    connect(renderSettings, SIGNAL(currentTextChanged(QString)), this, SLOT(saveSettings()));

    loadSettings();

    connect(ui.viewer, SIGNAL(postDrawShot(int)), this, SLOT(postDraw(int)));
    // commandLine->setFocus();

    fileNew();

    QTimer::singleShot(500, this, SLOT(setFullscreenActionState()));

    QTimer::singleShot(0, this, SLOT(loadLastFile()));
}

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

void Gui::toggleDeactivation(bool d) {
    ui.viewer->toggleDeactivation(d);
    ui.actionToggleDeactivation->setChecked(d);
}

void Gui::postDraw(int /* frame */) {
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
    }
}

void Gui::fileLoad(const QString &path) {
    QFile file(path);

    settings->beginGroup( "mainwindow" );
    settings->setValue( "lastFile", path);
    settings->endGroup();
    settings->sync();

#ifndef QT_NO_CURSOR
    QApplication::setOverrideCursor(Qt::WaitCursor);
#endif

    if (editor->load(path)) {
        setCurrentFile(path);
        setWindowTitle(tr("%1 - %2").arg(QCoreApplication::applicationName()).arg(file.fileName()));
        parseEditor();
        statusBar()->showMessage(tr("File loaded"), 2000);
        _fileSaved = true;
        ui.actionSave->setEnabled(false);
    } else {
        setWindowTitle(tr("%1 %2").arg(QCoreApplication::applicationName()).arg(QCoreApplication::applicationVersion()));
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
        setWindowTitle(tr("%1 %2 - %3").arg(QCoreApplication::applicationName()).arg(QCoreApplication::applicationVersion()).arg(strippedName(editor->script_filename)));

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
    QDockWidget* dw1 = new QDockWidget(this);
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

    // hide cmdline by default - the last state is restored via prefs or gui:showCommandLine() Lua function
    addDockWidget(Qt::RightDockWidgetArea, dw3);
    dw3->setVisible(false);
}

void Gui::helpAbout() {
    QString txt =
            tr("<p><b>%1 (%2)</b></p>").arg(QCoreApplication::applicationName()).arg(QCoreApplication::applicationVersion()) + \
            tr("<p>Build: %1 - %2</p>").arg(BUILDDATE).arg(BUILDTIME) + \
            tr("<p>%1 Bullet %2</p>").arg(LUA_VERSION).arg(BULLET_VERSION) + \
            tr("<p>&copy; 2008-2022 <a href=\"http://github.com/koppi\">Jakob Flierl</a></p>") + \
            tr("<p>&copy; 2012-2016 <a href=\"http://ignorancia.org/\">Jaime Vives Piqueres</a></p>");

    QMessageBox::about(this, tr("About"), txt);
}

void Gui::helpHomepage() {
    QDesktopServices::openUrl(QUrl("https://github.com/bullet-physics-playground"));
}

void Gui::helpIssues() {
    QDesktopServices::openUrl(QUrl("https://github.com/bullet-physics-playground/bpp/issues"));
}

void Gui::helpWiki() {
    QDesktopServices::openUrl(QUrl("https://github.com/bullet-physics-playground/bpp/wiki"));
}

void Gui::helpChat() {
    QDesktopServices::openUrl(QUrl("https://gitter.im/bullet-physics-playground/bpp"));
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
      _fileSaved=false;
      parseEditor();
    } else {
        // qDebug() << "Warning: Gui::scriptChanged() called, but editor text the same." << "\n";
    }
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
    editor->clear();
    setCurrentFile(editor->script_filename);
    ui.actionSave->setEnabled(true);
    _fileSaved=true;
}

void Gui::fileOpen(const QString& path) {
    if (!_fileSaved) {
        settings->beginGroup("gui");
        bool dontask = settings->value("dont_ask_unsaved_changes", false ).toBool();
        settings->endGroup();

        if (!dontask) {
            msgBox = new QMessageBox(this);
            msgBox->setWindowTitle(tr("Unsaved changes"));
            msgBox->setText(tr("File '%1'\n\nnot saved: continue anyhow?\n").arg(editor->script_filename));
            //msgBox->setIcon(QMessageBox::Icon::Question);
            msgBox->addButton(QMessageBox::No);
            msgBox->addButton(QMessageBox::Yes);
            msgBox->setDefaultButton(QMessageBox::No);

            QCheckBox *check = new QCheckBox(tr("Don't show this message again."), this);
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
    setCurrentFile(editor->script_filename);
    ui.actionSave->setEnabled(false);

    _fileSaved = true;
}


void Gui::fileReload() {
    editor->load(editor->script_filename);
    setCurrentFile(editor->script_filename);
    ui.actionSave->setEnabled(false);

    _fileSaved = true;
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
    Prefs *p = new Prefs(settings, this);

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

    if ( settings->value("fullscreen", isFullScreen() ).toBool()) {
        showFullScreen();
    } else {
        showNormal();
    }

    if ( settings->value("maximized", isMaximized() ).toBool()) {
        showMaximized();
    }

    renderSettings->setCurrentIndex(renderSettings->findText(settings->value("renderResolution", "View size").toString()));

    ui.actionToggleDeactivation->setChecked(settings->value("deactivationState", true).toBool());

    settings->endGroup();
}

void Gui::saveSettings() {
    settings->beginGroup("gui");

    settings->setValue("geometry", saveGeometry());
    settings->setValue("state", saveState());
    settings->setValue("fullscreen", isFullScreen());
    settings->setValue("maximized",  isMaximized());

    if ( !isMaximized() && !isFullScreen() ) {
        settings->setValue("pos", pos());
        settings->setValue("size", size());
    }

    settings->setValue("renderResolution", renderSettings->currentText());

    settings->setValue("deactivationState", ui.actionToggleDeactivation->isChecked());

    settings->endGroup();

    settings->sync();
}

void Gui::moveEvent(QMoveEvent *) {
}

void Gui::resizeEvent(QResizeEvent *) {
}

void Gui::closeEvent(QCloseEvent * event) {
    // qDebug() << "Gui::closeEvent";
    if(!_fileSaved) {
        event->ignore();

        settings->beginGroup("gui");
        bool dontask = settings->value("dont_ask_unsaved_changes", false ).toBool();
        settings->endGroup();

        if (!dontask) {
            msgBox = new QMessageBox(this);
            msgBox->setWindowTitle(tr("Unsaved changes"));
            msgBox->setText(tr("File '%1'\n\nnot saved: exit anyhow?\n").arg(editor->script_filename));
            //msgBox->setIcon(QMessageBox::Icon::Question);
            msgBox->addButton(QMessageBox::No);
            msgBox->addButton(QMessageBox::Yes);
            msgBox->setDefaultButton(QMessageBox::No);

            QCheckBox *check = new QCheckBox(tr("Don't show this message again."), this);
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
    }else{
        saveSettings();
        ui.viewer->close();
        event->accept();
    }
}

void Gui::command(QString cmd) {
    ui.viewer->command(cmd);
}

void Gui::log(QString text) {
    debugText->appendLine(text);
}

QString Gui::toString() const {
    return QString("Gui");
}

void Gui::setStatusBarText(QString msg) {
    statusBar()->showMessage(msg);
}
