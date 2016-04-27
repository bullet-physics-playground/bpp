#ifndef PREFS_H
#define PREFS_H

#include <QtCore>

#include <QSettings>
#include <QKeyEvent>

#include "ui_prefs.h"

class Prefs : public QDialog , public Ui_Prefs {
  Q_OBJECT

public:
  Prefs(QWidget* parent = 0);
  ~Prefs();

  void accept();
  void activateGroupPage(QString group, int id);

	QVariant getValue(const QString &key) const;

protected:
  void changeEvent(QEvent *e);

protected Q_SLOTS:
  void changeGroup(QListWidgetItem *current, QListWidgetItem *previous);
  void on_buttonOk_clicked();

	void fontFamilyChanged(const QString &);
	void fontSizeChanged(const QString &);

 signals:
	void fontChanged(const QString &family, uint size) const;

private:
	void keyPressEvent(QKeyEvent *e);
	void updateGUI();
	void removeDefaultSettings();
  void setupPages();

private:
  QHash<QString, QList<QString> > _pages;
  bool invalidParameter;

  QSettings *_settings;
	QSettings::SettingsMap defaultmap;
};

#endif
