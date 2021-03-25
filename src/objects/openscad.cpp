#include "openscad.h"

#include <QFile>
#include <QDir>
#include <QTemporaryFile>
#include <QProcess>
#include <QDebug>
#include <QStandardPaths>
#include <QCryptographicHash>
#include <QFileInfo>
#include <QSettings>

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

OpenSCAD::OpenSCAD(QString sdl, btScalar mass) : Mesh(NULL, mass) {
    this->sdl = sdl;

    // calculate SHA1 hash of OpenSCAD sdl text and see,
    // if OpenSCAD already has generated an STL file for the given OpenSCAD sdl text

    QCryptographicHash hashAlgo(QCryptographicHash::Sha1);
    hashAlgo.addData(sdl.toUtf8());
    QString hash = hashAlgo.result().toHex();

    QFileInfo cacheInfo(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    if (!cacheInfo.exists()) {
        QDir p(".");
        if (!p.mkpath(cacheInfo.absoluteFilePath())) {
            qDebug() << "unable to create " << cacheInfo.absoluteFilePath();
        }
    }

    QString stlfile = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QDir::separator() + hash + ".stl";

    // check, if the STL file exists in the cache. If so, load it and return
    QFileInfo check_file(stlfile);
    if (check_file.exists() && check_file.isFile()) {
        loadFile(stlfile, mass);
        return;
    }

    // else: the STL file needs to be generated with openscad:
    //// echo "cube([2,3,4]);" > /tmp/bpp.scad && openscad -o /tmp/bpp.stl /tmp/bpp.scad
    //QTemporaryFile tmp(QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/bpp");
    QTemporaryFile tmp("bpp");
    if (tmp.open()) {
        QFile scad(tmp.fileName() + ".scad");
        if (scad.open(QIODevice::WriteOnly | QIODevice::Text)) {
            // qDebug() << scad.fileName();
            QTextStream out(&scad);
            out << sdl;
            scad.close();

            QStringList args;

            QSettings s;
            QString openscad = s.value("openscad/executable", "/usr/bin/openscad").toString();

            args << openscad;
            args << "-o";
            args << stlfile;
            args << scad.fileName();

            qDebug() << "executing openscad " << args;

            QProcess p;
            p.start("nice", args);
            if (!p.waitForStarted()) {
                qDebug() << "openscad !p.waitForStarted()";
                return;
            }

            if (!p.waitForFinished(-1)) { // wait forever
                qDebug() << "openscad !p.waitForFinished()";
                return;
            }

            if (p.exitCode() != 0) {
                qDebug() << tr("openscad exited with code: %1.").arg(p.exitCode());
                QString err = p.readAllStandardError();
                if (!err.isEmpty()) {
                    qDebug() << err;
                }
                return;
            }

            loadFile(stlfile, mass);
        } else {
            qDebug() << tr("Error writing to file '%1'.").arg(scad.fileName());
            return;
        }
    }
}

void OpenSCAD::luaBind(lua_State *s) {
    using namespace luabind;

    open(s);

    module(s)
            [
            class_<OpenSCAD,Mesh>("OpenSCAD")
            .def(constructor<QString, btScalar>(), adopt(result))
            .def(tostring(const_self))
            ];
}

QString OpenSCAD::toString() const {
    return QString("OpenSCAD");
}
