#ifndef GUI_H
#define GUI_H

/**
 * @file gui.h
 * @brief The main application window.
 */

#include <QtGui>
#include <QtWidgets>

#include "ui_gui.h"

#include "cmd.h"
#include "code.h"
#include "viewer.h"

class QProgressBar;

class Gui;

/**
 * @brief The main window: script editor, 3D viewer and everything around them.
 *
 * Gui owns the widgets and wires them to each other, but holds almost no state
 * of its own. Layout comes from the @c gui.ui form, whose central widget is the
 * Viewer; around it createDock() adds dock widgets for the Lua script, the
 * debug log, the command line, the camera readout, the script parameters and
 * the shortcut reference.
 *
 * Editing the script re-parses it into the Viewer on every change, so the
 * scene follows the text as it is typed. The Parameters dock is generated from
 * whatever the running script registered - a slider for a value with a range,
 * a check box for a boolean, an editable cell otherwise - and edits are pushed
 * straight back into the simulation.
 *
 * The POV-Ray menu is not a set of application settings: it is built from a
 * table of @c \#declare names and reads and writes them directly in
 * @c includes/settings.inc, which is the file the exported scenes include.
 */
class Gui : public QMainWindow {
  Q_OBJECT

public:
  /**
   * @brief Builds the main window and connects everything together.
   *
   * Creates the docks, actions and menus, adds the render resolution chooser,
   * the progress bar and the frame counter to the status bar and tool bar,
   * connects the editor, command line and viewer to each other, restores the
   * saved settings and starts with an empty script. If the preference is set,
   * the last script is reopened once the event loop starts.
   *
   * @param settings Settings store to read and write. Not owned; it must
   *                 outlive the window.
   * @param parent   Parent widget, passed through to QMainWindow.
   */
  Gui(QSettings *settings, QWidget *parent = nullptr);

  /**
   * @brief Destroys the window; the child widgets go with it.
   */
  ~Gui() override;

  /**
   * @brief Returns a short description of this object.
   * @return The literal @c "Gui".
   */
  QString toString() const;

private slots:
  /**
   * @brief Runs a line typed at the command line as Lua.
   * @param cmd The command text.
   */
  void command(const QString &cmd);

  /**
   * @brief Shows the current simulation frame in the status bar.
   * @param frameNum The frame number to display.
   */
  void updateFrameLabel(int frameNum);

  /**
   * @brief Pushes an edited parameter cell back into the simulation.
   *
   * Used for parameters shown as plain editable cells, that is those with
   * neither a range nor a boolean value. The typed text is converted back to
   * the type the parameter already had.
   *
   * @param row    Row of the changed cell.
   * @param column Column of the changed cell; only the value column matters.
   */
   void onParamsTableCellChanged(int row, int column);

  /**
   * @brief Pushes a dragged parameter slider back into the simulation.
   *
   * Sliders work in integers, so the position is divided by the per-parameter
   * scale to recover the real value. At either end the configured bound is
   * used verbatim, since the int-to-float round trip can otherwise leave the
   * slider looking as if it never quite reaches its limits.
   *
   * @param value The new slider position.
   */
   void onParamSliderChanged(int value);

  /**
   * @brief Pushes a toggled parameter check box back into the simulation.
   * @param checked The new state.
   */
   void onParamCheckBoxChanged(bool checked);

  /**
   * @brief Handles window moves. Does nothing.
   * @param event The move event.
   */
  void moveEvent(QMoveEvent *event) override;

  /**
   * @brief Handles window resizes. Does nothing.
   * @param event The resize event.
   */
  void resizeEvent(QResizeEvent *event) override;

  /**
   * @brief Saves the settings and shuts the viewer down on close.
   *
   * If the script has unsaved changes the user is asked whether to quit
   * anyway, unless they previously ticked the box that suppresses the
   * question.
   *
   * @param event The close event; ignored while the question is pending.
   */
  void closeEvent(QCloseEvent *event) override;

  /**
   * @brief Notification that an animation started. Does nothing.
   */
  void animStarted();

  /**
   * @brief Notification of animation progress. Does nothing.
   * @param fmt Format string describing the progress.
   * @param n   Progress value.
   */
  void animProgress(const QString &fmt, int n);

  /**
   * @brief Notification that an animation finished. Does nothing.
   */
  void animFinished();

public slots:
  /**
   * @brief Refreshes the camera readout after a frame was drawn.
   *
   * Writes the viewer's current up vector, position and look-at point into the
   * Camera Info dock as Lua statements, ready to be pasted into a script.
   *
   * @param frame The frame that was just drawn. Unused.
   */
  void postDraw(int frame);

  /**
   * @brief Appends a line to the debug dock.
   * @param msg The text to append.
   */
  void debug(const QString &msg);

  /**
   * @brief Empties the debug dock.
   */
  void clearDebug();

  /**
   * @brief Shows a message in the status bar.
   * @param msg The text to show.
   */
  void setStatusBarText(const QString &msg);

  /**
   * @brief Updates the run/pause action to match the simulation state.
   *
   * Called when the Viewer starts or stops on its own, so the tool bar stays
   * in step with it.
   *
   * @param simRunning True if the simulation is now running.
   */
  void toggleSimButton(bool simRunning);

  /**
   * @brief Turns POV-Ray frame export on or off.
   * @param p True to export each simulated frame as a POV-Ray scene.
   */
  void togglePOVExport(bool p);

  /**
   * @brief Turns Bullet's sleeping of resting bodies on or off.
   * @param d True to allow bodies to deactivate.
   */
  void toggleDeactivation(bool d);

  /**
   * @brief Switches the window between full screen and normal.
   */
  void toggleFullscreen();

  /**
   * @brief Turns the drawing of constraints in the 3D view on or off.
   * @param checked True to draw them.
   */
  void toggleShowConstraints(bool checked);

  /**
   * @brief Starts a new, empty script.
   */
  void fileNew();

  /**
   * @brief Loads a script and records it as the file to reopen at start-up.
   *
   * Unlike fileOpen() this does not ask about unsaved changes; it is the path
   * used for the recent files list, drag and drop and the reopen-last-script
   * preference.
   *
   * @param path Script to load. An empty path makes the editor ask for one.
   */
  void fileLoad(const QString &path = QString());

  /**
   * @brief Re-reads the current script from disk, discarding edits.
   */
  void fileReload();

  /**
   * @brief Opens a script, asking first if the current one has unsaved edits.
   * @param path Script to open. An empty path makes the editor ask for one.
   */
  void fileOpen(const QString &path = QString());

  /**
   * @brief Saves the script to the file it came from.
   */
  void fileSave();

  /**
   * @brief Saves the script to a given path and adopts it as the current file.
   * @param path Where to write.
   */
  void fileSave(const QString &path);

  /**
   * @brief Saves the script under a name chosen in a dialog.
   */
  void fileSaveAs();

  /**
   * @brief Shows the about box, with the build and library versions.
   */
  void helpAbout();

  /**
   * @brief Opens the project home page in the browser.
   */
  void helpHomepage();

  /**
   * @brief Opens the project issue tracker in the browser.
   */
  void helpIssues();

  /**
   * @brief Opens the project wiki in the browser.
   */
  void helpWiki();

  /**
   * @brief Opens the project chat room in the browser.
   */
  void helpChat();

  /**
   * @brief Shows the preferences dialog.
   *
   * The dialog is created per invocation and deletes itself when closed. Its
   * change signals are connected to the editor and the viewer so preferences
   * take effect immediately.
   */
  void editPreferences();

  /**
   * @brief Loads the script named by the recent-files action that was invoked.
   */
  void openRecentFile();

  /**
   * @brief Reopens the script from the previous session.
   *
   * Does nothing unless the preference is set and a path was recorded.
   */
  void loadLastFile();

  /**
   * @brief Stores the reopen-last-script preference.
   * @param checked The new preference.
   */
  void setOpenLastFile(bool checked);

  /**
   * @brief Reacts to the script text having changed.
   *
   * Marks the file dirty and re-parses it into the viewer. The text is
   * compared against the previous contents first, because QPlainTextEdit also
   * emits textChanged() for changes that leave the text as it was.
   */
  void scriptChanged();

  /**
   * @brief Hands the editor contents to the viewer to be parsed as Lua.
   */
  void parseEditor();

  // drag & drop support
  /**
   * @brief Accepts a drag carrying file URLs.
   * @param event The drag event.
   */
  void dragEnterEvent(QDragEnterEvent *event) override;

  /**
   * @brief Loads the first dropped file as a script.
   * @param event The drop event.
   */
  void dropEvent(QDropEvent *event) override;

  /**
   * @brief Shows a message in the status bar.
   * @param aMessage The text to show.
   */
  void statusMessage(const QString aMessage) {
    statusBar()->showMessage(aMessage);
  }

  /**
   * @brief Shows the busy indicator in the status bar.
   *
   * The bar has no range, so it animates rather than showing a percentage; it
   * is used while a script is being parsed.
   *
   * @param message Optional status text to show alongside it.
   */
  void showProgressBar(const QString &message = QString());

  /**
   * @brief Hides the busy indicator and clears the status text.
   */
  void hideProgressBar();

  /**
   * @brief Parses the editor contents and starts the simulation.
   */
void runProgram() {
    statusBar()->showMessage(tr("Running simulation..."));
    parseEditor();
    ui.viewer->startSim();
  }

  /**
   * @brief Starts or pauses the simulation, and updates the tool bar action.
   */
  void toggleSim() {
    if (_simulationRunning) {
      QIcon playIcon = QIcon::fromTheme("media-playback-start");
      ui.actionToggleSim->setIcon(playIcon);
      ui.actionToggleSim->setText(tr("&Run simulation.."));
      ui.actionToggleSim->setStatusTip(tr("Run Simulation"));
      statusBar()->showMessage(tr("Stopped simulation."));
      ui.viewer->stopSim();
      _simulationRunning = false;
    } else {
      QIcon playIcon = QIcon::fromTheme("media-playback-pause");
      ui.actionToggleSim->setIcon(playIcon);
      ui.actionToggleSim->setText(tr("Pause &Simulation"));
      ui.actionToggleSim->setStatusTip(tr("Pause Simulation"));
      statusBar()->showMessage(tr("Running simulation..."));
      ui.viewer->startSim();
      _simulationRunning = true;
    }
  }

  /**
   * @brief Restarts the simulation from the beginning.
   */
  void rerunProgram() {
    statusBar()->showMessage(tr("Running re-started simulation..."));
    ui.viewer->restartSim();
  }

  /**
   * @brief Returns the 3D view to its default camera position.
   */
  void resetCamera() { ui.viewer->resetCamView(); }

  /**
   * @brief Applies a new font to all four text panes.
   * @param family Font family name.
   * @param size   Point size.
   */
  void fontChanged(const QString &family, uint size);

  /**
   * @brief Syncs the full screen menu item with the actual window state.
   *
   * Run shortly after start-up, once the window manager has settled on
   * whether the restored window really is full screen.
   */
  void setFullscreenActionState();

signals:
  /**
   * @brief Emitted to request that the simulation be played.
   */
  void play();

protected slots:
  /**
   * @brief Restores window geometry, dock layout and view settings.
   *
   * Honours the restore-window-state preference for the geometry, but always
   * forces the Parameters and Shortcuts docks visible: they are how a running
   * simulation is controlled and read, so they are not left to whatever a
   * previous session happened to save. The Lua script dock width is re-applied
   * on the next event loop iteration, because this runs before the window is
   * shown and resizeDocks() needs real layout geometry to act on.
   */
  void loadSettings();

  /**
   * @brief Saves window geometry, dock layout and view settings.
   */
  void saveSettings();

private:
  /**
   * @brief Creates the dock widgets around the 3D view.
   *
   * Debug log and Shortcuts along the bottom; Lua script, command line, camera
   * readout and parameters down the right. The Parameters dock is set to stay
   * on top while floating and offers a context menu to re-dock it.
   */
  void createDock();

  /**
   * @brief Creates the recent-file actions.
   *
   * They start hidden and are filled in by updateRecentFileActions().
   */
  void createActions();

  /**
   * @brief Adds the recent files and the POV-Ray menu to the menu bar.
   */
  void createMenus();

  /**
   * @brief Builds the POV-Ray menu from the render settings table.
   *
   * Each entry becomes either a checkable item or a submenu of mutually
   * exclusive options, initialised from the current value in
   * @c includes/settings.inc and writing straight back to it when chosen.
   * When bpp was built with VFE support, an extra item selects the in-process
   * renderer for quick renders.
   */
  void createPovrayMenu();

  /**
   * @brief Path of the POV-Ray settings include file.
   * @return @c includes/settings.inc under the start-up working directory.
   */
  QString povraySettingsPath() const;

  /**
   * @brief Reads one @c \#declare value from the POV-Ray settings file.
   * @param name         Name of the declaration to look for.
   * @param defaultValue Returned if the file cannot be read or has no such
   *                     declaration.
   * @return The declared integer value, or @p defaultValue.
   */
  int readPovraySetting(const QString &name, int defaultValue) const;

  /**
   * @brief Writes one @c \#declare value into the POV-Ray settings file.
   *
   * Rewrites the number in place, leaving the rest of the file untouched. If
   * the declaration is not present the file is left alone rather than having
   * anything appended to it.
   *
   * @param name  Name of the declaration to change.
   * @param value The new value.
   */
  void writePovraySetting(const QString &name, int value);

  bool _fileSaved;         ///< False while the script has unsaved changes.
  bool _simulationRunning; ///< Whether the simulation is currently stepping.

  // settings
  QSettings *settings; ///< The settings store; not owned.

  /**
   * @brief Refreshes the recent-file menu items from the stored list.
   *
   * Shows one item per remembered file and hides the rest, along with the
   * separator when the list is empty.
   */
  void updateRecentFileActions();

  /**
   * @brief Adopts a script as the current file.
   *
   * Tells the viewer the script's name and base path, changes the process's
   * working directory to the script's own directory so relative paths in the
   * script resolve as the author expected, updates the window title and puts
   * the file at the head of the recent list.
   *
   * @param fileName Path of the script, or @c "no_name" for an unsaved buffer,
   *                 which is not added to the recent list.
   */
  void setCurrentFile(const QString &fileName);

  // actions
  /// Sizes of the recent files menu.
  enum { MAX_RECENT_FILES = 5 };
  QAction *recentFileActions[MAX_RECENT_FILES]; ///< The recent file menu items.

  /**
   * @brief Returns the file name part of a path.
   * @param fullFileName The path to strip.
   * @return The file name, extension included.
   */
  QString strippedName(const QString &fullFileName);

  /**
   * @brief Returns the file name part of a path, without its extension.
   *
   * Used as the base name for exported POV-Ray scenes and images.
   *
   * @param fullFileName The path to strip.
   * @return The base name.
   */
  QString strippedNameNoExt(const QString &fullFileName);

  /**
   * @brief Appends a line to the debug dock.
   * @param text The text to append.
   */
  void log(const QString &text);

  Ui::MainWindow ui; ///< The widgets from the @c gui.ui form.

  QAction *actionSeparator; ///< Separator below the recent files, hidden when
                            ///< the list is empty.

  // main app components //////////////////////////////////////////////////////
  CodeEditor *editor;        ///< The Lua script editor.
  CodeEditor *debugText;     ///< Read-only pane showing script output.
  CodeEditor *camText;       ///< Read-only pane showing the camera as Lua.
  CodeEditor *shortcutsText; ///< Read-only pane listing the viewer shortcuts.
  CommandLine *commandLine;  ///< One-line Lua prompt.
  QDockWidget *dockLUAScript; ///< Dock holding #editor; its width is restored
                              ///< explicitly across sessions.
  QDockWidget *dockParams;    ///< Dock holding #paramsTable; always shown.
  QDockWidget *dockShortcuts; ///< Dock holding #shortcutsText; always shown.

  QMessageBox *msgBox; ///< The unsaved-changes prompt while it is up.

  QComboBox *renderSettings; ///< Output resolution for POV-Ray renders.
  QProgressBar *progressBar; ///< Busy indicator shown while parsing.
  QLabel *frameLabel;        ///< Status bar frame counter.

  QTableWidget *paramsTable; ///< Live parameters exposed by the script.

  /**
   * @brief Rebuilds the parameters table from the script's parameters.
   *
   * Each parameter gets the editor that suits it: a slider when it declares a
   * range, a check box when it is a boolean, an editable cell otherwise. When
   * the set and order of names is unchanged the existing widgets are updated
   * in place instead of being recreated, so that refreshing while a slider is
   * being dragged neither flickers nor interrupts the drag.
   */
  void updateParamsTable();

  /**
   * @brief Keeps parameter tooltips pinned to the moving cursor.
   *
   * Qt only re-positions a tooltip when a fresh QEvent::ToolTip arrives, which
   * is suppressed while the pointer stays inside the same item, so a tooltip
   * over a wide row would otherwise go stale. Re-showing it on each mouse move
   * keeps it under the cursor.
   *
   * @param obj   The watched object.
   * @param event The event.
   * @return Whatever QMainWindow::eventFilter() decides; the tooltip handling
   *         never consumes the event.
   */
  bool eventFilter(QObject *obj, QEvent *event) override;
};

#endif
