#ifndef GUI_H
#define GUI_H

#include <QtGui>

#include "ui_gui.h"

#include "commandline.h"
#include "viewer.h"

class Gui : public QMainWindow {
 Q_OBJECT

 public: 
  Gui(bool savePOV = false, bool savePNG = false, QWidget *parent = 0);

 private slots:
  void updateValues();
  void command(QString cmd);
  void closeEvent(QCloseEvent *);

 private:
  QSettings *settings;

  void log(QString text);

  void loadSettings();
  void saveSettings();

  Ui::MainWindow ui;
};

#endif
