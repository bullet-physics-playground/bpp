#ifndef PALETTE_H
#define PALETTE_H

#include <QColor>
#include <QList>

class Palette {
 public:
  Palette(QString fileName);
  ~Palette();

  QColor getRandomColor();

 protected:
	
  QList<unsigned char> colors[3];
};

#endif // PALETTE_H
