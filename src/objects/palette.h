#ifndef PALETTE_H
#define PALETTE_H

#include "object.h"

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>
#include <QColor>
#include <QList>

class Palette;

std::ostream& operator<<(std::ostream&, const Palette& pal);

class Palette : public QObject {
    Q_OBJECT;

public:
    Palette(QString fileName);
    ~Palette();

    QColor getRandomColor();
    void setSeed(int seed);

    static void luaBind(lua_State *s);
    virtual QString toString() const;

protected:
    QList<unsigned char> colors[3];
};

#endif // PALETTE_H
