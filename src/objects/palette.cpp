#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "palette.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QFile>
#include <QRegExp>
#include <QStringList>
#include <QTextStream>
#include <QDebug>

#include <boost/shared_ptr.hpp>
#include <luabind/adopt_policy.hpp>

using namespace std;

std::ostream& operator<<(std::ostream& ostream, const Palette& pal) {
  ostream << pal.toString().toAscii().data();

  return ostream;
}

#include <luabind/operator.hpp>

Palette::Palette(QString fileName) : QObject() {
  QFile f(fileName);

  if (f.open(QIODevice::ReadOnly)) {
    QTextStream in(&f);
    QString line;

    QRegExp rx("(\\d+)");
    int lineNum = 0;
    do {
      line = in.readLine();
      lineNum++;
      QStringList list;
      int pos = 0;

      while ((pos = rx.indexIn(line, pos)) != -1) {
        list << rx.cap(1);
        pos += rx.matchedLength();
      }

      if (list.size() == 3) {
	bool ok;
	bool fail = false;

	colors[0].append(list.at(0).toInt(&ok)); if (!ok) fail = true;
	colors[1].append(list.at(1).toInt(&ok)); if (!ok) fail = true;
	colors[2].append(list.at(2).toInt(&ok)); if (!ok) fail = true;

	if (fail) {
	  qDebug() << "error parsing palette line " << lineNum << ": " << line;
	}
      } else {
	// qDebug() << "skipping " << line;
      }

    } while (!line.isNull());

    f.close();
  } else {
    qDebug() << "Cannot open file for reading: "
	 << qPrintable(f.errorString()) << endl;
    return;
  }
}

QColor Palette::getRandomColor() {
  unsigned int r,g,b;

  unsigned int random = qrand() % colors[0].size();

  r = colors[0].at(random);
  g = colors[1].at(random);
  b = colors[2].at(random);

  QColor col(r,g,b);

  return col;
}

Palette::~Palette()
{
}

void Palette::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Palette>("Palette")
     .def(constructor<QString>(), adopt(result))
     .def("getRandomColor", &Palette::getRandomColor)
     .def(tostring(const_self))
     ];
}

QString Palette::toString() const {
  return QString("Palette");
}
