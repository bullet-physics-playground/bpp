#include "lua_qfile.h"

namespace luabind{
    QT_EMUN_CONVERTER(QFile::FileError)
    QT_EMUN_CONVERTER(QFile::Permission)
    QT_EMUN_CONVERTER(QFile::Permissions)
    QT_EMUN_CONVERTER(QDir::Filter)
    QT_EMUN_CONVERTER(QDir::Filters)
    QT_EMUN_CONVERTER(QDir::SortFlag)
    QT_EMUN_CONVERTER(QDir::SortFlags)
    QT_EMUN_CONVERTER(QIODevice::OpenMode)
}

bool lqfile_open(QFile* w)
{
    return w->open(QIODevice::ReadWrite);
}

QByteArray lqfile_readLine(QFile* w)
{
    return w->readLine();
}

LQFile lqfile()
{
    return
    class_<QFile,QObject>("QFile")
    .def(constructor<const QString&>())
    .def(constructor<QObject*>())
    .def(constructor<const QString&,QObject*>())
    .def("copy", (bool (QFile::*)(const QString &))&QFile::copy)
    .def("flush", &QFile::flush)
    .def("link", (bool (QFile::*)(const QString &))&QFile::link)
    .def("open", (bool (QFile::*)(QIODevice::OpenMode))&QFile::open)
    .def("open", lqfile_open)
    .def("close", &QFile::close)
    .def("peek", (QByteArray (QFile::*)(qint64))&QFile::peek)
    .def("pos", &QFile::pos)
    .def("read", (QByteArray (QFile::*)(qint64))&QFile::read)
    .def("readAll", &QFile::readAll)
    .def("readLine", (QByteArray(QFile::*)(qint64))&QFile::readLine)
    .def("readLine", lqfile_readLine)
    .def("reset", &QFile::reset)
    .def("seek", &QFile::seek)
    .def("write", (qint64(QFile::*)( const QByteArray&))&QFile::write)

    .def("remove", (bool (QFile::*)())&QFile::remove)
    .def("rename", (bool (QFile::*)(const QString &))&QFile::rename)
    .def("resize", (bool (QFile::*)(qint64))&QFile::resize)
    .def("symLinkTarget", (QString (QFile::*)()const)&QFile::symLinkTarget)

    .property("error", &QFile::error)
    .property("exists", (bool (QFile::*)() const)&QFile::exists)
    .property("errorString", &QFile::errorString)
    .property("fileName", &QFile::fileName, &QFile::setFileName)
    .property("isOpen", &QFile::isOpen)
    .property("isReadable", &QFile::isReadable)
    .property("isWritable", &QFile::isWritable)
    .property("isSequential", &QFile::isSequential)
    .property("openMode", &QFile::openMode)
    .property("canReadLine", &QFile::canReadLine)
    .property("atEnd", &QFile::atEnd)
    .property("size", &QFile::size)
    .property("permissions", (QFile::Permissions(QFile::*)()const)&QFile::permissions, (bool(QFile::*)(QFile::Permissions))&QFile::setPermissions)

    .scope[
            def("copy", (bool(*)(const QString&,const QString&))&QFile::copy),
            def("exists", (bool(*)(const QString&))&QFile::exists),
            def("link", (bool(*)(const QString&,const QString&))&QFile::link),
            def("permissions", (QFile::Permissions(*)(const QString&))&QFile::permissions),
            def("remove", (bool(*)(const QString&))&QFile::remove),
            def("rename", (bool(*)(const QString&,const QString&))&QFile::rename),
            def("resize", (bool(*)(const QString&,qint64))&QFile::resize),
            def("setPermissions", (bool(*)(const QString&,QFile::Permissions))&QFile::setPermissions),
            def("symLinkTarget", (QString(*)(const QString&))&QFile::symLinkTarget)
    ]
    ;
}


LQTemporaryFile lqtemporaryfile()
{
    return
    class_<QTemporaryFile, QFile>("QTemporaryFile")
    .def(constructor<>())
    .def(constructor<const QString&>())
    .def(constructor<QObject*>())
    .def(constructor<const QString&,QObject*>())
    .def("open", (bool(QTemporaryFile::*)())&QTemporaryFile::open)

    .property("autoRemove", &QTemporaryFile::autoRemove, &QTemporaryFile::setAutoRemove)
    .property("fileTemplate", &QTemporaryFile::fileTemplate, &QTemporaryFile::setFileTemplate)
    .property("fileName", &QTemporaryFile::fileName)

    .scope[
        def("createLocalFile", (QTemporaryFile *(*)(const QString&))&QTemporaryFile::createLocalFile),
        def("createLocalFile", (QTemporaryFile *(*)(QFile&))&QTemporaryFile::createLocalFile)
    ]
    ;
}

QFileInfoList lqdir_entryInfoList1(QDir* w){ return w->entryInfoList();}
QFileInfoList lqdir_entryInfoList2(QDir* w, const QStringList& s){ return w->entryInfoList(s);}
QFileInfoList lqdir_entryInfoList3(QDir* w, const QStringList& s, QDir::Filters f){ return w->entryInfoList(s,f);}
QFileInfoList lqdir_entryInfoList4(QDir* w, const QStringList& s, QDir::Filters f, QDir::SortFlags sf){ return w->entryInfoList(s,f,sf);}
QFileInfoList lqdir_entryInfoList5(QDir* w, QDir::Filters f){ return w->entryInfoList(f);}
QFileInfoList lqdir_entryInfoList6(QDir* w, QDir::Filters f, QDir::SortFlags sf){ return w->entryInfoList(f,sf);}

QStringList lqdir_entryList1(QDir* w){ return w->entryList();}
QStringList lqdir_entryList2(QDir* w, const QStringList& s){ return w->entryList(s);}
QStringList lqdir_entryList3(QDir* w, const QStringList& s, QDir::Filters f){ return w->entryList(s,f);}
QStringList lqdir_entryList4(QDir* w, const QStringList& s, QDir::Filters f, QDir::SortFlags sf){ return w->entryList(s,f,sf);}
QStringList lqdir_entryList5(QDir* w, QDir::Filters f){ return w->entryList(f);}
QStringList lqdir_entryList6(QDir* w, QDir::Filters f, QDir::SortFlags sf){ return w->entryList(f,sf);}

QString lqdir_separator()
{
    return QString(QDir::separator());
}

LQDir lqdir()
{
    return
    class_<QDir>("QDir")
    .def(constructor<const QString&, const QString&, QDir::SortFlags, QDir::Filters>())
    .def(constructor<const QString&, const QString&, QDir::SortFlags>())
    .def(constructor<const QString&, const QString&>())
    .def(constructor<const QString&>())
    .def(constructor<>())
    .def(constructor<const QDir&>())
    .def("absoluteFilePath", &QDir::absoluteFilePath)
    .def("absolutePath", &QDir::absolutePath)
    .def("canonicalPath", &QDir::canonicalPath)
    .def("cd", &QDir::cd)
    .def("cdUp", &QDir::cdUp)
    .def("entryInfoList", lqdir_entryInfoList1)
    .def("entryInfoList", lqdir_entryInfoList2)
    .def("entryInfoList", lqdir_entryInfoList3)
    .def("entryInfoList", lqdir_entryInfoList4)
    .def("entryInfoList", lqdir_entryInfoList5)
    .def("entryInfoList", lqdir_entryInfoList6)
    .def("entryList", lqdir_entryList1)
    .def("entryList", lqdir_entryList2)
    .def("entryList", lqdir_entryList3)
    .def("entryList", lqdir_entryList4)
    .def("entryList", lqdir_entryList5)
    .def("entryList", lqdir_entryList6)

    .def("exists", (bool(QDir::*)(const QString&)const)&QDir::exists)
    .def("filePath", &QDir::filePath)
    .def("filter", &QDir::filter)
    .def("makeAbsolute", &QDir::makeAbsolute)
    .def("mkdir", &QDir::mkdir)
    .def("mkpath", &QDir::mkpath)
    .def("refresh", &QDir::refresh)
    .def("relativeFilePath", &QDir::relativeFilePath)
    .def("remove", &QDir::remove)
    .def("rename", &QDir::rename)
    .def("rmdir", &QDir::rmdir)
    .def("rmpath", &QDir::rmpath)

    .property("count", &QDir::count)
    .property("dirName", &QDir::dirName)
    .property("exists", (bool(QDir::*)()const)&QDir::exists)
    .property("isAbsolute", &QDir::isAbsolute)
    .property("isReadable", &QDir::isReadable)
    .property("isRelative", &QDir::isRelative)
    .property("isRoot", &QDir::isRoot)
    .property("nameFilters", &QDir::nameFilters, &QDir::setNameFilters)
    .property("path", &QDir::path, &QDir::setPath)
    .property("sorting", &QDir::sorting, &QDir::setSorting)

    .scope[
        def("addSearchPath", &QDir::addSearchPath),
        def("cleanPath", &QDir::cleanPath),
        def("current", &QDir::current),
        def("currentPath", &QDir::currentPath),
        def("drives", &QDir::drives),
        def("fromNativeSeparators", &QDir::fromNativeSeparators),
        def("home", &QDir::home),
        def("homePath", &QDir::homePath),
        def("isAbsolutePath", &QDir::isAbsolutePath),
        def("isRelativePath", &QDir::isRelativePath),
        def("match", (bool(*)( const QString &, const QString &))&QDir::match),
        def("match", (bool(*)( const QStringList &, const QString &))&QDir::match),
        def("root", &QDir::root),
        def("rootPath", &QDir::rootPath),
        def("searchPaths", &QDir::searchPaths),
        def("setCurrent", &QDir::setCurrent),
        def("setSearchPaths", &QDir::setSearchPaths),
        def("temp", &QDir::temp),
        def("tempPath", &QDir::tempPath),
        def("toNativeSeparators", &QDir::toNativeSeparators),
        def("separator", lqdir_separator)
     ]
    ;
}

LQFileInfo lqfileinfo()
{
    return
    class_<QFileInfo>("QFileInfo")
    .def(constructor<>())
    .def(constructor<const QString&>())
    .def(constructor<const QDir&, const QString&>())
    .def(constructor<const QFile&>())
    .def(constructor<const QFileInfo&>())

    .property("absoluteDir", &QFileInfo::absoluteDir)
    .property("absoluteFilePath", &QFileInfo::absoluteFilePath)
    .property("absolutePath", &QFileInfo::absolutePath)
    .property("baseName", &QFileInfo::baseName)
    .property("bundleName", &QFileInfo::bundleName)
    .property("caching", &QFileInfo::caching, &QFileInfo::setCaching)
    .property("canonicalFilePath", &QFileInfo::canonicalFilePath)
    .property("canonicalPath", &QFileInfo::canonicalPath)
    .property("completeBaseName", &QFileInfo::completeBaseName)
    .property("completeSuffix", &QFileInfo::completeSuffix)
    .property("created", &QFileInfo::created)
    .property("dir", &QFileInfo::dir)
    .property("exists", &QFileInfo::exists)
    .property("fileName", &QFileInfo::fileName)
    .property("filePath", &QFileInfo::filePath)
    .property("group", &QFileInfo::group)
    .property("groupId", &QFileInfo::groupId)
    .property("isAbsolute", &QFileInfo::isAbsolute)
    .property("isBundle", &QFileInfo::isBundle)
    .property("isDir", &QFileInfo::isDir)
    .property("isExecutable", &QFileInfo::isExecutable)
    .property("isFile", &QFileInfo::isFile)
    .property("isHidden", &QFileInfo::isHidden)
    .property("isReadable", &QFileInfo::isReadable)
    .property("isRelative", &QFileInfo::isRelative)
    .property("isRoot", &QFileInfo::isRoot)
    .property("isSymLink", &QFileInfo::isSymLink)
    .property("isWritable", &QFileInfo::isWritable)
    .property("lastModified", &QFileInfo::lastModified)
    .property("lastRead", &QFileInfo::lastRead)
    .property("makeAbsolute", &QFileInfo::makeAbsolute)
    .property("owner", &QFileInfo::owner)
    .property("ownerId", &QFileInfo::ownerId)
    .property("path", &QFileInfo::path)
    .def("permission", &QFileInfo::permission)
    .property("permissions", &QFileInfo::permissions)
    .property("size", &QFileInfo::size)
    .property("suffix", &QFileInfo::suffix)
    .property("symLinkTarget", &QFileInfo::symLinkTarget)
    .def("refresh", &QFileInfo::refresh)
    .def("setFile", (void (QFileInfo::*)(const QDir&, const QString&))&QFileInfo::setFile)
    .def("setFile", (void (QFileInfo::*)(const QFile&))&QFileInfo::setFile)
    .def("setFile", (void (QFileInfo::*)(const QString&))&QFileInfo::setFile)
    ;
}










