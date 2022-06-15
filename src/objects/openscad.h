#ifndef OPENSCAD_H
#define OPENSCAD_H

#ifdef HAS_LIB_ASSIMP

#include "mesh.h"

#include <QObject>

class OpenSCAD : public Mesh
{
    Q_OBJECT
public:
    explicit OpenSCAD(QString sdl, btScalar mass);

    static void luaBind(lua_State *s);
    virtual QString toString() const;

signals:

public slots:

private:
    QString sdl;
};

#endif // HAS_LIB_ASSIMP

#endif // OPENSCAD_H
