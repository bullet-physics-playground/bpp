#ifndef LUA_QFILE_H
#define LUA_QFILE_H

#include "lua_qt.h"

typedef class_<QFile,QObject> LQFile;
typedef class_<QTemporaryFile, QFile> LQTemporaryFile;
typedef class_<QDir> LQDir;
typedef class_<QFileInfo> LQFileInfo;


LQFile lqfile();
LQTemporaryFile lqtemporaryfile();
LQDir lqdir();
LQFileInfo lqfileinfo();

#endif // LUA_QFILE_H
