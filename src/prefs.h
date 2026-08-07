#ifndef PREFS_H
#define PREFS_H

#include <QDialog>
#include <QHash>
#include <QListWidget>
#include <QString>
#include <QVariant>

#include <QKeyEvent>
#include <QSettings>

#include "ui_prefs.h"

QString getDefaultLuaPath(const QString &scriptBasePath = QString());

class Prefs : public QDialog, public Ui_Prefs {
  Q_OBJECT

public:
  Prefs(QSettings *settings, QWidget *parent = nullptr);
  ~Prefs();

  void accept();
  void activateGroupPage(const QString &group, int id);

  QVariant getValue(const QString &key) const;
  void setValue(const QString &key, QVariant value);

protected:
  void changeEvent(QEvent *e);

protected slots:
  void changeGroup(QListWidgetItem *current, QListWidgetItem *previous);
  void on_buttonOk_clicked();

  void guiOpenLastFileChanged(const bool);
  void guiWindowStateChanged(const bool);

  void fontFamilyChanged(const QString &);
  void fontSizeChanged(const QString &);

  void on_luaPathChanged();

  void on_povPreviewChanged();

  void on_povExecutableChanged();
  void on_povExecutableBrowse();

  void on_povExportDirChanged();
  void on_povExportDirBrowse();

  void on_scadExecutableChanged();
  void on_scadExecutableBrowse();

  void on_snNavigationModeChanged(int index);
  void on_snLockHorizonChanged(bool checked);
  void on_snAutoFlySpeedChanged(bool checked);
  void on_snShowOrbitAxisChanged(bool checked);
  void on_snZoomDirectionChanged(int index);
  void on_snPanZoomChanged(bool checked);

signals:
  void checkOpenLastFileChanged(const bool checked);
  void checkOpenLastWindowState(const bool checked);

  void fontChanged(const QString &family, uint size) const;

  void luaPathChanged(const QString &path) const;

  void povPreviewChanged(const QString &cmd) const;
  void povExecutableChanged(const QString &dir) const;
  void povExportDirChanged(const QString &dir) const;

  void scadExecutableChanged(const QString &dir) const;

  void snNavigationModeChanged(int mode) const;
  void snLockHorizonChanged(bool checked) const;
  void snAutoFlySpeedChanged(bool checked) const;
  void snShowOrbitAxisChanged(bool checked) const;
  void snZoomDirectionChanged(bool forward) const;
  void snPanZoomChanged(bool checked) const;

private:
  void keyPressEvent(QKeyEvent *e);
  void updateGUI();
  void setupPages();

private:
  QHash<QString, QList<QString>> _pages;
  bool invalidParameter;

  QSettings *_settings;
  QSettings::SettingsMap defaultmap;
};

#endif
