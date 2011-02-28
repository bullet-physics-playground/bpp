#ifndef GUI_H
#define GUI_H

#include <QtGui>

#include "ui_gui.h"

#include "viewer.h"

#include "cmdline.h"

class Gui : public QWidget {
 Q_OBJECT

 public: 
  Gui(QWidget *parent = 0, bool savePOV = false, bool savePNG = false);
 

 private slots:
  void updateValues();
  void command(QString cmd);

 private:
  void log(QString text);

  Ui::GuiForm ui;

  Viewer *m_viewer;
  CommandLine *m_cmdline;
};

#endif
