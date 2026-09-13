#pragma once

/**
 * @file appenv.h
 * @brief Access to process-wide environment state captured at start-up.
 */

#include <QDir>
#include <QString>

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
