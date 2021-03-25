#ifndef GUI_H
#define GUI_H

#include <QtGui>
#include <QtWidgets>

#include "ui_gui.h"

#include "cmd.h"
#include "code.h"
#include "viewer.h"

class Gui;

std::ostream& operator<<(std::ostream&, const Gui& v);

class Gui : public QMainWindow {
    Q_OBJECT

public:
    Gui(QSettings *settings, QWidget *parent = 0);

    QString toString() const;
    void luaBind(lua_State *s);

private slots:
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
    void clearDebug();

    void setStatusBarText(QString msg);

    void toggleSimButton(bool);

    void togglePOVExport(bool);
    void toggleDeactivation(bool);
    void toggleFullscreen();

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

    void toggleSim() {
        if(_simulationRunning){
            QIcon playIcon = QIcon::fromTheme("media-playback-start");
            ui.actionToggleSim->setIcon(playIcon);
            ui.actionToggleSim->setText(tr("&Run simulation.."));
            ui.actionToggleSim->setShortcut(tr("Ctrl+P"));
            ui.actionToggleSim->setStatusTip(tr("Run Simulation"));
            statusBar()->showMessage(tr("Stopped simulation."));
            ui.viewer->stopSim();
            _simulationRunning=false;
        }else{
            QIcon playIcon = QIcon::fromTheme("media-playback-pause");
            ui.actionToggleSim->setIcon(playIcon);
            ui.actionToggleSim->setText(tr("Pause &Simulation"));
            ui.actionToggleSim->setShortcut(tr("Ctrl+C"));
            ui.actionToggleSim->setStatusTip(tr("Pause Simulation"));
            statusBar()->showMessage(tr("Running simulation..."));
            ui.viewer->startSim();
            _simulationRunning=true;
        }
    }

    void rerunProgram() {
        statusBar()->showMessage(tr("Running re-started simulation..."));
        ui.viewer->restartSim();
    }

    void resetCamera() {
        ui.viewer->resetCamView();
    }

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

    void log(QString text);

    Ui::MainWindow ui;

    QAction* actionSeparator;

    // main app components //////////////////////////////////////////////////////
    CodeEditor *editor;
    CodeEditor *debugText;
    CommandLine *commandLine;

    QMessageBox *msgBox;

    QComboBox   *renderSettings;
};

#endif
