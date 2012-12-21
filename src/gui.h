#ifndef GUI_H
#define GUI_H

#include <QtGui>

#include "ui_gui.h"

#include "cmd.h"
#include "code.h"
#include "viewer.h"

class Gui;

std::ostream& operator<<(std::ostream&, const Gui& v);

class Gui : public QMainWindow {
 Q_OBJECT

 public: 
  Gui(bool savePOV = false, bool savePNG = false, QWidget *parent = 0);
  QMessageBox* msgBox;
 
  QString toString() const;
  void luaBind(lua_State *s);

private slots:
  void updateValues();
  void command(QString cmd);

  void moveEvent(QMoveEvent *);
  void resizeEvent(QResizeEvent *);
  void closeEvent(QCloseEvent *);

  void animStarted();
  void animProgress(QString fmt, int n);
  void animFinished();

 public slots:
  void postDraw(int);
  void debug(QString msg);
  void toggleSimButton(bool);
  void togglePOVButton(bool);
  void togglePNGButton(bool);
  void toggleDeactivationButton(bool);
  
  void about();
  void newFile();
  void loadFile(const QString &path = QString());
  void openFile(const QString &path = QString());
  void save();
  void saveAs();
  void saveFile(const QString &path = QString());

  void editPrefs();

  void openRecentFile();

  void loadLastFile();

  void scriptChanged();
 
  void parseEditor();

  // drag & drop support
  void dragEnterEvent(QDragEnterEvent *event);
  void dropEvent(QDropEvent *event);

  void statusMessage (const QString aMessage) {
    statusBar()->showMessage(aMessage);
  }

  void runProgram() {
    statusBar()->showMessage(tr("Running simulation..."));
    ui.viewer->startSim();
    //emit play();
  }
  /*
  void stopProgram() {
    statusBar()->showMessage(tr("Stopped simulation."));
    ui.viewer->stopSim();
    //emit stop();
  }
  */
  void toggleSim() {
    if(_simulationRunning){
      QIcon playIcon = QIcon::fromTheme("media-playback-start");
      playAction->setIcon(playIcon);
      playAction->setText(tr("&Run simulation.."));
      playAction->setShortcut(tr("Ctrl+P"));
      playAction->setStatusTip(tr("Run Simulation"));
      statusBar()->showMessage(tr("Stopped simulation."));
      ui.viewer->stopSim();
      _simulationRunning=false;
    }else{
      QIcon playIcon = QIcon::fromTheme("media-playback-pause");	  
      playAction->setIcon(playIcon);
      playAction->setText(tr("Pause &Simulation"));
      playAction->setShortcut(tr("Ctrl+C"));
      playAction->setStatusTip(tr("Pause Simulation"));
      statusBar()->showMessage(tr("Running simulation..."));
      ui.viewer->startSim();
      _simulationRunning=true;
    }
  }
  void rerunProgram() {
    statusBar()->showMessage(tr("Running re-started simulation..."));
    ui.viewer->restartSim();
  }
  void toggleExport() {
    ui.viewer->toggleSavePOV();
  }
  void toggleScreenshots() {
    ui.viewer->toggleSavePNG();
  }
  void toggleDeactivationState() {
    ui.viewer->toggleDeactivation();
  }
  void resetCamera() {
    ui.viewer->resetCamView();
  }

  void fontChanged(const QString &family, uint size);

 signals:
  void play();
  //void stop();

 private:
  void createDock();
  void createToolBar();
  void createActions();
  void createMenus();
 
  bool _fileSaved;
  bool _simulationRunning;
  
  // settings
  QSettings *settings;

  // menus
  QMenu *fileMenu;
  QMenu *recentFilesMenu;
  QAction *separatorAction;

  QMenu *editMenu;

  QMenu *helpMenu;

  void updateRecentFileActions();
  void setCurrentFile(const QString &fileName);

  // actions                                                                    
  QAction *newAction;
  QAction *openAction;
  QAction *saveAction;
  QAction *saveAsAction;

  enum { MAX_RECENT_FILES = 5 };
  QAction *recentFileActions[MAX_RECENT_FILES];

  QAction *editAction;

  QAction *cutAction;
  QAction *copyAction;
  QAction *pasteAction;

  QAction *prefsAction;

  QAction *exitAction;

  QAction *helpAction;
  QAction *aboutAction;

  QAction *playAction;
  //QAction *stopAction;
  QAction *restartAction;
  
  QAction *povAction;
  QAction *pngAction;
  QAction *deactivationAction;

  QAction *resetAction;

  // toolbars
  QToolBar* myToolBar;

  QString strippedName(const QString &fullFileName);
  QString strippedNameNoExt(const QString &fullFileName);

  void log(QString text);

  void loadSettings();
  void saveSettings();

  Ui::MainWindow ui;

  // main app components //////////////////////////////////////////////////////
  CodeEditor *editor;
  CodeEditor *debugText;
  CommandLine *commandLine;
  /////////////////////////////////////////////////////////////////////////////

  bool savePOV, savePNG;
};

#endif
