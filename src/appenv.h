#pragma once

/**
 * @file appenv.h
 * @brief Access to process-wide environment state captured at start-up, and
 *        the places bpp keeps its per-user files.
 */

#include <QDir>
#include <QString>

class QObject;
class QSettings;

/**
 * @brief Returns the process's current working directory, captured the first
 *        time this is called.
 *
 * main() calls it before anything can change the working directory
 * (Gui::setCurrentFile does QDir::setCurrent() to the directory of whichever
 * script was opened), so later callers get the directory bpp was launched from
 * rather than wherever the cwd happens to point to afterwards.
 *
 * @return Reference to the absolute start-up working directory. The string is
 *         a function-local static, so the reference stays valid for the
 *         lifetime of the process.
 */
inline const QString &startupWorkingDir() {
  static const QString dir = QDir::currentPath();
  return dir;
}

/**
 * @brief Points the environment's PWD at the current working directory, as
 *        a shell does when it changes directory.
 *
 * A script that asks a shell where it is (io.popen("pwd")) gets PWD back if
 * that shell trusts it, as macOS's /bin/sh does, so PWD must follow bpp's
 * working directory: main() calls this at start, Gui::setCurrentFile after
 * moving into a script's folder. (Unix only: Windows' cmd asks the system.)
 */
void syncPwd();

/**
 * @name Per-user files
 *
 * Where bpp keeps what belongs to the user rather than to a script: its
 * settings, the OpenSCAD mesh cache, @c v:dataDir, and quick renders. Ask
 * these functions rather than QStandardPaths or a bare QSettings, so that
 * @c BPP_USER_DIR moves all of them.
 *
 * By default they are the platform's places (the registry and AppData on
 * Windows, ~/.config and ~/.cache on Linux). With the environment variable
 * @c BPP_USER_DIR set to a folder, everything goes under it instead:
 *
 * | What        | Where                       |
 * |-------------|-----------------------------|
 * | settings    | BPP_USER_DIR/bpp.ini        |
 * | mesh cache  | BPP_USER_DIR/cache          |
 * | v:dataDir() | BPP_USER_DIR/data           |
 * | renders     | BPP_USER_DIR/renders        |
 *
 * The tests set it for every run (tests/harness.py), so no run reads or
 * writes the developer's own files. On Windows that is the only way to
 * keep them apart: Qt finds AppData through the shell, not the environment,
 * and keeps settings in the registry.
 * @{
 */

/// @c BPP_USER_DIR as bpp started with it, or empty when not set.
const QString &userDirOverride();

/**
 * @brief A new QSettings for bpp's settings store; the caller owns it.
 *
 * Every QSettings in bpp must come from here (or copy the store of one that
 * did, see Viewer's PrefsWriter): a bare @c QSettings() names no
 * organization, so it opens a different store.
 */
QSettings *newSettings(QObject *parent = nullptr);

/// The OpenSCAD mesh cache, which POV-Ray scenes also search (+L).
QString userCacheDir();

/// The folder @c v:dataDir gives scripts.
QString userDataDir();

/// The folder a quick render's PNG is written to: the desktop by default.
QString userRenderDir();

/// @}
