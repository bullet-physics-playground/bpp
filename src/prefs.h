#ifndef PREFS_H
#define PREFS_H

#include <QtCore>

#include <QSettings>
#include <QKeyEvent>

#include "ui_prefs.h"

class Prefs : public QDialog , public Ui_Prefs {
    Q_OBJECT

public:
    Prefs(QSettings *settings, QWidget* parent = 0);
    ~Prefs();

    void accept();
    void activateGroupPage(QString group, int id);

    QVariant getValue(QString key) const;
    void setValue(QString key, QVariant value);

protected:
    void changeEvent(QEvent *e);

protected slots:
    void changeGroup(QListWidgetItem *current, QListWidgetItem *previous);
    void on_buttonOk_clicked();

    void fontFamilyChanged(const QString);
    void fontSizeChanged(const QString);

    void on_povPreviewChanged();
    void on_povExportDirChanged();
    void on_povExportDirBrowse();

signals:
    void fontChanged(const QString &family, uint size) const;
    void povPreviewChanged(QString cmd) const;
    void povExportDirChanged(QString dir) const;

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
