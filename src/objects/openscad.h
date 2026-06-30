#ifndef OPENSCAD_H
#define OPENSCAD_H

#ifdef HAS_LIB_ASSIMP

#include "mesh.h"

#include <QObject>
#include <QProcess>

class OpenSCAD : public Mesh {
  Q_OBJECT
public:
  explicit OpenSCAD(QString sdl, btScalar mass, bool centerOfMass = true);

  static void luaBind(lua_State *s);
  virtual QString toString() const;

  bool isReady() const;

signals:
  void stlReady();

private:
  void showProgressBar();
  void hideProgressBar();

  QString sdl;
  QProcess *m_process;
  QString m_stlfile;
  btScalar m_pendingMass;
  bool m_centerOfMass;
  bool m_stlReady;
};

#endif // HAS_LIB_ASSIMP

#endif // OPENSCAD_H
