#include "palette.h"

#include <QFile>
#include <QRegExp>
#include <QStringList>
#include <QTextStream>
#include <QDebug>

using namespace std;

Palette::Palette(QString fileName) {
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
