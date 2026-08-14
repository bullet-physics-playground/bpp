#ifndef GUI_H
#define GUI_H

#include <QtGui>
#include <QtWidgets>

#include "ui_gui.h"

#include "cmd.h"
#include "code.h"
#include "viewer.h"

class QProgressBar;

class Gui;

class Gui : public QMainWindow {
  Q_OBJECT

public:
  Gui(QSettings *settings, QWidget *parent = nullptr);
  ~Gui() override;

  QString toString() const;

private slots:
  void command(const QString &cmd);
  void updateFrameLabel(int frameNum);
   void onParamsTableCellChanged(int row, int column);
   void onParamSliderChanged(int value);
   void onParamCheckBoxChanged(bool checked);

  void moveEvent(QMoveEvent *) override;
  void resizeEvent(QResizeEvent *) override;
  void closeEvent(QCloseEvent *) override;

  void animStarted();
  void animProgress(const QString &fmt, int n);
  void animFinished();

public slots:
  void postDraw(int);
  void debug(const QString &msg);
  void clearDebug();

  void setStatusBarText(const QString &msg);

  void toggleSimButton(bool);

  void togglePOVExport(bool);
  void toggleDeactivation(bool);
  void toggleFullscreen();
  void toggleShowConstraints(bool);

  void fileNew();
  void fileLoad(const QString &path = QString());
  void fileReload();
  void fileOpen(const QString &path = QString());
  void fileSave();
  void fileSave(const QString &path);
  void fileSaveAs();

  void helpAbout();
  void helpHomepage();
  void helpIssues();
  void helpWiki();
  void helpChat();

  void editPreferences();

  void openRecentFile();

  void loadLastFile();
  void setOpenLastFile(bool checked);

  void scriptChanged();

  void parseEditor();

  // drag & drop support
  void dragEnterEvent(QDragEnterEvent *event) override;
  void dropEvent(QDropEvent *event) override;

  void statusMessage(const QString aMessage) {
    statusBar()->showMessage(aMessage);
  }

  void showProgressBar(const QString &message = QString());
  void hideProgressBar();

void runProgram() {
    statusBar()->showMessage(tr("Running simulation..."));
    parseEditor();
    ui.viewer->startSim();
  }

  void toggleSim() {
    if (_simulationRunning) {
      QIcon playIcon = QIcon::fromTheme("media-playback-start");
      ui.actionToggleSim->setIcon(playIcon);
      ui.actionToggleSim->setText(tr("&Run simulation.."));
      ui.actionToggleSim->setShortcut(tr("Ctrl+P"));
      ui.actionToggleSim->setStatusTip(tr("Run Simulation"));
      statusBar()->showMessage(tr("Stopped simulation."));
      ui.viewer->stopSim();
      _simulationRunning = false;
    } else {
      QIcon playIcon = QIcon::fromTheme("media-playback-pause");
      ui.actionToggleSim->setIcon(playIcon);
      ui.actionToggleSim->setText(tr("Pause &Simulation"));
      ui.actionToggleSim->setShortcut(tr("Ctrl+C"));
      ui.actionToggleSim->setStatusTip(tr("Pause Simulation"));
      statusBar()->showMessage(tr("Running simulation..."));
      ui.viewer->startSim();
      _simulationRunning = true;
    }
  }

  void rerunProgram() {
    statusBar()->showMessage(tr("Running re-started simulation..."));
    ui.viewer->restartSim();
  }

  void resetCamera() { ui.viewer->resetCamView(); }

  void fontChanged(const QString &family, uint size);

  void setFullscreenActionState();

signals:
  void play();

protected slots:
  void loadSettings();
  void saveSettings();

private:
  void createDock();
  void createActions();
  void createMenus();
  void createPovrayMenu();
  QString povraySettingsPath() const;
  int readPovraySetting(const QString &name, int defaultValue) const;
  void writePovraySetting(const QString &name, int value);

  bool _fileSaved;
  bool _simulationRunning;

  // settings
  QSettings *settings;

  void updateRecentFileActions();
  void setCurrentFile(const QString &fileName);

  // actions
  enum { MAX_RECENT_FILES = 5 };
  QAction *recentFileActions[MAX_RECENT_FILES];

  QString strippedName(const QString &fullFileName);
  QString strippedNameNoExt(const QString &fullFileName);

  void log(const QString &text);

  Ui::MainWindow ui;

  QAction *actionSeparator;

  // main app components //////////////////////////////////////////////////////
  CodeEditor *editor;
  CodeEditor *debugText;
  CodeEditor *camText;
  CodeEditor *shortcutsText;
  CommandLine *commandLine;
  QDockWidget *dockLUAScript;
  QDockWidget *dockParams;
  QDockWidget *dockShortcuts;

  QMessageBox *msgBox;

  QComboBox *renderSettings;
  QProgressBar *progressBar;
  QLabel *frameLabel;

  QTableWidget *paramsTable;
  void updateParamsTable();
  bool eventFilter(QObject *obj, QEvent *event) override;
};

#endif
