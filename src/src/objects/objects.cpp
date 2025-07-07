#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "objects.h"

#include <GL/glut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

Objects::Objects() {
}

void Objects::luaBind(lua_State *s) {
    using namespace luabind;

    module(s)
            [
            class_<Objects, Object>("Objects")
            .def(constructor<>(), adopt(result))
            .def(tostring(const_self))
            ];
}

QList<Object *> Objects::getObjects() const {
    return QList<Object *>(); // FIXME
}

QString Objects::toString() const {
    return QString("Objects");
}

void Objects::toPOV(QTextStream *s) const {
    Q_UNUSED(s)
}

void Objects::renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb) {
    Q_UNUSED(minaabb)
    Q_UNUSED(maxaabb)
    qDebug() << "Objects::renderInLocalFrame should not be called!";
}
