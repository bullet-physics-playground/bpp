#pragma once

#include <QDir>
#include <QString>

// Returns the process's current working directory, captured the first time
// this is called. main() calls it before anything can change the working
// directory (Gui::setCurrentFile does QDir::setCurrent() to the directory of
// whichever script was opened), so later callers get the directory bpp was
// launched from rather than wherever the cwd happens to point to afterwards.
inline const QString &startupWorkingDir() {
  static const QString dir = QDir::currentPath();
  return dir;
}
