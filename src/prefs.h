#ifndef PREFS_H
#define PREFS_H

/**
 * @file prefs.h
 * @brief The preferences dialog and the settings it reads and writes.
 */

#include <QDialog>
#include <QHash>
#include <QListWidget>
#include <QString>
#include <QVariant>

#include <QKeyEvent>
#include <QSettings>

#include "ui_prefs.h"

/**
 * @brief Builds the default value for the @c lua/path setting.
 *
 * Assembles a Lua @c package.path search list from the places bpp's shipped
 * modules can live, so a script can @c require a module by its bare name. If a
 * script directory is given, the search walks up from it looking for a
 * @c module/ directory and puts the first one it finds at the front; then come
 * a @c demo/module next to or one level above the executable, and finally the
 * installed @c /usr/share/bpp/demo/module. Only directories that actually
 * exist are included.
 *
 * @param scriptBasePath Directory of the script being run, used to find a
 *                       project-local @c module/ directory. May be empty, in
 *                       which case only the application-wide locations are
 *                       considered.
 * @return The path entries, each ending in @c ";", concatenated into one
 *         string. Empty if none of the candidate directories exist.
 */
QString getDefaultLuaPath(const QString &scriptBasePath = QString());

/**
 * @brief The application preferences dialog.
 *
 * Presents the settings in groups chosen from a list box on the left, each
 * group being a page of tabs. Layout comes from the @c prefs.ui form, which
 * Prefs inherits from as Ui_Prefs, so the widgets are available as members.
 *
 * Settings are applied as they are edited rather than on OK: every widget's
 * change slot writes the new value straight to the QSettings store and emits
 * the matching signal, which the Gui connects to the objects that need to
 * react. Pressing OK re-emits all of them, so a consumer that was connected
 * late still gets the current state. Values are read back through getValue(),
 * which falls back to the per-key defaults computed in setupPages().
 */
class Prefs : public QDialog, public Ui_Prefs {
  Q_OBJECT

public:
  /**
   * @brief Builds the dialog and populates it from the settings.
   * @param settings Settings store to read and write. Not owned; it must
   *                 outlive the dialog.
   * @param parent   Parent widget, passed through to QDialog.
   */
  Prefs(QSettings *settings, QWidget *parent = nullptr);

  /**
   * @brief Destroys the dialog.
   */
  ~Prefs();

  /**
   * @brief Applies the settings and closes the dialog if they are valid.
   *
   * Reimplemented from QDialog. Re-emits every change signal through
   * on_buttonOk_clicked() and only accepts if no parameter was rejected.
   */
  void accept();

  /**
   * @brief Brings a particular settings page to the front.
   *
   * Used to open the dialog directly on the page a user action relates to.
   *
   * @param group Group name, matched against the list box items' user data.
   * @param id    Index of the tab to select within that group's page.
   */
  void activateGroupPage(const QString &group, int id);

  /**
   * @brief Reads a setting, falling back to its default.
   * @param key Settings key, for example @c "povray/executable".
   * @return The stored value, or the default computed in setupPages() if the
   *         key has never been written.
   */
  QVariant getValue(const QString &key) const;

  /**
   * @brief Writes a setting.
   * @param key   Settings key.
   * @param value Value to store.
   */
  void setValue(const QString &key, QVariant value);

protected:
  /**
   * @brief Re-translates the dialog when the application language changes.
   *
   * Besides the generated retranslateUi() call, the tab labels and the group
   * list entries are refreshed by hand, because their text comes from the
   * pages' window titles and the items' user data rather than from the form.
   *
   * @param e The change event.
   */
  void changeEvent(QEvent *e);

protected slots:
  /**
   * @brief Shows the page belonging to the newly selected group.
   * @param current  The item now selected, or null if the selection was
   *                 cleared.
   * @param previous The item selected before; used when @p current is null.
   */
  void changeGroup(QListWidgetItem *current, QListWidgetItem *previous);

  /**
   * @brief Re-emits every settings signal with the current values.
   *
   * Called when OK is pressed so that consumers are brought up to date even if
   * they were connected after a value was changed.
   */
  void on_buttonOk_clicked();

  /**
   * @brief Stores whether the last script should be reopened at start-up.
   * @param checked New state of the check box.
   */
  void guiOpenLastFileChanged(const bool checked);

  /**
   * @brief Stores whether window and dock geometry should be restored.
   * @param checked New state of the check box.
   */
  void guiWindowStateChanged(const bool checked);

  /**
   * @brief Stores the editor font family and announces the new font.
   * @param family The chosen font family.
   */
  void fontFamilyChanged(const QString &family);

  /**
   * @brief Stores the editor font size and announces the new font.
   * @param size The chosen size, as text from the editable combo box.
   */
  void fontSizeChanged(const QString &size);

  /**
   * @brief Stores the Lua module search path as it is typed.
   */
  void on_luaPathChanged();

  /**
   * @brief Stores the Lua language server executable.
   */
  void on_languageServerExecutableChanged();

  /**
   * @brief Asks for the Lua language server executable with a file dialog.
   */
  void on_languageServerExecutableBrowse();

  /**
   * @brief Stores the POV-Ray command line options used for previews.
   */
  void on_povPreviewChanged();

  /**
   * @brief Stores the POV-Ray executable path.
   */
  void on_povExecutableChanged();

  /**
   * @brief Asks for the POV-Ray executable with a file dialog.
   */
  void on_povExecutableBrowse();

  /**
   * @brief Stores the directory exported POV-Ray scenes are written to.
   */
  void on_povExportDirChanged();

  /**
   * @brief Asks for the POV-Ray export directory with a directory dialog.
   */
  void on_povExportDirBrowse();

  /**
   * @brief Stores the OpenSCAD executable path.
   */
  void on_scadExecutableChanged();

  /**
   * @brief Asks for the OpenSCAD executable with a file dialog.
   */
  void on_scadExecutableBrowse();

  /**
   * @brief Stores the 3D mouse navigation mode.
   * @param index Index of the chosen mode in the combo box.
   */
  void on_snNavigationModeChanged(int index);

  /**
   * @brief Stores whether the 3D mouse keeps the horizon level.
   * @param checked New state of the check box.
   */
  void on_snLockHorizonChanged(bool checked);

  /**
   * @brief Stores whether 3D mouse fly speed adapts to the scene.
   * @param checked New state of the check box.
   */
  void on_snAutoFlySpeedChanged(bool checked);

  /**
   * @brief Stores whether the 3D mouse orbit axis is drawn.
   * @param checked New state of the check box.
   */
  void on_snShowOrbitAxisChanged(bool checked);

  /**
   * @brief Stores which way the 3D mouse zooms.
   * @param index Index of the chosen direction; 0 means push to zoom in.
   */
  void on_snZoomDirectionChanged(int index);

  /**
   * @brief Stores whether 3D mouse panning also zooms.
   * @param checked New state of the check box.
   */
  void on_snPanZoomChanged(bool checked);

signals:
  /**
   * @brief Emitted when the reopen-last-script preference changes.
   * @param checked The new preference.
   */
  void checkOpenLastFileChanged(const bool checked);

  /**
   * @brief Emitted when the restore-window-state preference changes.
   * @param checked The new preference.
   */
  void checkOpenLastWindowState(const bool checked);

  /**
   * @brief Emitted when the editor font changes.
   * @param family The font family.
   * @param size   The point size.
   */
  void fontChanged(const QString &family, uint size) const;

  /**
   * @brief Emitted when the Lua module search path changes.
   * @param path The new @c package.path value.
   */
  void luaPathChanged(const QString &path) const;

  /**
   * @brief Emitted when the Lua language server executable changes.
   * @param path Path to the new server program.
   */
  void languageServerExecutableChanged(const QString &path) const;

  /**
   * @brief Emitted when the POV-Ray preview options change.
   * @param cmd The new command line options.
   */
  void povPreviewChanged(const QString &cmd) const;

  /**
   * @brief Emitted when the POV-Ray executable changes.
   * @param dir Path to the new executable.
   */
  void povExecutableChanged(const QString &dir) const;

  /**
   * @brief Emitted when the POV-Ray export directory changes.
   * @param dir The new directory.
   */
  void povExportDirChanged(const QString &dir) const;

  /**
   * @brief Emitted when the OpenSCAD executable changes.
   * @param dir Path to the new executable.
   */
  void scadExecutableChanged(const QString &dir) const;

  /**
   * @brief Emitted when the 3D mouse navigation mode changes.
   * @param mode The new mode.
   */
  void snNavigationModeChanged(int mode) const;

  /**
   * @brief Emitted when the 3D mouse horizon lock changes.
   * @param checked The new setting.
   */
  void snLockHorizonChanged(bool checked) const;

  /**
   * @brief Emitted when the 3D mouse automatic fly speed setting changes.
   * @param checked The new setting.
   */
  void snAutoFlySpeedChanged(bool checked) const;

  /**
   * @brief Emitted when the 3D mouse orbit axis display setting changes.
   * @param checked The new setting.
   */
  void snShowOrbitAxisChanged(bool checked) const;

  /**
   * @brief Emitted when the 3D mouse zoom direction changes.
   * @param forward True for the first combo box entry, i.e. push to zoom in.
   */
  void snZoomDirectionChanged(bool forward) const;

  /**
   * @brief Emitted when the 3D mouse pan-zoom setting changes.
   * @param checked The new setting.
   */
  void snPanZoomChanged(bool checked) const;

private:
  /**
   * @brief Closes the dialog on Escape, Ctrl+W, or Command+. on macOS.
   * @param e The key event.
   */
  void keyPressEvent(QKeyEvent *e);

  /**
   * @brief Loads every widget in the dialog from the current settings.
   */
  void updateGUI();

  /**
   * @brief Computes the default for every setting and wires up the widgets.
   *
   * Fills @c defaultmap with a fallback for each key - platform-dependent for
   * the monospace font and the POV-Ray and OpenSCAD executables, derived from
   * the start-up directory for the export path and the POV-Ray include options
   * - and populates the font size combo box. Also migrates the legacy
   * top-level @c openlastfile key to @c gui/openlastfile. Finally connects
   * each widget to the slot that stores its value.
   */
  void setupPages();

private:
  QHash<QString, QList<QString>> _pages; ///< Unused.
  bool invalidParameter; ///< Set while accepting if a value was rejected,
                         ///< which keeps the dialog open.

  QSettings *_settings;               ///< The settings store; not owned.
  QSettings::SettingsMap defaultmap;  ///< Default value per settings key, used
                                      ///< by getValue() when a key is unset.
};

#endif
