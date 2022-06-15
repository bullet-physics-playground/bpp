#include "lua_qftp.h"

#include "lua_qslot.h"

#include <luabind/adopt_policy.hpp>

namespace luabind{
    QT_ENUM_CONVERTER(QFtp::Command)
    QT_ENUM_CONVERTER(QFtp::Error)
    QT_ENUM_CONVERTER(QFtp::State)
    QT_ENUM_CONVERTER(QFtp::TransferMode)
    QT_ENUM_CONVERTER(QFtp::TransferType)
    QT_ENUM_CONVERTER(QUrlInfo::PermissionSpec)
}

QFile* lqftp_currentDevice(QFtp* w)
{
    return static_cast<QFile*>(w->currentDevice());
}

int lqftp_connectToHost(QFtp* w, const QString & host){ return w->connectToHost(host); }
int lqftp_get1(QFtp* w, const QString & file){ return w->get(file); }
int lqftp_get2(QFtp* w, const QString & file, QFile* f){ return w->get(file,f); }
int lqftp_get3(QFtp* w, const QString & file, QFile* f, QFtp::TransferType t){ return w->get(file,f,t); }
int lqftp_list1(QFtp* w){ return w->list(); }

int lqftp_login1(QFtp* w){ return w->login(); }
int lqftp_login2(QFtp* w, const QString& user){ return w->login(user); }


int lqftp_put1(QFtp* w, QFile* dev, const QString& file){ return w->put(dev,file);}
int lqftp_put2(QFtp* w, QFile* dev, const QString& file, QFtp::TransferType t){ return w->put(dev,file,t);}
int lqftp_put3(QFtp* w, const QByteArray& data, const QString& file){ return w->put(data,file);}
int lqftp_put4(QFtp* w, const QByteArray& data, const QString& file, QFtp::TransferType t){ return w->put(data,file,t);}



QByteArray lqftp_read(QFtp* w, qint64 max)
{
    QByteArray arr(max,0);
    qint64 r = w->read(arr.data(), max);
    arr.resize(r);
    return arr;
}

SIGNAL_PROPERYT(lqftp, commandFinished, QFtp, "(int,bool)")
SIGNAL_PROPERYT(lqftp, commandStarted, QFtp, "(int)")
SIGNAL_PROPERYT(lqftp, dataTransferProgress, QFtp, "(qint64,qint64)")
SIGNAL_PROPERYT(lqftp, done, QFtp, "(bool)")
SIGNAL_PROPERYT(lqftp, listInfo, QFtp, "(const QUrlInfo &)")
SIGNAL_PROPERYT(lqftp, rawCommandReply, QFtp, "(int,const QString&)")
SIGNAL_PROPERYT(lqftp, readyRead, QFtp, "()")
SIGNAL_PROPERYT(lqftp, stateChanged, QFtp, "(int)")

// raw version
int lqftp_cd(QFtp* w, const QByteArray& dir)
{
    return w->cd(QString::fromLatin1(dir));
}

int lqftp_connectToHost1(QFtp* w, const QByteArray & host, quint16 port){ return w->connectToHost(QString::fromLatin1(host),port); }
int lqftp_connectToHost2(QFtp* w, const QByteArray & host){ return w->connectToHost(QString::fromLatin1(host)); }

int lqftp_get4(QFtp* w, const QByteArray & file){ return w->get(QString::fromLatin1(file)); }
int lqftp_get5(QFtp* w, const QByteArray & file, QFile* f){ return w->get(QString::fromLatin1(file),f); }
int lqftp_get6(QFtp* w, const QByteArray & file, QFile* f, QFtp::TransferType t){ return w->get(QString::fromLatin1(file),f,t); }
int lqftp_list2(QFtp* w, const QByteArray & dir){ return w->list(QString::fromLatin1(dir)); }

int lqftp_login3(QFtp* w, const QByteArray& user){ return w->login(QString::fromLatin1(user)); }
int lqftp_login4(QFtp* w, const QByteArray& user, const QByteArray& pwd){ return w->login(QString::fromLatin1(user),QString::fromLatin1(pwd)); }

int lqftp_mkdir(QFtp* w, const QByteArray & dir){ return w->mkdir(QString::fromLatin1(dir)); }

int lqftp_put5(QFtp* w, QFile* dev, const QByteArray& file){ return w->put(dev,QString::fromLatin1(file));}
int lqftp_put6(QFtp* w, QFile* dev, const QByteArray& file, QFtp::TransferType t){ return w->put(dev,QString::fromLatin1(file),t);}
int lqftp_put7(QFtp* w, const QByteArray& data, const QByteArray& file){ return w->put(data,QString::fromLatin1(file));}
int lqftp_put8(QFtp* w, const QByteArray& data, const QByteArray& file, QFtp::TransferType t){ return w->put(data,QString::fromLatin1(file),t);}

int lqftp_rawcommand(QFtp* w, const QByteArray& cmd){ return w->rawCommand(QString::fromLatin1(cmd)); }

int lqftp_remove(QFtp* w, const QByteArray& file){ return w->remove(QString::fromLatin1(file)); }
int lqftp_rename(QFtp* w, const QByteArray& oldname, const QByteArray& newname){ return w->rename(QString::fromLatin1(oldname),QString::fromLatin1(newname)); }
int lqftp_rmdir(QFtp* w, const QByteArray& dir){ return w->rmdir(QString::fromLatin1(dir)); }
int lqftp_setProxy(QFtp* w, const QByteArray & host, quint16 port){ return w->setProxy(QString::fromLatin1(host),port); }

LQFtp lqftp()
{
    return
    class_<QFtp,QObject>("QFtp")
    .def(constructor<QObject*>())
    .def(constructor<>())
    .def("cd", &QFtp::cd)
    .def("cd", lqftp_cd)        // raw
    .def("clearPendingCommands", &QFtp::clearPendingCommands)
    .def("close", &QFtp::close)
    .def("connectToHost", &QFtp::connectToHost)
    .def("connectToHost", lqftp_connectToHost)
    .def("connectToHost", lqftp_connectToHost1) // raw
    .def("connectToHost", lqftp_connectToHost2) // raw
    .def("currentCommand", &QFtp::currentCommand)
    .def("currentDevice", lqftp_currentDevice)
    .def("currentId", &QFtp::currentId)
    .def("get", lqftp_get1)
    .def("get", lqftp_get2, adopt(_3))
    .def("get", lqftp_get3, adopt(_3))
    .def("get", lqftp_get4)                     // raw
    .def("get", lqftp_get5, adopt(_3))          // raw
    .def("get", lqftp_get6, adopt(_3))          // raw
    .def("list", &QFtp::list)
    .def("list", lqftp_list1)
    .def("list", lqftp_list2)                   // raw
    .def("login", &QFtp::login)
    .def("login", lqftp_login1)
    .def("login", lqftp_login2)
    .def("login", lqftp_login3)                 // raw
    .def("login", lqftp_login4)                 // raw
    .def("mkdir", &QFtp::mkdir)
    .def("mkdir", lqftp_mkdir)                  // raw
    .def("put", lqftp_put1, adopt(_2))
    .def("put", lqftp_put2, adopt(_2))
    .def("put", lqftp_put3)
    .def("put", lqftp_put4)
    .def("put", lqftp_put5, adopt(_2))          // raw
    .def("put", lqftp_put6, adopt(_2))          // raw
    .def("put", lqftp_put7)                     // raw
    .def("put", lqftp_put8)                     // raw
    .def("rawCommand", &QFtp::rawCommand)
    .def("rawCommand", lqftp_rawcommand)        // raw
    .def("read", lqftp_read)
    .def("readAll", &QFtp::readAll)
    .def("remove", &QFtp::remove)
    .def("remove", lqftp_remove)                // raw
    .def("rename", &QFtp::rename)
    .def("rename", lqftp_rename)                // raw
    .def("rmdir", &QFtp::rmdir)
    .def("rmdir", lqftp_rmdir)                  // raw
    .def("setProxy", &QFtp::setProxy)
    .def("setProxy", lqftp_setProxy)            // raw
    .def("setTransferMode", &QFtp::setTransferMode)
    .def("abort", &QFtp::abort)



    .property("error", &QFtp::error)
    .property("errorString", &QFtp::errorString)
    .property("hasPendingCommands", &QFtp::hasPendingCommands)
    .property("state", &QFtp::state)
    .sig_prop(lqftp, commandFinished)
    .sig_prop(lqftp, commandStarted)
    .sig_prop(lqftp, dataTransferProgress)
    .sig_prop(lqftp, done)
    .sig_prop(lqftp, listInfo)
    .sig_prop(lqftp, rawCommandReply)
    .sig_prop(lqftp, readyRead)
    .sig_prop(lqftp, stateChanged)
    ;
}

QByteArray lqurlinfo_name(QUrlInfo* w){ return w->name().toLatin1();}
void lqurlinfo_setName(QUrlInfo* w, const QByteArray& name){ return w->setName(QString::fromLatin1(name)); }
QByteArray lqurlinfo_owner(QUrlInfo* w){ return w->owner().toLatin1();}
void lqurlinfo_setOwner(QUrlInfo* w, const QByteArray& owner){ return w->setOwner(QString::fromLatin1(owner)); }

LQUrlInfo lqurlinfo()
{
    return
    class_<QUrlInfo>("QUrlInfo")
    .def(constructor<const QUrlInfo&>())
    .def(constructor<>())
    //.def(constructor<const QString&,int,const QString&,const QString&,qint64,const QDateTime&,const QDateTime&,bool,bool,bool,bool,bool,bool>())
    //.def(constructor<const QUrl&,int,const QString&,const QString&,qint64,const QDateTime&,const QDateTime&,bool,bool,bool,bool,bool,bool>())
    .def("setDir", &QUrlInfo::setDir)
    .def("setFile", &QUrlInfo::setFile)
    .def("setSymLink", &QUrlInfo::setSymLink)
    .def("setWritable", &QUrlInfo::setWritable)
    .def("setReadable", &QUrlInfo::setReadable)


    .property("group", &QUrlInfo::group, &QUrlInfo::setGroup)
    .property("isDir", &QUrlInfo::isDir, &QUrlInfo::setDir)
    .property("isExecutable", &QUrlInfo::isExecutable)
    .property("isFile", &QUrlInfo::isFile, &QUrlInfo::setFile)
    .property("isReadable", &QUrlInfo::isReadable, &QUrlInfo::setReadable)
    .property("isSymLink", &QUrlInfo::isSymLink, &QUrlInfo::setSymLink)
    .property("isValid", &QUrlInfo::isValid)
    .property("isWritable", &QUrlInfo::isWritable, &QUrlInfo::setWritable)
    .property("lastModified", &QUrlInfo::lastModified, &QUrlInfo::setLastModified)
    .property("lastRead", &QUrlInfo::lastRead, &QUrlInfo::setLastRead)
    .property("name", &QUrlInfo::name, &QUrlInfo::setName)
    .property("owner", &QUrlInfo::owner, &QUrlInfo::setOwner)
    .property("permissions", &QUrlInfo::permissions, &QUrlInfo::setPermissions)
    .property("size", &QUrlInfo::size, &QUrlInfo::setSize)
    .property("rawName", lqurlinfo_name, lqurlinfo_setName)
    .property("rawOwner", lqurlinfo_owner, lqurlinfo_setOwner)
    ;
}

QStringList lqtextcodec_aliases(QTextCodec* w)
{
    QStringList res;
    QList<QByteArray> r = w->aliases();
    foreach(QByteArray a, r){
        res.append( QString::fromAscii(a.data()));
    }
    return res;
}

QString lqtextcodec_fromUnicode(QTextCodec* w, const QString& s)
{
    QByteArray r = w->fromUnicode(s);
    return QString::fromAscii(r.data());
}

QByteArray lqtextcodec_fromUnicode1(QTextCodec* w, const QString& s)
{
    return w->fromUnicode(s);
}

QString lqtextcodec_toUnicode(QTextCodec* w, const QString& s)
{
    return w->toUnicode(s.toAscii());
}

QString lqtextcodec_toUnicode1(QTextCodec* w, const QByteArray& s)
{
    return w->toUnicode(s);
}

QString lqtextcodec_name(QTextCodec* w)
{
    return QString::fromAscii(w->name().data());
}

QString lqtextcodec_defname(QTextCodec* w)
{
    return QString::fromAscii(QTextCodec_wrap::def_name(w).data());
}

QStringList lqtextcodec_availableCodecs()
{
    QStringList res;
    QList<QByteArray> r = QTextCodec::availableCodecs();
    foreach(QByteArray a, r){
        res.append( QString::fromAscii(a.data()));
    }
    return res;
}

QTextCodec * lqtextcodec_codecForHtml1(const char* ba)
{
    return QTextCodec::codecForHtml(QByteArray::fromRawData(ba,strlen(ba)));
}

QTextCodec * lqtextcodec_codecForHtml2(const char* ba, QTextCodec* def)
{
    return QTextCodec::codecForHtml(QByteArray::fromRawData(ba,strlen(ba)),def);
}

QTextCodec * lqtextcodec_codecForUtfText1(const char* ba)
{
    return QTextCodec::codecForUtfText(QByteArray::fromRawData(ba,strlen(ba)));
}

QTextCodec * lqtextcodec_codecForUtfText2(const char* ba, QTextCodec* def)
{
    return QTextCodec::codecForUtfText(QByteArray::fromRawData(ba,strlen(ba)),def);
}

LQTextCodec lqtextcodec()
{
    return
    class_<QTextCodec,QTextCodec_wrap>("QTextCodec")
    .def("canEncode", (bool(QTextCodec::*)(const QString&)const)&QTextCodec::canEncode)
    .def("fromUnicode", lqtextcodec_fromUnicode1)
    .def("toUnicode", lqtextcodec_toUnicode)
    .def("toUnicode", lqtextcodec_toUnicode1)
    .property("aliases", lqtextcodec_aliases)
    .def("name", lqtextcodec_name, lqtextcodec_defname)
    .def("mibEnum", &QTextCodec::mibEnum, &QTextCodec_wrap::def_mibEnum)
    .scope[
        def("availableCodecs", lqtextcodec_availableCodecs),
        def("availableMibs", &QTextCodec::availableMibs),
        def("codecForCStrings", &QTextCodec::codecForCStrings),
        def("codecForLocale", &QTextCodec::codecForLocale),
        def("codecForMib", &QTextCodec::codecForMib),
        def("codecForTr", &QTextCodec::codecForTr),
        def("setCodecForCStrings", &QTextCodec::setCodecForCStrings),
        def("setCodecForLocale", &QTextCodec::setCodecForLocale),
        def("setCodecForTr", &QTextCodec::setCodecForTr),
        def("codecForHtml", lqtextcodec_codecForHtml1),
        def("codecForHtml", lqtextcodec_codecForHtml2),
        def("codecForUtfText", lqtextcodec_codecForUtfText1),
        def("codecForUtfText", lqtextcodec_codecForUtfText2),
        def("codecForName", (QTextCodec*(*)(const char*))&QTextCodec::codecForName)
    ]
    ;
}

QString lqtextdecoder_toUnicode(QTextDecoder* w, const QString& s)
{
    return w->toUnicode(s.toAscii());
}
LQTextDecoder lqtextdecoder()
{
    return
    class_<QTextDecoder>("QTextDecoder")
    .def("QTextDecoder", lqtextdecoder_toUnicode)
    .property("hasFailure", &QTextDecoder::hasFailure)
    ;
}

QString lqtextencoder_fromUnicode(QTextEncoder* w, const QString& s)
{
    QByteArray r = w->fromUnicode(s);
    return QString::fromAscii(r.data());
}

LQTextEncoder lqtextencoder()
{
    return
    class_<QTextEncoder>("QTextEncoder")
    .def("fromUnicode", lqtextencoder_fromUnicode)
    .property("hasFailure", &QTextEncoder::hasFailure)
    ;
}




